-- SAUVEGARDE DEFINITIONNELLE CIBLEE du 13/11/2026, 09:21 Europe/Paris.
-- UNIQUEMENT les 7 définitions de fonctions et la tâche cron affectées.
-- Source : pg_get_functiondef sur Supabase COMMERCIAL, sans lecture des lignes utilisateurs.
-- La restauration de ce script rétablirait le +1 AUTOMATIQUE :
-- NE PAS EXECUTER sans autorisation expresse du propriétaire.
-- Ceci n'est PAS une sauvegarde complète de la base ni des objets Storage.
-- Les signatures/propriétaires/ACL ont été vérifiés; CREATE OR REPLACE garde ACL/propriétaire.
-- À utiliser uniquement si les deux migrations validées sont annulées.
BEGIN;

-- ORIGINAL private.can_manage_badges(), owner=club_scope
CREATE OR REPLACE FUNCTION private.can_manage_badges()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    coalesce(private.jwt() ->> 'role' = 'service_role', false)
    or exists (
      select 1
      from public.profiles p
      where p.id = private.uid()
        and p.status = 'active'
        and p.role = 'admin'
    );
$function$;

-- ORIGINAL private.finalize_due_waitlist_turns_for_season(uuid), owner=club_scope
CREATE OR REPLACE FUNCTION private.finalize_due_waitlist_turns_for_season(p_season_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_match record;
  v_total integer := 0;
  v_enabled_at timestamptz;
begin
  select activated_at into v_enabled_at
  from private.sport_waitlist_engine_activation where singleton;

  for v_match in
    select m.id from public.matches m
    join public.match_sport_workflows w on w.match_id = m.id
    where m.season_id = p_season_id
      and m.kickoff_at <= now()
      and m.kickoff_at >= v_enabled_at
      and m.status <> 'annule'
      and not w.waitlist_passages_exempt
      and (
        exists (select 1 from private.sport_waitlist_passage_ledger l
                where l.match_id = m.id
                  and l.credited_at is null and l.voided_at is null)
        or exists (
          select 1 from public.match_sport_participants p
          where p.match_id = m.id and p.is_eligible
            and p.availability_status = 'available'
            and p.convocation_status = 'not_convoked'
            and not exists (
              select 1 from private.sport_waitlist_passage_ledger l
              where l.match_id = m.id
                and l.season_player_id = p.season_player_id
            )
        )
      )
    order by m.kickoff_at, m.id
  loop
    v_total := v_total
      + private.finalize_match_waitlist_turns_internal(v_match.id, false);
  end loop;
  return v_total;
end;
$function$;

-- ORIGINAL private.finalize_match_waitlist_turns_internal(uuid,boolean), owner=club_scope
CREATE OR REPLACE FUNCTION private.finalize_match_waitlist_turns_internal(p_match_id uuid, p_force boolean DEFAULT false)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_season_id uuid;
  v_kickoff timestamptz;
  v_status text;
  v_exempt boolean;
  v_enabled_at timestamptz;
  v_count integer := 0;
begin
  perform private.require_sports_management_enabled();

  select m.season_id, m.kickoff_at, m.status, w.waitlist_passages_exempt
    into v_season_id, v_kickoff, v_status, v_exempt
  from public.matches m
  join public.match_sport_workflows w on w.match_id = m.id
  where m.id = p_match_id
  for update of w;
  if not found then
    raise exception 'Match not found' using errcode = 'P0002';
  end if;
  select activated_at into v_enabled_at
  from private.sport_waitlist_engine_activation where singleton;

  if v_kickoff is null or now() < v_kickoff
     or v_kickoff < v_enabled_at
     or v_status = 'annule' or v_exempt then
    return 0;
  end if;

  perform private.ensure_sport_waitlist(v_season_id, null);

  -- Un joueur toujours en attente au coup d'envoi doit être crédité même
  -- s'il ne s'est produit aucun changement depuis J-1 à 12 h.
  insert into private.sport_waitlist_passage_ledger
      (match_id, season_player_id, first_eligible_at)
  select p_match_id, p.season_player_id,
         private.waitlist_credit_cutoff(v_kickoff)
  from public.match_sport_participants p
  join public.sport_waitlist_entries e
    on e.season_player_id = p.season_player_id
   and e.season_id = v_season_id
  where p.match_id = p_match_id
    and p.is_eligible and p.availability_status = 'available'
    and p.convocation_status = 'not_convoked'
  on conflict (match_id, season_player_id) do nothing;

  -- Une seule instruction transactionnelle crédite et incrémente
  -- le compteur utilisé par l'interface et par le classement.
  with fresh as (
    update private.sport_waitlist_passage_ledger l
    set credited_at = now()
    where l.match_id = p_match_id
      and l.credited_at is null and l.voided_at is null
    returning l.season_player_id
  ), grouped as (
    select season_player_id, count(*)::integer as increment
    from fresh group by season_player_id
  )
  update public.sport_waitlist_entries e
     set manual_waitlist_count = e.manual_waitlist_count + g.increment,
         updated_at = now()
    from grouped g
   where e.season_player_id = g.season_player_id
     and e.season_id = v_season_id;
  get diagnostics v_count = row_count;

  if v_count > 0 then
    update public.match_sport_participants p
      set waitlist_turn_state = 'consumed',
          waitlist_turn_should_consume = true,
          waitlist_turn_updated_at = now(),
          updated_at = now()
    where p.match_id = p_match_id
      and exists (
        select 1 from private.sport_waitlist_passage_ledger l
        where l.match_id = p.match_id
          and l.season_player_id = p.season_player_id
          and l.credited_at is not null
      );

    -- Préserve l'événement historique sans en produire plusieurs au retry.
    insert into public.match_sport_participant_events (
      participant_id, match_id, event_type, old_value, new_value,
      actor_profile_id, actor_kind
    )
    select p.id, p_match_id, 'waitlist_turn_consumed',
      '{}'::jsonb,
      jsonb_build_object('counted_at', l.credited_at),
      null, 'system'
    from public.match_sport_participants p
    join private.sport_waitlist_passage_ledger l
      on l.match_id = p.match_id and l.season_player_id = p.season_player_id
    where p.match_id = p_match_id and l.credited_at is not null
      and not exists (
        select 1 from public.match_sport_participant_events ev
        where ev.participant_id = p.id
          and ev.match_id = p_match_id
          and ev.event_type = 'waitlist_turn_consumed'
      );

    perform private.rebuild_sport_waitlist_order(v_season_id, null);
    perform private.rebalance_upcoming_waitlist_matches(v_season_id);
  end if;

  return v_count;
end;
$function$;

-- ORIGINAL private.is_admin(), owner=club_scope
CREATE OR REPLACE FUNCTION private.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select private.uid())
      and p.role = 'admin'
      and p.status = 'active'
  );
