-- Liste d'attente : trois modes au choix du club.
--
-- Jusqu'ici, une seule règle existait (celle du club d'origine) : quand trop
-- de joueurs sont disponibles, ceux qui étaient le moins venus la saison
-- précédente passent en attente les premiers, puis chacun son tour.
-- L'administrateur choisit maintenant entre :
--   0. Par présence l'an dernier : la règle d'origine, inchangée (défaut) ;
--   1. Ordre d'arrivée : premier à se dire disponible, premier convoqué ;
--   2. Par choix : tous les disponibles sont convoqués, l'administrateur met
--      lui-même en attente ceux qui sont en trop.
-- Le réglage rejoint les autres règles du club (même table, mêmes droits).

-- ---------------------------------------------------------------------------
-- 1. Nouvelle règle au catalogue
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
    ('motm_window_hours', 'Durée du vote de l’homme du match',
     'Combien d’heures après le coup d’envoi le vote reste ouvert.',
     'h', 'Après le match', 24, 1, 168, 50),
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
     'h', 'Liste d’attente', 12, 0, 23, 80)
  ) as catalogue(key, label, description, unit, group_label,
                 default_value, min_value, max_value, sort_order);
$$;

-- ---------------------------------------------------------------------------
-- 2. Rang affiché d'un joueur dans la liste d'attente d'un match
-- ---------------------------------------------------------------------------
-- Même convention que le classement de saison : plus le nombre est grand,
-- plus le joueur est prioritaire (le n° 1 est le premier à attendre).
-- En ordre d'arrivée, le rang dépend du moment où chacun s'est dit
-- disponible pour CE match ; sinon c'est le rang de saison, inchangé.
create function private.match_waitlist_position(
  p_match_id uuid,
  p_season_player_id uuid,
  p_season_position integer
) returns integer
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_rank integer;
begin
  if p_season_player_id is null
     or private.club_rule('waitlist_mode') <> 1 then
    return p_season_position;
  end if;

  select ranked.rank into v_rank
  from (
    select p.season_player_id, row_number() over (
      order by p.availability_updated_at desc nulls first, p.id desc
    )::integer as rank
    from public.match_sport_participants p
    join public.season_players sp on sp.id = p.season_player_id
    where p.match_id = p_match_id
      and p.is_eligible
      and p.availability_status = 'available'
      and not sp.is_coach
  ) ranked
  where ranked.season_player_id = p_season_player_id;

  return v_rank;
end;
$$;

alter function private.match_waitlist_position(uuid, uuid, integer) owner to club_scope;
revoke all on function private.match_waitlist_position(uuid, uuid, integer) from public, anon, authenticated;
grant execute on function private.match_waitlist_position(uuid, uuid, integer) to club_scope, service_role;

-- ---------------------------------------------------------------------------
-- 3. Le calcul des convocations suit le mode choisi
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "private"."recompute_match_convocations_internal"("p_match_id" "uuid", "p_reset_overrides" boolean DEFAULT false) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_actor uuid := (select private.uid());
  v_season_id uuid;
  v_limit integer;
  v_match_type text;
  v_kickoff timestamptz;
  v_status text;
  v_available integer;
  v_convoked integer;
  v_waiting integer;
  v_auto_slots integer;
  -- 0 : par présence l'an dernier (rotation d'origine) ; 1 : ordre
  -- d'arrivée ; 2 : par choix de l'administrateur.
  v_mode integer := private.club_rule('waitlist_mode');
