-- Chaque fonctionnalité découpée en sous-réglages, club par club.
--
-- Jusqu'ici, plusieurs comportements restaient identiques pour tous les clubs :
-- quelles notifications partent, comment les cotes des pronostics sont
-- calculées, qui pilote le direct, la durée d'un match, le vote pour soi-même
-- à l'Étoile du match, la musique du bilan de saison. Ils deviennent des
-- règles du club, rangées dans les Réglages sous la fonctionnalité concernée.
--
-- Sans réglage, chaque règle vaut exactement le comportement d'avant : un
-- club qui ne touche à rien ne voit aucune différence.
--
-- Catalogue repris de 20261114002000_bareme_pronostics_club.sql ; les
-- règles existantes sont inchangées, les nouvelles sont ajoutées à la suite.

-- ---------------------------------------------------------------------------
-- 1. Catalogue des règles
-- ---------------------------------------------------------------------------
create or replace function private.club_rule_catalogue()
returns table (
  key text,
  label text,
  description text,
  unit text,
  group_label text,
  default_value integer,
  min_value integer,
  max_value integer,
  sort_order integer
)
language sql immutable
set search_path to ''
as $$
  select * from (values
    ('features_open_days', 'Ouverture avant le match',
     'Combien de jours avant le coup d’envoi s’ouvrent les disponibilités, la composition et les pronostics.',
     'jours', 'Avant le match', 6, 1, 21, 10),
    ('features_open_hour', 'Heure d’ouverture',
     'Heure (en France) à laquelle ils s’ouvrent ce jour-là.',
     'h', 'Avant le match', 12, 0, 23, 20),
    ('prediction_close_minutes', 'Fermeture des pronostics',
     'Combien de minutes avant le coup d’envoi les pronostics se ferment (et le mode live s’ouvre).',
     'min', 'Pronostics', 15, 0, 240, 30),
    ('prediction_reminder_hour', 'Heure du rappel de pronostic',
     'Heure (en France) du rappel envoyé le jour du match à ceux qui n’ont pas pronostiqué.',
     'h', 'Pronostics', 16, 0, 23, 40),
    ('prediction_reminder_lead_minutes', 'Rappel avant un match tôt',
     'Si le match commence avant l’heure du rappel, le rappel part ce nombre de minutes avant la fermeture des pronostics.',
     'min', 'Pronostics', 60, 15, 600, 45),
    ('motm_window_hours', 'Durée du vote de l’Étoile du match',
     'Combien d’heures après le coup d’envoi le vote reste ouvert.',
     'h', 'Après le match', 24, 6, 168, 50),
    ('correction_window_hours', 'Délai de correction du résultat',
     'Combien d’heures après sa validation le résultat peut encore être corrigé.',
     'h', 'Après le match', 24, 1, 168, 60),
    ('waitlist_mode', 'Liste d’attente : qui passe en premier',
     'Quand il y a plus de disponibles que de places : par présence l’an dernier, par ordre d’arrivée, ou par choix de l’administrateur.',
     'mode', 'Liste d’attente', 0, 0, 2, 65),
    ('waitlist_cutoff_days', 'Liste d’attente : jour limite',
     'Combien de jours avant le match la liste d’attente cesse de créditer des places (0 = le jour même).',
     'jours', 'Liste d’attente', 1, 0, 7, 70),
    ('waitlist_cutoff_hour', 'Liste d’attente : heure limite',
     'Heure (en France) de ce jour limite.',
     'h', 'Liste d’attente', 12, 0, 23, 80),
    ('prediction_points_exact', 'Barème : score exact',
     'La cote du bon résultat est multipliée par ce nombre quand le score exact est trouvé. S’applique aussi aux matchs déjà joués.',
     '×', 'Barème des pronostics', 20, 0, 50, 90),
    ('prediction_points_goal_difference', 'Barème : bon écart de buts',
     'Bon vainqueur (ou match nul) avec le bon écart de buts, sans le score exact. S’applique aussi aux matchs déjà joués.',
     '×', 'Barème des pronostics', 15, 0, 50, 91),
    ('prediction_points_one_score', 'Barème : un des deux scores',
     'Bon vainqueur et le bon nombre de buts d’une des deux équipes. S’applique aussi aux matchs déjà joués.',
     '×', 'Barème des pronostics', 15, 0, 50, 92),
    ('prediction_points_winner', 'Barème : bon vainqueur seulement',
     'Bon vainqueur, sans autre précision juste. S’applique aussi aux matchs déjà joués.',
     '×', 'Barème des pronostics', 10, 0, 50, 93),
    ('notify_prediction_reminder', 'Notification : rappel de pronostic',
     'Rappeler le jour du match à ceux qui n’ont pas encore pronostiqué.',
     'bool', 'Notifications', 1, 0, 1, 39),
    ('notify_availability_open', 'Notification : disponibilités ouvertes',
     'Prévenir les joueurs quand ils peuvent dire s’ils sont disponibles pour un match.',
     'bool', 'Notifications', 1, 0, 1, 21),
    ('notify_availability_reminders', 'Notification : relances des disponibilités',
     'Relancer à J-3 et à J-1 ceux qui n’ont pas encore répondu.',
     'bool', 'Notifications', 1, 0, 1, 22),
    ('motm_self_vote', 'Étoile du match : voter pour soi',
     'Autoriser un joueur à voter pour lui-même. Interdit par défaut.',
     'bool', 'Étoile du match', 0, 0, 1, 51),
    ('notify_motm_open', 'Notification : vote de l’Étoile du match',
     'Prévenir les votants quand le vote s’ouvre.',
     'bool', 'Notifications', 1, 0, 1, 52),
    ('notify_motm_result', 'Notification : résultat de l’Étoile du match',
     'Annoncer le résultat du vote à l’équipe et au gagnant.',
     'bool', 'Notifications', 1, 0, 1, 53),
    ('notify_convocation', 'Notification : convocation et liste d’attente',
     'Prévenir un joueur quand il passe de la liste d’attente aux convoqués, ou l’inverse.',
     'bool', 'Notifications', 1, 0, 1, 66),
    ('notify_composition', 'Notification : composition publiée',
     'Prévenir les convoqués quand la composition est publiée.',
     'bool', 'Notifications', 1, 0, 1, 67),
    ('odds_mode', 'Cotes des pronostics',
     'Calculées automatiquement d’après les résultats du club, ou sans cotes : un pronostic rapporte alors seulement le multiplicateur du barème (score exact = 2 points par défaut). S’applique aux prochains matchs.',
     'mode', 'Cotes', 0, 0, 1, 94),
    ('odds_draw_factor', 'Cotes : poids du match nul',
     'Plus ce nombre est grand, plus la cote du match nul est haute (il rapporte plus de points). S’applique aux prochains matchs.',
     '×', 'Cotes', 15, 10, 30, 95),
    ('odds_form_memory_days', 'Cotes : mémoire de la forme',
     'Au bout de combien de jours un résultat compte deux fois moins dans la forme du moment de l’équipe. S’applique aux prochains matchs.',
     'jours', 'Cotes', 180, 30, 720, 96),
    ('odds_h2h_memory_days', 'Cotes : mémoire des confrontations',
     'Au bout de combien de jours un match contre le même adversaire compte deux fois moins. S’applique aux prochains matchs.',
     'jours', 'Cotes', 900, 90, 3600, 97),
    ('match_duration_minutes', 'Durée d’un match',
     'Temps de jeu prévu (90 min pour deux mi-temps de 45 min). Proposé pour chaque nouveau match et à l’ouverture du direct, modifiable à chaque match.',
     'min', 'Matchs', 90, 20, 120, 120),
    ('live_pilot_mode', 'Direct : qui le pilote',
     'Le coach de la saison seulement, ou aussi les administrateurs. Utile si le club n’a pas désigné de coach.',
     'mode', 'Mode live', 0, 0, 1, 121),
    ('notify_live_kickoff', 'Notification : coup d’envoi et fin du match',
     'Pendant le direct, prévenir au coup d’envoi et au coup de sifflet final.',
     'bool', 'Notifications', 1, 0, 1, 122),
    ('notify_live_goals', 'Notification : buts en direct',
     'Pendant le direct, prévenir à chaque but marqué ou encaissé.',
     'bool', 'Notifications', 1, 0, 1, 123),
    ('notify_match_changes', 'Notification : match annulé ou déplacé',
     'Prévenir les membres quand un match est annulé ou change de date ou d’heure.',
     'bool', 'Notifications', 1, 0, 1, 124),
    ('notify_badges', 'Notification : badge débloqué',
     'Prévenir un joueur quand il gagne un badge.',
     'bool', 'Notifications', 1, 0, 1, 131),
    ('wrapped_music', 'Bilan de saison : musique',
     'Jouer la musique pendant le bilan de fin de saison. Chaque joueur peut toujours couper le son.',
     'bool', 'Bilan de saison', 1, 0, 1, 132),
    ('notify_admin_signups', 'Notification : nouvelle inscription',
     'Prévenir les administrateurs quand un nouveau compte attend leur validation.',
     'bool', 'Notifications', 1, 0, 1, 140)
  ) as catalogue(key, label, description, unit, group_label,
                 default_value, min_value, max_value, sort_order);
