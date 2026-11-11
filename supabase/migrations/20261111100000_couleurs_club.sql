-- L'administrateur choisit les deux couleurs de son club : l'application
-- s'habille à ces couleurs pour tous ses membres.
create function public.admin_update_club_colors(p_primary text, p_secondary text)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_club public.clubs;
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;
  if p_primary is null or p_secondary is null
     or p_primary !~ '^#[0-9A-Fa-f]{6}$'
     or p_secondary !~ '^#[0-9A-Fa-f]{6}$' then
    raise exception 'Couleur invalide.' using errcode = '22023';
  end if;

  update public.clubs
  set primary_color = upper(p_primary), secondary_color = upper(p_secondary)
  where id = (select private.current_club_id())
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
    'secondary_color', v_club.secondary_color
  );
end;
$$;

alter function public.admin_update_club_colors(text, text) owner to club_scope;
revoke all on function public.admin_update_club_colors(text, text) from public, anon;
grant execute on function public.admin_update_club_colors(text, text)
  to authenticated, service_role, club_scope;
