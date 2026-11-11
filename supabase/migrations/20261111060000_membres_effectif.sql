-- Un membre = un compte = un joueur de l'effectif.
--
-- Dans la version d'origine, les comptes et les joueurs de l'effectif étaient
-- deux listes à tenir séparément : l'administrateur validait un compte, puis
-- ajoutait à la main le même nom dans l'effectif et reliait les deux. Ici, un
-- compte validé rejoint automatiquement l'effectif de la saison ouverte (sauf
-- si l'administrateur le relie à une fiche existante), et l'ouverture d'une
-- saison y place d'emblée tous les membres actifs. L'effectif garde la
-- possibilité d'ajouter un joueur sans compte.

grant select, insert, update on public.season_players to club_scope;

-- Ajoute un compte actif à l'effectif de la saison ouverte de son club.
create function private.add_profile_to_roster(p_profile_id uuid) returns void
language plpgsql security definer
set search_path to ''
as $$
declare
  v_profile public.profiles;
  v_season uuid;
begin
  select * into v_profile from public.profiles where id = p_profile_id;
  if v_profile.id is null or v_profile.status <> 'active' then
    return;
  end if;
  perform set_config('app.club_id', v_profile.club_id::text, true);

  select season.id into v_season
  from public.seasons season
  where season.club_id = v_profile.club_id and season.status = 'open'
  order by season.created_at desc
  limit 1;
  if v_season is null then
    return;
  end if;

  insert into public.season_players(
    season_id, club_id, profile_id, player_id,
    first_name, last_name, is_goalkeeper, is_active, position
  )
  select
    v_season, v_profile.club_id, v_profile.id, v_profile.player_id,
    v_profile.first_name, v_profile.last_name, v_profile.is_goalkeeper, true,
    coalesce(max(sp.position), 0) + 1
  from public.season_players sp
  where sp.season_id = v_season
  on conflict (season_id, profile_id) where profile_id is not null
  do update set is_active = true;
end;
$$;

-- Place tous les membres actifs d'un club dans l'effectif d'une saison.
create function private.seed_roster_for_season(p_season_id uuid) returns void
language plpgsql security definer
set search_path to ''
as $$
declare
  v_club uuid;
  v_base integer;
begin
  select season.club_id into v_club from public.seasons season where season.id = p_season_id;
  if v_club is null then
    return;
  end if;
  perform set_config('app.club_id', v_club::text, true);

  select coalesce(max(sp.position), 0) into v_base
  from public.season_players sp
  where sp.season_id = p_season_id;

  insert into public.season_players(
    season_id, club_id, profile_id, player_id,
    first_name, last_name, is_goalkeeper, is_active, position
  )
  select
    p_season_id, p.club_id, p.id, p.player_id,
    p.first_name, p.last_name, p.is_goalkeeper, true,
    v_base + row_number() over (order by p.created_at, p.id)
  from public.profiles p
  where p.club_id = v_club
    and p.status = 'active'
    and p.id <> '00000000-0000-0000-0000-000000000001'::uuid
  on conflict (season_id, profile_id) where profile_id is not null do nothing;
end;
$$;

do $$
declare
  v_signature text;
begin
  foreach v_signature in array array[
    'private.add_profile_to_roster(uuid)',
    'private.seed_roster_for_season(uuid)'
  ] loop
    execute format('alter function %s owner to club_scope', v_signature);
    execute format('revoke all on function %s from public, anon, authenticated', v_signature);
    execute format('grant execute on function %s to club_scope, postgres, service_role', v_signature);
  end loop;
end;
$$;

