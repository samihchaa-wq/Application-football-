-- Adresse e-mail de contact d'un compte : confirmation par lien, et
-- récupération du mot de passe par e-mail.
--
-- Les comptes se connectent avec un identifiant (prénom + initiale), sans
-- adresse réelle. L'adresse e-mail est donc un complément facultatif : elle ne
-- sert qu'à confirmer l'identité de la personne et à lui envoyer un lien quand
-- elle a perdu son mot de passe. Elle ne devient utilisable pour cela
-- qu'une fois confirmée par un lien.

-- ---------------------------------------------------------------------------
-- 1. Colonnes du profil
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column contact_email text,
  add column contact_email_confirmed_at timestamptz,
  add column pending_contact_email text;

alter table public.profiles
  add constraint profiles_contact_email_format check (
    contact_email is null
    or (
      contact_email = lower(btrim(contact_email))
      and char_length(contact_email) <= 254
      and contact_email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
    )
  ),
  add constraint profiles_pending_contact_email_format check (
    pending_contact_email is null
    or (
      pending_contact_email = lower(btrim(pending_contact_email))
      and char_length(pending_contact_email) <= 254
      and pending_contact_email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
    )
  ),
  -- Une adresse n'est « de contact » que si elle est confirmée.
  add constraint profiles_contact_email_confirmed check (
    (contact_email is null) = (contact_email_confirmed_at is null)
  );

-- Une adresse confirmée n'appartient qu'à un seul compte, tous clubs
-- confondus : c'est elle qui retrouve le compte au moment de la récupération.
-- Une adresse seulement saisie ne bloque personne.
create unique index profiles_contact_email_uidx
  on public.profiles (contact_email)
  where contact_email is not null;

-- ---------------------------------------------------------------------------
-- 2. Liens de confirmation
-- ---------------------------------------------------------------------------
-- Seule l'empreinte du lien est conservée : la base ne permet pas de le
-- reconstituer. Table globale (le lien identifie lui-même le compte).
create table private.email_confirmations (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  email text not null,
  token_hash text not null unique check (token_hash ~ '^[0-9a-f]{64}$'),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '24 hours',
  used_at timestamptz
);
create index email_confirmations_profile_idx on private.email_confirmations (profile_id);
alter table private.email_confirmations enable row level security;
revoke all on private.email_confirmations from public, anon, authenticated;
create policy deny_client_access on private.email_confirmations
  as restrictive to anon, authenticated using (false);

-- Plafond des demandes d'envoi, par origine et par adresse : empêche d'utiliser
-- l'application pour inonder une boîte mail.
create table private.email_attempts (
  id bigint generated always as identity primary key,
  kind text not null check (kind in ('origin', 'email')),
  key_hash text not null check (key_hash ~ '^[0-9a-f]{64}$'),
  attempted_at timestamptz not null default now()
);
create index email_attempts_lookup_idx on private.email_attempts (kind, key_hash, attempted_at);
alter table private.email_attempts enable row level security;
revoke all on private.email_attempts from public, anon, authenticated;
create policy deny_client_access on private.email_attempts
  as restrictive to anon, authenticated using (false);

-- ---------------------------------------------------------------------------
-- 3. Fonctions réservées au serveur d'envoi (clé de service)
-- ---------------------------------------------------------------------------
create function public.consume_email_rate_limit(p_origin_hash text, p_email_hash text)
returns boolean
language plpgsql security definer
set search_path to ''
as $$
declare
  v_origin integer;
  v_email integer;
begin
  if p_origin_hash is null or p_origin_hash !~ '^[0-9a-f]{64}$'
     or p_email_hash is null or p_email_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'Invalid hash' using errcode = '22023';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_origin_hash, 1)
  );

  delete from private.email_attempts where attempted_at < now() - interval '24 hours';

  select count(*)::integer into v_origin
  from private.email_attempts
  where kind = 'origin' and key_hash = p_origin_hash
    and attempted_at >= now() - interval '1 hour';

  select count(*)::integer into v_email
  from private.email_attempts
  where kind = 'email' and key_hash = p_email_hash
    and attempted_at >= now() - interval '1 hour';

  -- 10 demandes par heure et par origine ; 3 par heure et par adresse.
  if v_origin >= 10 or v_email >= 3 then
    return false;
  end if;

  insert into private.email_attempts (kind, key_hash)
  values ('origin', p_origin_hash), ('email', p_email_hash);
  return true;