$$;

-- ---------------------------------------------------------------------------
-- 2. Notifications coupées par le club
-- ---------------------------------------------------------------------------
-- Chaque type d'envoi dépend d'une règle oui/non. La fonction d'envoi lit la
-- liste des types coupés pour le club et n'envoie rien pour ceux-là (ni
-- notification sur le téléphone, ni entrée dans la cloche). Les messages
-- écrits à la main par un administrateur et le test d'envoi ne sont jamais
-- coupés.
create function private.club_notification_rules()
returns table (kind text, rule_key text)
language sql immutable
set search_path to ''
as $$
  select * from (values
    ('availability_open', 'notify_availability_open'),
    ('availability_manual', 'notify_availability_open'),
    ('availability_j3', 'notify_availability_reminders'),
    ('availability_j1', 'notify_availability_reminders'),
    ('convocation_promoted', 'notify_convocation'),
    ('convocation_demoted', 'notify_convocation'),
    ('composition_published', 'notify_composition'),
    ('match_cancelled', 'notify_match_changes'),
    ('match_rescheduled_date', 'notify_match_changes'),
    ('match_rescheduled_time', 'notify_match_changes'),
    ('live_kickoff', 'notify_live_kickoff'),
    ('live_full_time', 'notify_live_kickoff'),
    ('live_goal_us', 'notify_live_goals'),
    ('live_goal_them', 'notify_live_goals'),
    ('prediction_j5', 'notify_prediction_reminder'),
    ('motm_open', 'notify_motm_open'),
    ('motm_result_general', 'notify_motm_result'),
    ('motm_result_winner', 'notify_motm_result'),
    ('badge_unlocked', 'notify_badges'),
    ('admin_pending_signup', 'notify_admin_signups')
  ) as mapping(kind, rule_key);
