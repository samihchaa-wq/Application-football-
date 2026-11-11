-- L'administrateur envoie l'écusson de son club. Le fichier est déposé dans
-- l'espace d'images public, sous un dossier au nom du club ; cette fonction
-- n'enregistre que le chemin, et refuse tout chemin d'un autre club.
create function public.admin_set_club_logo(p_path text)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_club_id uuid := (select private.current_club_id());
  v_club public.clubs;
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;
  if p_path is not null
     and p_path !~ ('^club-logos/' || v_club_id::text || '/[A-Za-z0-9._-]{1,80}$') then
    raise exception 'Chemin de logo invalide.' using errcode = '22023';
  end if;

  update public.clubs set logo_path = p_path where id = v_club_id
  returning * into v_club;

  if v_club.id is null then
    raise exception 'Club introuvable.' using errcode = 'P0002';
  end if;

  return jsonb_build_object(
    'id', v_club.id,
    'name', v_club.name,
    'short_name', v_club.short_name,
    'invite_code', v_club.invite_code,
    'primary_color', v_club.primary_color,
    'secondary_color', v_club.secondary_color,
    'logo_path', v_club.logo_path
  );
end;
$$;

alter function public.admin_set_club_logo(text) owner to club_scope;
revoke all on function public.admin_set_club_logo(text) from public, anon;
grant execute on function public.admin_set_club_logo(text)
  to authenticated, service_role, club_scope;
