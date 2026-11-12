-- Notifications : le nom du club remplace « AS Grinta ».
--
-- Trois fonctions héritées d'AS Grinta écrivaient encore ce nom en dur dans
-- les notifications envoyées aux joueurs (Live : coup d'envoi, buts, fin de
-- match ; fin de match avec vote de l'Homme du match ; notifications de test).
-- Un joueur d'un autre club recevait donc « But de l'AS Grinta ! ».
--
-- Les corps sont repris à l'identique de 20261111000100_socle_structure.sql ;
-- seuls changent : le nom du club, lu dans public.clubs via matches.club_id
-- (ou le club du compte pour les tests), et le titre de la notification de
-- test. CREATE OR REPLACE conserve propriétaire et droits existants.

CREATE OR REPLACE FUNCTION "public"."internal_claim_match_live_notification"("p_notification_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_event private.match_live_notification_events%rowtype;
  v_match record;
  v_home_name text;
  v_away_name text;
  v_home_score integer;
  v_away_score integer;
  v_scoreline text;
  v_payload jsonb;
  v_subscriptions jsonb;
  v_recipients jsonb;
  v_log_kind text;
begin
  update private.match_live_notification_events event
  set state = 'dispatching', claimed_at = now()
  where event.id = p_notification_id
    and event.state = 'pending'
    and event.due_at <= now()
  returning event.* into v_event;

  if not found then
    return jsonb_build_object('claimed', false);
  end if;

  select
    match.location,
    coalesce(nullif(btrim(opponent.name), ''), 'Adversaire') as opponent_name,
    coalesce(nullif(btrim(club.name), ''), 'Notre club') as club_name
  into v_match
  from public.matches match
  left join public.opponents opponent on opponent.id = match.opponent_id
  left join public.clubs club on club.id = match.club_id
  where match.id = v_event.match_id;

  if not found then
    update private.match_live_notification_events event
    set state = 'cancelled', completed_at = now()
    where event.id = v_event.id;
    return jsonb_build_object('claimed', false);
  end if;

  if v_match.location = 'domicile' then
    v_home_name := v_match.club_name;
    v_away_name := v_match.opponent_name;
    v_home_score := v_event.score_as_grinta;
    v_away_score := v_event.score_adverse;
  else
    v_home_name := v_match.opponent_name;
    v_away_name := v_match.club_name;
    v_home_score := v_event.score_adverse;
    v_away_score := v_event.score_as_grinta;
  end if;

  v_scoreline := format('%s %s–%s %s', v_home_name, v_home_score, v_away_score, v_away_name);

  if v_event.kind = 'kickoff' then
    v_log_kind := 'live_kickoff';
    v_payload := jsonb_build_object(
      'title', '⚽ Le match commence',
      'body', format('%s – %s', v_home_name, v_away_name),
      'url', 'matches/' || v_event.match_id || '/lineup?section=live',
      'tag', 'live-' || v_event.match_id || '-kickoff'
    );
  elsif v_event.kind = 'goal_us' then
    v_log_kind := 'live_goal_us';
    v_payload := jsonb_build_object(
      'title', '⚽ But !',
      'body', case
        when nullif(btrim(v_event.scorer_name), '') is not null
          then format('But de %s ! %s', v_event.scorer_name, v_scoreline)
        else format('But pour %s ! %s', v_match.club_name, v_scoreline)
      end,
      'url', 'matches/' || v_event.match_id || '/lineup?section=live',
      'tag', 'live-' || v_event.match_id || '-goal-' || v_event.id
    );
  elsif v_event.kind = 'goal_them' then
    v_log_kind := 'live_goal_them';
    v_payload := jsonb_build_object(
      'title', format('⚽ But pour %s', v_match.opponent_name),
      'body', v_scoreline,
      'url', 'matches/' || v_event.match_id || '/lineup?section=live',
      'tag', 'live-' || v_event.match_id || '-goal-' || v_event.id
    );
  else
    v_log_kind := 'live_full_time';
    v_payload := jsonb_build_object(
      'title', '🏁 Fin du match',
      'body', v_scoreline,
      'url', 'matches/' || v_event.match_id || '/lineup?section=live',
      'tag', 'live-' || v_event.match_id || '-full-time'
    );
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'profile_id', push.profile_id,
        'endpoint', push.endpoint,
        'p256dh', push.p256dh,
        'auth', push.auth
      ) order by push.profile_id, push.endpoint
    ),
    '[]'::jsonb
  )
  into v_subscriptions
  from private.match_live_notification_event_targets target
  join public.match_live_notification_subscriptions subscription
    on subscription.match_id = v_event.match_id
   and subscription.profile_id = target.profile_id
   and subscription.completed_at is null
  join public.profiles profile
    on profile.id = target.profile_id
   and profile.status = 'active'
  join public.push_subscriptions push
    on push.profile_id = target.profile_id
  where target.notification_id = v_event.id;

  -- Cibles toujours inscrites, téléphone abonné ou non : l'historique les
  -- reçoit toutes, au moment de l'envoi.
  select coalesce(
    jsonb_agg(target.profile_id order by target.profile_id),
    '[]'::jsonb
  )
  into v_recipients
  from private.match_live_notification_event_targets target
  join public.match_live_notification_subscriptions subscription
    on subscription.match_id = v_event.match_id
   and subscription.profile_id = target.profile_id
   and subscription.completed_at is null
  join public.profiles profile
    on profile.id = target.profile_id
   and profile.status = 'active'
  where target.notification_id = v_event.id;

  return jsonb_build_object(
    'claimed', true,
    'notification_id', v_event.id,
    'match_id', v_event.match_id,
    'kind', v_log_kind,
    'payload', v_payload,
    'subscriptions', v_subscriptions,
    'recipient_profile_ids', v_recipients
  );
