-- Réglages du club par son administrateur : identité (nom, nom court) et
-- fonctionnalités à activer ou non.

-- ---------------------------------------------------------------------------
-- 1. Fonctionnalités optionnelles
-- ---------------------------------------------------------------------------
-- Liste fermée : une fonctionnalité absente de cette liste ne peut être ni
-- lue ni modifiée par ce biais. Une fonctionnalité sans réglage enregistré est
-- considérée comme activée : un nouveau club démarre avec tout.
create function private.club_module_keys() returns text[]
language sql immutable
set search_path to ''
as $$
  select array[
    'predictions',       -- pronostics et leur classement
    'badges',            -- badges et armoire
    'statistics',        -- statistiques de l'équipe et des joueurs
    'man_of_the_match',  -- vote de l'homme du match
    'season_wrapped',    -- bilan de fin de saison
    'weather'            -- météo du match
  ];
$$;

revoke all on function private.club_module_keys() from public;
grant execute on function private.club_module_keys() to authenticated, service_role, club_scope;

create function public.get_club_modules() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
begin
  if not (select private.is_active_profile()) then
    return '{}'::jsonb;
  end if;

  return (
    select jsonb_object_agg(module.key, coalesce(flag.enabled, true))
    from unnest(private.club_module_keys()) as module(key)
    left join private.app_feature_flags flag on flag.key = module.key
  );
end;
$$;

alter function public.get_club_modules() owner to club_scope;
revoke all on function public.get_club_modules() from public, anon;
grant execute on function public.get_club_modules() to authenticated, service_role, club_scope;

create function public.admin_set_club_module(p_key text, p_enabled boolean)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;
  if p_enabled is null or p_key is null
     or not (p_key = any (private.club_module_keys())) then
    raise exception 'Fonctionnalité inconnue.' using errcode = '22023';
  end if;

  insert into private.app_feature_flags (key, enabled, config, updated_at, updated_by)
  values (p_key, p_enabled, '{}'::jsonb, now(), (select private.uid()))
  on conflict (club_id, key) do update
  set enabled = excluded.enabled,
      updated_at = excluded.updated_at,
      updated_by = excluded.updated_by;

  return public.get_club_modules();
end;
$$;

alter function public.admin_set_club_module(text, boolean) owner to club_scope;
revoke all on function public.admin_set_club_module(text, boolean) from public, anon;
grant execute on function public.admin_set_club_module(text, boolean) to authenticated, service_role, club_scope;

-- ---------------------------------------------------------------------------
-- 2. Identité du club
-- ---------------------------------------------------------------------------
create function public.admin_update_club_identity(p_name text, p_short_name text)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_name text := btrim(regexp_replace(coalesce(p_name, ''), '\s+', ' ', 'g'));
  v_short text := btrim(coalesce(p_short_name, ''));
  v_club public.clubs;
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;
  if char_length(v_name) < 2 or char_length(v_name) > 80 then
    raise exception 'Le nom du club doit compter entre 2 et 80 caractères.'
      using errcode = '22023';
  end if;
  if char_length(v_short) < 2 or char_length(v_short) > 12 then
    raise exception 'Le nom court doit compter entre 2 et 12 caractères.'
      using errcode = '22023';
  end if;

  update public.clubs
  set name = v_name, short_name = v_short
  where id = (select private.current_club_id())
  returning * into v_club;

  if v_club.id is null then
    raise exception 'Club introuvable.' using errcode = 'P0002';
  end if;

  return jsonb_build_object(
    'id', v_club.id,
    'name', v_club.name,
    'short_name', v_club.short_name,
    'invite_code', v_club.invite_code
  );
end;
$$;

alter function public.admin_update_club_identity(text, text) owner to club_scope;
revoke all on function public.admin_update_club_identity(text, text) from public, anon;
grant execute on function public.admin_update_club_identity(text, text) to authenticated, service_role, club_scope;
