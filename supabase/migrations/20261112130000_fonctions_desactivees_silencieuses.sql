-- Fonction désactivée par le club : plus de notification ni de travail
-- caché en arrière-plan.
--
-- Quand un administrateur coupait les pronostics, l'homme du match, les badges
-- ou la météo, l'application cachait bien l'écran et le serveur refusait les
-- saisies, mais les tâches automatiques continuaient comme si de rien
-- n'était :
--   - rappel « Pense à pronostiquer » envoyé aux joueurs ;
--   - vote de l'homme du match ouvert, puis notification « Pense à voter »
--     et annonce du résultat (y compris à la clôture d'un vote ouvert avant
--     la coupure) ;
--   - notification « Badge débloqué » ;
--   - météo du match demandée au service externe toutes les 15 minutes.
-- Un joueur recevait donc une notification qui menait vers un écran absent.
--
-- Chaque tâche vérifie maintenant que la fonction est activée pour le club
-- traité (les tâches planifiées passent club par club). La file des
-- annonces de badges est en plus bornée explicitement au club traité, en
-- complément du cloisonnement par règles d'accès (relecture sécurité). Les corps sont repris
-- à l'identique de 20261111000100_socle_structure.sql ; seule la vérification
-- est ajoutée. CREATE OR REPLACE conserve propriétaire et droits.

-- 1. Rappel de pronostic
CREATE OR REPLACE FUNCTION "public"."push_prediction_j5_notifications"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_match record;
  v_sent integer := 0;
begin
  if private.is_feature_enabled('notifications_paused')
     or not private.club_module_enabled('predictions') then
    return 0;
  end if;

  -- Le cron tourne chaque minute. La fenêtre de 10 minutes ne sert qu'à
  -- rattraper une exécution manquée : passé 16 h 10, le rappel n'est plus
  -- envoyé, et jamais après la fermeture des pronostics (T-15).
  for v_match in
    select m.id
    from public.matches m
    where m.status = 'a_venir'
      and m.match_type <> 'entre_nous'
      and m.kickoff_at is not null
      and now() >= private.match_prediction_notification_at(m.kickoff_at)
      and now() < private.match_prediction_notification_at(m.kickoff_at)
        + interval '10 minutes'
      and now() < private.match_prediction_closes_at(m.kickoff_at)
      and (m.predictions_closed_at is null or now() < m.predictions_closed_at)
    order by m.kickoff_at
  loop
    insert into public.push_notification_log(match_id, kind, sent_at)
    values (v_match.id, 'prediction_j5', now())
    on conflict do nothing;
    if found then
      perform public.internal_push_notify('prediction_j5', v_match.id);
      v_sent := v_sent + 1;
    end if;
  end loop;
  return v_sent;
end;
$$;

