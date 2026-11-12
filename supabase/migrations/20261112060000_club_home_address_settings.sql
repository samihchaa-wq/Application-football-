-- M02 / C05 : adresse du terrain à domicile propre au club.
-- Migration préparée uniquement : ne pas appliquer à la base commerciale sans accord.
-- La lecture continue via public.club_settings, filtrée par les politiques RLS.
create function public.admin_set_club_home_address(p_address text)
returns text
language plpgsql security definer
set search_path to ''
as $$
declare
  v_club_id uuid := (select private.current_club_id());
  v_address text := nullif(btrim(p_address), '');
  v_saved text;
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;

  if v_address is not null
     and (char_length(v_address) > 200 or v_address ~ '[[:cntrl:]]') then
    raise exception 'Adresse invalide (200 caractères maximum, une seule ligne).'
      using errcode = '22023';
  end if;

  update public.club_settings
  set home_address = v_address
  where club_id = v_club_id
  returning home_address into v_saved;

  if not found then
    raise exception 'Réglages du club introuvables.' using errcode = 'P0002';
  end if;

  return v_saved;
end;
$$;

alter function public.admin_set_club_home_address(text) owner to club_scope;
revoke all on function public.admin_set_club_home_address(text) from public, anon;
grant execute on function public.admin_set_club_home_address(text)
  to authenticated, service_role, club_scope;
