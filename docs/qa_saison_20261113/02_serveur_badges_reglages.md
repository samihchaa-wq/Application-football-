# Grille QA — API serveur, badges, réglages, notifications et rôles

> Source : lecture seule de Supabase `jvxkhgdopslctpcjrhzw`, et code `main` du 13/11/2026. **Présence technique ≠ fonctionnement authentifié**. Sans identité de test et écran utilisable, tous les comportements réels restent **NON VÉRIFIÉS**. Les noms de fonctions peuvent inclure des points de compatibilité historiques.

## 1. Fonctions SQL publiques : 257 signatures inventoriées

Les fonctions SQL ne doivent **jamais** être invoquées avec le rôle propriétaire pour faire passer un contrôle des droits utilisateur. Chaque ligne demande au minimum une invocation avec un compte autorisé et une tentative de rôle non autorisé, sur A et B, et une comparaison en lecture.

| N° | Fonction et paramètres | SECURITY DEFINER | Preuve inventaire | Résultat réel |
|---:|---|---|---|---|
| RPC-001 | `accept_terms(p_version text, p_age_confirmation text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-002 | `admin_add_historical_match(p_match jsonb)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-003 | `admin_add_or_reuse_match_guest(p_match_id uuid, p_guest_player_id uuid, p_first_name text, p_last_name text, p_is_goalkeeper boolean, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-004 | `admin_attach_match_sport_report_player(p_match_id uuid, p_season_player_id uuid, p_guest_player_id uuid, p_first_name text, p_last_name text, p_is_goalkeeper boolean, p_reason text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-005 | `admin_cancel_match_motm_vote(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-006 | `admin_close_match_motm_vote_early(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-007 | `admin_configure_match_sport_workflow(p_match_id uuid, p_squad_size_limit integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-008 | `admin_create_match_complete(p_season_id uuid, p_opponent_id uuid, p_match_date date, p_match_time time without time zone, p_location text, p_win numeric, p_draw numeric, p_loss numeric, p_squad_size_limit integer, p_address text, p_remember_address_as_default boolean, p_match_type text, p_jersey_note text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-009 | `admin_create_match_complete_v2(p_season_id uuid, p_opponent_id uuid, p_match_date date, p_match_time time without time zone, p_location text, p_win numeric, p_draw numeric, p_loss numeric, p_squad_size_limit integer, p_address text, p_remember_address_as_default boolean, p_match_type text, p_jersey_note text, p_availability_schedule_mode text, p_availability_opens_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-010 | `admin_create_match_complete_v3(p_season_id uuid, p_opponent_id uuid, p_match_date date, p_match_time time without time zone, p_location text, p_win numeric, p_draw numeric, p_loss numeric, p_squad_size_limit integer, p_address text, p_remember_address_as_default boolean, p_match_type text, p_jersey_note text, p_availability_schedule_mode text, p_availability_opens_at timestamp with time zone, p_meeting_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-011 | `admin_create_postmatch_composition(p_match_id uuid, p_formation_code text, p_entries jsonb, p_allow_squad_size_exception boolean, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-012 | `admin_delete_historical_match(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-013 | `admin_delete_unused_opponent(p_opponent_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-014 | `admin_finalize_match_sport_postgame(p_match_id uuid, p_score_as_grinta integer, p_score_adverse integer, p_participants jsonb, p_reason text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-015 | `admin_finalize_match_waitlist_turns(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-016 | `admin_get_club_storage_usage()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-017 | `admin_get_club_subscription()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-018 | `admin_get_finished_bench_counts(p_match_id uuid)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-019 | `admin_get_guest_players(p_include_archived boolean)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-020 | `admin_get_history_entry_context()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-021 | `admin_get_internal_composition(p_match_id uuid)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-022 | `admin_get_match_availability_reminders(p_match_id uuid)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-023 | `admin_get_match_composition(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-024 | `admin_get_match_convocations(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-025 | `admin_get_match_guests(p_match_id uuid)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-026 | `admin_get_match_motm_dashboard(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-027 | `admin_get_match_sport_finalization(p_match_id uuid)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-028 | `admin_get_match_sport_report(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-029 | `admin_get_match_sport_statistics_integrity(p_match_id uuid)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-030 | `admin_get_notifications_paused()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-031 | `admin_get_player_position_history(p_since timestamp with time zone)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-032 | `admin_get_player_unavailabilities()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-033 | `admin_get_sport_waitlist(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-034 | `admin_list_match_motm_votes()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-035 | `admin_override_match_availability(p_match_id uuid, p_season_player_id uuid, p_status text, p_private_comment text, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-036 | `admin_publish_match_composition(p_match_id uuid, p_allow_squad_size_exception boolean, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-037 | `admin_publish_match_convocations(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-038 | `admin_publish_match_effectif(p_match_id uuid, p_squad_size_limit integer, p_decisions jsonb, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-039 | `admin_recalculate_sport_waitlist(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-040 | `admin_recent_client_incidents(p_limit integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-041 | `admin_recompute_match_convocations(p_match_id uuid, p_reset_overrides boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-042 | `admin_regenerate_club_invite_code()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-043 | `admin_remove_match_guest(p_match_id uuid, p_participant_id uuid, p_reason text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-044 | `admin_reorder_sport_waitlist(p_season_id uuid, p_ordered_player_ids uuid[], p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-045 | `admin_require_password_change(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-046 | `admin_reset_internal_composition(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-047 | `admin_restart_match_motm_vote(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-048 | `admin_save_internal_composition(p_match_id uuid, p_team1_name text, p_team2_name text, p_entries jsonb)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-049 | `admin_save_internal_composition_v2(p_match_id uuid, p_team1_name text, p_team2_name text, p_team1_jersey text, p_team2_jersey text, p_entries jsonb)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-050 | `admin_save_internal_composition_v3(p_match_id uuid, p_team1_name text, p_team2_name text, p_team1_jersey text, p_team2_jersey text, p_team1_formation text, p_team2_formation text, p_entries jsonb)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-051 | `admin_save_internal_composition_v4(p_match_id uuid, p_team1_name text, p_team2_name text, p_team1_jersey text, p_team2_jersey text, p_team1_formation text, p_team2_formation text, p_entries jsonb, p_require_visual_complete boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-052 | `admin_save_internal_composition_v5(p_match_id uuid, p_team1_name text, p_team2_name text, p_team1_jersey text, p_team2_jersey text, p_team1_formation text, p_team2_formation text, p_entries jsonb)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-053 | `admin_save_match_composition(p_match_id uuid, p_formation_code text, p_entries jsonb, p_allow_squad_size_exception boolean, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-054 | `admin_save_match_composition(p_match_id uuid, p_formation_code text, p_entries jsonb, p_allow_squad_size_exception boolean, p_reason text, p_expected_version integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-055 | `admin_save_match_effectif(p_match_id uuid, p_squad_size_limit integer, p_decisions jsonb, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-056 | `admin_save_opponent_stadium(p_opponent_id uuid, p_name text, p_stadium_name text, p_address text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-057 | `admin_send_custom_push(p_title text, p_body text, p_profile_ids uuid[])` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-058 | `admin_send_match_availability_reminder(p_match_id uuid, p_season_player_id uuid, p_reason text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-059 | `admin_set_club_home_address(p_address text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-060 | `admin_set_club_logo(p_path text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-061 | `admin_set_club_module(p_key text, p_enabled boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-062 | `admin_set_club_rule(p_key text, p_value integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-063 | `admin_set_club_usual_squad_size(p_size integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-064 | `admin_set_guest_archived(p_guest_player_id uuid, p_archived boolean, p_reason text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-065 | `admin_set_guest_photo(p_guest_player_id uuid, p_photo_url text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-066 | `admin_set_match_address(p_match_id uuid, p_address text, p_remember_as_default boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-067 | `admin_set_match_championship_round(p_match_id uuid, p_championship_round integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-068 | `admin_set_match_convocation(p_match_id uuid, p_season_player_id uuid, p_status text, p_turn_should_consume boolean, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-069 | `admin_set_match_jersey(p_match_id uuid, p_jersey_note text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-070 | `admin_set_match_type(p_match_id uuid, p_match_type text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-071 | `admin_set_notifications_paused(p_enabled boolean, p_justification text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-072 | `admin_set_waitlist_manual_count(p_season_player_id uuid, p_count integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-073 | `admin_submit_match_sport_report(p_match_id uuid, p_score_as_grinta integer, p_score_adverse integer, p_lineup jsonb, p_goal_actions jsonb, p_reason text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-074 | `admin_sync_match_sport_workflow(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-075 | `admin_update_club_colors(p_primary text, p_secondary text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-076 | `admin_update_club_identity(p_name text, p_short_name text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-077 | `admin_update_club_kits(p_kits jsonb)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-078 | `admin_update_match_complete(p_match_id uuid, p_season_id uuid, p_opponent_id uuid, p_match_date date, p_match_time time without time zone, p_location text, p_status text, p_win numeric, p_draw numeric, p_loss numeric, p_expected_updated_at timestamp with time zone, p_squad_size_limit integer, p_address text, p_remember_address_as_default boolean, p_match_type text, p_jersey_note text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-079 | `admin_update_match_complete_v2(p_match_id uuid, p_season_id uuid, p_opponent_id uuid, p_match_date date, p_match_time time without time zone, p_location text, p_status text, p_win numeric, p_draw numeric, p_loss numeric, p_expected_updated_at timestamp with time zone, p_squad_size_limit integer, p_address text, p_remember_address_as_default boolean, p_match_type text, p_jersey_note text, p_meeting_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-080 | `admin_update_match_complete_v3(p_match_id uuid, p_season_id uuid, p_opponent_id uuid, p_match_date date, p_match_time time without time zone, p_location text, p_status text, p_win numeric, p_draw numeric, p_loss numeric, p_expected_updated_at timestamp with time zone, p_squad_size_limit integer, p_address text, p_remember_address_as_default boolean, p_match_type text, p_jersey_note text, p_meeting_at timestamp with time zone, p_availability_schedule_mode text, p_availability_opens_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-081 | `admin_update_postmatch_composition(p_match_id uuid, p_formation_code text, p_entries jsonb, p_allow_squad_size_exception boolean, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-082 | `admin_update_profile_fields(p_profile_id uuid, p_role text, p_status text, p_is_goalkeeper boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-083 | `archive_match(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-084 | `award_season_titles(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-085 | `calculate_match_odds_v4(p_opponent_id uuid, p_location text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-086 | `calculate_match_odds_v5(p_opponent_id uuid, p_reference_date date)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-087 | `cancel_match(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-088 | `cancel_my_unavailability(p_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-089 | `cast_match_motm_vote(p_match_id uuid, p_candidate_participant_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-090 | `claim_match_live_pilot(p_match_id uuid, p_planned_duration_minutes integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-091 | `cleanup_replaced_badge_image()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-092 | `cleanup_replaced_photo()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-093 | `close_match_predictions(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-094 | `club_for_invite_code(p_code text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-095 | `coach_add_match_live_players(p_match_id uuid, p_players jsonb, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-096 | `coach_adjust_match_live_score(p_match_id uuid, p_team text, p_delta integer, p_scorer_participant_id uuid, p_operation_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-097 | `coach_change_match_live_formation(p_match_id uuid, p_formation_code text, p_entries jsonb, p_expected_lineup_revision integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-098 | `coach_delete_match_live_event(p_match_id uuid, p_event_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-099 | `coach_end_match_live(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-100 | `coach_publish_match_live_recap(p_match_id uuid, p_score_as_grinta integer, p_score_adverse integer, p_participants jsonb, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-101 | `coach_reopen_match_live(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-102 | `coach_restart_match_live_session(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-103 | `coach_save_match_live_lineup(p_match_id uuid, p_entries jsonb, p_substitution jsonb, p_expected_lineup_revision integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-104 | `coach_set_match_live_clock_state(p_match_id uuid, p_action text, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-105 | `coach_set_match_live_event_scorer(p_match_id uuid, p_event_id uuid, p_scorer_participant_id uuid, p_is_opponent_own_goal boolean, p_assist_participant_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-106 | `complete_password_change()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-107 | `confirm_contact_email(p_token_hash text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-108 | `confirm_start_match_live(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-109 | `consume_email_rate_limit(p_origin_hash text, p_email_hash text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-110 | `consume_registration_rate_limit(p_origin_hash text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-111 | `create_club(p_name text, p_short_name text, p_primary_color text, p_secondary_color text, p_timezone text, p_created_by uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-112 | `create_internal_match(p_season_id uuid, p_match_date date, p_match_time time without time zone, p_address text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-113 | `create_internal_match_v2(p_season_id uuid, p_match_date date, p_match_time time without time zone, p_address text, p_availability_schedule_mode text, p_availability_opens_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-114 | `create_internal_match_v3(p_season_id uuid, p_match_date date, p_match_time time without time zone, p_address text, p_availability_schedule_mode text, p_availability_opens_at timestamp with time zone, p_meeting_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-115 | `create_match_with_odds(p_season_id uuid, p_opponent_id uuid, p_match_date date, p_match_time time without time zone, p_location text, p_win numeric, p_draw numeric, p_loss numeric)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-116 | `create_match_with_odds_and_sport_limit(p_season_id uuid, p_opponent_id uuid, p_match_date date, p_match_time time without time zone, p_location text, p_win numeric, p_draw numeric, p_loss numeric, p_squad_size_limit integer)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-117 | `current_profile_role()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-118 | `delete_match(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-119 | `delete_my_notification(p_id bigint)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-120 | `discard_empty_club(p_club_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-121 | `export_my_data()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-122 | `featured_badges()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-123 | `finalize_match_postgame(p_match_id uuid, p_score_adverse integer, p_scorers jsonb, p_clean_sheet_player_id uuid, p_score_as_grinta integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-124 | `finalize_match_postgame_with_lineup(p_match_id uuid, p_score_adverse integer, p_scorers jsonb, p_clean_sheet_player_id uuid, p_score_as_grinta integer, p_present uuid[], p_man_of_match_player_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-125 | `found_club(p_club_id uuid, p_profile_id uuid, p_contract_version text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-126 | `get_all_historical_match_results()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-127 | `get_club_modules()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-128 | `get_club_rules()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-129 | `get_historical_match_detail(p_match_id uuid)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-130 | `get_historical_match_results(p_season_name text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-131 | `get_internal_composition(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-132 | `get_last_opponent_encounters(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-133 | `get_match_availability_board(p_match_id uuid)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-134 | `get_match_availability_schedule(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-135 | `get_match_live_add_player_options(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-136 | `get_match_live_notification_subscription(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-137 | `get_match_live_state(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-138 | `get_match_live_timeline(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-139 | `get_match_motm_vote(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-140 | `get_match_sport_goal_actions(p_match_id uuid)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-141 | `get_match_sport_result(p_match_id uuid)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-142 | `get_my_club_access()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-143 | `get_my_match_availability(p_match_id uuid)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-144 | `get_my_notification_history(p_limit integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-145 | `get_my_profile()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-146 | `get_my_season_wrapped()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-147 | `get_my_unavailabilities()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-148 | `get_my_unread_notification_count()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-149 | `get_my_upcoming_match_states(p_match_ids uuid[])` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-150 | `get_or_create_calendar_subscription_token()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-151 | `get_or_create_opponent(p_name text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-152 | `get_player_season_statistics(p_full_name text, p_is_goalkeeper boolean, p_profile_id uuid)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-153 | `get_public_feature_flags()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-154 | `get_published_match_composition(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-155 | `get_season_wrapped_state()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-156 | `get_sport_waitlist(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-157 | `guard_match_prediction_window()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-158 | `guard_sensitive_profile_fields()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-159 | `handle_new_auth_user()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-160 | `heartbeat_match_live_pilot(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-161 | `internal_claim_match_live_notification(p_notification_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-162 | `internal_mark_match_live_notification_delivery(p_notification_id uuid, p_attempted integer, p_sent integer, p_failed integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-163 | `internal_mark_sport_notification_delivery(p_event_id bigint, p_attempted integer, p_sent integer, p_failed integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-164 | `internal_match_weather_candidates(p_match_id uuid, p_now timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-165 | `internal_next_free_username(p_base text, p_skip text[])` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-166 | `internal_push_config()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-167 | `internal_push_delivery_health(p_since timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-168 | `internal_push_dispatch(p_kind text, p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-169 | `internal_push_notify(p_kind text, p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-170 | `internal_push_prune(p_endpoints text[])` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-171 | `internal_record_notification_history(p_kind text, p_match_id uuid, p_profile_ids uuid[], p_title text, p_body text, p_url text, p_tag text, p_dedupe_key text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-172 | `internal_sport_push_dispatch(p_kind text, p_match_id uuid, p_profile_ids uuid[])` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-173 | `is_active_profile()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-174 | `is_admin()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-175 | `is_match_staff()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-176 | `is_moderator()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-177 | `is_valid_person_name(txt text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-178 | `log_client_incident(p_reference text, p_operation text, p_error_type text, p_app_version text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-179 | `mark_my_notifications_read()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-180 | `match_prediction_participant_count(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-181 | `open_match_live_workspace(p_match_id uuid, p_planned_duration_minutes integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-182 | `open_or_create_season(p_name text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-183 | `platform_health()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-184 | `platform_list_clubs()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-185 | `platform_update_club(p_club_id uuid, p_status text, p_subscription_status text, p_trial_ends_at timestamp with time zone, p_current_period_end timestamp with time zone, p_price_per_player_cents integer, p_base_price_cents integer, p_storage_quota_bytes bigint, p_notes text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-186 | `prepare_profile_for_hard_deletion(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-187 | `preview_match_odds(p_opponent_id uuid, p_location text, p_reference_date date)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-188 | `profile_badge_display_metrics(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-189 | `profile_badge_metrics(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-190 | `profile_badge_stars(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-191 | `profile_for_recovery_email(p_email text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-192 | `profile_mvp_count(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-193 | `promote_club_founder(p_club_id uuid, p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-194 | `push_closing_reminders()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-195 | `push_on_match_insert()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-196 | `push_on_motm_election_closed()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-197 | `push_on_motm_election_opened()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-198 | `push_prediction_j5_notifications()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-199 | `recalculate_all_badges()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-200 | `recalculate_profile_badges(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-201 | `recalculate_upcoming_match_odds_v4()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-202 | `register_push_subscription(p_endpoint text, p_p256dh text, p_auth text, p_user_agent text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-203 | `release_match_live_pilot(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-204 | `report_my_push_device(p_endpoint text, p_permission text, p_receipts jsonb)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-205 | `request_contact_email(p_profile_id uuid, p_email text, p_token_hash text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-206 | `resolve_player_identities(p_names text[])` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-207 | `save_match_prediction(p_match_id uuid, p_score_as_grinta integer, p_score_adverse integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-208 | `save_match_prediction(p_match_id uuid, p_score_as_grinta integer, p_score_adverse integer, p_use_x2 boolean)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-209 | `seed_match_predictions()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-210 | `seed_predictions_for_active_profile()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-211 | `send_test_push()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-212 | `send_test_push_kind(p_kind text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-213 | `set_badge_featured(p_badge_code text, p_featured boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-214 | `set_match_live_notifications(p_match_id uuid, p_enabled boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-215 | `set_match_odds(p_match_id uuid, p_win numeric, p_draw numeric, p_loss numeric)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-216 | `set_my_match_availability(p_match_id uuid, p_status text, p_private_comment text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-217 | `set_my_unavailability(p_id uuid, p_starts_on date, p_ends_on date, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-218 | `set_season_status(p_season_id uuid, p_status text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-219 | `set_sports_management_enabled(p_enabled boolean, p_justification text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-220 | `staff_app_integrity_report()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-221 | `staff_award_badge(p_profile_id uuid, p_badge_code text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-222 | `staff_create_badge(p_code text, p_name text, p_emoji text, p_description text, p_image_url text, p_color text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-223 | `staff_list_historical_players()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-224 | `staff_list_profiles()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-225 | `staff_profile_username(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-226 | `staff_revoke_badge(p_profile_id uuid, p_badge_code text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-227 | `staff_set_historical_profile(p_profile_id uuid, p_historical_id bigint)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-228 | `staff_set_match_attendance(p_match_id uuid, p_present uuid[])` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-229 | `staff_set_match_mvp(p_match_id uuid, p_players uuid[])` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-230 | `staff_set_season_player_profile(p_season_player_id uuid, p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-231 | `staff_update_badge_image(p_badge_code text, p_image_url text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-232 | `staff_update_badge_text(p_badge_code text, p_name text, p_description text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-233 | `staff_update_badge_threshold(p_badge_code text, p_threshold integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-234 | `staff_validate_profile(p_profile_id uuid, p_season_player_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-235 | `sync_match_kickoff_at()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-236 | `take_over_match_live_pilot(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-237 | `trg_award_titles_on_season_close()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-238 | `trg_badges_on_attendance()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-239 | `trg_badges_on_historical_link()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-240 | `trg_badges_on_match_result()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-241 | `trg_badges_on_mvp()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-242 | `trg_badges_on_player_stats()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-243 | `trg_badges_on_prediction()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-244 | `trg_badges_on_roster_change()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-245 | `trigger_match_odds_v4()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-246 | `trigger_recalculate_upcoming_odds_v3()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-247 | `update_internal_match(p_match_id uuid, p_season_id uuid, p_match_date date, p_match_time time without time zone, p_address text, p_expected_updated_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-248 | `update_internal_match_v2(p_match_id uuid, p_season_id uuid, p_match_date date, p_match_time time without time zone, p_address text, p_expected_updated_at timestamp with time zone, p_meeting_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-249 | `update_internal_match_v3(p_match_id uuid, p_season_id uuid, p_match_date date, p_match_time time without time zone, p_address text, p_expected_updated_at timestamp with time zone, p_meeting_at timestamp with time zone, p_availability_schedule_mode text, p_availability_opens_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-250 | `update_match_with_odds(p_match_id uuid, p_season_id uuid, p_opponent_id uuid, p_match_date date, p_match_time time without time zone, p_location text, p_status text, p_win numeric, p_draw numeric, p_loss numeric)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-251 | `update_match_with_odds_and_sport_limit(p_match_id uuid, p_season_id uuid, p_opponent_id uuid, p_match_date date, p_match_time time without time zone, p_location text, p_status text, p_win numeric, p_draw numeric, p_loss numeric, p_squad_size_limit integer)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-252 | `update_my_admin_availability_notification(p_enabled boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-253 | `update_my_app_preferences(p_notify_prediction_open boolean, p_notify_prediction_reminders boolean, p_notify_match_reminders boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-254 | `update_my_badge_notifications(p_enabled boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-255 | `update_my_notification_preferences(p_notify_prediction boolean, p_notify_motm_vote boolean, p_notify_convocation boolean, p_notify_composition boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-256 | `upsert_match_odds_v4(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| RPC-257 | `validate_profile_names()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |

## 2. Fonctions Edge : 8

| ID | Fonction | État déclaratif | Résultat réel |
|---|---|---|---|
| EDGE-01 | `account-email` | ACTIVE (métadonnées) | **NON VÉRIFIÉ** |
| EDGE-02 | `calendar-feed` | ACTIVE (métadonnées) | **NON VÉRIFIÉ** |
| EDGE-03 | `claim-account` | ACTIVE (métadonnées) | **NON VÉRIFIÉ** |
| EDGE-04 | `claim-club` | ACTIVE (métadonnées) | **NON VÉRIFIÉ** |
| EDGE-05 | `manage-user` | ACTIVE (métadonnées) | **NON VÉRIFIÉ** |
| EDGE-06 | `register-account` | ACTIVE (métadonnées) | **NON VÉRIFIÉ** |
| EDGE-07 | `send-prediction-reminders` | ACTIVE (métadonnées) | **NON VÉRIFIÉ** |
| EDGE-08 | `send-push` | ACTIVE (métadonnées) | **NON VÉRIFIÉ** |

## 3. Badges répertoriés pour le Club Test A : 67

Chaque badge demande : déclenchement, non-attribution en dessous du seuil, recalcul, notification activée/désactivée, suppression/rétrocorrection et isolation interclub. L'inventaire ci-dessous ne constitue pas une attribution obtenue.

| ID | Code | Nom | Famille / type | Seuil | Secret | Résultat à l'écran |
|---|---|---|---|---|---|---|
| BADGE-01 | `5LJPA73V` | test cloisonnement | joueur/custom | – | non | **NON VÉRIFIÉ** |
| BADGE-02 | `assists__10` | Faiseur de jeu | joueur/tier | 10 | non | **NON VÉRIFIÉ** |
| BADGE-03 | `assists__100` | Architecte du jeu | joueur/tier | 100 | non | **NON VÉRIFIÉ** |
| BADGE-04 | `assists__25` | Passeur confirmé | joueur/tier | 25 | non | **NON VÉRIFIÉ** |
| BADGE-05 | `assists__50` | Maestro | joueur/tier | 50 | non | **NON VÉRIFIÉ** |
| BADGE-06 | `assists_season__10` | Créateur | joueur/tier | 15 | non | **NON VÉRIFIÉ** |
| BADGE-07 | `assists_season__15` | Chef d’orchestre | joueur/tier | 20 | non | **NON VÉRIFIÉ** |
| BADGE-08 | `assists_season__3` | Passeur en herbe | joueur/tier | 5 | non | **NON VÉRIFIÉ** |
| BADGE-09 | `assists_season__5` | Passeur | joueur/tier | 10 | non | **NON VÉRIFIÉ** |
| BADGE-10 | `clean_sheets__10` | Verrou confirmé | joueur/tier | 10 | non | **NON VÉRIFIÉ** |
| BADGE-11 | `clean_sheets__20` | Gardien du temple | joueur/tier | 20 | non | **NON VÉRIFIÉ** |
| BADGE-12 | `clean_sheets__30` | Mur infranchissable | joueur/tier | 30 | non | **NON VÉRIFIÉ** |
| BADGE-13 | `clean_sheets__50` | Bastion | joueur/tier | 50 | non | **NON VÉRIFIÉ** |
| BADGE-14 | `clean_sheets_season__10` | Forteresse imprenable | joueur/tier | 10 | non | **NON VÉRIFIÉ** |
| BADGE-15 | `clean_sheets_season__3` | Premier verrou | joueur/tier | 3 | non | **NON VÉRIFIÉ** |
| BADGE-16 | `clean_sheets_season__5` | Dernier rempart | joueur/tier | 5 | non | **NON VÉRIFIÉ** |
| BADGE-17 | `clean_sheets_season__7` | Muraille | joueur/tier | 7 | non | **NON VÉRIFIÉ** |
| BADGE-18 | `exploit_but_vainqueur_tardif` | Buteur décisif | joueur/custom | – | non | **NON VÉRIFIÉ** |
| BADGE-19 | `exploit_csc` | Contre son camp | joueur/custom | – | non | **NON VÉRIFIÉ** |
| BADGE-20 | `exploit_penalty_provoque` | Penalty concédé | joueur/custom | – | non | **NON VÉRIFIÉ** |
| BADGE-21 | `exploit_penalty_subi` | Penalty obtenu | joueur/custom | – | non | **NON VÉRIFIÉ** |
| BADGE-22 | `exploit_remplace_gardien` | Gardien d’un soir | joueur/custom | – | non | **NON VÉRIFIÉ** |
| BADGE-23 | `goals__100` | Centurion | joueur/tier | 100 | non | **NON VÉRIFIÉ** |
| BADGE-24 | `goals__25` | Buteur confirmé | joueur/tier | 25 | non | **NON VÉRIFIÉ** |
| BADGE-25 | `goals__50` | Canonnier | joueur/tier | 50 | non | **NON VÉRIFIÉ** |
| BADGE-26 | `goals__75` | Chasseur de records | joueur/tier | 75 | non | **NON VÉRIFIÉ** |
| BADGE-27 | `goals_season__10` | Finisseur | joueur/tier | 10 | non | **NON VÉRIFIÉ** |
| BADGE-28 | `goals_season__20` | Artilleur | joueur/tier | 20 | non | **NON VÉRIFIÉ** |
| BADGE-29 | `goals_season__30` | Goleador | joueur/tier | 30 | non | **NON VÉRIFIÉ** |
| BADGE-30 | `goals_season__5` | Première gâchette | joueur/tier | 5 | non | **NON VÉRIFIÉ** |
| BADGE-31 | `matches_played__100` | Vétéran | joueur/tier | 100 | non | **NON VÉRIFIÉ** |
| BADGE-32 | `matches_played__150` | Cadre du club | joueur/tier | 150 | non | **NON VÉRIFIÉ** |
| BADGE-33 | `matches_played__200` | Légende du club | joueur/tier | 200 | non | **NON VÉRIFIÉ** |
| BADGE-34 | `matches_played__50` | Fidèle | joueur/tier | 50 | non | **NON VÉRIFIÉ** |
| BADGE-35 | `matches_played_season__15` | Habitué | joueur/tier | 15 | non | **NON VÉRIFIÉ** |
| BADGE-36 | `matches_played_season__20` | Assidu | joueur/tier | 20 | non | **NON VÉRIFIÉ** |
| BADGE-37 | `matches_played_season__25` | Pilier | joueur/tier | 25 | non | **NON VÉRIFIÉ** |
| BADGE-38 | `matches_played_season__30` | Incontournable | joueur/tier | 30 | non | **NON VÉRIFIÉ** |
| BADGE-39 | `max_match_assists__3` | Triple passe | joueur/tier | 3 | non | **NON VÉRIFIÉ** |
| BADGE-40 | `max_match_goals__3` | Triplé | joueur/tier | 3 | non | **NON VÉRIFIÉ** |
| BADGE-41 | `max_match_goals__4` | Quadruplé | joueur/tier | 4 | non | **NON VÉRIFIÉ** |
| BADGE-42 | `max_match_goals__5` | Quintuplé | joueur/tier | 5 | non | **NON VÉRIFIÉ** |
| BADGE-43 | `mvp__10` | Étoile montante | joueur/tier | 10 | non | **NON VÉRIFIÉ** |
| BADGE-44 | `mvp__20` | Étoile confirmée | joueur/tier | 20 | non | **NON VÉRIFIÉ** |
| BADGE-45 | `mvp__30` | Supernova | joueur/tier | 30 | non | **NON VÉRIFIÉ** |
| BADGE-46 | `mvp__50` | Icône du club | joueur/tier | 50 | non | **NON VÉRIFIÉ** |
| BADGE-47 | `role_coach` | Coach | joueur/custom | – | non | **NON VÉRIFIÉ** |
| BADGE-48 | `role_goalkeeper` | Gardien | joueur/custom | – | non | **NON VÉRIFIÉ** |
| BADGE-49 | `role_president` | Présidence | joueur/custom | – | non | **NON VÉRIFIÉ** |
| BADGE-50 | `test_a` | Badge test A | joueur/custom | – | non | **NON VÉRIFIÉ** |
| BADGE-51 | `title_best_winrate__1` | Porte-bonheur | joueur/tier | 1 | non | **NON VÉRIFIÉ** |
| BADGE-52 | `title_most_present__1` | Fidèle au poste | joueur/tier | 1 | non | **NON VÉRIFIÉ** |
| BADGE-53 | `title_mvp_king__1` | Étoile de la saison | joueur/tier | 1 | non | **NON VÉRIFIÉ** |
| BADGE-54 | `title_top_assists__1` | Baguette magique | joueur/tier | 1 | non | **NON VÉRIFIÉ** |
| BADGE-55 | `title_top_scorer__1` | Machine à buts | joueur/tier | 1 | non | **NON VÉRIFIÉ** |
| BADGE-56 | `wins__100` | Centurion victorieux | joueur/tier | 100 | non | **NON VÉRIFIÉ** |
| BADGE-57 | `wins__150` | Maître de la gagne | joueur/tier | 150 | non | **NON VÉRIFIÉ** |
| BADGE-58 | `wins__200` | Légende victorieuse | joueur/tier | 200 | non | **NON VÉRIFIÉ** |
| BADGE-59 | `wins__50` | Habitué de la victoire | joueur/tier | 50 | non | **NON VÉRIFIÉ** |
| BADGE-60 | `wins_season__10` | Compétiteur | joueur/tier | 10 | non | **NON VÉRIFIÉ** |
| BADGE-61 | `wins_season__15` | Gagnant | joueur/tier | 15 | non | **NON VÉRIFIÉ** |
| BADGE-62 | `wins_season__20` | Serial winner | joueur/tier | 20 | non | **NON VÉRIFIÉ** |
| BADGE-63 | `wins_season__25` | Invincible | joueur/tier | 25 | non | **NON VÉRIFIÉ** |
| BADGE-64 | `bet_against_grinta__1` | Avocat du diable | pronostiqueur/tier | 1 | oui | **NON VÉRIFIÉ** |
| BADGE-65 | `title_best_pred_match__1` | Le Visionnaire | pronostiqueur/tier | 1 | non | **NON VÉRIFIÉ** |
| BADGE-66 | `title_best_pred_overall__1` | Le Cerveau | pronostiqueur/tier | 1 | non | **NON VÉRIFIÉ** |
| BADGE-67 | `title_best_pred_player__1` | L’Analyste | pronostiqueur/tier | 1 | non | **NON VÉRIFIÉ** |

## 4. Modules activables par club

| ID | Clé | Intitulé | À tester | Résultat réel |
|---|---|---|---|
| MODULE-01 | `predictions` | Pronostics et classement | Allumer, éteindre, ouvrir écran direct, vérifier RPC/notifications/statistiques, rallumer sans effacer les données | **NON VÉRIFIÉ** |
| MODULE-02 | `statistics` | Statistiques | Allumer, éteindre, ouvrir écran direct, vérifier RPC/notifications/statistiques, rallumer sans effacer les données | **NON VÉRIFIÉ** |
| MODULE-03 | `man_of_the_match` | Étoile du match | Allumer, éteindre, ouvrir écran direct, vérifier RPC/notifications/statistiques, rallumer sans effacer les données | **NON VÉRIFIÉ** |
| MODULE-04 | `live_mode` | Mode live | Allumer, éteindre, ouvrir écran direct, vérifier RPC/notifications/statistiques, rallumer sans effacer les données | **NON VÉRIFIÉ** |
| MODULE-05 | `badges` | Badges | Allumer, éteindre, ouvrir écran direct, vérifier RPC/notifications/statistiques, rallumer sans effacer les données | **NON VÉRIFIÉ** |
| MODULE-06 | `season_wrapped` | Bilan de fin de saison | Allumer, éteindre, ouvrir écran direct, vérifier RPC/notifications/statistiques, rallumer sans effacer les données | **NON VÉRIFIÉ** |
| MODULE-07 | `weather` | Météo du match | Allumer, éteindre, ouvrir écran direct, vérifier RPC/notifications/statistiques, rallumer sans effacer les données | **NON VÉRIFIÉ** |

## 5. Réglages client connus

Le code de `ClubRules` expose les règles ci-dessous. La table `private.club_rules` ne liste que les valeurs persistées et ne prouve pas à elle seule le catalogue réellement affiché par `get_club_rules`. Il faut comparer sa réponse authentifiée à cette grille avant de déclarer la liste exhaustive.

| ID | Clé | Valeur défaut dans le code | Présent en base comme valeur propre à un club ? | Résultat après changement |
|---|---|---|---|
| RULE-01 | `features_open_days` | 6 | non ou valeur par défaut | **NON VÉRIFIÉ** |
| RULE-02 | `features_open_hour` | 12 | non ou valeur par défaut | **NON VÉRIFIÉ** |
| RULE-03 | `prediction_close_minutes` | 15 | non ou valeur par défaut | **NON VÉRIFIÉ** |
| RULE-04 | `correction_window_hours` | 24 | non ou valeur par défaut | **NON VÉRIFIÉ** |
| RULE-05 | `waitlist_mode` | 0 | oui | **NON VÉRIFIÉ** |
| RULE-06 | `prediction_points_exact` | 20 | non ou valeur par défaut | **NON VÉRIFIÉ** |
| RULE-07 | `prediction_points_goal_difference` | 15 | non ou valeur par défaut | **NON VÉRIFIÉ** |
| RULE-08 | `prediction_points_one_score` | 15 | non ou valeur par défaut | **NON VÉRIFIÉ** |
| RULE-09 | `prediction_points_winner` | 10 | non ou valeur par défaut | **NON VÉRIFIÉ** |
| RULE-10 | `odds_mode` | 0 | oui | **NON VÉRIFIÉ** |
| RULE-11 | `live_pilot_mode` | 0 | non ou valeur par défaut | **NON VÉRIFIÉ** |
| RULE-12 | `motm_self_vote` | 0 | non ou valeur par défaut | **NON VÉRIFIÉ** |
| RULE-13 | `wrapped_music` | 1 | non ou valeur par défaut | **NON VÉRIFIÉ** |
| RULE-14 | `bool` | non défini | non ou valeur par défaut | **NON VÉRIFIÉ** |
| RULE-15 | `mode` | non défini | non ou valeur par défaut | **NON VÉRIFIÉ** |

**Autres éléments d'administration à éprouver indépendamment :** nom, nom court, couleurs principales/secondaires, logo, adresse du stade, quota, code/lien d'invitation, 3 tenues et couleurs de gardien, saisons, coaching, bibliothèque des adversaires et stades, quotas de stockage, notifications libres et abonnement. La présence des contrôles dans `club_settings_page.dart` et `club_kits_page.dart` n'est pas un test écran.

## 6. Catégories de notifications à couvrir

| ID | Type | Activée (réception) | Désactivée (absence de réception) |
|---|---|---|---|
| NOTIF-01 (L01) | Abonnement Web Push et autorisation appareil | **NON VÉRIFIÉ** | **NON VÉRIFIÉ** |
| NOTIF-02 (L02) | Notifications d'ouverture des disponibilités | **NON VÉRIFIÉ** | **NON VÉRIFIÉ** |
| NOTIF-03 (L03) | Convocation, désistement, liste d'attente | **NON VÉRIFIÉ** | **NON VÉRIFIÉ** |
| NOTIF-04 (L04) | Changement, annulation ou report de match | **NON VÉRIFIÉ** | **NON VÉRIFIÉ** |
| NOTIF-05 (L05) | Composition publiée | **NON VÉRIFIÉ** | **NON VÉRIFIÉ** |
| NOTIF-06 (L06) | Pronostics, vote HDM et résultat | **NON VÉRIFIÉ** | **NON VÉRIFIÉ** |
| NOTIF-07 (L07) | Badge débloqué | **NON VÉRIFIÉ** | **NON VÉRIFIÉ** |
| NOTIF-08 (L08) | Message libre administrateur et sélection destinataires | **NON VÉRIFIÉ** | **NON VÉRIFIÉ** |
| NOTIF-09 (L09) | Préférences individuelles et coupe-circuit club | **NON VÉRIFIÉ** | **NON VÉRIFIÉ** |
| NOTIF-10 (L10) | Historique notifications et pastille non lue | **NON VÉRIFIÉ** | **NON VÉRIFIÉ** |
| NOTIF-11 (L11) | Service worker, manifeste et installation PWA | **NON VÉRIFIÉ** | **NON VÉRIFIÉ** |
| NOTIF-12 (L12) | Météo et push via tâche planifiée | **NON VÉRIFIÉ** | **NON VÉRIFIÉ** |

## 7. Rôles et états d'accès à tester

Les rôles serveur, les statuts de comptes et les attributs sportifs sont **trois concepts distincts**. Un joueur coach n'est pas nécessairement un rôle SQL `coach`.

| ID | Identité/scénario | Test de permission et de cloisonnement | Résultat |
|---|---|---|---|
| R01 | Admin actif A | Administration A autorisée, accès B refusé | **NON VÉRIFIÉ** |
| R02 | Admin actif B | Administration B autorisée, accès A refusé | **NON VÉRIFIÉ** |
| R03 | Joueur actif | Actions joueur autorisées, actions admin refusées | **NON VÉRIFIÉ** |
| R04 | Coach actif (attribut sportif) | Piloter Live si réglage autorise, quota distinct | **NON VÉRIFIÉ** |
| R05 | Membre en attente | Aucune donnée métier privée ni opération sensible | **NON VÉRIFIÉ** |
| R06 | Membre archivé/inactif | Refus serveur et cache révoqué | **NON VÉRIFIÉ** |
| R07 | Invité (sans compte) | Places/convocations/stats sans session d'administration | **NON VÉRIFIÉ** |
| R08 | Non connecté | Refus des routes et API privées | **NON VÉRIFIÉ** |

## 8. Remarques méthodologiques

- Cet inventaire inclut les **signatures SQL** présentes, pas seulement les 164 fonctions métier. Les fonctions privées, triggers SQL et tâches planifiées demandent un inventaire complémentaire avant certification exhaustive.
- Le compte `alphat` a été nommé par le demandeur mais **aucune authentification** n'a été possible : aucun mot de passe n'a été fourni dans ce fil et aucun outil navigateur authentifié n'est disponible.
- Le catalogue de badges de B est séparé et contient lui aussi 67 badges : il faut vérifier les mêmes épreuves dans l'autre club. Deux badges de test personnalisés figurent en A et ne prouvent pas une attribution.
- Aucun appel d'écriture ni changement de réglage n'a été effectué sur la base commerciale.