-- 2. Homme du match : pas de vote créé
CREATE OR REPLACE FUNCTION "private"."ensure_match_motm_election"("p_match_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_exists boolean;
  v_has_ballot boolean;
  v_opens_at timestamptz;
  v_closes_at timestamptz;
  v_version integer;
begin
  -- Homme du match désactivé : aucun vote n'est ouvert pour ce match.
  if not private.club_module_enabled('man_of_the_match') then
    return;
  end if;

  select true into v_exists
  from public.match_sport_motm_elections election
  where election.match_id = p_match_id;
  if v_exists then
    return;
  end if;

  select private.match_motm_opens_at(p_match_id) into v_opens_at;
  select private.match_motm_closes_at(p_match_id) into v_closes_at;
  if v_opens_at is null
     or v_closes_at is null
     or v_closes_at <= v_opens_at then
    return;
  end if;

  if exists (
    select 1
    from public.matches match
    where match.id = p_match_id
      and match.status = 'annule'
  ) then
    return;
  end if;

  v_has_ballot := private.match_has_eligible_motm_ballot(p_match_id);
  if not v_has_ballot then
    return;
  end if;

  v_version := private.match_motm_anchor_version(p_match_id);

  insert into public.match_sport_motm_elections (
    match_id, finalization_version, state, opens_at, closes_at, closed_at,
    total_votes, max_votes, created_at, updated_at
  ) values (
    p_match_id,
    v_version,
    'draft'::public.sport_vote_state,
    v_opens_at,
    v_closes_at,
    null,
    0,
    0,
    now(),
    now()
  )
  on conflict (match_id) do nothing;

  update public.match_sport_workflows
  set vote_state = 'draft',
      updated_at = now()
  where match_id = p_match_id;
end;
$$;

-- 3. Homme du match : pas de « Pense à voter » (vote ouvert avant la coupure)
CREATE OR REPLACE FUNCTION "private"."push_due_motm_open_notifications"("p_now" timestamp with time zone DEFAULT "now"()) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_row record;
  v_sent integer := 0;
begin
  if private.is_feature_enabled('notifications_paused')
     or not private.is_feature_enabled('sports_management')
     or not private.club_module_enabled('man_of_the_match') then
    return 0;
  end if;

  for v_row in
    select election.match_id
    from public.match_sport_motm_elections election
    where election.state = 'open'
      and election.opens_at <= p_now
      and election.closes_at > p_now
      and not exists (
        select 1 from public.push_notification_log log
        where log.match_id = election.match_id and log.kind = 'motm_open'
      )
    order by election.opens_at, election.match_id
    for update skip locked
  loop
    insert into public.push_notification_log(match_id, kind, sent_at)
    values (v_row.match_id, 'motm_open', p_now)
    on conflict do nothing;
    if found then
      perform private.dispatch_motm_push('motm_open', v_row.match_id);
      v_sent := v_sent + 1;
    end if;
  end loop;
  return v_sent;
end;
$$;

-- 4. Homme du match : pas d'annonce du résultat
CREATE OR REPLACE FUNCTION "private"."push_due_motm_result_notifications"("p_now" timestamp with time zone DEFAULT "now"()) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_row record;
  v_sent integer := 0;
begin
  if not private.is_feature_enabled('sports_management')
     or not private.club_module_enabled('man_of_the_match') then
    return 0;
  end if;

  for v_row in
    select election.match_id
    from public.match_sport_motm_elections election
    where election.state = 'closed'
      and election.closed_at is not null
      and election.closed_at >= p_now - interval '30 days'
      and (
        not exists (
          select 1 from public.push_notification_log log
          where log.match_id = election.match_id
            and log.kind = 'motm_result_general'
        )
        or not exists (
          select 1 from public.push_notification_log log
          where log.match_id = election.match_id
            and log.kind = 'motm_result_winner'
        )
      )
    order by election.closed_at, election.match_id
  loop
    if private.try_motm_result_notification(
      'motm_result_general',
      v_row.match_id,
      p_now
    ) then
      v_sent := v_sent + 1;
    end if;
    if private.try_motm_result_notification(
      'motm_result_winner',
      v_row.match_id,
      p_now
    ) then
      v_sent := v_sent + 1;
    end if;
  end loop;

  return v_sent;
end;
$$;

-- 5. Badges : pas de « Badge débloqué »
CREATE OR REPLACE FUNCTION "private"."process_badge_unlock_notifications"("p_now" timestamp with time zone DEFAULT "now"()) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_token text;
  v_sent integer := 0;
  v_row record;
  v_payload jsonb;
begin
  -- Deux exécutions simultanées ne doivent pas annoncer deux fois.
  if not pg_catalog.pg_try_advisory_xact_lock(
    pg_catalog.hashtextextended('process_badge_unlock_notifications', 0)
  ) then
    return 0;
  end if;

  -- Badges désactivés : les badges continuent d'être comptés sans bruit
  -- (ils réapparaissent si le club réactive la fonction), mais aucune
  -- annonce ne part. La file du club est vidée pour ne pas tout annoncer
  -- d'un coup à la réactivation.
  if not private.club_module_enabled('badges') then
    delete from private.badge_unlock_push_queue queue
    where queue.club_id = (select private.current_club_id());
    return 0;
  end if;

  select secret.decrypted_secret
  into v_token
  from private.vault_secrets() secret
  where secret.name = 'push_internal_token';

  if v_token is null then
    -- Sans canal push, on évite simplement que la file grossisse sans fin.
    delete from private.badge_unlock_push_queue queue
    where queue.queued_at < p_now - interval '1 day'
      and queue.club_id = (select private.current_club_id());
    return 0;
  end if;

  for v_row in
    with ready as (
      select queue.profile_id
      from private.badge_unlock_push_queue queue
      where queue.club_id = (select private.current_club_id())
      group by queue.profile_id
      having max(queue.queued_at) <= p_now - interval '45 seconds'
    ),
    taken as (
      delete from private.badge_unlock_push_queue queue
      using ready
      where queue.profile_id = ready.profile_id
        and queue.club_id = (select private.current_club_id())
      returning queue.profile_id, queue.badge_id, queue.queued_at
    )
    select
      taken.profile_id,
      array_agg(badge.name order by taken.queued_at, badge.name) as names
    from taken
    join public.badges badge on badge.id = taken.badge_id
    join public.profile_badges owned
      on owned.profile_id = taken.profile_id
     and owned.badge_id = taken.badge_id
    join public.profiles profile on profile.id = taken.profile_id
    where profile.status = 'active'
      and profile.notify_badges
    group by taken.profile_id
  loop
    v_payload := private.badge_unlock_push_message(v_row.names);
    if v_payload is null then
      continue;
    end if;

    perform private.http_post(
      url := private.edge_function_url('send-push'),
      body := jsonb_build_object(
        'kind', 'custom',
        'log_kind', 'badge_unlocked',
        'profile_ids', jsonb_build_array(v_row.profile_id),
        'title', v_payload ->> 'title',
        'message', v_payload ->> 'message',
        'url', 'armoire'
      ),
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-push-token', v_token
      ),
      timeout_milliseconds := 10000
    );
    v_sent := v_sent + 1;
  end loop;

  return v_sent;
