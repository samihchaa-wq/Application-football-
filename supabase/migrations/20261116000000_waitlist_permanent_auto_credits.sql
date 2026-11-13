-- Petit Filet: priorite +1 cumulative sur la saison, a partir du coup d'envoi.
-- Nouvelle decision du 13/11/2026 qui remplace l'ancienne regle "admin uniquement".
-- Ne modifie aucun compteur passe. Ne touche pas a AS Grinta original.
-- Un deploiement exige une autorisation distincte, sauvegarde, tests et revue.

-- Pas de rattrapage retroactif pour les matchs passes avant ce deploiement.
create table private.waitlist_auto_activation (
  singleton boolean primary key default true check (singleton),
  activated_at timestamptz not null default now()
);
insert into private.waitlist_auto_activation(singleton) values (true)
on conflict (singleton) do nothing;

-- Chaque match est traite au maximum une fois, y compris s'il n'a aucun
-- joueur en attente. Le credit reste permanent meme apres une convocation.
create table private.waitlist_auto_processed_matches (
  match_id uuid primary key references public.matches(id) on delete cascade,
  season_id uuid not null references public.seasons(id),
  club_id uuid not null,
  kickoff_at timestamptz not null,
  processed_at timestamptz not null default now(),
  credited_count integer not null default 0 check (credited_count >= 0)
);
-- Les fonctions existantes sont SECURITY DEFINER sous le role club_scope :
-- ce role doit posseder les tables privees pour que RLS n'ecarte pas
-- silencieusement ses lignes, sans rien ouvrir aux utilisateurs.
alter table private.waitlist_auto_activation owner to club_scope;
alter table private.waitlist_auto_processed_matches owner to club_scope;
-- Le coordonnateur cron s'execute comme postgres : lecture seule des
-- registres necessaire pour parcourir tous les matchs.
grant select on private.waitlist_auto_activation,
  private.waitlist_auto_processed_matches to postgres;
alter table private.waitlist_auto_activation enable row level security;
alter table private.waitlist_auto_processed_matches enable row level security;
-- Comme toutes les tables avec club_id, le registre a une politique de
-- cloisonnement restrictive, y compris si les droits evoluent plus tard.
create policy club_isolation on private.waitlist_auto_processed_matches
  as restrictive for all to public
  using (club_id = (select private.current_club_id()))
  with check (club_id = (select private.current_club_id()));
revoke all on private.waitlist_auto_activation,
  private.waitlist_auto_processed_matches from public, anon, authenticated;

-- Le classement est d'abord base sur la somme reelle des +1 de la saison,
-- puis sur la presence l'an passe ; jamais sur un credit "depense".
-- La table legacy sport_waitlist_start n'efface plus les credits anterieurs.
CREATE OR REPLACE FUNCTION private.rebuild_sport_waitlist_order(p_season_id uuid, p_actor uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_offset integer;
begin
  -- Sérialiser les reclassements de la même saison.
  perform 1 from public.seasons where id = p_season_id for update;
  if not found then
    raise exception 'Season not found' using errcode = 'P0002';
  end if;

  -- Pas d'écriture quand le classement est déjà le bon.
  if not exists (
    select 1 from (
      select e.position, row_number() over (
        order by e.manual_waitlist_count,
        e.previous_season_attendance_count,
          lower(p.last_name), lower(p.first_name), e.season_player_id
      )::integer as expected
      from public.sport_waitlist_entries e
      join public.season_players p on p.id = e.season_player_id
      left join private.sport_waitlist_start st
        on st.season_id = e.season_id
       and st.season_player_id = e.season_player_id
      where e.season_id = p_season_id
    ) ranks where ranks.position <> ranks.expected
  ) then
    return;
  end if;

  -- Positions intermédiaires au-delà des anciennes : respecte
  -- UNIQUE(season_id, position) pendant la réécriture.
  select coalesce(max(position), 0) + count(*)::integer + 1
    into v_offset
  from public.sport_waitlist_entries where season_id = p_season_id;

  update public.sport_waitlist_entries
     set position = position + v_offset
   where season_id = p_season_id;

  with ranked as (
    select e.season_player_id, row_number() over (
      order by e.manual_waitlist_count,
        e.previous_season_attendance_count,
        lower(p.last_name), lower(p.first_name), e.season_player_id
    )::integer as position
    from public.sport_waitlist_entries e
    join public.season_players p on p.id = e.season_player_id
    left join private.sport_waitlist_start st
      on st.season_id = e.season_id
     and st.season_player_id = e.season_player_id
    where e.season_id = p_season_id
  )
  update public.sport_waitlist_entries e
     set position = r.position,
         updated_by = coalesce(p_actor, e.updated_by),
         updated_at = now()
    from ranked r
   where e.season_id = p_season_id
     and e.season_player_id = r.season_player_id;
end;
$function$;

-- En mode ordre d'arrivee : credits +1 d'abord, anciennete de la reponse
-- ensuite. Les deux autres modes ne changent pas de principe.
CREATE OR REPLACE FUNCTION private.match_waitlist_position(p_match_id uuid, p_season_player_id uuid, p_season_position integer)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
      order by coalesce(e.manual_waitlist_count, 0) asc,
        p.availability_updated_at desc nulls first, p.id desc
    )::integer as rank
    from public.match_sport_participants p
    join public.season_players sp on sp.id = p.season_player_id
    left join public.sport_waitlist_entries e
      on e.season_player_id = p.season_player_id
     and e.season_id = sp.season_id
    where p.match_id = p_match_id
      and p.is_eligible
      and p.availability_status = 'available'
      and not sp.is_coach
  ) ranked
  where ranked.season_player_id = p_season_player_id;

  return v_rank;