-- Appels depuis les parcours existants.
CREATE OR REPLACE FUNCTION public.open_or_create_season(p_name text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  season_name text := btrim(coalesce(p_name, ''));
  start_year integer;
  end_year integer;
  season_id uuid;
  season_status text;
begin
  if not public.is_match_staff() then
    raise exception 'Active administrator role required' using errcode = '42501';
  end if;
  if season_name !~ '^[0-9]{4}-[0-9]{4}$' then
    raise exception 'Le nom doit respecter le format 2026-2027.' using errcode = '22023';
  end if;

  start_year := substring(season_name from 1 for 4)::integer;
  end_year := substring(season_name from 6 for 4)::integer;
  if end_year <> start_year + 1 then
    raise exception 'La saison doit couvrir deux années consécutives.' using errcode = '22023';
  end if;
  if start_year < 2000 or start_year > 2100 then
    raise exception 'Cette année de saison n’est pas acceptée.' using errcode = '22023';
  end if;

  select season.id, season.status
  into season_id, season_status
  from public.seasons season
  where season.name = season_name
  for update;

  if found then
    if season_status <> 'open'
       and private.season_has_historical_competition(season_id) then
      raise exception 'Une saison avec des données de compétition ne peut pas être rouverte.'
        using errcode = '22023';
    end if;

    update public.seasons
    set status = 'archived'
    where status = 'open'
      and id <> season_id;

    update public.seasons
    set status = 'open'
    where id = season_id;

    perform private.seed_roster_for_season(season_id);

    return season_id;
  end if;

  update public.seasons
  set status = 'archived'
  where status = 'open';

  insert into public.seasons(name, status)
  values (season_name, 'open')
  returning id into season_id;

  perform private.seed_roster_for_season(season_id);

  return season_id;
end;
$function$;

CREATE OR REPLACE FUNCTION public.set_season_status(p_season_id uuid, p_status text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_current_status text;
begin
  if not public.is_match_staff() then
    raise exception 'Active administrator role required' using errcode = '42501';
  end if;
  if p_season_id is null then
    raise exception 'Season id is required' using errcode = '22023';
  end if;
  if p_status is null or p_status not in ('open', 'terminee', 'archived') then
    raise exception 'Statut de saison invalide' using errcode = '22023';
  end if;

  select season.status
  into v_current_status
  from public.seasons season
  where season.id = p_season_id
  for update;

  if not found then
    raise exception 'Season not found' using errcode = 'P0002';
  end if;

  if v_current_status = p_status then
    return true;
  end if;

  if p_status = 'open'
     and v_current_status <> 'open'
     and private.season_has_historical_competition(p_season_id) then
    raise exception 'Une saison avec des données de compétition ne peut pas être rouverte.'
      using errcode = '22023';
  end if;

  if p_status = 'open' then
    update public.seasons
    set status = 'archived'
    where status = 'open'
      and id <> p_season_id;
  end if;

  update public.seasons
  set status = p_status
  where id = p_season_id;

  if p_status = 'open' then
    perform private.seed_roster_for_season(p_season_id);
  end if;

  return true;
end;
$function$;

CREATE OR REPLACE FUNCTION public.staff_validate_profile(p_profile_id uuid, p_season_player_id uuid DEFAULT NULL::uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not public.is_match_staff() then
    raise exception 'Active administrator role required' using errcode = '42501';
  end if;

  if p_profile_id is null then
    raise exception 'Profile id is required' using errcode = '22023';
  end if;

  if p_profile_id = '00000000-0000-0000-0000-000000000001'::uuid then
    raise exception 'Protected technical account' using errcode = '42501';
  end if;

  update public.profiles
  set status = 'active', updated_at = now()
  where id = p_profile_id
    and status = 'pending';

  if not found then
    raise exception 'Pending profile not found' using errcode = 'P0002';
  end if;

  if p_season_player_id is not null then
    perform public.staff_set_season_player_profile(
      p_season_player_id,
      p_profile_id
    );
  else
    -- Sans fiche d'effectif à relier, le compte rejoint l'effectif tout seul.
    perform private.add_profile_to_roster(p_profile_id);
  end if;

  return true;
end;
$function$;

CREATE OR REPLACE FUNCTION public.promote_club_founder(p_club_id uuid, p_profile_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  perform set_config('app.club_id', p_club_id::text, true);

  if not exists (
    select 1 from public.profiles profile
    where profile.id = p_profile_id and profile.club_id = p_club_id
  ) then
    raise exception 'Ce compte n’appartient pas à ce club.' using errcode = '22023';
  end if;

  if exists (
    select 1 from public.profiles profile
    where profile.club_id = p_club_id
      and profile.id <> p_profile_id
      and profile.status = 'active'
  ) then
    raise exception 'Ce club a déjà des membres.' using errcode = '22023';
  end if;

  update public.profiles
  set role = 'admin', status = 'active', updated_at = now()
  where id = p_profile_id and club_id = p_club_id;

  perform private.add_profile_to_roster(p_profile_id);

  update public.clubs
  set created_by = p_profile_id
  where id = p_club_id and created_by is null;
end;
$function$;