begin
  perform private.require_sports_management_enabled();
  select m.season_id, w.squad_size_limit, m.match_type, m.kickoff_at, m.status
    into v_season_id, v_limit, v_match_type, v_kickoff, v_status
  from public.matches m
  join public.match_sport_workflows w on w.match_id = m.id
  where m.id = p_match_id for update of w;
  if not found then
    raise exception 'Sport workflow not found' using errcode = 'P0002';
  end if;

  -- L'effectif est déjà verrouillé à T-15 : ne rien réécrire pour ce match.
  if v_status = 'a_venir'
     and v_kickoff is not null
     and now() < v_kickoff - interval '15 minutes' then
    -- Une liste toute neuve est triée selon les trois critères ; ensuite,
    -- pas de retri ici : l'ordre choisi par l'administrateur est conservé.
    -- La liste n'est retriée que lorsque des +1 changent (coup d'envoi,
    -- annulation) ou lorsque l'administrateur clique sur « Recalculer ».
    perform private.ensure_sport_waitlist(v_season_id, v_actor);

    -- Un choix manuel de l'admin est conservé (comme avant la refonte, il
    -- peut pré-placer un joueur absent ou sans réponse). Il disparaît sur
    -- demande explicite, pour un joueur inéligible, ou quand un joueur
    -- présent se désiste (voir clear_manual_override_on_availability).
    update public.match_sport_participants p
       set convocation_manual_override = false,
           updated_at = now()
     where p.match_id = p_match_id
       and p.season_player_id is not null
       and p.convocation_manual_override
       and (
         p_reset_overrides
         or not p.is_eligible
         or p.convocation_status not in ('convoked', 'not_convoked')
       );

    select greatest(0, v_limit - count(*)::integer) into v_auto_slots
    from public.match_sport_participants p
    join public.season_players sp on sp.id = p.season_player_id
    where p.match_id = p_match_id
      and p.convocation_manual_override
      and p.convocation_status = 'convoked'
      and not sp.is_coach;

    -- Match « entre nous » : inchangé, tous les présents sont convoqués.
    -- Mode « par choix » : tous les présents sont convoqués et
    -- l'administrateur place lui-même en attente ceux qui sont en trop.
    if v_match_type = 'entre_nous' or v_mode = 2 then
      v_auto_slots := 2147483647;
    end if;

    -- Un seul passage fixe l'état de TOUS les membres du match :
    -- le rang ne concerne que les joueurs présents, éligibles et non forcés.
    with ranked as (
      select p.id, row_number() over (
        order by
          -- Ordre d'arrivée : le premier à s'être dit présent passe d'abord.
          case when v_mode = 1 then p.availability_updated_at end asc nulls last,
          e.position desc, p.id
      ) as priority
      from public.match_sport_participants p
      join public.sport_waitlist_entries e
        on e.season_player_id = p.season_player_id
       and e.season_id = v_season_id
      where p.match_id = p_match_id
        and p.is_eligible
        and p.availability_status = 'available'
        and not p.convocation_manual_override
    ), decision as (
      select p.id,
        private.match_waitlist_position(p_match_id, p.season_player_id, e.position) as position,
        sp.is_coach, r.priority,
        p.convocation_manual_override and not sp.is_coach as manual,
        case
          when sp.is_coach and p.availability_status = 'available'
            then 'convoked'::public.sport_convocation_status
          when sp.is_coach
            then 'not_applicable'::public.sport_convocation_status
          when p.convocation_manual_override
            then p.convocation_status
          when r.priority <= v_auto_slots
            then 'convoked'::public.sport_convocation_status
          when r.priority > v_auto_slots
            then 'not_convoked'::public.sport_convocation_status
          else 'not_applicable'::public.sport_convocation_status
        end as status
      from public.match_sport_participants p
      join public.season_players sp on sp.id = p.season_player_id
      left join public.sport_waitlist_entries e
        on e.season_player_id = p.season_player_id
       and e.season_id = v_season_id
      left join ranked r on r.id = p.id
      where p.match_id = p_match_id
    )
    update public.match_sport_participants p
       set convocation_status = d.status,
           convocation_manual_override = d.manual,
           -- Compatibilité avec le Live : un joueur qui figurait en attente
           -- dans la dernière composition publiée rejoint le banc s'il est
           -- ensuite convoqué. Cette trace ne modifie jamais sa priorité.
           promoted_after_withdrawal_at = case
             when d.status = 'convoked'
              and exists (
                select 1
                from public.match_composition_publications pub
                where pub.match_id = p_match_id
                  and pub.version = (
                    select max(latest.version)
                    from public.match_composition_publications latest
                    where latest.match_id = p_match_id
                  )
                  and (pub.snapshot -> 'entries') @> jsonb_build_array(
                    jsonb_build_object(
                      'participant_id', p.id::text,
                      'convocation_status', 'not_convoked'
                    )
                  )
              ) then coalesce(p.promoted_after_withdrawal_at, now())
             else null
           end,
           promoted_from_participant_id = null,
           waitlist_position_snapshot =
             case when d.is_coach then null else d.position end,
           waitlist_recommended_not_convoked =
             not d.manual and coalesce(d.priority > v_auto_slots, false),
           -- Un tour d'attente ne compte que pour un joueur présent.
           waitlist_turn_should_consume = d.status = 'not_convoked'
             and p.availability_status = 'available',
           waitlist_turn_state = case
             when d.is_coach then 'not_applicable'::public.sport_waitlist_turn_state
             when p.waitlist_turn_state = 'consumed'
               then 'consumed'::public.sport_waitlist_turn_state
             when d.status = 'not_convoked'
              and p.availability_status = 'available'
               then 'pending'::public.sport_waitlist_turn_state
             when d.status = 'convoked'
               then 'waived'::public.sport_waitlist_turn_state
             else 'not_applicable'::public.sport_waitlist_turn_state
           end,
           waitlist_turn_updated_at = now(),
           updated_at = now()
      from decision d
     where p.id = d.id;

    update public.match_sport_workflows
       set convocation_generated_at = now(),
           updated_by = coalesce(v_actor, updated_by),
           updated_at = now()
    where match_id = p_match_id;
  end if;

  select count(*)::integer,
         count(*) filter (where p.convocation_status = 'convoked')::integer,
         count(*) filter (where p.convocation_status = 'not_convoked')::integer
    into v_available, v_convoked, v_waiting
  from public.match_sport_participants p
  join public.season_players sp on sp.id = p.season_player_id
  where p.match_id = p_match_id
    and p.is_eligible
    and p.availability_status = 'available'
    and not sp.is_coach;

  return jsonb_build_object(
    'match_id', p_match_id,
    'squad_size_limit', v_limit,
    'available_count', v_available,
    'convoked_count', v_convoked,
    'not_convoked_count', v_waiting,
    'over_limit_count', greatest(0, v_convoked - v_limit)
  );