$$;

create function private.club_disabled_notification_kinds()
returns text[]
language sql stable security definer
set search_path to ''
as $$
  select coalesce(array_agg(mapping.kind order by mapping.kind), '{}'::text[])
  from private.club_notification_rules() mapping
  where private.club_rule(mapping.rule_key) = 0;
$$;

alter function private.club_notification_rules() owner to club_scope;
alter function private.club_disabled_notification_kinds() owner to club_scope;
revoke all on function private.club_notification_rules() from public, anon, authenticated;
revoke all on function private.club_disabled_notification_kinds() from public, anon, authenticated;
grant execute on function private.club_notification_rules() to service_role, club_scope;
grant execute on function private.club_disabled_notification_kinds() to service_role, club_scope;

-- Même configuration qu'avant, avec en plus les types coupés par le club
-- (le club vient de l'en-tête x-club-id de la fonction d'envoi).
create or replace function public.internal_push_config()
returns jsonb
language sql stable security definer
set search_path to ''
as $$
  select jsonb_build_object(
    'vapid_public', max(decrypted_secret) filter (where name = 'push_vapid_public'),
    'vapid_private', max(decrypted_secret) filter (where name = 'push_vapid_private'),
    'token', max(decrypted_secret) filter (where name = 'push_internal_token'),
    'notifications_paused', private.is_feature_enabled('notifications_paused'),
    'disabled_kinds', to_jsonb(private.club_disabled_notification_kinds())
  )
  from private.vault_secrets()
  where name in ('push_vapid_public', 'push_vapid_private', 'push_internal_token');
