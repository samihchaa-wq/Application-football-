-- Deux défauts qui n'apparaissaient qu'avec plusieurs clubs.
--
-- 1. Notifications : la base appelait la fonction d'envoi sans dire de quel
--    club il s'agissait. Sur une base réelle, la fonction ne trouvait alors
--    aucun destinataire (les règles d'accès ne laissent rien voir sans club)
--    et aucune notification ne partait. Les tests ne le voyaient pas : ils
--    utilisent un club par défaut, absent d'une base réelle.
--    Désormais, tout appel sortant porte le club courant dans l'en-tête
--    x-club-id, que la fonction d'envoi transmet à chacune de ses lectures.
--
-- 2. Fichiers : les photos de profil et les images de badges n'étaient pas
--    cloisonnées. Un administrateur pouvait remplacer ou supprimer les
--    fichiers d'un autre club, et un membre lire les photos d'un autre club.
--    Un fichier appartient au club de la personne qui l'a déposé ; une règle
--    restrictive interdit tout accès depuis un autre club. Chaque club a en
--    plus un quota d'espace, pour garder le coût de stockage maîtrisé.

-- ---------------------------------------------------------------------------
-- 1. Appels sortants : le club voyage avec la requête
-- ---------------------------------------------------------------------------

create or replace function private.http_post(
  url text,
  body jsonb default '{}'::jsonb,
  params jsonb default '{}'::jsonb,
  headers jsonb default '{"Content-Type": "application/json"}'::jsonb,
  timeout_milliseconds integer default 5000
) returns bigint
language plpgsql security definer
set search_path to ''
as $$
declare
  v_headers jsonb := coalesce(headers, '{}'::jsonb);
  v_club uuid := private.current_club_id();
begin
  -- Un en-tête déjà fourni par l'appelant est conservé tel quel.
  if v_club is not null and not (v_headers ? 'x-club-id') then
    v_headers := v_headers || jsonb_build_object('x-club-id', v_club::text);
  end if;

  return net.http_post(
    url := url,
    body := body,
    params := params,
    headers := v_headers,
    timeout_milliseconds := timeout_milliseconds
  );
end;
$$;

revoke all on function private.http_post(text, jsonb, jsonb, jsonb, integer) from public;
grant execute on function private.http_post(text, jsonb, jsonb, jsonb, integer) to club_scope;

-- ---------------------------------------------------------------------------
-- 2. Fichiers : cloisonnement par club
-- ---------------------------------------------------------------------------

-- Espaces de fichiers propres à chaque club. 'app-assets' reste commun : il
-- contient les images livrées avec l'application.
create function private.is_club_bucket(p_bucket text) returns boolean
language sql immutable
set search_path to ''
as $$
  select p_bucket in ('profile-photos', 'badge-images');
$$;
alter function private.is_club_bucket(text) owner to club_scope;
grant execute on function private.is_club_bucket(text) to authenticated, club_scope;

-- Vrai si le fichier peut être vu ou modifié depuis le club courant, c'est-à-
-- dire si son déposant est membre du club courant. Appartient à club_scope,
-- soumis au cloisonnement : il ne voit que les profils du club courant, ce
-- qui est exactement la vérification voulue.
create function private.storage_object_in_current_club(
  p_bucket text,
  p_owner text
) returns boolean
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_club uuid;
begin
  if not private.is_club_bucket(p_bucket) then
    return true;
  end if;
  v_club := private.current_club_id();
  if v_club is null or p_owner is null then
    return false;
  end if;
  return exists (
    select 1
    from public.profiles profile
    where profile.id::text = p_owner
      and profile.club_id = v_club
  );
end;
$$;

alter function private.storage_object_in_current_club(text, text) owner to club_scope;
revoke all on function private.storage_object_in_current_club(text, text) from public;
grant execute on function private.storage_object_in_current_club(text, text)
  to authenticated, club_scope;

-- Règle restrictive : s'ajoute aux règles existantes (propriétaire, admin…)
-- sans les remplacer. Un fichier d'un autre club devient invisible et
-- intouchable, même pour un administrateur.
create policy club_files_isolation on storage.objects
  as restrictive for all to authenticated
  using ((select private.storage_object_in_current_club(bucket_id, owner_id)))
  with check ((select private.storage_object_in_current_club(bucket_id, owner_id)));

-- Les fonctions serveur aussi ne touchent qu'aux fichiers de leur club.
drop policy club_scope_files on storage.objects;
create policy club_scope_files on storage.objects
  for all to club_scope
  using (
    bucket_id in ('profile-photos', 'badge-images', 'app-assets')
    and private.storage_object_in_current_club(bucket_id, owner_id)
  )
  with check (
    bucket_id in ('profile-photos', 'badge-images', 'app-assets')
    and private.storage_object_in_current_club(bucket_id, owner_id)
  );

-- ---------------------------------------------------------------------------
-- 3. Fichiers : quota par club
-- ---------------------------------------------------------------------------

-- 200 Mo par défaut : de quoi stocker plusieurs milliers de photos de profil
-- compressées. 500 clubs au maximum de leur quota tiennent dans les 100 Go
-- inclus dans l'offre payante de Supabase.
alter table public.clubs
  add column storage_quota_bytes bigint not null default 209715200
    constraint clubs_storage_quota_bytes_check
      check (storage_quota_bytes between 0 and 10737418240);

comment on column public.clubs.storage_quota_bytes is
  'Espace de fichiers maximal du club (photos, images de badges), en octets.';

-- Espace occupé par les fichiers du club courant. Appartient à club_scope :
-- ne voit que les fichiers et les profils du club courant.
create function private.club_storage_used_bytes() returns bigint
language sql stable security definer
set search_path to ''
as $$
  select coalesce(sum(coalesce((object.metadata ->> 'size')::bigint, 0)), 0)::bigint
  from storage.objects object
  join public.profiles profile on profile.id::text = object.owner_id
  where profile.club_id = private.current_club_id()
    and private.is_club_bucket(object.bucket_id);
$$;

alter function private.club_storage_used_bytes() owner to club_scope;
revoke all on function private.club_storage_used_bytes() from public;

-- Un dépôt est accepté tant que le club n'a pas atteint son quota. Le dernier
-- fichier peut le dépasser au plus de la taille maximale d'un fichier (5 Mo).
create function private.club_storage_within_quota(p_bucket text) returns boolean
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_club uuid;
  v_quota bigint;
begin
  if not private.is_club_bucket(p_bucket) then
    return true;
  end if;
  v_club := private.current_club_id();
  if v_club is null then
    return false;
  end if;
  select club.storage_quota_bytes into v_quota
  from public.clubs club
  where club.id = v_club;
  return coalesce(v_quota, 0) > private.club_storage_used_bytes();
end;
$$;

alter function private.club_storage_within_quota(text) owner to club_scope;
revoke all on function private.club_storage_within_quota(text) from public;
grant execute on function private.club_storage_within_quota(text) to authenticated;

create policy club_files_quota on storage.objects
  as restrictive for insert to authenticated
  with check ((select private.club_storage_within_quota(bucket_id)));

-- Espace utilisé et quota, pour l'écran des réglages du club.
create function public.admin_get_club_storage_usage() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_club uuid := private.current_club_id();
  v_quota bigint;
begin
  if not private.is_admin() then
    raise exception 'Réservé aux administrateurs du club.' using errcode = '42501';
  end if;
  select club.storage_quota_bytes into v_quota from public.clubs club where club.id = v_club;
  return jsonb_build_object(
    'used_bytes', private.club_storage_used_bytes(),
    'quota_bytes', coalesce(v_quota, 0)
  );
end;
$$;

alter function public.admin_get_club_storage_usage() owner to club_scope;
revoke all on function public.admin_get_club_storage_usage() from public, anon;
grant execute on function public.admin_get_club_storage_usage() to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Fichiers orphelins
-- ---------------------------------------------------------------------------

-- Un fichier dont le déposant a été supprimé n'est plus visible par aucun
-- club et ne compte plus dans aucun quota. Il est effacé chaque nuit, pour ne
-- pas payer son stockage indéfiniment. Délai d'un jour : un dépôt en cours au
-- moment d'une suppression de compte n'est jamais touché.
select cron.schedule(
  'purge-orphan-club-files',
  '41 3 * * *',
  $cron$
  do $job$
  begin
    perform set_config('storage.allow_delete_query', 'true', true);
    delete from storage.objects object
    where object.bucket_id in ('profile-photos', 'badge-images')
      and object.owner_id is not null
      and object.created_at < now() - interval '1 day'
      and not exists (
        select 1 from public.profiles profile
        where profile.id::text = object.owner_id
      );
  end;
  $job$;
  $cron$
);
