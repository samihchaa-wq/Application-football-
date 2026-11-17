-- Entre deux saisons, « Précédente » désigne la dernière saison clôturée.
-- Même référence pour joueurs, équipe et pronostics. La saison actuelle reste
-- vide jusqu'à l'ouverture de la suivante. Aucun résultat n'est réécrit.
create view public.v_statistics_season_periods
with (security_invoker = true) as
with current_season as (
  select id, name
  from public.seasons
  where club_id = (select private.current_club_id()) and status = 'open'
  order by created_at desc, id desc
  limit 1
), previous_season as (
  select s.id, s.name
  from public.seasons s
  where s.club_id = (select private.current_club_id())
    and s.status in ('terminee', 'archived')
    and (not exists (select 1 from current_season)
         or s.name < (select name from current_season))
  order by s.name desc, s.created_at desc, s.id desc
  limit 1
)
select 'current'::text as period_key, id as season_id, name as period_label
from current_season
union all
select 'previous', id, name from previous_season;

alter view public.v_statistics_season_periods owner to club_scope;
revoke all on public.v_statistics_season_periods from public, anon;
grant select on public.v_statistics_season_periods to authenticated, service_role;

CREATE OR REPLACE VIEW "public"."v_statistics_players" WITH ("security_invoker"='true') AS
 WITH "open_season" AS (
         select season_id as id, period_label as name
         from public.v_statistics_season_periods where period_key = 'current'
        ), "prev_ref" AS (
         select season_id as id, period_label as name
         from public.v_statistics_season_periods where period_key = 'previous'
        ), "app_present" AS (
         SELECT "present"."match_id",
            "present"."season_player_id",
            "m"."season_id",
            "m"."score_as_grinta",
            "m"."score_adverse"
           FROM (( SELECT "match_attendance"."match_id",
                    "match_attendance"."season_player_id"
                   FROM "public"."match_attendance"
                UNION
                 SELECT "match_player_stats"."match_id",
                    "match_player_stats"."season_player_id"
                   FROM "public"."match_player_stats"
                UNION
                 SELECT "match_man_of_match"."match_id",
                    "match_man_of_match"."season_player_id"
                   FROM "public"."match_man_of_match") "present"
             JOIN "public"."matches" "m" ON ((("m"."id" = "present"."match_id") AND ("m"."status" = ANY (ARRAY['termine'::"text", 'archive'::"text"])))))
        ), "app_results" AS (
         SELECT "app_present"."season_player_id",
            ("count"(*))::integer AS "matches_played",
            ("count"(*) FILTER (WHERE ("app_present"."score_as_grinta" > "app_present"."score_adverse")))::integer AS "wins",
            ("count"(*) FILTER (WHERE ("app_present"."score_as_grinta" = "app_present"."score_adverse")))::integer AS "draws",
            ("count"(*) FILTER (WHERE ("app_present"."score_as_grinta" < "app_present"."score_adverse")))::integer AS "losses",
            ("count"(*) FILTER (WHERE ("app_present"."score_adverse" = 0)))::integer AS "team_clean_sheets"
           FROM "app_present"
          GROUP BY "app_present"."season_player_id"
        ), "app_pstats" AS (
         SELECT "st"."season_player_id",
            (COALESCE("sum"("st"."goals"), (0)::bigint))::integer AS "goals",
            (COALESCE("sum"("st"."assists"), (0)::bigint))::integer AS "assists",
            ("count"(*) FILTER (WHERE "st"."clean_sheet"))::integer AS "clean_sheets"
           FROM ("public"."match_player_stats" "st"
             JOIN "public"."matches" "m" ON ((("m"."id" = "st"."match_id") AND ("m"."status" = ANY (ARRAY['termine'::"text", 'archive'::"text"])))))
          GROUP BY "st"."season_player_id"
        ), "app_mvp" AS (
         SELECT "mvp"."season_player_id",
            ("count"(DISTINCT "mvp"."match_id"))::integer AS "hdm"
           FROM ("public"."match_man_of_match" "mvp"
             JOIN "public"."matches" "m" ON ((("m"."id" = "mvp"."match_id") AND ("m"."status" = ANY (ARRAY['termine'::"text", 'archive'::"text"])))))
          GROUP BY "mvp"."season_player_id"
        ), "app_season_player" AS (
         SELECT "sp"."season_id",
            "sp"."profile_id",
            "sp"."position" AS "display_order",
            "concat_ws"(' '::"text", "sp"."first_name", NULLIF("sp"."last_name", ''::"text")) AS "full_name",
            "sp"."is_goalkeeper",
            "sp"."is_active",
            COALESCE("r"."matches_played", 0) AS "matches_played",
            COALESCE("r"."wins", 0) AS "wins",
            COALESCE("r"."draws", 0) AS "draws",
            COALESCE("r"."losses", 0) AS "losses",
            COALESCE("g"."goals", 0) AS "goals",
            COALESCE("g"."assists", 0) AS "assists",
            COALESCE("mv"."hdm", 0) AS "hdm",
            COALESCE("g"."clean_sheets", 0) AS "clean_sheets",
            COALESCE("r"."team_clean_sheets", 0) AS "team_clean_sheets",
                CASE
                    WHEN "sp"."is_goalkeeper" THEN COALESCE("g"."clean_sheets", 0)
                    ELSE COALESCE("g"."goals", 0)
                END AS "ranking_metric"
           FROM ((("public"."season_players" "sp"
             LEFT JOIN "app_results" "r" ON (("r"."season_player_id" = "sp"."id")))
             LEFT JOIN "app_pstats" "g" ON (("g"."season_player_id" = "sp"."id")))
             LEFT JOIN "app_mvp" "mv" ON (("mv"."season_player_id" = "sp"."id")))
          WHERE (NOT "sp"."is_coach")
        ), "prev_has_app" AS (
         SELECT (EXISTS ( SELECT 1
                   FROM ("app_season_player" "asp"
                     JOIN "prev_ref" "pr" ON (("pr"."id" = "asp"."season_id"))))) AS "has_app"
        ), "current_ranked" AS (
         SELECT 'current'::"text" AS "period_key",
            "os"."name" AS "period_label",
            ("rank"() OVER (PARTITION BY "asp"."is_goalkeeper" ORDER BY "asp"."ranking_metric" DESC))::integer AS "display_rank",
            COALESCE("asp"."display_order", 9999) AS "display_order",
            "asp"."full_name" AS "player_name",
            "asp"."is_goalkeeper",
            "asp"."matches_played",
            "asp"."wins",
            "asp"."draws",
            "asp"."losses",
            "asp"."goals",
            "asp"."assists",
            "asp"."hdm",
            "asp"."clean_sheets",
            "asp"."profile_id",
            "asp"."team_clean_sheets",
            NULL::"uuid" AS "archive_player_id",
            "asp"."full_name" AS "app_full_name"
           FROM ("app_season_player" "asp"
             JOIN "open_season" "os" ON (("os"."id" = "asp"."season_id")))
          WHERE "asp"."is_active"
        ), "previous_from_app" AS (
         SELECT 'previous'::"text" AS "period_key",
            "pr"."name" AS "period_label",
            ("rank"() OVER (PARTITION BY "asp"."is_goalkeeper" ORDER BY "asp"."ranking_metric" DESC))::integer AS "display_rank",
            COALESCE("asp"."display_order", 9999) AS "display_order",
            "asp"."full_name" AS "player_name",
            "asp"."is_goalkeeper",
            "asp"."matches_played",
            "asp"."wins",
            "asp"."draws",
            "asp"."losses",
            "asp"."goals",
            "asp"."assists",
            "asp"."hdm",
            "asp"."clean_sheets",
            "asp"."profile_id",
            "asp"."team_clean_sheets",
            NULL::"uuid" AS "archive_player_id",
            "asp"."full_name" AS "app_full_name"
           FROM (("app_season_player" "asp"
             JOIN "prev_ref" "pr" ON (("pr"."id" = "asp"."season_id")))
             CROSS JOIN "prev_has_app" "ph")
          WHERE "ph"."has_app"
        ), "previous_from_import" AS (
         SELECT 'previous'::"text" AS "period_key",
            "h"."season_name" AS "period_label",
            "h"."display_rank",
            "h"."display_rank" AS "display_order",
            "h"."player_name",
            "h"."is_goalkeeper",
            "h"."matches_played",
            "h"."wins",
            "h"."draws",
            "h"."losses",
            "h"."goals",
            0 AS "assists",
            "h"."hdm",
            COALESCE("h"."clean_sheets", 0) AS "clean_sheets",
            "h"."profile_id",
            COALESCE("h"."team_clean_sheets", 0) AS "team_clean_sheets",
            "h"."player_id" AS "archive_player_id",
            NULL::"text" AS "app_full_name"
           FROM ("public"."historical_player_statistics" "h"
             CROSS JOIN "prev_has_app" "ph")
          WHERE (("h"."scope" = 'previous'::"text") AND (NOT "ph"."has_app"))
        ), "historical_all_time" AS (
         SELECT "h"."player_id",
            "h"."player_name",
            "h"."profile_id",
            "h"."is_goalkeeper",
            "h"."matches_played",
            "h"."wins",
            "h"."draws",
            "h"."losses",
            "h"."goals",
            "h"."hdm",
            COALESCE("h"."clean_sheets", 0) AS "clean_sheets",
            COALESCE("h"."team_clean_sheets", 0) AS "team_clean_sheets"
           FROM "public"."historical_player_statistics" "h"
          WHERE ("h"."scope" = 'all_time'::"text")
        ), "app_all" AS (
         SELECT "app_season_player"."full_name",
            "app_season_player"."is_goalkeeper",
            ("max"(("app_season_player"."profile_id")::"text"))::"uuid" AS "profile_id",
            ("sum"("app_season_player"."matches_played"))::integer AS "matches_played",
            ("sum"("app_season_player"."wins"))::integer AS "wins",
            ("sum"("app_season_player"."draws"))::integer AS "draws",
            ("sum"("app_season_player"."losses"))::integer AS "losses",
            ("sum"("app_season_player"."goals"))::integer AS "goals",
            ("sum"("app_season_player"."assists"))::integer AS "assists",
            ("sum"("app_season_player"."hdm"))::integer AS "hdm",
            ("sum"("app_season_player"."clean_sheets"))::integer AS "clean_sheets",
            ("sum"("app_season_player"."team_clean_sheets"))::integer AS "team_clean_sheets"
           FROM "app_season_player"
          GROUP BY "app_season_player"."full_name", "app_season_player"."is_goalkeeper"
         HAVING ("sum"("app_season_player"."matches_played") > 0)
        ), "all_time_combined" AS (
         SELECT COALESCE("history"."player_name", "app"."full_name") AS "player_name",
            COALESCE("history"."profile_id", "app"."profile_id") AS "profile_id",
            COALESCE("history"."is_goalkeeper", "app"."is_goalkeeper") AS "is_goalkeeper",
            (COALESCE("history"."matches_played", 0) + COALESCE("app"."matches_played", 0)) AS "matches_played",
            (COALESCE("history"."wins", 0) + COALESCE("app"."wins", 0)) AS "wins",
            (COALESCE("history"."draws", 0) + COALESCE("app"."draws", 0)) AS "draws",
            (COALESCE("history"."losses", 0) + COALESCE("app"."losses", 0)) AS "losses",
            (COALESCE("history"."goals", 0) + COALESCE("app"."goals", 0)) AS "goals",
            COALESCE("app"."assists", 0) AS "assists",
            (COALESCE("history"."hdm", 0) + COALESCE("app"."hdm", 0)) AS "hdm",
            (COALESCE("history"."clean_sheets", 0) + COALESCE("app"."clean_sheets", 0)) AS "clean_sheets",
            (COALESCE("history"."team_clean_sheets", 0) + COALESCE("app"."team_clean_sheets", 0)) AS "team_clean_sheets",
            "history"."player_id" AS "archive_player_id",
            "app"."full_name" AS "app_full_name"
           FROM ("historical_all_time" "history"
             FULL JOIN "app_all" "app" ON ((("lower"("btrim"("history"."player_name")) = "lower"("btrim"("app"."full_name"))) AND ("history"."is_goalkeeper" = "app"."is_goalkeeper"))))
        ), "all_time_ranked" AS (
         SELECT 'all_time'::"text" AS "period_key",
            'Toutes saisons'::"text" AS "period_label",
            ("rank"() OVER (PARTITION BY "all_time_combined"."is_goalkeeper" ORDER BY "all_time_combined"."matches_played" DESC, "all_time_combined"."goals" DESC, "all_time_combined"."player_name"))::integer AS "display_rank",
            ("rank"() OVER (PARTITION BY "all_time_combined"."is_goalkeeper" ORDER BY "all_time_combined"."matches_played" DESC, "all_time_combined"."goals" DESC, "all_time_combined"."player_name"))::integer AS "display_order",
            "all_time_combined"."player_name",
            "all_time_combined"."is_goalkeeper",
            "all_time_combined"."matches_played",
            "all_time_combined"."wins",
            "all_time_combined"."draws",
            "all_time_combined"."losses",
            "all_time_combined"."goals",
            "all_time_combined"."assists",
            "all_time_combined"."hdm",
            "all_time_combined"."clean_sheets",
            "all_time_combined"."profile_id",
            "all_time_combined"."team_clean_sheets",
            "all_time_combined"."archive_player_id",
            "all_time_combined"."app_full_name"
           FROM "all_time_combined"
        )
 SELECT "current_ranked"."period_key",
    "current_ranked"."period_label",
    "current_ranked"."display_rank",
    "current_ranked"."display_order",
    "current_ranked"."player_name",
    "current_ranked"."is_goalkeeper",
    "current_ranked"."matches_played",
    "current_ranked"."wins",
    "current_ranked"."draws",
    "current_ranked"."losses",
    "current_ranked"."goals",
    "current_ranked"."hdm",
    "current_ranked"."clean_sheets",
    "current_ranked"."profile_id",
    "current_ranked"."team_clean_sheets",
    "current_ranked"."assists",
    "current_ranked"."archive_player_id",
    "current_ranked"."app_full_name"
   FROM "current_ranked"
