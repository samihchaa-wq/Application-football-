-- Fichiers : un dépôt ne peut viser que le dossier d'un élément de son club.
--
-- Constaté lors du test de cloisonnement du 12/11/2026 : la règle
-- club_files_isolation vérifie le club du déposant, pas le dossier visé. Un
-- administrateur pouvait donc déposer un fichier dans le dossier photo d'un
-- joueur d'un autre club. Le fichier restait invisible pour l'autre club et ne
-- remplaçait rien, mais il occupait le nom choisi.
--
-- Dossiers utilisés par l'application :
--   profile-photos/<profil>/...          photo d'un compte
--   profile-photos/guest/<invité>/...    photo d'un invité
--   profile-photos/season/<joueur>/...   photo d'un joueur de saison
--   badge-images/club-logos/<club>/...   logo du club
--   badge-images/custom/...              image de badge (sans dossier d'élément)

create function private.storage_path_in_current_club(
  p_bucket text,
  p_name text
) returns boolean
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_club uuid := private.current_club_id();
  v_parts text[] := storage.foldername(p_name);
  v_first text := v_parts[1];
  v_second text := v_parts[2];
begin
  if not private.is_club_bucket(p_bucket) then
    return true;
  end if;
  if v_club is null then
    return false;
  end if;

  if p_bucket = 'badge-images' then
    if v_first = 'club-logos' then
      return v_second = v_club::text;
    end if;
    return true;
  end if;

  -- profile-photos. Cette fonction appartient à club_scope : elle ne voit que
  -- les lignes du club courant, ce qui est exactement la vérification voulue.
  if v_first = 'guest' then
    return exists (
      select 1 from public.guest_players guest where guest.id::text = v_second
    );
  end if;
  if v_first = 'season' then
    return exists (
      select 1 from public.season_players player where player.id::text = v_second
    );
  end if;
  return exists (
    select 1 from public.profiles profile where profile.id::text = v_first
  );
end;
$$;

alter function private.storage_path_in_current_club(text, text) owner to club_scope;
revoke all on function private.storage_path_in_current_club(text, text) from public;
grant execute on function private.storage_path_in_current_club(text, text)
  to authenticated, club_scope;

create policy club_files_folder_insert on storage.objects
  as restrictive for insert to authenticated
  with check ((select private.storage_path_in_current_club(bucket_id, name)));

create policy club_files_folder_update on storage.objects
  as restrictive for update to authenticated
  using ((select private.storage_path_in_current_club(bucket_id, name)))
  with check ((select private.storage_path_in_current_club(bucket_id, name)));