end;
$$;


-- ---------------------------------------------------------------------------
-- 4. Les écrans montrent le rang qui correspond au mode
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "private"."get_match_availability_board"("p_match_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_result jsonb;
begin
  perform private.require_sports_management_enabled();
  if not private.is_active_profile() then
    raise exception 'Active profile required' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'match_id', match.id,
    'kickoff_at', match.kickoff_at,
    'availability_state', case
      when now() >= match.kickoff_at then 'closed'
      when now() >= workflow.availability_opens_at
        and workflow.availability_state = 'pending' then 'open'
      else workflow.availability_state::text
    end,
    'availability_opens_at', workflow.availability_opens_at,
    'squad_size_limit', workflow.squad_size_limit,
    'convocation_state', workflow.convocation_state,
    'convocation_version', workflow.convocation_version,
    'composition_published', exists (
      select 1
      from public.match_composition_publications publication
      where publication.match_id = match.id
    ),
    'players', coalesce(jsonb_agg(
      jsonb_build_object(
        'participant_id', participant.id,
        'season_player_id', participant.season_player_id,
        'guest_player_id', participant.guest_player_id,
        'first_name', coalesce(player.first_name, guest.first_name),
        'last_name', coalesce(player.last_name, guest.last_name),
        'display_name', case
          when guest.id is not null then btrim(guest.first_name)
          else coalesce(nullif(btrim(profile.surnom), ''), nullif(btrim(profile.first_name), ''), btrim(player.first_name))
        end,
        'is_guest', guest.id is not null,
        'is_coach', coalesce(player.is_coach, false),
        'photo_url', coalesce(profile.photo_url, player.photo_url, guest.photo_url),
        'is_goalkeeper', coalesce(player.is_goalkeeper, guest.is_goalkeeper, false),
        'is_unavailable', private.is_player_unavailable_at(
          profile.id, match.kickoff_at
        ),
        'status', participant.availability_status,
        'convocation_status', participant.convocation_status,
        'waitlist_position', private.match_waitlist_position(match.id, participant.season_player_id, waitlist.position),
        'promoted_from_participant_id', participant.promoted_from_participant_id
      )
      order by
        case
          when participant.convocation_status = 'convoked'
            and (participant.availability_status = 'available' or guest.id is not null) then 0
          when participant.availability_status = 'available' then 1
          when participant.availability_status = 'absent' then 2
          when participant.availability_status = 'no_response' then 3
          else 4
        end,
        case
          when participant.convocation_status = 'convoked'
            and (participant.availability_status = 'available' or guest.id is not null)
            then private.match_waitlist_position(match.id, participant.season_player_id, waitlist.position)
        end desc nulls last,
        case
          when participant.convocation_status = 'not_convoked'
            and participant.availability_status = 'available'
            then private.match_waitlist_position(match.id, participant.season_player_id, waitlist.position)
        end asc nulls last,
        lower(coalesce(player.first_name, guest.first_name, '')),
        participant.id
    ) filter (where participant.id is not null), '[]'::jsonb)
  )
  into v_result
  from public.matches match
  join public.match_sport_workflows workflow on workflow.match_id = match.id
  left join public.match_sport_participants participant
    on participant.match_id = match.id
   and (
     participant.is_eligible
     or private.participant_is_coach(participant.season_player_id)
   )
  left join public.season_players player
    on player.id = participant.season_player_id
  left join public.profiles profile
    on profile.id = player.profile_id
  left join public.guest_players guest
    on guest.id = participant.guest_player_id
  left join public.sport_waitlist_entries waitlist
    on waitlist.season_player_id = participant.season_player_id
  where match.id = p_match_id
  group by match.id, workflow.match_id;

  if v_result is null then
    raise exception 'Sport workflow not found' using errcode = 'P0002';
  end if;
  return v_result;
