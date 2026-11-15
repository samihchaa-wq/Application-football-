-- M01 / Petit Filet : empêcher qu'un membre réserve un chemin Storage
-- correspondant à un élément d'un AUTRE club.
-- Ne modifie ni les objets existants ni leurs métadonnées.
--
-- Le propriétaire SECURITY DEFINER club_scope possède sur les tables métier
-- une politique permissive club_scope_access (USING true). L'existence d'un
-- profil, invité ou joueur ne garantit donc PAS son appartenance au club.
-- L'ancienne migration 20261113020000 reste immuable.

create or replace function private.storage_path_in_current_club(
  p_bucket text,
  p_name text
) returns boolean
language plpgsql stable security definer
set search_path to ''
as $function$
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
    -- Le dossier "custom" conserve son contrat existant. L'écriture reste
    -- soumise aux autres politiques restrictives Storage.
    return true;
  end if;

  if v_first = 'guest' then
    return exists (
      select 1
      from public.guest_players guest
      where guest.id::text = v_second
        and guest.club_id = v_club
    );
  end if;

  if v_first = 'season' then
    return exists (
      select 1
      from public.season_players player
      where player.id::text = v_second
        and player.club_id = v_club
    );
  end if;

  return exists (
    select 1
    from public.profiles profile
    where profile.id::text = v_first
      and profile.club_id = v_club
  );
end;
$function$;

alter function private.storage_path_in_current_club(text, text)
  owner to club_scope;
revoke all on function private.storage_path_in_current_club(text, text)
  from public;
grant execute on function private.storage_path_in_current_club(text, text)
  to authenticated, club_scope;
