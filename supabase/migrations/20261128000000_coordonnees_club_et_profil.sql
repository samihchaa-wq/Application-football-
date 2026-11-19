-- Coordonnées du club et coordonnées personnelles du membre.
--
-- 1. Club : responsable, e-mail, téléphone, adresse postale, site et numéro
--    d'immatriculation (RNA ou SIRET de l'association). Rangés dans
--    public.club_settings, déjà lisible par les membres du club et cloisonné
--    par club. Écriture réservée aux administrateurs, par une fonction.
-- 2. Membre : téléphone et date de naissance, dans une table à part. Ces
--    données ne doivent PAS être visibles des autres membres, alors que
--    public.profiles est lisible par tout le club. Seul le membre lui-même les
--    lit et les modifie, par deux fonctions. Elles partent dans l'export
--    « Mes données » (colonne profile_id) et sont effacées avec le compte.

-- ---------------------------------------------------------------------------
-- 1. Coordonnées du club
-- ---------------------------------------------------------------------------

alter table public.club_settings
  add column contact_name text
    constraint club_settings_contact_name_check
      check (contact_name is null
             or (char_length(contact_name) between 2 and 120
                 and contact_name !~ '[[:cntrl:]]')),
  add column contact_email text
    constraint club_settings_contact_email_check
      check (contact_email is null
             or (char_length(contact_email) <= 254
                 and contact_email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$')),
  add column contact_phone text
    constraint club_settings_contact_phone_check
      check (contact_phone is null
             or contact_phone ~ '^\+?[0-9][0-9 .()-]{5,24}$'),
  add column postal_address text
    constraint club_settings_postal_address_check
      check (postal_address is null
             or (char_length(postal_address) between 5 and 300
                 and postal_address !~ '[[:cntrl:]]')),
  add column website text
    constraint club_settings_website_check
      check (website is null
             or (char_length(website) <= 200 and website !~ '[[:space:][:cntrl:]]')),
  add column registration_number text
    constraint club_settings_registration_number_check
      check (registration_number is null
             or registration_number ~ '^(W[0-9]{9}|[0-9]{9}|[0-9]{14})$');

comment on column public.club_settings.contact_name is
  'Personne à contacter pour le club (président, secrétaire…).';
comment on column public.club_settings.contact_email is
  'Adresse e-mail de contact du club.';
comment on column public.club_settings.contact_phone is
  'Téléphone de contact du club.';
comment on column public.club_settings.postal_address is
  'Adresse postale du club (siège), utile pour les factures.';
comment on column public.club_settings.website is
  'Site internet ou page du club.';
comment on column public.club_settings.registration_number is
  'Numéro RNA (W + 9 chiffres), SIREN (9) ou SIRET (14) du club.';

create function public.admin_set_club_contact(
  p_contact_name text,
  p_email text,
  p_phone text,
  p_postal_address text,
  p_website text,
  p_registration_number text
)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_club_id uuid := (select private.current_club_id());
  v_name text := nullif(btrim(p_contact_name), '');
  v_email text := lower(nullif(btrim(p_email), ''));
  v_phone text := nullif(btrim(p_phone), '');
  v_address text := nullif(btrim(p_postal_address), '');
  v_website text := nullif(btrim(p_website), '');
  -- Les espaces sont tolérés à la saisie : « 123 456 789 00012 ».
  v_registration text :=
    nullif(upper(regexp_replace(coalesce(p_registration_number, ''), '\s', '', 'g')), '');
  v_saved public.club_settings;
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;

  if v_name is not null
     and (char_length(v_name) not between 2 and 120 or v_name ~ '[[:cntrl:]]') then
    raise exception 'Nom du contact invalide (2 à 120 caractères).'
      using errcode = '22023';
  end if;
  if v_email is not null
     and (char_length(v_email) > 254
          or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$') then
    raise exception 'Adresse e-mail invalide.' using errcode = '22023';
  end if;
  if v_phone is not null and v_phone !~ '^\+?[0-9][0-9 .()-]{5,24}$' then
    raise exception 'Numéro de téléphone invalide.' using errcode = '22023';
  end if;
  if v_address is not null
     and (char_length(v_address) not between 5 and 300 or v_address ~ '[[:cntrl:]]') then
    raise exception 'Adresse invalide (une ligne, 5 à 300 caractères).'
      using errcode = '22023';
  end if;
  if v_website is not null
     and (char_length(v_website) > 200 or v_website ~ '[[:space:][:cntrl:]]') then
    raise exception 'Adresse du site invalide.' using errcode = '22023';
  end if;
  if v_registration is not null
     and v_registration !~ '^(W[0-9]{9}|[0-9]{9}|[0-9]{14})$' then
    raise exception 'Numéro invalide : RNA (W + 9 chiffres), SIREN (9 chiffres) ou SIRET (14 chiffres).'
      using errcode = '22023';
  end if;

  update public.club_settings
  set contact_name = v_name,
      contact_email = v_email,
      contact_phone = v_phone,
      postal_address = v_address,
      website = v_website,
      registration_number = v_registration
  where club_id = v_club_id
  returning * into v_saved;

  if not found then
    raise exception 'Réglages du club introuvables.' using errcode = 'P0002';
  end if;

  return jsonb_build_object(
    'contact_name', v_saved.contact_name,
    'contact_email', v_saved.contact_email,
    'contact_phone', v_saved.contact_phone,
    'postal_address', v_saved.postal_address,
    'website', v_saved.website,
    'registration_number', v_saved.registration_number
  );
end;
$$;

alter function public.admin_set_club_contact(text, text, text, text, text, text)
  owner to club_scope;
revoke all on function public.admin_set_club_contact(text, text, text, text, text, text)
  from public, anon;
grant execute on function public.admin_set_club_contact(text, text, text, text, text, text)
  to authenticated, service_role, club_scope;

-- ---------------------------------------------------------------------------
-- 2. Téléphone et date de naissance du membre
-- ---------------------------------------------------------------------------

create table public.profile_private_details (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  club_id uuid not null default private.current_club_id()
    references public.clubs(id) on delete cascade,
  phone text
    constraint profile_private_details_phone_check
      check (phone is null or phone ~ '^\+?[0-9][0-9 .()-]{5,24}$'),
  birth_date date
    constraint profile_private_details_birth_date_check
      check (birth_date is null or birth_date between date '1900-01-01' and current_date),
  updated_at timestamptz not null default now()
);

comment on table public.profile_private_details is
  'Téléphone et date de naissance d''un membre. Visibles par lui seul.';

create index profile_private_details_club_id_idx
  on public.profile_private_details (club_id);

alter table public.profile_private_details enable row level security;
-- Aucun accès direct depuis l'application : uniquement par les deux
-- fonctions ci-dessous, qui ne touchent que la ligne du membre connecté.
revoke all on public.profile_private_details from public, anon, authenticated;
grant all on public.profile_private_details to service_role;
grant select, insert, update, delete on public.profile_private_details to club_scope;

create policy club_isolation on public.profile_private_details
  as restrictive for all to public
  using (club_id = (select private.current_club_id()))
  with check (club_id = (select private.current_club_id()));

create policy active_authenticated_profile_only on public.profile_private_details
  as restrictive for all to authenticated
  using ((select private.is_active_profile()))
  with check ((select private.is_active_profile()));

create policy club_scope_access on public.profile_private_details
  for all to club_scope using (true) with check (true);

create function public.get_my_private_details()
returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_uid uuid := private.uid();
  v_row public.profile_private_details;
begin
  if v_uid is null then
    raise exception 'Connexion requise.' using errcode = '42501';
  end if;

  select * into v_row
  from public.profile_private_details details
  where details.profile_id = v_uid;

  return jsonb_build_object(
    'phone', v_row.phone,
    'birth_date', v_row.birth_date
  );
end;
$$;

alter function public.get_my_private_details() owner to club_scope;
revoke all on function public.get_my_private_details() from public, anon;
grant execute on function public.get_my_private_details() to authenticated;

create function public.set_my_private_details(p_phone text, p_birth_date date)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_uid uuid := private.uid();
  v_phone text := nullif(btrim(p_phone), '');
begin
  if v_uid is null then
    raise exception 'Connexion requise.' using errcode = '42501';
  end if;
  if not (select private.is_active_profile()) then
    raise exception 'Compte inactif.' using errcode = '42501';
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
    where details.profile_id = v_uid;
  else
    insert into public.profile_private_details as details
      (profile_id, phone, birth_date, updated_at)
    values (v_uid, v_phone, p_birth_date, now())
    on conflict (profile_id) do update
      set phone = excluded.phone,
          birth_date = excluded.birth_date,
          updated_at = now();
  end if;

  return jsonb_build_object('phone', v_phone, 'birth_date', p_birth_date);
end;
$$;

alter function public.set_my_private_details(text, date) owner to club_scope;
revoke all on function public.set_my_private_details(text, date) from public, anon;
grant execute on function public.set_my_private_details(text, date) to authenticated;
