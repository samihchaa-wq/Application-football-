-- Téléphone et date de naissance des membres, visibles dans l'Effectif.
--
-- Décision produit du 19/11/2026 : tous les membres actifs du club voient le
-- téléphone et la date de naissance des autres membres (écran Effectif). Le
-- membre modifie les siens depuis son Profil ; un administrateur peut les
-- saisir ou les corriger pour n'importe quel membre de son club.
--
-- La table reste fermée à toute lecture directe : on passe par les fonctions
-- ci-dessous, qui ne renvoient que les membres actifs du club courant (règle
-- club_isolation sur les deux tables lues).

comment on table public.profile_private_details is
  'Téléphone et date de naissance d''un membre. Visibles par les membres actifs de son club (Effectif), modifiables par lui-même et par les administrateurs du club.';

create function public.get_club_member_contacts()
returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
begin
  if private.uid() is null then
    raise exception 'Connexion requise.' using errcode = '42501';
  end if;
  if not (select private.is_active_profile()) then
    raise exception 'Compte inactif.' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'profile_id', details.profile_id,
        'phone', details.phone,
        'birth_date', details.birth_date
      )
      order by details.profile_id
    )
    from public.profile_private_details details
    join public.profiles profile on profile.id = details.profile_id
    where profile.status = 'active'
      and profile.club_id = (select private.current_club_id())
      and details.club_id = (select private.current_club_id())
  ), '[]'::jsonb);
end;
$$;

alter function public.get_club_member_contacts() owner to club_scope;
revoke all on function public.get_club_member_contacts() from public, anon;
grant execute on function public.get_club_member_contacts() to authenticated;

create function public.admin_set_member_private_details(
  p_profile_id uuid,
  p_phone text,
  p_birth_date date
)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_phone text := nullif(btrim(p_phone), '');
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.profiles profile
    where profile.id = p_profile_id
      and profile.club_id = (select private.current_club_id())
  ) then
    raise exception 'Membre introuvable dans ce club.' using errcode = 'P0002';
  end if;
  if v_phone is not null and v_phone !~ '^\+?[0-9][0-9 .()-]{5,24}$' then
    raise exception 'Numéro de téléphone invalide.' using errcode = '22023';
  end if;
  if p_birth_date is not null
     and p_birth_date not between date '1900-01-01' and current_date then
    raise exception 'Date de naissance invalide.' using errcode = '22023';
  end if;

  if v_phone is null and p_birth_date is null then
    delete from public.profile_private_details details
    where details.profile_id = p_profile_id;
  else
    insert into public.profile_private_details as details
      (profile_id, phone, birth_date, updated_at)
    values (p_profile_id, v_phone, p_birth_date, now())
    on conflict (profile_id) do update
      set phone = excluded.phone,
          birth_date = excluded.birth_date,
          updated_at = now();
  end if;

  return jsonb_build_object(
    'profile_id', p_profile_id,
    'phone', v_phone,
    'birth_date', p_birth_date
  );
end;
$$;

alter function public.admin_set_member_private_details(uuid, text, date)
  owner to club_scope;
revoke all on function public.admin_set_member_private_details(uuid, text, date)
  from public, anon;
grant execute on function public.admin_set_member_private_details(uuid, text, date)
  to authenticated, service_role, club_scope;