UNION ALL
 SELECT "previous_from_app"."period_key",
    "previous_from_app"."period_label",
    "previous_from_app"."display_rank",
    "previous_from_app"."display_order",
    "previous_from_app"."player_name",
    "previous_from_app"."is_goalkeeper",
    "previous_from_app"."matches_played",
    "previous_from_app"."wins",
    "previous_from_app"."draws",
    "previous_from_app"."losses",
    "previous_from_app"."goals",
    "previous_from_app"."hdm",
    "previous_from_app"."clean_sheets",
    "previous_from_app"."profile_id",
    "previous_from_app"."team_clean_sheets",
    "previous_from_app"."assists",
    "previous_from_app"."archive_player_id",
    "previous_from_app"."app_full_name"
   FROM "previous_from_app"
UNION ALL
 SELECT "previous_from_import"."period_key",
    "previous_from_import"."period_label",
    "previous_from_import"."display_rank",
    "previous_from_import"."display_order",
    "previous_from_import"."player_name",
    "previous_from_import"."is_goalkeeper",
    "previous_from_import"."matches_played",
    "previous_from_import"."wins",
    "previous_from_import"."draws",
    "previous_from_import"."losses",
    "previous_from_import"."goals",
    "previous_from_import"."hdm",
    "previous_from_import"."clean_sheets",
    "previous_from_import"."profile_id",
    "previous_from_import"."team_clean_sheets",
    "previous_from_import"."assists",
    "previous_from_import"."archive_player_id",
    "previous_from_import"."app_full_name"
   FROM "previous_from_import"