$function$;

-- ORIGINAL private.process_due_waitlist_credits(), owner=club_scope
CREATE OR REPLACE FUNCTION private.process_due_waitlist_credits()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_season record;
  v_total integer := 0;
begin
  for v_season in
    select s.id from public.seasons s where s.status = 'open'
  loop
    v_total := v_total
      + private.finalize_due_waitlist_turns_for_season(v_season.id);
  end loop;
  return v_total;
end;
$function$;

-- ORIGINAL private.void_match_waitlist_credits(uuid), owner=club_scope
CREATE OR REPLACE FUNCTION private.void_match_waitlist_credits(p_match_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_season_id uuid;
  v_count integer := 0;
begin
  select m.season_id into v_season_id
  from public.matches m where m.id = p_match_id;
  if v_season_id is null then return 0; end if;

  with voided as (
    update private.sport_waitlist_passage_ledger l
    set voided_at = now()
    where l.match_id = p_match_id and l.voided_at is null
    returning l.season_player_id, l.credited_at
  ), counts as (
    select season_player_id, count(*)::integer as removed
    from voided where credited_at is not null
    group by season_player_id
  )
  update public.sport_waitlist_entries e
     set manual_waitlist_count =
           greatest(0, e.manual_waitlist_count - c.removed),
         updated_at = now()
    from counts c
   where e.season_id = v_season_id
     and e.season_player_id = c.season_player_id;
  get diagnostics v_count = row_count;

  if v_count > 0 then
    perform private.rebuild_sport_waitlist_order(v_season_id, null);
    perform private.rebalance_upcoming_waitlist_matches(v_season_id);
  end if;
  return v_count;
end;
$function$;

-- ORIGINAL is_moderator(), owner=club_scope
CREATE OR REPLACE FUNCTION public.is_moderator()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select private.uid())
      and p.role = 'admin'
      and p.status = 'active'
  );
$function$;

-- ORIGINAL job waitlist-credit (actif=true).
-- Appeler cron.schedule sur le même nom réinstaure le traitement d'origine.
SELECT cron.schedule('waitlist-credit', '* * * * *', 'select private.run_for_each_club(''select private.process_due_waitlist_credits()'');');

COMMIT;