end;
$$;

-- 6. Météo : pas d'appel au service externe
CREATE OR REPLACE FUNCTION "private"."request_match_weather_refresh"("p_match_id" "uuid" DEFAULT NULL::"uuid") RETURNS bigint
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_token text;
  v_request_id bigint;
begin
  -- Météo désactivée : aucun appel au service météo pour ce club.
  if not private.club_module_enabled('weather') then
    return null;
  end if;

  select secret.decrypted_secret
  into v_token
  from private.vault_secrets() secret
  where secret.name = 'push_internal_token';

  if v_token is null then
    return null;
  end if;

  select private.http_post(
    url := private.edge_function_url('send-push'),
    body := case
      when p_match_id is null then jsonb_build_object('kind', 'refresh_match_weather')
      else jsonb_build_object(
        'kind', 'refresh_match_weather',
        'match_id', p_match_id
      )
    end,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-token', v_token
    ),
    timeout_milliseconds := 30000
  ) into v_request_id;

  return v_request_id;
exception
  when others then
    return null;
end;
$$;

-- 7. Homme du match : pas d'annonce du résultat à la clôture d'un vote ouvert
-- avant la coupure (déclencheur push_on_motm_election_closed)
CREATE OR REPLACE FUNCTION "private"."try_motm_result_notification"("p_kind" "text", "p_match_id" "uuid", "p_sent_at" timestamp with time zone DEFAULT "now"()) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  if p_kind not in ('motm_result_general', 'motm_result_winner') then
    raise exception 'Unknown MOTM result notification kind' using errcode = '22023';
  end if;

  -- Homme du match coupé (par exemple pendant un vote déjà ouvert) : le
  -- résultat n'est pas annoncé, ni à la clôture ni en rattrapage.
  if not private.club_module_enabled('man_of_the_match') then
    return false;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_match_id::text || ':' || p_kind, 0)
  );

  if exists (
    select 1
    from public.push_notification_log log
    where log.match_id = p_match_id
      and log.kind = p_kind
  ) then
    return false;
  end if;

  if not private.dispatch_motm_result_notification(p_kind, p_match_id) then
    return false;
  end if;

  insert into public.push_notification_log(match_id, kind, sent_at)
  values (p_match_id, p_kind, p_sent_at)
  on conflict do nothing;

  return found;
end;
$$;