end;
$$;


CREATE OR REPLACE FUNCTION "private"."get_match_convocations"("p_match_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_result jsonb;
begin
  perform private.require_sports_management_enabled();
  if not private.is_admin() then
    raise exception 'Active administrator role required' using errcode = '42501';
  end if;

  if exists (
    select 1
    from public.match_sport_workflows workflow
    where workflow.match_id = p_match_id
      and workflow.convocation_state = 'draft'
  ) then
    perform private.recompute_match_convocations_internal(p_match_id, false);
  end if;

  select jsonb_build_object(
    'match_id', match.id,
    'opponent_name', coalesce(opponent.name, 'Match entre nous'),
    'kickoff_at', match.kickoff_at,
    'season_id', match.season_id,
    'squad_size_limit', workflow.squad_size_limit,
    'published_squad_size_limit', workflow.squad_size_limit,
    'convocation_state', workflow.convocation_state,
    'convocation_version', workflow.convocation_version,
    'has_unpublished_changes', false,
    'late_withdrawal_cutoff_at', workflow.late_withdrawal_cutoff_at,
    'available_count', coalesce(players.available_count, 0),
    'convoked_count', coalesce(players.convoked_count, 0),
    'not_convoked_count', coalesce(players.not_convoked_count, 0),
    'players', coalesce(players.items, '[]'::jsonb)
  )
  into v_result
  from public.matches match
  left join public.opponents opponent on opponent.id = match.opponent_id
  join public.match_sport_workflows workflow on workflow.match_id = match.id
  left join lateral (
    select
      count(*) filter (
        where row.is_eligible
          and (
            (row.season_player_id is not null and row.availability_status = 'available')
            or row.guest_player_id is not null
          )
      )::integer as available_count,
      count(*) filter (
        where row.is_eligible
          and row.convocation_status = 'convoked'
          and (
            row.availability_status = 'available'
            or row.guest_player_id is not null
          )
      )::integer as convoked_count,
      count(*) filter (
        where row.is_eligible
          and row.season_player_id is not null
          and row.availability_status = 'available'
          and row.convocation_status = 'not_convoked'
      )::integer as not_convoked_count,
      jsonb_agg(
        jsonb_build_object(
          'participant_id', row.participant_id,
          'season_player_id', row.season_player_id,
          'guest_player_id', row.guest_player_id,
          'first_name', row.first_name,
          'last_name', row.last_name,
          'display_name', row.display_name,
          'photo_url', row.photo_url,
          'is_guest', row.guest_player_id is not null,
          'is_coach', row.is_coach,
          'is_goalkeeper', row.is_goalkeeper,
          'availability_status', row.availability_status,
          'availability_updated_at', row.availability_updated_at,
          'convocation_status', row.convocation_status,
          'published_convocation_status', row.convocation_status,
          'manual_override', row.convocation_manual_override,
          'waitlist_position', row.waitlist_position,
          'waitlist_position_snapshot', row.waitlist_position_snapshot,
          'current_season_waitlist_count', row.current_season_waitlist_count,
          'recommended_not_convoked', row.waitlist_recommended_not_convoked,
          'turn_should_consume', row.waitlist_turn_should_consume,
          'turn_state', row.waitlist_turn_state,
          'promoted_after_withdrawal_at', row.promoted_after_withdrawal_at
        )
        order by row.availability_order, row.waitlist_position,
          lower(row.first_name), lower(coalesce(row.last_name, ''))
      ) filter (
        where row.participant_id is not null
          and (row.is_eligible or row.is_coach)
      ) as items
    from (
      select
        participant.id as participant_id,
        participant.season_player_id,
        participant.guest_player_id,
        participant.is_eligible,
        coalesce(player.is_coach, false) as is_coach,
        coalesce(player.first_name, guest.first_name) as first_name,
        coalesce(player.last_name, guest.last_name) as last_name,
        case
          when guest.id is not null then btrim(guest.first_name) || ' (Invité)'
          else coalesce(
            nullif(btrim(profile.surnom), ''),
            nullif(btrim(profile.first_name), ''),
            btrim(player.first_name)
          )
        end as display_name,
        coalesce(profile.photo_url, player.photo_url, guest.photo_url) as photo_url,
        coalesce(player.is_goalkeeper, guest.is_goalkeeper, false) as is_goalkeeper,
        participant.availability_status,
        participant.availability_updated_at,
        participant.convocation_status,
        participant.convocation_manual_override,
        private.match_waitlist_position(match.id, participant.season_player_id, waitlist.position) as waitlist_position,
        participant.waitlist_position_snapshot,
        coalesce(waitlist.manual_waitlist_count, 0) as current_season_waitlist_count,
        participant.waitlist_recommended_not_convoked,
        participant.waitlist_turn_should_consume,
        participant.waitlist_turn_state,
        participant.promoted_after_withdrawal_at,
        case
          when participant.guest_player_id is not null then 0
          when participant.availability_status = 'available' then 0
          when participant.availability_status = 'no_response' then 1
          when participant.availability_status = 'absent' then 2
          else 3
        end as availability_order
      from public.match_sport_participants participant
      left join public.season_players player
        on player.id = participant.season_player_id
      left join public.profiles profile on profile.id = player.profile_id
      left join public.guest_players guest
        on guest.id = participant.guest_player_id
      left join public.sport_waitlist_entries waitlist
        on waitlist.season_player_id = participant.season_player_id
       and waitlist.season_id = match.season_id
      where participant.match_id = match.id
    ) row
  ) players on true
  where match.id = p_match_id;

  if v_result is null then
    raise exception 'Sport workflow not found' using errcode = 'P0002';
  end if;
  return v_result;
end;
$$;