UNION ALL
 SELECT "all_time_ranked"."period_key",
    "all_time_ranked"."period_label",
    "all_time_ranked"."display_rank",
    "all_time_ranked"."display_order",
    "all_time_ranked"."player_name",
    "all_time_ranked"."is_goalkeeper",
    "all_time_ranked"."matches_played",
    "all_time_ranked"."wins",
    "all_time_ranked"."draws",
    "all_time_ranked"."losses",
    "all_time_ranked"."goals",
    "all_time_ranked"."hdm",
    "all_time_ranked"."clean_sheets",
    "all_time_ranked"."profile_id",
    "all_time_ranked"."team_clean_sheets",
    "all_time_ranked"."assists",
    "all_time_ranked"."archive_player_id",
    "all_time_ranked"."app_full_name"
   FROM "all_time_ranked";


alter view public.v_statistics_players owner to club_scope;

CREATE OR REPLACE VIEW "public"."v_statistics_team_dynamic_base" WITH ("security_invoker"='true') AS
 WITH "open_season" AS (
         select season_id as id, period_label as name
         from public.v_statistics_season_periods where period_key = 'current'
        ), "previous_season" AS (
         select season_id as id, period_label as name
         from public.v_statistics_season_periods where period_key = 'previous'
        ), "baseline" AS (
         SELECT "historical_team_statistics"."scope",
            "historical_team_statistics"."through_season",
            "historical_team_statistics"."matches_played",
            "historical_team_statistics"."wins",
            "historical_team_statistics"."draws",
            "historical_team_statistics"."losses",
            "historical_team_statistics"."goals_for",
            "historical_team_statistics"."goals_against",
            "historical_team_statistics"."best_win_streak",
            "historical_team_statistics"."best_win_start",
            "historical_team_statistics"."best_win_end",
            "historical_team_statistics"."best_unbeaten_streak",
            "historical_team_statistics"."best_unbeaten_start",
            "historical_team_statistics"."best_unbeaten_end",
            "historical_team_statistics"."worst_loss_streak",
            "historical_team_statistics"."worst_loss_start",
            "historical_team_statistics"."worst_loss_end",
            "historical_team_statistics"."worst_winless_streak",
            "historical_team_statistics"."worst_winless_start",
            "historical_team_statistics"."worst_winless_end",
            "historical_team_statistics"."updated_at"
           FROM "public"."historical_team_statistics"
          WHERE ("historical_team_statistics"."scope" = 'all_time'::"text")
        ), "scored_matches" AS (
         SELECT "m"."id",
            "m"."season_id",
            "s"."name" AS "season_name",
            "m"."match_date",
            "m"."score_as_grinta" AS "goals_for",
            "m"."score_adverse" AS "goals_against",
            ("m"."score_as_grinta" - "m"."score_adverse") AS "margin",
                CASE
                    WHEN ("m"."score_as_grinta" > "m"."score_adverse") THEN 'V'::"text"
                    WHEN ("m"."score_as_grinta" = "m"."score_adverse") THEN 'N'::"text"
                    ELSE 'D'::"text"
                END AS "result"
           FROM ("public"."matches" "m"
             JOIN "public"."seasons" "s" ON (("s"."id" = "m"."season_id")))
          WHERE (("m"."status" = ANY (ARRAY['termine'::"text", 'archive'::"text"])) AND ("m"."score_as_grinta" IS NOT NULL) AND ("m"."score_adverse" IS NOT NULL))
        ), "period_refs" AS (
         SELECT 'current'::"text" AS "period_key",
            "current"."id" AS "season_id",
            "current"."name" AS "period_label"
           FROM "open_season" "current"
        UNION ALL
         SELECT 'previous'::"text" AS "text",
            "previous"."id",
            "previous"."name"
           FROM "previous_season" "previous"
        ), "period_totals" AS (
         SELECT "refs"."period_key",
            "refs"."period_label",
            ("count"("matches"."id"))::integer AS "matches_played",
            ("count"(*) FILTER (WHERE ("matches"."result" = 'V'::"text")))::integer AS "wins",
            ("count"(*) FILTER (WHERE ("matches"."result" = 'N'::"text")))::integer AS "draws",
            ("count"(*) FILTER (WHERE ("matches"."result" = 'D'::"text")))::integer AS "losses",
            (COALESCE("sum"("matches"."goals_for"), (0)::bigint))::integer AS "goals_for",
            (COALESCE("sum"("matches"."goals_against"), (0)::bigint))::integer AS "goals_against"
           FROM ("period_refs" "refs"
             LEFT JOIN "scored_matches" "matches" ON (("matches"."season_id" = "refs"."season_id")))
          GROUP BY "refs"."period_key", "refs"."period_label"
        ), "period_recent_ranked" AS (
         SELECT "refs"."period_key",
            "matches"."result",
            "matches"."match_date",
            "matches"."id",
            "row_number"() OVER (PARTITION BY "refs"."period_key" ORDER BY "matches"."match_date" DESC, "matches"."id" DESC) AS "recent_rank"
           FROM ("period_refs" "refs"
             JOIN "scored_matches" "matches" ON (("matches"."season_id" = "refs"."season_id")))
        ), "period_recent" AS (
         SELECT "period_recent_ranked"."period_key",
            "array_agg"("period_recent_ranked"."result" ORDER BY "period_recent_ranked"."match_date", "period_recent_ranked"."id") AS "recent_results"
           FROM "period_recent_ranked"
          WHERE ("period_recent_ranked"."recent_rank" <= 6)
          GROUP BY "period_recent_ranked"."period_key"
        ), "period_margin_counts" AS (
         SELECT "refs"."period_key",
            "matches"."margin",
            ("count"(*))::integer AS "match_count"
           FROM ("period_refs" "refs"
             JOIN "scored_matches" "matches" ON (("matches"."season_id" = "refs"."season_id")))
          GROUP BY "refs"."period_key", "matches"."margin"
        ), "period_margins" AS (
         SELECT "period_margin_counts"."period_key",
            "jsonb_object_agg"(("period_margin_counts"."margin")::"text", "period_margin_counts"."match_count" ORDER BY "period_margin_counts"."margin") AS "distribution"
           FROM "period_margin_counts"
          GROUP BY "period_margin_counts"."period_key"
        ), "period_streak_expanded" AS (
         SELECT "refs"."period_key",
            "matches"."id",
            "matches"."match_date",
            "streak"."kind",
            "streak"."qualifies",
            "sum"(
                CASE
                    WHEN "streak"."qualifies" THEN 0
                    ELSE 1
                END) OVER (PARTITION BY "refs"."period_key", "streak"."kind" ORDER BY "matches"."match_date", "matches"."id") AS "streak_group"
           FROM (("period_refs" "refs"
             JOIN "scored_matches" "matches" ON (("matches"."season_id" = "refs"."season_id")))
             CROSS JOIN LATERAL ( VALUES ('win'::"text",("matches"."result" = 'V'::"text")), ('unbeaten'::"text",("matches"."result" <> 'D'::"text")), ('loss'::"text",("matches"."result" = 'D'::"text")), ('winless'::"text",("matches"."result" <> 'V'::"text"))) "streak"("kind", "qualifies"))
        ), "period_streaks" AS (
         SELECT "period_streak_expanded"."period_key",
            "period_streak_expanded"."kind",
            ("count"(*))::integer AS "streak_length",
            "min"("period_streak_expanded"."match_date") AS "start_date",
            "max"("period_streak_expanded"."match_date") AS "end_date"
           FROM "period_streak_expanded"
          WHERE "period_streak_expanded"."qualifies"
          GROUP BY "period_streak_expanded"."period_key", "period_streak_expanded"."kind", "period_streak_expanded"."streak_group"
        ), "period_streak_ranked" AS (
         SELECT "period_streaks"."period_key",
            "period_streaks"."kind",
            "period_streaks"."streak_length",
            "period_streaks"."start_date",
            "period_streaks"."end_date",
            "row_number"() OVER (PARTITION BY "period_streaks"."period_key", "period_streaks"."kind" ORDER BY "period_streaks"."streak_length" DESC, "period_streaks"."end_date" DESC) AS "streak_rank"
           FROM "period_streaks"
        ), "period_streak_summary" AS (
         SELECT "period_streak_ranked"."period_key",
            COALESCE("max"("period_streak_ranked"."streak_length") FILTER (WHERE (("period_streak_ranked"."kind" = 'win'::"text") AND ("period_streak_ranked"."streak_rank" = 1))), 0) AS "best_win_streak",
            "max"("period_streak_ranked"."start_date") FILTER (WHERE (("period_streak_ranked"."kind" = 'win'::"text") AND ("period_streak_ranked"."streak_rank" = 1))) AS "best_win_start",
            "max"("period_streak_ranked"."end_date") FILTER (WHERE (("period_streak_ranked"."kind" = 'win'::"text") AND ("period_streak_ranked"."streak_rank" = 1))) AS "best_win_end",
            COALESCE("max"("period_streak_ranked"."streak_length") FILTER (WHERE (("period_streak_ranked"."kind" = 'unbeaten'::"text") AND ("period_streak_ranked"."streak_rank" = 1))), 0) AS "best_unbeaten_streak",
            "max"("period_streak_ranked"."start_date") FILTER (WHERE (("period_streak_ranked"."kind" = 'unbeaten'::"text") AND ("period_streak_ranked"."streak_rank" = 1))) AS "best_unbeaten_start",
            "max"("period_streak_ranked"."end_date") FILTER (WHERE (("period_streak_ranked"."kind" = 'unbeaten'::"text") AND ("period_streak_ranked"."streak_rank" = 1))) AS "best_unbeaten_end",
            COALESCE("max"("period_streak_ranked"."streak_length") FILTER (WHERE (("period_streak_ranked"."kind" = 'loss'::"text") AND ("period_streak_ranked"."streak_rank" = 1))), 0) AS "worst_loss_streak",
            "max"("period_streak_ranked"."start_date") FILTER (WHERE (("period_streak_ranked"."kind" = 'loss'::"text") AND ("period_streak_ranked"."streak_rank" = 1))) AS "worst_loss_start",
            "max"("period_streak_ranked"."end_date") FILTER (WHERE (("period_streak_ranked"."kind" = 'loss'::"text") AND ("period_streak_ranked"."streak_rank" = 1))) AS "worst_loss_end",
            COALESCE("max"("period_streak_ranked"."streak_length") FILTER (WHERE (("period_streak_ranked"."kind" = 'winless'::"text") AND ("period_streak_ranked"."streak_rank" = 1))), 0) AS "worst_winless_streak",
            "max"("period_streak_ranked"."start_date") FILTER (WHERE (("period_streak_ranked"."kind" = 'winless'::"text") AND ("period_streak_ranked"."streak_rank" = 1))) AS "worst_winless_start",
            "max"("period_streak_ranked"."end_date") FILTER (WHERE (("period_streak_ranked"."kind" = 'winless'::"text") AND ("period_streak_ranked"."streak_rank" = 1))) AS "worst_winless_end"
           FROM "period_streak_ranked"
          GROUP BY "period_streak_ranked"."period_key"
        ), "dynamic_periods" AS (
         SELECT "totals"."period_key",
            "totals"."period_label",
            "totals"."matches_played",
            "totals"."wins",
            "totals"."draws",
            "totals"."losses",
            "totals"."goals_for",
            "totals"."goals_against",
            ("totals"."goals_for" - "totals"."goals_against") AS "goal_difference",
            0 AS "clean_sheets",
            COALESCE("recent"."recent_results", ARRAY[]::"text"[]) AS "recent_results",
            "margins"."distribution" AS "score_margin_distribution",
            COALESCE("streaks"."best_win_streak", 0) AS "best_win_streak",
            "streaks"."best_win_start",
            "streaks"."best_win_end",
            COALESCE("streaks"."best_unbeaten_streak", 0) AS "best_unbeaten_streak",
            "streaks"."best_unbeaten_start",
            "streaks"."best_unbeaten_end",
            COALESCE("streaks"."worst_loss_streak", 0) AS "worst_loss_streak",
            "streaks"."worst_loss_start",
            "streaks"."worst_loss_end",
            COALESCE("streaks"."worst_winless_streak", 0) AS "worst_winless_streak",
            "streaks"."worst_winless_start",
            "streaks"."worst_winless_end"
           FROM ((("period_totals" "totals"
             LEFT JOIN "period_recent" "recent" USING ("period_key"))
             LEFT JOIN "period_margins" "margins" USING ("period_key"))
             LEFT JOIN "period_streak_summary" "streaks" USING ("period_key"))
        ), "post_baseline_matches" AS (
         SELECT "matches"."id",
            "matches"."season_id",
            "matches"."season_name",
            "matches"."match_date",
            "matches"."goals_for",
            "matches"."goals_against",
            "matches"."margin",
            "matches"."result"
           FROM ("scored_matches" "matches"
             CROSS JOIN "baseline" "history")
          WHERE ("matches"."season_name" > "history"."through_season")
        ), "all_time_sequence" AS (
         SELECT "matches"."id",
            "matches"."season_id",
            "matches"."season_name",
            "matches"."match_date",
            "matches"."goals_for",
            "matches"."goals_against",
            "matches"."margin",
            "matches"."result"
           FROM ("scored_matches" "matches"
             CROSS JOIN "baseline" "history")
          WHERE ("matches"."season_name" >= "history"."through_season")
        ), "all_time_totals" AS (
         SELECT ("history"."matches_played" + ("count"("matches"."id"))::integer) AS "matches_played",
            ("history"."wins" + ("count"(*) FILTER (WHERE ("matches"."result" = 'V'::"text")))::integer) AS "wins",
            ("history"."draws" + ("count"(*) FILTER (WHERE ("matches"."result" = 'N'::"text")))::integer) AS "draws",
            ("history"."losses" + ("count"(*) FILTER (WHERE ("matches"."result" = 'D'::"text")))::integer) AS "losses",
            ("history"."goals_for" + (COALESCE("sum"("matches"."goals_for"), (0)::bigint))::integer) AS "goals_for",
            ("history"."goals_against" + (COALESCE("sum"("matches"."goals_against"), (0)::bigint))::integer) AS "goals_against"
           FROM ("baseline" "history"
             LEFT JOIN "post_baseline_matches" "matches" ON (true))
          GROUP BY "history"."matches_played", "history"."wins", "history"."draws", "history"."losses", "history"."goals_for", "history"."goals_against"
        ), "all_time_recent_ranked" AS (
         SELECT "all_time_sequence"."result",
            "all_time_sequence"."match_date",
            "all_time_sequence"."id",
            "row_number"() OVER (ORDER BY "all_time_sequence"."match_date" DESC, "all_time_sequence"."id" DESC) AS "recent_rank"
           FROM "all_time_sequence"
        ), "all_time_recent" AS (
         SELECT "array_agg"("all_time_recent_ranked"."result" ORDER BY "all_time_recent_ranked"."match_date", "all_time_recent_ranked"."id") AS "recent_results"
           FROM "all_time_recent_ranked"
          WHERE ("all_time_recent_ranked"."recent_rank" <= 6)
        ), "all_time_streak_expanded" AS (
         SELECT "matches"."id",
            "matches"."match_date",
            "streak"."kind",
            "streak"."qualifies",
            "sum"(
                CASE
                    WHEN "streak"."qualifies" THEN 0
                    ELSE 1
                END) OVER (PARTITION BY "streak"."kind" ORDER BY "matches"."match_date", "matches"."id") AS "streak_group"
           FROM ("all_time_sequence" "matches"
             CROSS JOIN LATERAL ( VALUES ('win'::"text",("matches"."result" = 'V'::"text")), ('unbeaten'::"text",("matches"."result" <> 'D'::"text")), ('loss'::"text",("matches"."result" = 'D'::"text")), ('winless'::"text",("matches"."result" <> 'V'::"text"))) "streak"("kind", "qualifies"))
        ), "all_time_streaks" AS (
         SELECT "all_time_streak_expanded"."kind",
            ("count"(*))::integer AS "streak_length",
            "min"("all_time_streak_expanded"."match_date") AS "start_date",
            "max"("all_time_streak_expanded"."match_date") AS "end_date"
           FROM "all_time_streak_expanded"
          WHERE "all_time_streak_expanded"."qualifies"
          GROUP BY "all_time_streak_expanded"."kind", "all_time_streak_expanded"."streak_group"
        ), "all_time_streak_ranked" AS (
         SELECT "all_time_streaks"."kind",
            "all_time_streaks"."streak_length",
            "all_time_streaks"."start_date",
            "all_time_streaks"."end_date",
            "row_number"() OVER (PARTITION BY "all_time_streaks"."kind" ORDER BY "all_time_streaks"."streak_length" DESC, "all_time_streaks"."end_date" DESC) AS "streak_rank"
           FROM "all_time_streaks"
        ), "all_time_dynamic_streaks" AS (
         SELECT COALESCE("max"("all_time_streak_ranked"."streak_length") FILTER (WHERE (("all_time_streak_ranked"."kind" = 'win'::"text") AND ("all_time_streak_ranked"."streak_rank" = 1))), 0) AS "best_win_streak",
            "max"("all_time_streak_ranked"."start_date") FILTER (WHERE (("all_time_streak_ranked"."kind" = 'win'::"text") AND ("all_time_streak_ranked"."streak_rank" = 1))) AS "best_win_start",
            "max"("all_time_streak_ranked"."end_date") FILTER (WHERE (("all_time_streak_ranked"."kind" = 'win'::"text") AND ("all_time_streak_ranked"."streak_rank" = 1))) AS "best_win_end",
            COALESCE("max"("all_time_streak_ranked"."streak_length") FILTER (WHERE (("all_time_streak_ranked"."kind" = 'unbeaten'::"text") AND ("all_time_streak_ranked"."streak_rank" = 1))), 0) AS "best_unbeaten_streak",
            "max"("all_time_streak_ranked"."start_date") FILTER (WHERE (("all_time_streak_ranked"."kind" = 'unbeaten'::"text") AND ("all_time_streak_ranked"."streak_rank" = 1))) AS "best_unbeaten_start",
            "max"("all_time_streak_ranked"."end_date") FILTER (WHERE (("all_time_streak_ranked"."kind" = 'unbeaten'::"text") AND ("all_time_streak_ranked"."streak_rank" = 1))) AS "best_unbeaten_end",
            COALESCE("max"("all_time_streak_ranked"."streak_length") FILTER (WHERE (("all_time_streak_ranked"."kind" = 'loss'::"text") AND ("all_time_streak_ranked"."streak_rank" = 1))), 0) AS "worst_loss_streak",
            "max"("all_time_streak_ranked"."start_date") FILTER (WHERE (("all_time_streak_ranked"."kind" = 'loss'::"text") AND ("all_time_streak_ranked"."streak_rank" = 1))) AS "worst_loss_start",
            "max"("all_time_streak_ranked"."end_date") FILTER (WHERE (("all_time_streak_ranked"."kind" = 'loss'::"text") AND ("all_time_streak_ranked"."streak_rank" = 1))) AS "worst_loss_end",
            COALESCE("max"("all_time_streak_ranked"."streak_length") FILTER (WHERE (("all_time_streak_ranked"."kind" = 'winless'::"text") AND ("all_time_streak_ranked"."streak_rank" = 1))), 0) AS "worst_winless_streak",
            "max"("all_time_streak_ranked"."start_date") FILTER (WHERE (("all_time_streak_ranked"."kind" = 'winless'::"text") AND ("all_time_streak_ranked"."streak_rank" = 1))) AS "worst_winless_start",
            "max"("all_time_streak_ranked"."end_date") FILTER (WHERE (("all_time_streak_ranked"."kind" = 'winless'::"text") AND ("all_time_streak_ranked"."streak_rank" = 1))) AS "worst_winless_end"
           FROM "all_time_streak_ranked"
        ), "all_time_period" AS (
         SELECT 'all_time'::"text" AS "period_key",
            'Toutes saisons'::"text" AS "period_label",
            "totals"."matches_played",
            "totals"."wins",
            "totals"."draws",
            "totals"."losses",
            "totals"."goals_for",
            "totals"."goals_against",
            ("totals"."goals_for" - "totals"."goals_against") AS "goal_difference",
            0 AS "clean_sheets",
            COALESCE("recent"."recent_results", ARRAY[]::"text"[]) AS "recent_results",
            NULL::"jsonb" AS "score_margin_distribution",
                CASE
                    WHEN ("dynamic"."best_win_streak" > "history"."best_win_streak") THEN "dynamic"."best_win_streak"
                    ELSE "history"."best_win_streak"
                END AS "best_win_streak",
                CASE
                    WHEN ("dynamic"."best_win_streak" > "history"."best_win_streak") THEN "dynamic"."best_win_start"
                    ELSE "history"."best_win_start"
                END AS "best_win_start",
                CASE
                    WHEN ("dynamic"."best_win_streak" > "history"."best_win_streak") THEN "dynamic"."best_win_end"
                    ELSE "history"."best_win_end"
                END AS "best_win_end",
                CASE
                    WHEN ("dynamic"."best_unbeaten_streak" > "history"."best_unbeaten_streak") THEN "dynamic"."best_unbeaten_streak"
                    ELSE "history"."best_unbeaten_streak"
                END AS "best_unbeaten_streak",
                CASE
                    WHEN ("dynamic"."best_unbeaten_streak" > "history"."best_unbeaten_streak") THEN "dynamic"."best_unbeaten_start"
                    ELSE "history"."best_unbeaten_start"
                END AS "best_unbeaten_start",
                CASE
                    WHEN ("dynamic"."best_unbeaten_streak" > "history"."best_unbeaten_streak") THEN "dynamic"."best_unbeaten_end"
                    ELSE "history"."best_unbeaten_end"
                END AS "best_unbeaten_end",
                CASE
                    WHEN ("dynamic"."worst_loss_streak" > "history"."worst_loss_streak") THEN "dynamic"."worst_loss_streak"
                    ELSE "history"."worst_loss_streak"
                END AS "worst_loss_streak",
                CASE
                    WHEN ("dynamic"."worst_loss_streak" > "history"."worst_loss_streak") THEN "dynamic"."worst_loss_start"
                    ELSE "history"."worst_loss_start"
                END AS "worst_loss_start",
                CASE
                    WHEN ("dynamic"."worst_loss_streak" > "history"."worst_loss_streak") THEN "dynamic"."worst_loss_end"
                    ELSE "history"."worst_loss_end"
                END AS "worst_loss_end",
                CASE
                    WHEN ("dynamic"."worst_winless_streak" > "history"."worst_winless_streak") THEN "dynamic"."worst_winless_streak"
                    ELSE "history"."worst_winless_streak"
                END AS "worst_winless_streak",
                CASE
                    WHEN ("dynamic"."worst_winless_streak" > "history"."worst_winless_streak") THEN "dynamic"."worst_winless_start"
                    ELSE "history"."worst_winless_start"
                END AS "worst_winless_start",
                CASE
                    WHEN ("dynamic"."worst_winless_streak" > "history"."worst_winless_streak") THEN "dynamic"."worst_winless_end"
                    ELSE "history"."worst_winless_end"
                END AS "worst_winless_end"
           FROM ((("all_time_totals" "totals"
             CROSS JOIN "baseline" "history")
             CROSS JOIN "all_time_recent" "recent")
             CROSS JOIN "all_time_dynamic_streaks" "dynamic")
        )
 SELECT "dynamic_periods"."period_key",
    "dynamic_periods"."period_label",
    "dynamic_periods"."matches_played",
    "dynamic_periods"."wins",
    "dynamic_periods"."draws",
    "dynamic_periods"."losses",
    "dynamic_periods"."goals_for",
    "dynamic_periods"."goals_against",
    "dynamic_periods"."goal_difference",
    "dynamic_periods"."clean_sheets",
    "dynamic_periods"."recent_results",
    "dynamic_periods"."score_margin_distribution",
    "dynamic_periods"."best_win_streak",
    "dynamic_periods"."best_win_start",
    "dynamic_periods"."best_win_end",
    "dynamic_periods"."best_unbeaten_streak",
    "dynamic_periods"."best_unbeaten_start",
    "dynamic_periods"."best_unbeaten_end",
    "dynamic_periods"."worst_loss_streak",
    "dynamic_periods"."worst_loss_start",
    "dynamic_periods"."worst_loss_end",
    "dynamic_periods"."worst_winless_streak",
    "dynamic_periods"."worst_winless_start",
    "dynamic_periods"."worst_winless_end"
   FROM "dynamic_periods"
