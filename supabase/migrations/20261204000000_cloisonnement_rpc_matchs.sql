-- Correctif sécurité : deux RPC SECURITY DEFINER vérifiaient « profil actif »
-- mais pas le club. Un compte actif d'un autre club connaissant l'identifiant
-- d'un match pouvait lire les derniers scores contre un adversaire, ou le
-- nombre de pronostics. Le match doit maintenant appartenir au club courant ;
-- sinon on répond « introuvable » (même message qu'un identifiant inconnu).
-- CREATE OR REPLACE conserve propriétaire, droits et search_path.

create or replace function public.get_last_opponent_encounters(p_match_id uuid)
returns table(
  encounter_id uuid, encounter_date date, grinta_score integer,
  opponent_score integer, is_historical boolean, is_home boolean
)
language plpgsql
stable
security definer
set search_path to ''
as $function$
declare
  v_opponent_id uuid;
  v_reference_date date;
begin
  if not public.is_active_profile() then
    raise exception 'Active profile required' using errcode = '42501';
  end if;
  if p_match_id is null then
    raise exception 'Match id is required' using errcode = '22023';
  end if;

  select m.opponent_id, m.match_date
  into v_opponent_id, v_reference_date
  from public.matches m
  where m.id = p_match_id
    and m.club_id = private.current_club_id();

  if not found then
    raise exception 'Match not found' using errcode = 'P0002';
  end if;

  return query
  with all_results as (
    select
      m.id,
      m.match_date,
      m.score_as_grinta::integer as score_as_grinta,
      m.score_adverse::integer as score_adverse,
      false as is_historical,
      coalesce(m.location, 'domicile') = 'domicile' as is_home
    from public.matches m
    where m.opponent_id = v_opponent_id
      and m.club_id = private.current_club_id()
      and m.status in ('termine', 'archive')
      and m.score_as_grinta is not null
      and m.score_adverse is not null

    union all

    select
      h.id,
      h.match_date,
      h.score_as_grinta::integer as score_as_grinta,
      h.score_adverse::integer as score_adverse,
      true as is_historical,
      coalesce(h.is_home, true) as is_home
    from public.historical_match_scores h
    where h.opponent_id = v_opponent_id
      and h.club_id = private.current_club_id()
  ), deduplicated as (
    select distinct on (r.id)
      r.id, r.match_date, r.score_as_grinta, r.score_adverse,
      r.is_historical, r.is_home
    from all_results r
    order by r.id, r.match_date desc, r.is_historical
  )
  select
    d.id, d.match_date, d.score_as_grinta, d.score_adverse,
    d.is_historical, d.is_home
  from deduplicated d
  where d.match_date < v_reference_date
  order by d.match_date desc, d.id desc
  limit 5;
end;
$function$;

create or replace function public.match_prediction_participant_count(p_match_id uuid)
returns integer
language plpgsql
stable
security definer
set search_path to ''
as $function$
begin
  if not public.is_active_profile() then
    raise exception 'Active profile required' using errcode = '42501';
  end if;
  if p_match_id is null then
    raise exception 'Match id is required' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.matches m
    where m.id = p_match_id and m.club_id = private.current_club_id()
  ) then
    raise exception 'Match not found' using errcode = 'P0002';
  end if;
  return (
    select count(*)::integer
    from public.match_predictions mp
    where mp.match_id = p_match_id and mp.is_filled
  );
end;
$function$;