$$;

-- ---------------------------------------------------------------------------
-- 3. Calcul des cotes réglable
-- ---------------------------------------------------------------------------
-- Même calcul qu'avant (repris de 20261111000100_socle_structure.sql), avec
-- les trois constantes lues dans les règles du club, et un mode « sans
-- cotes ». Les cotes déjà enregistrées des matchs joués ne changent pas.
create or replace function public.calculate_match_odds_v5(p_opponent_id uuid, p_reference_date date)
returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_ref date := coalesce(p_reference_date, current_date);
  v_h_v numeric := 0;
  v_h_d numeric := 0;
  v_form_v numeric := 0;
  v_form_d numeric := 0;
  v_q_forme numeric;
  v_q numeric;
  v_cote_v_prov numeric;
  v_cote_d_prov numeric;
  v_cote_n_prov numeric;
  v_u_v numeric;
  v_u_n numeric;
  v_u_d numeric;
  v_s numeric;
  v_p_v numeric;
  v_p_n numeric;
  v_p_d numeric;
  -- Réglages du club (valeurs d'origine par défaut : 900 j, 180 j, × 1,5).
  v_h2h_days numeric := private.club_rule('odds_h2h_memory_days')::numeric;
  v_form_days numeric := private.club_rule('odds_form_memory_days')::numeric;
  v_draw_factor numeric := private.club_rule('odds_draw_factor')::numeric / 10;
begin
  if not exists (select 1 from public.opponents where id = p_opponent_id) then
    raise exception 'Adversaire introuvable';
  end if;

  -- Club sans cotes : chaque issue vaut 1, le barème seul fait les points.
  if private.club_rule('odds_mode') = 1 then
    return jsonb_build_object(
      'win', 1.00, 'draw', 1.00, 'loss', 1.00,
      'probability_win', round(1.0 / 3, 6),
      'probability_draw', round(1.0 / 3, 6),
      'probability_loss', round(1.0 / 3, 6),
      'model_version', 'club_without_odds'
    );
  end if;

  with all_results as (
    select m.id, m.opponent_id, m.match_date,
      m.score_as_grinta, m.score_adverse
    from public.matches m
    where m.status = 'termine'
      and m.score_as_grinta is not null
      and m.score_adverse is not null
    union all
    select h.id, h.opponent_id, h.match_date,
      h.score_as_grinta::integer, h.score_adverse::integer
    from public.historical_match_scores h
  ), h2h as (
    select
      case
        when r.score_as_grinta > r.score_adverse then 'V'
        when r.score_as_grinta = r.score_adverse then 'N'
        else 'D'
      end as result,
      row_number() over (
        order by r.match_date desc, r.id desc
      ) as rang,
      greatest(0, (v_ref - r.match_date))::numeric as age
    from all_results r
    where r.opponent_id = p_opponent_id
      and r.match_date < v_ref
  ), weighted as (
    select result,
      case
        when rang <= 5 then
          (array[1.0, 0.95, 0.90, 0.85, 0.80])[rang::int]
            * power(0.5::numeric, age / v_h2h_days)
        else
          0.35 * power(0.75::numeric, (rang - 6)::numeric)
            * power(0.5::numeric, age / v_h2h_days)
      end as poids
    from h2h
  )
  select
    coalesce(sum(poids) filter (where result = 'V'), 0),
    coalesce(sum(poids) filter (where result = 'D'), 0)
  into v_h_v, v_h_d
  from weighted;

  with all_results as (
    select m.id, m.match_date, m.score_as_grinta, m.score_adverse
    from public.matches m
    where m.status = 'termine'
      and m.score_as_grinta is not null
      and m.score_adverse is not null
    union all
    select h.id, h.match_date,
      h.score_as_grinta::integer, h.score_adverse::integer
    from public.historical_match_scores h
  ), form as (
    select
      case
        when r.score_as_grinta > r.score_adverse then 'V'
        when r.score_as_grinta = r.score_adverse then 'N'
        else 'D'
      end as result,
      power(
        0.5::numeric,
        greatest(0, (v_ref - r.match_date))::numeric / v_form_days
      ) as poids
    from all_results r
    where r.match_date < v_ref
  )
  select
    coalesce(sum(poids) filter (where result = 'V'), 0),
    coalesce(sum(poids) filter (where result = 'D'), 0)
  into v_form_v, v_form_d
  from form;

  if (v_form_v + v_form_d) = 0 then
    v_q_forme := 0.50;
  else
    v_q_forme := v_form_v / (v_form_v + v_form_d);
  end if;

  v_q := (1.0 * v_q_forme + v_h_v) / (1.0 + v_h_v + v_h_d);
  v_q := least(0.999999, greatest(0.000001, v_q));

  v_cote_v_prov := 1.0 / v_q;
  v_cote_d_prov := 1.0 / (1.0 - v_q);
  v_cote_n_prov := ((v_cote_v_prov + v_cote_d_prov) / 2.0) * v_draw_factor;

  v_u_v := 1.0 / v_cote_v_prov;
  v_u_n := 1.0 / v_cote_n_prov;
  v_u_d := 1.0 / v_cote_d_prov;
  v_s := v_u_v + v_u_n + v_u_d;
  v_p_v := v_u_v / v_s;
  v_p_n := v_u_n / v_s;
  v_p_d := v_u_d / v_s;

  return jsonb_build_object(
    'win', round(1.0 / v_p_v, 2),
    'draw', round(1.0 / v_p_n, 2),
    'loss', round(1.0 / v_p_d, 2),
    'probability_win', round(v_p_v, 6),
    'probability_draw', round(v_p_n, 6),
    'probability_loss', round(v_p_d, 6),
    'q_decisive', round(v_q, 6),
    'q_form', round(v_q_forme, 6),
    'h2h_win_weight', round(v_h_v, 6),
    'h2h_loss_weight', round(v_h_d, 6),
    'model_version', 'compact_history_v6'
  );
end;
$$;


-- Un changement de réglage des cotes recalcule aussitôt les matchs à venir
-- du club (la règle de cloisonnement limite le calcul au club courant).
create function private.recalculate_odds_after_rule_change()
returns trigger
language plpgsql security definer
set search_path to ''
as $$
declare
  v_key text := case when tg_op = 'DELETE' then old.key else new.key end;
begin
  if v_key like 'odds\_%' then
    perform public.recalculate_upcoming_match_odds_v4();
  end if;
  return null;
end;
$$;

alter function private.recalculate_odds_after_rule_change() owner to club_scope;
revoke all on function private.recalculate_odds_after_rule_change()
  from public, anon, authenticated, service_role;

create trigger trg_club_rules_recalculate_odds
after insert or update or delete on private.club_rules
for each row execute function private.recalculate_odds_after_rule_change();

-- ---------------------------------------------------------------------------
-- 4. Durée d'un match
-- ---------------------------------------------------------------------------
-- Les matchs étaient toujours créés avec 90 minutes. Un nouveau match prend
-- maintenant la durée réglée par le club ; une autre durée donnée
-- explicitement est respectée.
create function private.apply_club_match_duration()
returns trigger
language plpgsql security definer
set search_path to ''
as $$
begin
  if new.planned_duration_minutes is null or new.planned_duration_minutes = 90 then
    new.planned_duration_minutes := private.club_rule('match_duration_minutes');
  end if;
  return new;
end;
$$;

alter function private.apply_club_match_duration() owner to club_scope;
revoke all on function private.apply_club_match_duration()
  from public, anon, authenticated, service_role;

create trigger trg_matches_club_duration
before insert on public.matches
for each row execute function private.apply_club_match_duration();

-- ---------------------------------------------------------------------------
-- 5. Qui pilote le direct
-- ---------------------------------------------------------------------------
-- Règle d'origine : le coach actif de la saison seulement. Le club peut
-- ouvrir le pilotage à ses administrateurs (club sans coach désigné).
create or replace function private.is_match_live_pilot_coach(p_match_id uuid)
returns boolean
language sql stable security definer
set search_path to ''
as $$
  select private.is_active_profile()
    and (
      exists (
        select 1
        from public.season_players sp
        join public.matches m on m.season_id = sp.season_id
        where m.id = p_match_id
          and sp.profile_id = (select private.uid())
          and sp.is_coach = true
          and sp.is_active = true
      )
      or (
        private.club_rule('live_pilot_mode') = 1
        and private.is_admin()
        and exists (select 1 from public.matches m where m.id = p_match_id)
      )
    );
$$;

comment on function private.is_match_live_pilot_coach(uuid) is
  'Vrai si le profil courant peut piloter le Live : coach actif de la saison du match, ou administrateur si le club l’autorise (règle live_pilot_mode).';

-- ---------------------------------------------------------------------------
-- 6. Étoile du match : voter pour soi
-- ---------------------------------------------------------------------------
-- Repris de 20261111000100_socle_structure.sql ; seul le refus du vote pour
-- soi-même dépend maintenant de la règle motm_self_vote (refusé par défaut).
create or replace function private.cast_match_motm_vote(p_match_id uuid, p_candidate_participant_id uuid)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_actor uuid := (select private.uid());
  v_election public.match_sport_motm_elections%rowtype;
  v_voter_participant_id uuid;
  v_candidate_profile_id uuid;
  v_candidate_ok boolean;
  v_cast_at timestamptz := now();
begin
  perform private.require_sports_management_enabled();
  if not private.is_active_profile() then
    raise exception 'Active profile required' using errcode = '42501';
  end if;

  perform private.ensure_match_motm_election(p_match_id);
  perform private.transition_match_motm_election(p_match_id);

  select * into v_election
  from public.match_sport_motm_elections election
  where election.match_id = p_match_id
  for update;

  if not found then
    raise exception 'MOTM vote is unavailable' using errcode = 'P0002';
  end if;
  if v_election.state <> 'open'
     or v_election.opens_at is null
     or v_cast_at < v_election.opens_at
     or v_cast_at >= v_election.closes_at then
    raise exception 'MOTM vote is closed' using errcode = '22023';
  end if;

  v_voter_participant_id := private.match_motm_voter_participant(
    p_match_id, v_actor
  );

  if v_voter_participant_id is null then
    raise exception 'Only a registered player from the lineup can vote'
      using errcode = '42501';
  end if;

  select true, candidate_player.profile_id
  into v_candidate_ok, v_candidate_profile_id
  from private.match_motm_candidate_participants(p_match_id) candidate
  join public.match_sport_participants participant
    on participant.id = candidate.participant_id
  left join public.season_players candidate_player
    on candidate_player.id = participant.season_player_id
  where participant.id = p_candidate_participant_id;

  if not coalesce(v_candidate_ok, false) then
    raise exception 'Candidate must be part of the published lineup' using errcode = '22023';
  end if;
  if v_candidate_profile_id = v_actor
     and private.club_rule('motm_self_vote') = 0 then
    raise exception 'A player cannot vote for himself' using errcode = '22023';
  end if;

  begin
    insert into public.match_sport_motm_votes(
      match_id, voter_profile_id, candidate_participant_id,
      finalization_version, cast_at
    ) values (
      p_match_id, v_actor, p_candidate_participant_id,
      v_election.finalization_version, v_cast_at
    );
  exception
    when unique_violation then
      raise exception 'MOTM vote is immutable and has already been cast'
        using errcode = '23505';
  end;

  update public.match_sport_motm_elections
  set total_votes = total_votes + 1, updated_at = now()
  where match_id = p_match_id;

  return jsonb_build_object(
    'accepted', true,
    'cast_at', v_cast_at,
    'closes_at', v_election.closes_at
  );
end;
$$;