UNION ALL
 SELECT "all_time_period"."period_key",
    "all_time_period"."period_label",
    "all_time_period"."matches_played",
    "all_time_period"."wins",
    "all_time_period"."draws",
    "all_time_period"."losses",
    "all_time_period"."goals_for",
    "all_time_period"."goals_against",
    "all_time_period"."goal_difference",
    "all_time_period"."clean_sheets",
    "all_time_period"."recent_results",
    "all_time_period"."score_margin_distribution",
    "all_time_period"."best_win_streak",
    "all_time_period"."best_win_start",
    "all_time_period"."best_win_end",
    "all_time_period"."best_unbeaten_streak",
    "all_time_period"."best_unbeaten_start",
    "all_time_period"."best_unbeaten_end",
    "all_time_period"."worst_loss_streak",
    "all_time_period"."worst_loss_start",
    "all_time_period"."worst_loss_end",
    "all_time_period"."worst_winless_streak",
    "all_time_period"."worst_winless_start",
    "all_time_period"."worst_winless_end"
   FROM "all_time_period";


alter view public.v_statistics_team_dynamic_base owner to club_scope;

CREATE OR REPLACE VIEW "public"."v_statistics_team_with_recent_results" WITH ("security_invoker"='true') AS
 WITH "open_season" AS (
         select season_id as id, period_label as name
         from public.v_statistics_season_periods where period_key = 'current'
        ), "previous_season" AS (
         select season_id as id, period_label as name
         from public.v_statistics_season_periods where period_key = 'previous'
        ), "previous_has_app_roster" AS (
         SELECT (EXISTS ( SELECT 1
                   FROM ("public"."season_players" "player"
                     JOIN "previous_season" "previous" ON (("previous"."id" = "player"."season_id"))))) AS "has_app"
        ), "imported_previous" AS (
         SELECT 'previous'::"text" AS "period_key",
            "history"."through_season" AS "period_label",
            "history"."matches_played",
            "history"."wins",
            "history"."draws",
            "history"."losses",
            "history"."goals_for",
            "history"."goals_against",
            ("history"."goals_for" - "history"."goals_against") AS "goal_difference",
            0 AS "clean_sheets",
            "history"."recent_results",
            "history"."score_margin_distribution",
            "history"."best_win_streak",
            "history"."best_win_start",
            "history"."best_win_end",
            "history"."best_unbeaten_streak",
            "history"."best_unbeaten_start",
            "history"."best_unbeaten_end",
            "history"."worst_loss_streak",
            "history"."worst_loss_start",
            "history"."worst_loss_end",
            "history"."worst_winless_streak",
            "history"."worst_winless_start",
            "history"."worst_winless_end"
           FROM ("public"."historical_team_statistics" "history"
             CROSS JOIN "previous_has_app_roster" "app")
          WHERE (("history"."scope" = 'previous'::"text") AND (NOT "app"."has_app"))
        )
 SELECT "dynamic"."period_key",
    "dynamic"."period_label",
    "dynamic"."matches_played",
    "dynamic"."wins",
    "dynamic"."draws",
    "dynamic"."losses",
    "dynamic"."goals_for",
    "dynamic"."goals_against",
    "dynamic"."goal_difference",
    "dynamic"."clean_sheets",
    "dynamic"."recent_results",
    "dynamic"."score_margin_distribution",
    "dynamic"."best_win_streak",
    "dynamic"."best_win_start",
    "dynamic"."best_win_end",
    "dynamic"."best_unbeaten_streak",
    "dynamic"."best_unbeaten_start",
    "dynamic"."best_unbeaten_end",
    "dynamic"."worst_loss_streak",
    "dynamic"."worst_loss_start",
    "dynamic"."worst_loss_end",
    "dynamic"."worst_winless_streak",
    "dynamic"."worst_winless_start",
    "dynamic"."worst_winless_end"
   FROM "public"."v_statistics_team_dynamic_base" "dynamic"
  WHERE ("dynamic"."period_key" = ANY (ARRAY['current'::"text", 'all_time'::"text"]))