end;
$function$;

CREATE OR REPLACE FUNCTION private.recompute_match_convocations_internal(p_match_id uuid, p_reset_overrides boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
          case when v_mode = 1 then e.manual_waitlist_count end desc nulls last,
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
$function$;

-- Fonction centralisee de credit. Le p_force historique ne permet PAS de
-- passer outre le coup d'envoi ou la date d'activation.
create or replace function private.finalize_match_waitlist_turns_internal(
  p_match_id uuid, p_force boolean default false
) returns integer
language plpgsql security definer
set search_path to ''
as $function$
declare
  v_match record;
  v_activation timestamptz;
  v_old_club_setting text := coalesce(current_setting('app.club_id', true), '');
  v_processed_id uuid;
  v_credited integer := 0;
begin
  -- Le verrou match/workflow protege le roster contre une publication admin
  -- concurrente et serialise les credits de deux executions simultanees.
  select m.id, m.season_id, m.club_id, m.kickoff_at, m.status
    into v_match
  from public.matches m
  join public.match_sport_workflows w on w.match_id = m.id
  where m.id = p_match_id
  for update of m, w;

  if not found then return 0; end if;

  select a.activated_at into v_activation
  from private.waitlist_auto_activation a where a.singleton;

  if v_match.kickoff_at is null
     or v_activation is null
     or v_match.kickoff_at < v_activation
     or v_match.kickoff_at > now()
     or v_match.status in ('annule', 'reporte') then
    return 0;
  end if;

  -- Un appel depuis un profil d'un autre club n'est jamais autorise.
  if private.uid() is not null
     and private.current_club_id() is distinct from v_match.club_id then
    raise exception 'Match belongs to another club' using errcode = '42501';
  end if;

  -- Le cron ne possede aucun utilisateur et doit utiliser le bon club pour
  -- lire les regles et recalculer les convocations des autres matchs.
  perform set_config('app.club_id', v_match.club_id::text, true);

  -- Echec explicite plutot que de perdre un credit si une entree manque.
  if exists (
    select 1
    from public.match_sport_participants p
    join public.season_players sp
      on sp.id = p.season_player_id
     and sp.season_id = v_match.season_id
     and sp.club_id = v_match.club_id
    left join public.sport_waitlist_entries e
      on e.season_player_id = p.season_player_id
     and e.season_id = v_match.season_id
     and e.club_id = v_match.club_id
    where p.match_id = v_match.id
      and p.club_id = v_match.club_id
      and p.season_player_id is not null
      and p.is_eligible
      and p.availability_status = 'available'
      and p.convocation_status = 'not_convoked'
      and not sp.is_coach
      and e.season_player_id is null
  ) then
    raise exception 'Missing waitlist entry for match %', v_match.id
      using errcode = 'P0002';
  end if;

  insert into private.waitlist_auto_processed_matches(
    match_id, season_id, club_id, kickoff_at
  ) values (
    v_match.id, v_match.season_id, v_match.club_id, v_match.kickoff_at
  )
  on conflict (match_id) do nothing
  returning match_id into v_processed_id;

  if v_processed_id is null then
    perform set_config('app.club_id', v_old_club_setting, true);
    return 0;
  end if;

  -- Uniquement les presents toujours en attente au coup d'envoi, y compris
  -- ceux places manuellement par l'admin dans le mode "Par choix".
  -- Ni coach, ni absent, ni invite sans joueur de saison.
  with credited as (
    update public.sport_waitlist_entries e
       set manual_waitlist_count = e.manual_waitlist_count + 1,
           updated_at = now()
      from public.match_sport_participants p
      join public.season_players sp
        on sp.id = p.season_player_id
       and sp.season_id = v_match.season_id
       and sp.club_id = v_match.club_id
     where p.match_id = v_match.id
       and p.club_id = v_match.club_id
       and p.is_eligible
       and p.availability_status = 'available'
       and p.convocation_status = 'not_convoked'
       and not sp.is_coach
       and e.season_player_id = p.season_player_id
       and e.season_id = v_match.season_id
       and e.club_id = v_match.club_id
    returning e.season_player_id
  )
  insert into private.sport_waitlist_passage_ledger (
    match_id, season_player_id, first_eligible_at, credited_at, club_id
  )
  select v_match.id, c.season_player_id, now(), now(), v_match.club_id
  from credited c
  on conflict (match_id, season_player_id) do update
    set credited_at = excluded.credited_at,
        voided_at = null;

  get diagnostics v_credited = row_count;
  update private.waitlist_auto_processed_matches
     set credited_count = v_credited where match_id = v_match.id;

  if v_credited > 0 then
    perform private.rebuild_sport_waitlist_order(v_match.season_id, null);
    if private.is_feature_enabled('sports_management') then
      perform private.rebalance_upcoming_waitlist_matches(v_match.season_id);
    end if;
  end if;

  perform set_config('app.club_id', v_old_club_setting, true);
  return v_credited;
end;
$function$;

-- Seul le coordonnateur cron utilise SECURITY INVOKER pour reperer
-- tous les clubs sous le role PostgreSQL proprietaire des tables et
-- contournant RLS. Chaque credit individuel reste SECURITY DEFINER
-- sous club_scope, avec son app.club_id fixe par le coordonnateur.
-- Les lectures de liste des utilisateurs n'entrainent aucun credit.
create or replace function private.process_due_waitlist_credits()
returns integer
language plpgsql security invoker
set search_path to ''
as $function$
declare
  v_match record;
  v_total integer := 0;
  v_old_club_setting text := coalesce(current_setting('app.club_id', true), '');
begin
  for v_match in
    select m.id, m.club_id
    from public.matches m
    join public.match_sport_workflows w on w.match_id = m.id
    cross join private.waitlist_auto_activation a
    where a.singleton
      and m.kickoff_at >= a.activated_at
      and m.kickoff_at <= now()
      and m.status not in ('annule', 'reporte')
      and not exists (
        select 1 from private.waitlist_auto_processed_matches done
        where done.match_id = m.id
      )
    order by m.kickoff_at, m.id
    limit 100
  loop
    perform set_config('app.club_id', v_match.club_id::text, true);
    v_total := v_total
      + private.finalize_match_waitlist_turns_internal(v_match.id, false);
  end loop;
  perform set_config('app.club_id', v_old_club_setting, true);
  return v_total;
end;
$function$;

-- Permanence : pas de retrait si un joueur est convoque, si le quota
-- change, ou si le match est annule apres son coup d'envoi.
-- private.void_match_waitlist_credits et les rattrapages en lecture restent
-- neutralises par 20261115000000_waitlist_credits_admin_only.sql.

revoke all on function private.finalize_match_waitlist_turns_internal(uuid,boolean)
  from public, anon, authenticated;
revoke all on function private.process_due_waitlist_credits()
  from public, anon, authenticated;
-- La tache pg_cron est executee comme postgres, jamais comme un client.
grant execute on function private.process_due_waitlist_credits() to postgres;
grant execute on function private.finalize_match_waitlist_turns_internal(uuid,boolean)
  to postgres;

-- Reprendre une execution a la minute ; aucune fonction client n'est exposee.
select cron.schedule(
  'waitlist-credit',
  '* * * * *',
  $cron$select private.process_due_waitlist_credits();$cron$
);