end;
$$;

-- Enregistre une adresse à confirmer pour un compte. Renvoie vrai quand un
-- lien doit être envoyé ; faux quand l'adresse appartient déjà à un autre
-- compte (rien n'est envoyé, et l'appelant répond comme dans le cas normal :
-- la réponse ne révèle pas si l'adresse est déjà prise).
create function public.request_contact_email(
  p_profile_id uuid,
  p_email text,
  p_token_hash text
) returns boolean
language plpgsql security definer
set search_path to ''
as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
begin
  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
     or char_length(v_email) > 254 then
    raise exception 'Adresse e-mail invalide.' using errcode = '22023';
  end if;

  if not exists (select 1 from public.profiles where id = p_profile_id) then
    raise exception 'Compte introuvable.' using errcode = 'P0002';
  end if;

  if exists (
    select 1 from public.profiles
    where contact_email = v_email and id <> p_profile_id
  ) then
    return false;
  end if;

  -- Déjà confirmée sur ce compte : rien à refaire.
  if exists (
    select 1 from public.profiles
    where id = p_profile_id and contact_email = v_email
  ) then
    update public.profiles set pending_contact_email = null
    where id = p_profile_id and pending_contact_email is not null;
    return false;
  end if;

  update public.profiles
  set pending_contact_email = v_email
  where id = p_profile_id;

  delete from private.email_confirmations
  where profile_id = p_profile_id and used_at is null;

  insert into private.email_confirmations (profile_id, email, token_hash)
  values (p_profile_id, v_email, p_token_hash);
  return true;
end;
$$;

-- Valide un lien de confirmation. Renvoie vrai si l'adresse est désormais
-- confirmée pour le compte.
create function public.confirm_contact_email(p_token_hash text) returns boolean
language plpgsql security definer
set search_path to ''
as $$
declare
  v_row private.email_confirmations;
begin
  select * into v_row
  from private.email_confirmations
  where token_hash = p_token_hash
    and used_at is null
    and expires_at > now()
  for update;

  if v_row.id is null then
    return false;
  end if;

  update private.email_confirmations set used_at = now() where id = v_row.id;

  if exists (
    select 1 from public.profiles
    where contact_email = v_row.email and id <> v_row.profile_id
  ) then
    return false;
  end if;

  update public.profiles
  set contact_email = v_row.email,
      contact_email_confirmed_at = now(),
      pending_contact_email = null
  where id = v_row.profile_id
    and pending_contact_email = v_row.email;

  return found;
end;
$$;

-- Retrouve le compte actif qui a confirmé cette adresse, pour lui envoyer un
-- lien de récupération. Renvoie l'identifiant de connexion technique du compte.
create function public.profile_for_recovery_email(p_email text)
returns table (profile_id uuid, auth_email text)
language sql stable security definer
set search_path to ''
as $$
  select profile.id, profile.email
  from public.profiles profile
  where profile.contact_email = lower(btrim(coalesce(p_email, '')))
    and profile.status = 'active';
$$;

do $$
declare
  v_signature text;
begin
  foreach v_signature in array array[
    'public.consume_email_rate_limit(text,text)',
    'public.request_contact_email(uuid,text,text)',
    'public.confirm_contact_email(text)',
    'public.profile_for_recovery_email(text)'
  ] loop
    execute format('alter function %s owner to postgres', v_signature);
    execute format('revoke all on function %s from public, anon, authenticated', v_signature);
    execute format('grant execute on function %s to service_role', v_signature);
  end loop;
end;
$$;