UNION ALL
 SELECT "dynamic"."period_key",
    "dynamic"."period_label",
    "dynamic"."matches_played",
    "dynamic"."wins",
    "dynamic"."draws",
    "dynamic"."losses",
    "dynamic"."goals_for",
    "dynamic"."goals_against",
    "dynamic"."goal_difference",
    "dynamic"."clean_sheets",
    "dynamic"."recent_results",
    "dynamic"."score_margin_distribution",
    "dynamic"."best_win_streak",
    "dynamic"."best_win_start",
    "dynamic"."best_win_end",
    "dynamic"."best_unbeaten_streak",
    "dynamic"."best_unbeaten_start",
    "dynamic"."best_unbeaten_end",
    "dynamic"."worst_loss_streak",
    "dynamic"."worst_loss_start",
    "dynamic"."worst_loss_end",
    "dynamic"."worst_winless_streak",
    "dynamic"."worst_winless_start",
    "dynamic"."worst_winless_end"
   FROM ("public"."v_statistics_team_dynamic_base" "dynamic"
     CROSS JOIN "previous_has_app_roster" "app")
  WHERE (("dynamic"."period_key" = 'previous'::"text") AND "app"."has_app")
UNION ALL
 SELECT "imported"."period_key",
    "imported"."period_label",
    "imported"."matches_played",
    "imported"."wins",
    "imported"."draws",
    "imported"."losses",
    "imported"."goals_for",
    "imported"."goals_against",
    "imported"."goal_difference",
    "imported"."clean_sheets",
    "imported"."recent_results",
    "imported"."score_margin_distribution",
    "imported"."best_win_streak",
    "imported"."best_win_start",
    "imported"."best_win_end",
    "imported"."best_unbeaten_streak",
    "imported"."best_unbeaten_start",
    "imported"."best_unbeaten_end",
    "imported"."worst_loss_streak",
    "imported"."worst_loss_start",
    "imported"."worst_loss_end",
    "imported"."worst_winless_streak",
    "imported"."worst_winless_start",
    "imported"."worst_winless_end"
   FROM "imported_previous" "imported";


