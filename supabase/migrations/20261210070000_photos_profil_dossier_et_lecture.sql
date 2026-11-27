-- Photos de profil : chacun son dossier, et lecture limitée aux dossiers du club.
--
-- Audit du 26/11/2026, points 47 et 21.
--
-- Point 47. Un membre pouvait écrire dans profiles.photo_url le chemin du
-- fichier d'un autre membre et afficher ainsi le visage de quelqu'un d'autre
-- comme le sien. Désormais, une photo de profil doit se trouver dans le
-- dossier de ce profil (« <id du profil>/... ») ou être vide. La règle vaut
-- aussi quand un administrateur change la photo d'un joueur : l'application
-- dépose déjà le fichier dans le dossier du joueur.
--
-- Les valeurs déjà enregistrées ne sont pas relues : le contrôle ne joue que
-- lorsqu'une photo est posée ou changée. Les photos existantes s'affichent
-- donc comme avant.
--
-- Point 21. La lecture des fichiers ne vérifiait que le club du déposant.
-- Elle vérifie maintenant aussi le dossier visé, comme le dépôt et le
-- remplacement le font déjà depuis 20261113020000. Un membre ne voit, et ne
-- peut lister ou signer, que les dossiers des profils, joueurs de saison et
-- invités de son propre club.

-- ---------------------------------------------------------------------------
-- 1. Point 47 : photo_url dans le dossier du profil
-- ---------------------------------------------------------------------------

create function private.profile_photo_path_allowed(
  p_profile_id uuid,
  p_value text
) returns boolean
language sql immutable
set search_path to ''
as $$
  select case
    when private.profile_photo_storage_path(p_value) is null then true
    else
      -- Un fichier (pas seulement le dossier) dans le dossier du profil,
      -- sans remontée « .. » ni segment vide.
      private.profile_photo_storage_path(p_value)
        like p_profile_id::text || '/_%'
      and private.profile_photo_storage_path(p_value)
        !~ '(^|/)\.\.?(/|$)'
      and position('//' in private.profile_photo_storage_path(p_value)) = 0
      and position(E'\\' in private.profile_photo_storage_path(p_value)) = 0
  end;
$$;

alter function private.profile_photo_path_allowed(uuid, text) owner to club_scope;
revoke all on function private.profile_photo_path_allowed(uuid, text)
  from public, anon, authenticated;
grant execute on function private.profile_photo_path_allowed(uuid, text)
  to club_scope;

comment on function private.profile_photo_path_allowed(uuid, text) is
  'Vrai si la photo est vide ou se trouve dans le dossier du profil (<id>/...).';

-- Exécutée avec les droits de club_scope : le membre n'a pas besoin d'accès
-- direct aux fonctions de chemin.
create function private.enforce_profile_photo_folder() returns trigger
language plpgsql security definer
set search_path to ''
as $$
begin
  if tg_op = 'UPDATE' and new.photo_url is not distinct from old.photo_url then
    return new;
  end if;
  if not private.profile_photo_path_allowed(new.id, new.photo_url) then
    raise exception 'La photo de profil doit être déposée dans le dossier de ce profil.'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

alter function private.enforce_profile_photo_folder() owner to club_scope;
-- Un déclencheur n'a pas besoin du droit EXECUTE pour se déclencher.
revoke all on function private.enforce_profile_photo_folder()
  from public, anon, authenticated;

create trigger trg_enforce_profile_photo_folder
  before insert or update of photo_url on public.profiles
  for each row execute function private.enforce_profile_photo_folder();

-- ---------------------------------------------------------------------------
-- 2. Point 21 : la lecture vérifie aussi le dossier
-- ---------------------------------------------------------------------------

-- Règle restrictive : s'ajoute à profile_photos_active_read et à
-- club_files_isolation. private.storage_path_in_current_club appartient à
-- club_scope : elle ne voit que les profils, joueurs de saison et invités du
-- club courant. Un fichier rangé dans le dossier d'un autre club devient
-- invisible, même s'il a été déposé par un membre du club courant.
-- Les images de badge (lues par adresse publique) ne sont pas concernées en
-- dehors des logos de club.
create policy club_files_folder_select on storage.objects
  as restrictive for select to authenticated
  using ((select private.storage_path_in_current_club(bucket_id, name)));
