-- Création d'un match trop proche du coup d'envoi : message clair.
--
-- Avant : créer un match qui commence dans moins de 15 minutes (ou déjà
-- commencé) échouait plus loin dans la chaîne avec « Le match est verrouillé
-- depuis l'ouverture du Live », alors que le match n'existait pas encore.
-- Désormais les deux fonctions de création appelées par l'appli refusent tout
-- de suite, avec un message qui dit quoi faire. La frontière reste
-- private.match_prediction_closes_at (T-15), la même que pour le verrou.
--
-- create or replace conserve le propriétaire (club_scope) et les droits.

create or replace function private.assert_new_match_kickoff_open(
  p_match_date date,
  p_match_time time without time zone
) returns void
language plpgsql
stable
set search_path to ''
as $$
declare
  v_kickoff timestamptz;
  v_minutes integer;
begin
  if p_match_date is null or p_match_time is null then
    return;
  end if;

  v_kickoff := (p_match_date + p_match_time) at time zone 'Europe/Paris';

  if v_kickoff <= now() then
    raise exception 'Impossible de créer un match dont l’heure est déjà passée.'
      using errcode = '22023';
  end if;

  if now() >= private.match_prediction_closes_at(v_kickoff) then
    v_minutes := ceil(
      extract(epoch from v_kickoff - private.match_prediction_closes_at(v_kickoff)) / 60
    )::integer;
    raise exception 'Impossible de créer un match qui commence dans moins de % minutes.',
      v_minutes
      using errcode = '22023';
  end if;
end;
$$;

revoke all on function private.assert_new_match_kickoff_open(date, time without time zone) from public, anon, authenticated;

comment on function private.assert_new_match_kickoff_open(date, time without time zone) is
  'Refuse la création d''un match déjà commencé ou qui commence avant l''ouverture du Live (T-15), avec un message clair.';

alter function private.assert_new_match_kickoff_open(date, time without time zone) owner to club_scope;

CREATE OR REPLACE FUNCTION "public"."admin_create_match_complete_v3"("p_season_id" "uuid", "p_opponent_id" "uuid", "p_match_date" "date", "p_match_time" time without time zone, "p_location" "text", "p_win" numeric, "p_draw" numeric, "p_loss" numeric, "p_squad_size_limit" integer DEFAULT NULL::integer, "p_address" "text" DEFAULT NULL::"text", "p_remember_address_as_default" boolean DEFAULT false, "p_match_type" "text" DEFAULT 'championnat'::"text", "p_jersey_note" "text" DEFAULT NULL::"text", "p_availability_schedule_mode" "text" DEFAULT 'automatic'::"text", "p_availability_opens_at" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_meeting_at" timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_match_id uuid;
begin
  if not private.is_admin() then
    raise exception 'Active administrator role required' using errcode = '42501';
  end if;

  perform private.assert_new_match_kickoff_open(p_match_date, p_match_time);

  v_match_id := public.admin_create_match_complete_v2(
    p_season_id,
    p_opponent_id,
    p_match_date,
    p_match_time,
    p_location,
    p_win,
    p_draw,
    p_loss,
    p_squad_size_limit,
    p_address,
    p_remember_address_as_default,
    p_match_type,
    p_jersey_note,
    p_availability_schedule_mode,
    p_availability_opens_at
  );

  perform private.set_match_meeting_at(v_match_id, p_meeting_at);
  return v_match_id;
end;
$$;

CREATE OR REPLACE FUNCTION "public"."create_internal_match_v3"("p_season_id" "uuid", "p_match_date" "date", "p_match_time" time without time zone, "p_address" "text" DEFAULT NULL::"text", "p_availability_schedule_mode" "text" DEFAULT 'automatic'::"text", "p_availability_opens_at" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_meeting_at" timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_match_id uuid;
begin
  if not public.is_match_staff() then
    raise exception 'Active administrator role required' using errcode = '42501';
  end if;

  perform private.assert_new_match_kickoff_open(p_match_date, p_match_time);

  v_match_id := public.create_internal_match_v2(
    p_season_id,
    p_match_date,
    p_match_time,
    p_address,
    p_availability_schedule_mode,
    p_availability_opens_at
  );

  perform private.set_match_meeting_at(v_match_id, p_meeting_at);
  return v_match_id;
end;
$$;