alter view public.v_statistics_team_with_recent_results owner to club_scope;

CREATE OR REPLACE VIEW "public"."v_statistics_team" WITH ("security_invoker"='true') AS
 WITH "baseline" AS (
         SELECT "historical_team_statistics"."through_season",
            "historical_team_statistics"."recent_results",
            "historical_team_statistics"."score_margin_distribution"
           FROM "public"."historical_team_statistics"
          WHERE ("historical_team_statistics"."scope" = 'all_time'::"text")
        ), "post_baseline" AS (
         SELECT "m"."id",
            "m"."match_date",
                CASE
                    WHEN ("m"."score_as_grinta" > "m"."score_adverse") THEN 'V'::"text"
                    WHEN ("m"."score_as_grinta" = "m"."score_adverse") THEN 'N'::"text"
                    ELSE 'D'::"text"
                END AS "result",
            ("m"."score_as_grinta" - "m"."score_adverse") AS "margin"
           FROM (("public"."matches" "m"
             JOIN "public"."seasons" "s" ON (("s"."id" = "m"."season_id")))
             CROSS JOIN "baseline" "b")
          WHERE (("m"."status" = ANY (ARRAY['termine'::"text", 'archive'::"text"])) AND ("m"."score_as_grinta" IS NOT NULL) AND ("m"."score_adverse" IS NOT NULL) AND ("s"."name" > "b"."through_season"))
        ), "post_ranked" AS (
         SELECT "post_baseline"."id",
            "post_baseline"."match_date",
            "post_baseline"."result",
            "post_baseline"."margin",
            "row_number"() OVER (ORDER BY "post_baseline"."match_date" DESC, "post_baseline"."id" DESC) AS "rn"
           FROM "post_baseline"
        ), "post_recent" AS (
         SELECT COALESCE("array_agg"("post_ranked"."result" ORDER BY "post_ranked"."match_date", "post_ranked"."id") FILTER (WHERE ("post_ranked"."rn" <= 6)), ARRAY[]::"text"[]) AS "results",
            ("count"(*))::integer AS "total_count"
           FROM "post_ranked"
        ), "recent_all_time" AS (
         SELECT
                CASE
                    WHEN ("p"."total_count" >= 6) THEN "p"."results"
                    ELSE (COALESCE("b"."recent_results"[GREATEST(((COALESCE("array_length"("b"."recent_results", 1), 0) - (6 - "p"."total_count")) + 1), 1):COALESCE("array_length"("b"."recent_results", 1), 0)], ARRAY[]::"text"[]) || "p"."results")
                END AS "results"
           FROM ("baseline" "b"
             CROSS JOIN "post_recent" "p")
        ), "margin_parts" AS (
         SELECT ("jsonb_each_text"."key")::integer AS "margin",
            ("jsonb_each_text"."value")::integer AS "cnt"
           FROM "baseline" "b",
            LATERAL "jsonb_each_text"(COALESCE("b"."score_margin_distribution", '{}'::"jsonb")) "jsonb_each_text"("key", "value")
        UNION ALL
         SELECT "post_baseline"."margin",
            ("count"(*))::integer AS "count"
           FROM "post_baseline"
          GROUP BY "post_baseline"."margin"
        ), "all_time_margins" AS (
         SELECT COALESCE("jsonb_object_agg"(("x"."margin")::"text", "x"."cnt" ORDER BY "x"."margin"), '{}'::"jsonb") AS "distribution"
           FROM ( SELECT "margin_parts"."margin",
                    ("sum"("margin_parts"."cnt"))::integer AS "cnt"
                   FROM "margin_parts"
                  GROUP BY "margin_parts"."margin") "x"
        )
 SELECT "period_key",
    "period_label",
    "matches_played",
    "wins",
    "draws",
    "losses",
    "goals_for",
    "goals_against",
    "goal_difference",
    "clean_sheets",
        CASE
            WHEN ("period_key" = 'previous'::"text") THEN "source"."recent_results"
            WHEN ("period_key" = 'all_time'::"text") THEN ( SELECT "recent_all_time"."results"
               FROM "recent_all_time")
            ELSE "recent_results"
        END AS "recent_results",
        CASE
            WHEN ("period_key" = 'all_time'::"text") THEN ( SELECT "all_time_margins"."distribution"
               FROM "all_time_margins")
            ELSE "score_margin_distribution"
        END AS "score_margin_distribution",
    "best_win_streak",
    "best_win_start",
    "best_win_end",
    "best_unbeaten_streak",
    "best_unbeaten_start",
    "best_unbeaten_end",
    "worst_loss_streak",
    "worst_loss_start",
    "worst_loss_end",
    "worst_winless_streak",
    "worst_winless_start",
    "worst_winless_end"
   FROM "public"."v_statistics_team_with_recent_results" "source";


