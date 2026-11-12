-- Effectif figé au moment choisi par le club, pas à T-15 en dur.
--
-- La règle « Fermeture des pronostics » est réglable par club ; c'est aussi
-- l'instant où le mode live s'ouvre. Mais quatre fonctions figeaient encore
-- l'effectif et la liste d'attente à 15 minutes avant le coup d'envoi, en
-- dur. Un club qui réglait 60 minutes voyait le live s'ouvrir à T-60 alors
-- que l'effectif pouvait encore changer (et la liste d'attente se recalculer)
-- jusqu'à T-15, pendant le live. Un club qui réglait 0 minute voyait
-- l'effectif figé à T-15 alors que la composition restait modifiable.
--
-- Les quatre fonctions utilisent maintenant la même frontière que le live et
-- les pronostics (private.match_prediction_closes_at, ou la même règle lue
-- directement pour admin_remove_match_guest, qui tourne avec les droits du
-- compte connecté). Corps repris à
-- l'identique de 20261111000100_socle_structure.sql ; seule cette frontière
-- change. Avec le réglage par défaut (15 minutes), rien ne change.

CREATE OR REPLACE FUNCTION "private"."publish_match_effectif"("p_match_id" "uuid", "p_squad_size_limit" integer, "p_decisions" "jsonb", "p_reason" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_actor uuid := (select private.uid());
  v_reason text := nullif(btrim(p_reason), '');
  v_kickoff_at timestamptz;
  v_match_status text;
  v_payload_count integer;
  v_input_count integer;
  v_missing_count integer;
  v_invalid_count integer;
  v_result jsonb;
begin
  perform private.require_sports_management_enabled();
  if not private.is_admin() then
    raise exception 'Active administrator role required' using errcode = '42501';
  end if;
  if p_squad_size_limit is null
     or p_squad_size_limit < 1
     or p_squad_size_limit > 30 then
    raise exception 'Squad size limit must be between 1 and 30'
      using errcode = '22023';
  end if;
  if p_decisions is null or jsonb_typeof(p_decisions) <> 'array' then
    raise exception 'Effectif decisions must be a JSON array'
      using errcode = '22023';
  end if;
  if v_reason is not null and char_length(v_reason) > 500 then
    raise exception 'Reason cannot exceed 500 characters' using errcode = '22023';
  end if;

  select match.kickoff_at, match.status
  into v_kickoff_at, v_match_status
  from public.matches match
  join public.match_sport_workflows workflow on workflow.match_id = match.id
  where match.id = p_match_id
  for update of match, workflow;

  if not found then
    raise exception 'Sport workflow not found' using errcode = 'P0002';
  end if;
  -- L'effectif est verrouillé à l'ouverture du Live (T-15).
  if v_match_status <> 'a_venir'
     or now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'Effectif already locked' using errcode = '22023';
  end if;

  create temporary table if not exists pg_temp.effectif_input (
    season_player_id uuid primary key,
    status public.sport_convocation_status not null,
    changed boolean
  ) on commit drop;
  truncate table pg_temp.effectif_input;

  begin
    insert into pg_temp.effectif_input(season_player_id, status, changed)
    select
      (item ->> 'season_player_id')::uuid,
      (item ->> 'status')::public.sport_convocation_status,
      case jsonb_typeof(item -> 'changed')
        when 'boolean' then (item ->> 'changed')::boolean
        else null
      end
    from jsonb_array_elements(p_decisions) item
    where item ->> 'status' in ('convoked', 'not_convoked');
  exception
    when unique_violation then
      raise exception 'A player can appear only once in effectif decisions'
        using errcode = '22023';
    when invalid_text_representation or not_null_violation then
      raise exception 'Invalid effectif decision' using errcode = '22023';
  end;

  v_payload_count := jsonb_array_length(p_decisions);
  select count(*)::integer into v_input_count
  from pg_temp.effectif_input;

  if v_input_count <> v_payload_count then
    raise exception 'Invalid effectif decision' using errcode = '22023';
  end if;

  select count(*)::integer into v_missing_count
  from public.match_sport_participants participant
  left join pg_temp.effectif_input input
    on input.season_player_id = participant.season_player_id
  where participant.match_id = p_match_id
    and participant.is_eligible
    and participant.season_player_id is not null
    and participant.availability_status = 'available'
    and input.season_player_id is null;

  if v_missing_count > 0 then
    raise exception 'Every available permanent player needs one effectif decision'
      using errcode = '22023';
  end if;

  select count(*)::integer into v_invalid_count
  from pg_temp.effectif_input input
  left join public.match_sport_participants participant
    on participant.match_id = p_match_id
   and participant.season_player_id = input.season_player_id
   and participant.is_eligible
   and participant.availability_status in (
     'available', 'absent', 'no_response'
   )
  where participant.id is null;

  if v_invalid_count > 0 then
    raise exception 'Effectif contains an ineligible player'
      using errcode = '22023';
  end if;

  update public.match_sport_workflows
  set squad_size_limit = p_squad_size_limit,
      updated_by = v_actor,
      updated_at = now()
  where match_id = p_match_id;

  -- Seules les décisions de l'admin sont figées. Les autres restent
  -- automatiques : le recalcul qui suit les place selon la liste d'attente.
  update public.match_sport_participants participant
  set convocation_status = input.status,
      convocation_manual_override = true,
      waitlist_recommended_not_convoked = false,
      waitlist_turn_should_consume =
        input.status = 'not_convoked'
        and participant.availability_status = 'available',
      waitlist_turn_state = case
        when participant.waitlist_turn_state = 'consumed'
          then 'consumed'::public.sport_waitlist_turn_state
        when input.status = 'not_convoked'
             and participant.availability_status = 'available'
          then 'pending'::public.sport_waitlist_turn_state
        when input.status = 'convoked'
          then 'waived'::public.sport_waitlist_turn_state
        else 'not_applicable'::public.sport_waitlist_turn_state
      end,
      waitlist_turn_updated_at = now(),
      updated_at = now()
  from pg_temp.effectif_input input
  where participant.match_id = p_match_id
    and participant.season_player_id = input.season_player_id
    and participant.is_eligible
    and (
      participant.convocation_manual_override
      or coalesce(
        input.changed,
        participant.convocation_status is distinct from input.status
      )
    );

  update public.match_sport_participants participant
  set convocation_status = 'not_applicable',
      convocation_manual_override = false,
      waitlist_recommended_not_convoked = false,
      waitlist_turn_should_consume = false,
      waitlist_turn_state = case
        when participant.waitlist_turn_state = 'consumed'
          then 'consumed'::public.sport_waitlist_turn_state
        else 'not_applicable'::public.sport_waitlist_turn_state
      end,
      waitlist_turn_updated_at = now(),
      updated_at = now()
  where participant.match_id = p_match_id
    and participant.is_eligible
    and participant.season_player_id is not null
    and participant.availability_status <> 'available'
    and not exists (
      select 1
      from pg_temp.effectif_input input
      where input.season_player_id = participant.season_player_id
    );

  update public.match_sport_participants participant
  set convocation_status = 'convoked',
      convocation_manual_override = true,
      waitlist_recommended_not_convoked = false,
      waitlist_turn_should_consume = false,
      waitlist_turn_state = 'waived',
      waitlist_turn_updated_at = now(),
      updated_at = now()
  where participant.match_id = p_match_id
    and participant.is_eligible
    and participant.guest_player_id is not null;

  v_result := private.publish_match_convocations(
    p_match_id,
    coalesce(v_reason, 'Mise à jour immédiate de l’effectif')
  );

  insert into private.sport_admin_audit_log(
    match_id, action, actor_profile_id, reason, metadata
  ) values (
    p_match_id,
    'update_match_effectif',
    v_actor,
    v_reason,
    jsonb_build_object(
      'squad_size_limit', p_squad_size_limit,
      'convocation_version', v_result -> 'convocation_version'
    )
  );

  return private.get_match_convocations(p_match_id);
end;
$$;

CREATE OR REPLACE FUNCTION "private"."rebalance_upcoming_waitlist_matches"("p_season_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare v_match record;
begin
  for v_match in
    select m.id from public.matches m
    join public.match_sport_workflows w on w.match_id = m.id
    where m.season_id = p_season_id
      and m.status = 'a_venir'
      and now() < private.match_prediction_closes_at(m.kickoff_at)
    order by m.kickoff_at, m.id
  loop
    perform private.recompute_match_convocations_internal(v_match.id, false);
  end loop;
end;
$$;

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
     and now() < private.match_prediction_closes_at(v_kickoff) then
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
    if v_match_type = 'entre_nous' then
      v_auto_slots := 2147483647;
    end if;

    -- Un seul passage fixe l'état de TOUS les membres du match :
    -- le rang ne concerne que les joueurs présents, éligibles et non forcés.
    with ranked as (
      select p.id, row_number() over (
        order by e.position desc, p.id
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
      select p.id, e.position, sp.is_coach, r.priority,
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

CREATE OR REPLACE FUNCTION "public"."admin_remove_match_guest"("p_match_id" "uuid", "p_participant_id" "uuid", "p_reason" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
declare
  v_status text;
  v_kickoff_at timestamptz;
begin
  select match.status, match.kickoff_at
  into v_status, v_kickoff_at
  from public.matches match
  where match.id = p_match_id;

  if not found then
    raise exception 'Match not found' using errcode = 'P0002';
  end if;

  if v_status = 'a_venir'
     and v_kickoff_at is not null
     -- Fonction appelée avec les droits du joueur connecté : la règle est lue
     -- par private.club_rule, ouverte aux comptes connectés, plutôt que par
     -- private.match_prediction_closes_at, qui ne l'est pas.
     and now() >= v_kickoff_at
       - make_interval(mins => private.club_rule('prediction_close_minutes')) then
    raise exception 'L’effectif est figé depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  return private.remove_match_guest(p_match_id, p_participant_id, p_reason);
end;
$$;