end;
$$;

CREATE OR REPLACE FUNCTION "public"."internal_push_dispatch"("p_kind" "text", "p_match_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_match record;
  v_payload jsonb;
  v_subscriptions jsonb;
  v_recipients jsonb;
  v_date text;
  v_time text;
  v_scoreline text;
begin
  select
    m.id,
    m.kickoff_at,
    m.status,
    m.match_type,
    m.location,
    m.score_as_grinta,
    m.score_adverse,
    nullif(btrim(o.name), '') as opponent_name,
    coalesce(nullif(btrim(c.name), ''), 'Notre club') as club_name
  into v_match
  from public.matches m
  left join public.opponents o on o.id = m.opponent_id
  left join public.clubs c on c.id = m.club_id
  where m.id = p_match_id;

  if not found then
    raise exception 'Match not found' using errcode = 'P0002';
  end if;

  if v_match.kickoff_at is null then
    raise exception 'Match kickoff is required' using errcode = '22023';
  end if;

  if p_kind = 'prediction_j5' and v_match.match_type = 'entre_nous' then
    return jsonb_build_object(
      'payload', '{}'::jsonb,
      'subscriptions', '[]'::jsonb
    );
  end if;

  v_date := to_char(v_match.kickoff_at at time zone 'Europe/Paris', 'DD/MM');
  v_time := private.match_notification_time_label(v_match.kickoff_at);

  if p_kind = 'prediction_j5' then
    v_payload := jsonb_build_object(
      'title', 'Pronostic',
      'body', case
        when v_match.opponent_name is null then format(
          'Pense à pronostiquer pour le match entre nous du %s.',
          v_date
        )
        else format(
          'Pense à pronostiquer pour le match du %s contre %s.',
          v_date,
          v_match.opponent_name
        )
      end,
      'url', 'matches/' || p_match_id || '/lineup?section=prediction',
      'tag', 'match-' || p_match_id || '-prediction-j5'
    );

    select coalesce(jsonb_agg(jsonb_build_object(
      'profile_id', subscription.profile_id,
      'endpoint', subscription.endpoint,
      'p256dh', subscription.p256dh,
      'auth', subscription.auth
    )), '[]'::jsonb)
    into v_subscriptions
    from public.push_subscriptions subscription
    join public.profiles profile on profile.id = subscription.profile_id
    where profile.status = 'active'
      and profile.notify_prediction_reminders
      and not exists (
        select 1
        from public.match_predictions prediction
        where prediction.match_id = p_match_id
          and prediction.profile_id = profile.id
          and prediction.is_filled
      );

    -- Mêmes destinataires, téléphone abonné ou non : l'historique les
    -- reçoit tous.
    select coalesce(jsonb_agg(profile.id order by profile.id), '[]'::jsonb)
    into v_recipients
    from public.profiles profile
    where profile.status = 'active'
      and profile.notify_prediction_reminders
      and not exists (
        select 1
        from public.match_predictions prediction
        where prediction.match_id = p_match_id
          and prediction.profile_id = profile.id
          and prediction.is_filled
      );

  elsif p_kind in ('match_cancelled', 'match_rescheduled_date', 'match_rescheduled_time') then
    v_payload := case p_kind
      when 'match_cancelled' then jsonb_build_object(
        'title', 'Match annulé',
        'body', case
          when v_match.opponent_name is null then format(
            'Le match entre nous du %s à %s est annulé.',
            v_date, v_time
          )
          else format(
            'Le match du %s contre %s à %s est annulé.',
            v_date, v_match.opponent_name, v_time
          )
        end,
        'url', 'matches?match=' || p_match_id,
        'tag', 'match-' || p_match_id || '-cancelled'
      )
      when 'match_rescheduled_date' then jsonb_build_object(
        'title', 'Match reporté',
        'body', case
          when private.match_features_open_at(v_match.kickoff_at) <= now()
            then case
              when v_match.opponent_name is null then format(
                'Le match entre nous est reporté au %s à %s. Es-tu disponible ?',
                v_date, v_time
              )
              else format(
                'Le match contre %s est reporté au %s à %s. Es-tu disponible ?',
                v_match.opponent_name, v_date, v_time
              )
            end
          else case
            when v_match.opponent_name is null then format(
              'Le match entre nous est reporté au %s à %s.',
              v_date, v_time
            )
            else format(
              'Le match contre %s est reporté au %s à %s.',
              v_match.opponent_name, v_date, v_time
            )
          end
        end,
        'url', 'matches?match=' || p_match_id,
        'tag', 'match-' || p_match_id || '-rescheduled-date'
      )
      else jsonb_build_object(
        'title', 'Horaire du match modifié',
        'body', case
          when v_match.opponent_name is null then format(
            'Le match entre nous du %s aura finalement lieu à %s.',
            v_date, v_time
          )
          else format(
            'Le match du %s contre %s aura finalement lieu à %s.',
            v_date, v_match.opponent_name, v_time
          )
        end,
        'url', 'matches/' || p_match_id || '/lineup?section=info',
        'tag', 'match-' || p_match_id || '-rescheduled-time'
      )
    end;

    select coalesce(jsonb_agg(jsonb_build_object(
      'profile_id', subscription.profile_id,
      'endpoint', subscription.endpoint,
      'p256dh', subscription.p256dh,
      'auth', subscription.auth
    )), '[]'::jsonb)
    into v_subscriptions
    from public.push_subscriptions subscription
    join public.profiles profile on profile.id = subscription.profile_id
    where profile.status = 'active'
      and exists (
        select 1
        from public.match_sport_participants participant
        join public.season_players player on player.id = participant.season_player_id
        where participant.match_id = p_match_id
          and (participant.is_eligible or player.is_coach)
          and player.profile_id = profile.id
      );

    select coalesce(jsonb_agg(profile.id order by profile.id), '[]'::jsonb)
    into v_recipients
    from public.profiles profile
    where profile.status = 'active'
      and exists (
        select 1
        from public.match_sport_participants participant
        join public.season_players player on player.id = participant.season_player_id
        where participant.match_id = p_match_id
          and (participant.is_eligible or player.is_coach)
          and player.profile_id = profile.id
      );

  elsif p_kind = 'motm_open' then
    if not private.is_feature_enabled('sports_management') then
      return jsonb_build_object('payload', '{}'::jsonb, 'subscriptions', '[]'::jsonb);
    end if;
    if not exists (
      select 1
      from public.match_sport_motm_elections election
      where election.match_id = p_match_id
        and election.state = 'open'
        and now() >= election.opens_at
        and now() < election.closes_at
    ) then
      return jsonb_build_object('payload', '{}'::jsonb, 'subscriptions', '[]'::jsonb);
    end if;

    if v_match.opponent_name is not null
       and v_match.score_as_grinta is not null
       and v_match.score_adverse is not null then
      v_scoreline := case
        when v_match.location = 'domicile' then format(
          '%s %s - %s %s',
          v_match.club_name, v_match.score_as_grinta, v_match.score_adverse, v_match.opponent_name
        )
        else format(
          '%s %s - %s %s',
          v_match.opponent_name, v_match.score_adverse, v_match.score_as_grinta,
          v_match.club_name
        )
      end;
    end if;

    v_payload := jsonb_build_object(
      'title', 'Fin du match',
      'body', concat_ws(
        E'\n',
        v_scoreline,
        'Pense à voter pour l’Homme du match.'
      ),
      'url', 'matches/' || p_match_id || '/vote',
      'tag', 'sport-' || p_match_id || '-motm-open'
    );

    select coalesce(jsonb_agg(jsonb_build_object(
      'profile_id', subscription.profile_id,
      'endpoint', subscription.endpoint,
      'p256dh', subscription.p256dh,
      'auth', subscription.auth
    )), '[]'::jsonb)
    into v_subscriptions
    from public.push_subscriptions subscription
    join public.profiles profile on profile.id = subscription.profile_id
    where profile.status = 'active'
      and profile.notify_motm_vote
      and private.match_motm_voter_participant(p_match_id, profile.id) is not null;

    select coalesce(jsonb_agg(profile.id order by profile.id), '[]'::jsonb)
    into v_recipients
    from public.profiles profile
    where profile.status = 'active'
      and profile.notify_motm_vote
      and private.match_motm_voter_participant(p_match_id, profile.id) is not null;

  else
    raise exception 'Unknown notification kind: %', p_kind using errcode = '22023';
  end if;

  return jsonb_build_object(
    'payload', v_payload,
    'subscriptions', coalesce(v_subscriptions, '[]'::jsonb),
    'recipient_profile_ids', coalesce(v_recipients, '[]'::jsonb)
  );
end;
$$;

CREATE OR REPLACE FUNCTION "public"."send_test_push_kind"("p_kind" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_token text;
  v_actor uuid := (select private.uid());
  v_subscriptions integer;
  v_recent_attempts integer;
  v_title text;
  v_body text;
  v_kind text := btrim(coalesce(p_kind, ''));
  v_badge_payload jsonb;
  -- Les exemples liés à un match n'ont pas de vrai match : ils ouvrent
  -- l'accueil. Les autres ouvrent le même écran que la vraie notification.
  v_url text := '.';
begin
  if v_actor is null or not private.is_active_profile() then
    raise exception 'Active profile required' using errcode = '42501';
  end if;

  if v_kind = 'admin_availability_change'
     and not public.is_admin() then
    raise exception 'Active administrator role required' using errcode = '42501';
  end if;

  case v_kind
    when 'test' then
      v_title := 'Notification de test';
      v_body := 'Si tu vois ceci, les notifications fonctionnent 🎉';
    when 'availability_open' then
      v_title := 'Disponibilité';
      v_body := 'Es-tu disponible pour le match du 12/09 contre FC Exemple à 20h30 ?';
    when 'availability_manual' then
      v_title := 'Tu n''as pas répondu 👀';
      v_body := 'Pense à indiquer si tu es disponible pour le match contre FC Exemple !';
    when 'convocation_promoted' then
      v_title := 'Tu es convoqué';
      v_body := 'Tu es convoqué pour le match du 12/09 contre FC Exemple.';
    when 'convocation_demoted' then
      v_title := 'Tu passes en liste d''attente';
      v_body := 'Tu passes en liste d''attente pour le match du 12/09 contre FC Exemple.';
    when 'composition_published' then
      v_title := 'La composition est en ligne';
      v_body := 'La composition du match du 12/09 contre FC Exemple est en ligne.';
    when 'prediction_j5' then
      v_title := 'Pronostic';
      v_body := 'Pense à pronostiquer pour le match du 12/09 contre FC Exemple.';
    when 'match_cancelled' then
      v_title := 'Match annulé';
      v_body := 'Le match du 12/09 contre FC Exemple à 20h30 est annulé.';
    when 'match_rescheduled_date' then
      v_title := 'Match reporté';
      v_body := 'Le match contre FC Exemple est reporté au 12/09 à 20h30. Es-tu disponible ?';
    when 'match_rescheduled_time' then
      v_title := 'Horaire du match modifié';
      v_body := 'Le match du 12/09 contre FC Exemple aura finalement lieu à 20h30.';
    when 'motm_open' then
      v_title := 'Fin du match';
      v_body := format(
        E'%s 2 - 1 FC Exemple\nPense à voter pour l’Homme du match.',
        coalesce(
          (
            select nullif(btrim(club.name), '')
            from public.clubs club
            where club.id = private.current_club_id()
          ),
          'Notre club'
        )
      );
    when 'motm_result_general' then
      v_title := 'Homme du match';
      v_body := 'Joueur Test a été élu Homme du match !';
    when 'motm_result_winner' then
      v_title := 'Homme du match';
      v_body := 'Bravo, tu as été élu Homme du match !';
    when 'admin_pending_signup' then
      v_title := 'Nouveau compte en attente';
      v_body := 'Joueur Test attend ta validation.';
      v_url := 'admin/administration';
    when 'admin_availability_change' then
      v_title := 'Changement de disponibilité';
      v_body := 'À 20h30, Joueur Test est passé de présent à absent.';
    when 'badge_unlocked' then
      v_badge_payload := private.badge_unlock_push_message(array['Buteur']);
      v_title := v_badge_payload ->> 'title';
      v_body := v_badge_payload ->> 'message';
      v_url := 'armoire';
    when 'badges_unlocked' then
      v_badge_payload := private.badge_unlock_push_message(
        array['Buteur', 'Passeur']
      );
      v_title := v_badge_payload ->> 'title';
      v_body := v_badge_payload ->> 'message';
      v_url := 'armoire';
    else
      raise exception 'Unknown test notification kind' using errcode = '22023';
  end case;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('send_test_push:' || v_actor::text, 0)
  );

  delete from private.test_push_attempts attempt
  where attempt.profile_id = v_actor
    and attempt.attempted_at < now() - interval '1 day';

  select count(*)::integer
  into v_recent_attempts
  from private.test_push_attempts attempt
  where attempt.profile_id = v_actor
    and attempt.attempted_at >= now() - interval '10 minutes';

  if v_recent_attempts >= 3 then
    return jsonb_build_object('sent', false, 'reason', 'rate_limited');
  end if;

  select count(*)
  into v_subscriptions
  from public.push_subscriptions subscription
  where subscription.profile_id = v_actor;

  if v_subscriptions = 0 then
    return jsonb_build_object('sent', false, 'reason', 'no_subscription');
  end if;

  if coalesce(
       (private.get_notifications_paused()
          #>> '{notifications_paused,enabled}')::boolean,
       false
     ) then
    return jsonb_build_object('sent', false, 'reason', 'notifications_paused');
  end if;

  select secret.decrypted_secret into v_token
  from private.vault_secrets() secret
  where secret.name = 'push_internal_token';

  if v_token is null then
    return jsonb_build_object('sent', false, 'reason', 'not_configured');
  end if;

  insert into private.test_push_attempts (profile_id)
  values (v_actor);

  perform private.http_post(
    url := private.edge_function_url('send-push'),
    body := jsonb_build_object(
      'kind', 'custom',
      'profile_ids', jsonb_build_array(v_actor),
      'title', v_title,
      'message', v_body,
      'url', v_url,
      -- Un essai n'est pas un message du club : jamais dans l'historique.
      'record_history', false
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-token', v_token
    ),
    timeout_milliseconds := 10000
  );

  return jsonb_build_object(
    'sent', true,
    'subscriptions', v_subscriptions,
    'kind', v_kind
  );
end;
$$;