alter view public.v_statistics_team owner to club_scope;

-- Classement des pronostics par période ; le classement général historique
-- reste disponible pour les anciens clients et les autres points d'entrée.
create view public.v_statistics_predictions
with (security_invoker = true) as
with period_matches as (
  select refs.period_key, m.id, m.score_as_grinta, m.score_adverse
  from public.v_statistics_season_periods refs
  join public.matches m on m.season_id = refs.season_id
  where m.status in ('termine', 'archive')
  union all
  select 'all_time', m.id, m.score_as_grinta, m.score_adverse
  from public.matches m
  where m.club_id = (select private.current_club_id())
    and m.status in ('termine', 'archive')
), totals as (
  select m.period_key, p.profile_id,
    count(*) as match_pronos,
    coalesce(sum(points.points), 0::numeric) as match_points,
    count(*) filter (where
      sign(p.predicted_score_as_grinta - p.predicted_score_adverse)
      = sign(m.score_as_grinta - m.score_adverse)) as match_bons,
    count(*) filter (where p.predicted_score_as_grinta = m.score_as_grinta
      and p.predicted_score_adverse = m.score_adverse) as match_exacts
  from period_matches m
  join public.match_predictions p on p.match_id = m.id and p.is_filled
  left join public.v_match_prediction_points points on points.id = p.id
  group by m.period_key, p.profile_id
)
select t.period_key, p.id as profile_id, p.first_name, p.surnom,
  t.match_points, t.match_bons, t.match_exacts, t.match_pronos
from totals t
join public.profiles p on p.id = t.profile_id
where not p.is_test_account and p.status in ('active', 'archived');

alter view public.v_statistics_predictions owner to club_scope;
revoke all on public.v_statistics_predictions from public, anon;
grant select on public.v_statistics_predictions to authenticated, service_role;

-- Le calcul des bilans se termine après la clôture. Un nouveau signal réveille
-- aussi les clients qui ont lu « indisponible » avant la fin de ce calcul.
create trigger trg_shared_data_change
  after insert or update or delete on public.season_wrapped
  for each statement execute function private.signal_shared_data_change();
