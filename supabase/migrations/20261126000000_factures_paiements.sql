-- Une facture pour chaque paiement noté.
--
-- Chaque paiement reçu hors ligne (virement, chèque, espèces) que l'éditeur
-- note crée une facture. Le club la télécharge depuis ses réglages, l'éditeur
-- la retrouve dans sa console avec toutes les autres.
--
-- Règles d'une facture de micro-entreprise :
--   * numéro unique, chronologique et sans trou : PF-2027-0001, 0002…
--     (compteur remis à 1 chaque année, attribué dans la même transaction
--     que l'émission : une émission annulée ne consomme aucun numéro) ;
--   * coordonnées du vendeur (nom, adresse, SIRET, e-mail) et du client
--     (nom, adresse) figées au moment de l'émission ;
--   * une facture émise ne se modifie ni ne se supprime plus, même si le club
--     est supprimé ensuite (conservation 10 ans).
--
-- Tant que les coordonnées du vendeur (dont le SIRET) ou l'adresse du club
-- manquent, la facture reste « en attente » : elle n'a pas de numéro, n'est
-- visible que de l'éditeur (en brouillon), et peut être écartée. L'éditeur
-- l'émet dès que tout est renseigné.

-- ---------------------------------------------------------------------------
-- 1. Coordonnées du vendeur, modifiables depuis la console
-- ---------------------------------------------------------------------------

create table private.invoice_settings (
  singleton boolean primary key default true
    constraint invoice_settings_singleton_check check (singleton),
  seller_name text not null default ''
    constraint invoice_settings_seller_name_check check (char_length(seller_name) <= 120),
  seller_address text not null default ''
    constraint invoice_settings_seller_address_check check (char_length(seller_address) <= 300),
  siret text not null default ''
    constraint invoice_settings_siret_check check (siret = '' or siret ~ '^[0-9]{14}$'),
  contact_email text not null default ''
    constraint invoice_settings_contact_email_check check (char_length(contact_email) <= 254),
  updated_at timestamptz not null default now()
);

comment on table private.invoice_settings is
  'Coordonnées de l''éditeur imprimées sur les factures (ligne unique).';

insert into private.invoice_settings default values;

alter table private.invoice_settings enable row level security;
revoke all on private.invoice_settings from public, anon, authenticated;

-- Compteur de numéros par année d'émission.
create table private.invoice_counters (
  year integer primary key,
  last_number integer not null
    constraint invoice_counters_last_number_check check (last_number > 0)
);

comment on table private.invoice_counters is
  'Dernier numéro de facture attribué pour chaque année.';

alter table private.invoice_counters enable row level security;
revoke all on private.invoice_counters from public, anon, authenticated;

create function private.invoice_settings_ready() returns boolean
language sql stable
set search_path to ''
as $$
  select exists (
    select 1 from private.invoice_settings s
    where btrim(s.seller_name) <> ''
      and btrim(s.seller_address) <> ''
      and s.siret ~ '^[0-9]{14}$'
      and btrim(s.contact_email) <> ''
  )
$$;

revoke all on function private.invoice_settings_ready() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. Coordonnées de facturation du club
-- ---------------------------------------------------------------------------

alter table public.club_subscriptions
  add column billing_name text
    constraint club_subscriptions_billing_name_check
      check (billing_name is null or char_length(btrim(billing_name)) between 2 and 120),
  add column billing_address text
    constraint club_subscriptions_billing_address_check
      check (billing_address is null or char_length(btrim(billing_address)) between 5 and 300);

comment on column public.club_subscriptions.billing_name is
  'Nom du client imprimé sur les factures (nom de l''association) ; à défaut, le nom du club.';
comment on column public.club_subscriptions.billing_address is
  'Adresse du client imprimée sur les factures ; obligatoire pour émettre une facture.';

-- ---------------------------------------------------------------------------
-- 3. Factures
-- ---------------------------------------------------------------------------

create table public.club_invoices (
  id uuid primary key default gen_random_uuid(),
  -- Gardées même si le club ou le paiement disparaît : la facture reste.
  club_id uuid references public.clubs(id) on delete set null,
  payment_id uuid unique references public.club_payments(id) on delete set null,
  status text not null default 'pending'
    constraint club_invoices_status_check check (status in ('pending', 'issued')),
  number text unique,
  issued_on date,
  amount_cents integer not null
    constraint club_invoices_amount_check check (amount_cents between 0 and 1000000),
  payment_method text not null,
  received_on date not null,
  period_start date not null,
  period_end date not null,
  description text not null,
  seller jsonb,
  buyer_name text,
  buyer_address text,
  created_at timestamptz not null default now(),
  constraint club_invoices_issued_check check (
    (status = 'pending' and number is null and issued_on is null)
    or (status = 'issued' and number is not null and issued_on is not null
        and seller is not null and buyer_name is not null and buyer_address is not null)
  )
);

comment on table public.club_invoices is
  'Factures des abonnements payés. Une facture émise est définitive.';

create index club_invoices_club_id_idx on public.club_invoices (club_id, issued_on desc);
create index club_invoices_issued_on_idx on public.club_invoices (issued_on desc);

alter table public.club_invoices enable row level security;
revoke all on public.club_invoices from public, anon, authenticated;
grant select on public.club_invoices to authenticated;
grant all on public.club_invoices to service_role;
grant select on public.club_invoices to club_scope;

-- Lecture par les administrateurs du club, et seulement les factures émises.
-- Aucune écriture par un compte : tout passe par les fonctions de l'éditeur.
create policy club_isolation on public.club_invoices
  as restrictive for all to public
  using (club_id = (select private.current_club_id()))
  with check (club_id = (select private.current_club_id()));
create policy active_authenticated_profile_only on public.club_invoices
  as restrictive for all to authenticated
  using ((select private.is_active_profile()))
  with check ((select private.is_active_profile()));
create policy club_scope_access on public.club_invoices
  for select to club_scope using (true);
create policy club_invoices_admin_read on public.club_invoices
  for select to authenticated
  using (status = 'issued' and (select private.is_admin()));

-- Une facture émise est définitive. Seuls les liens vers le club et le
-- paiement peuvent être vidés (suppression du club).
create function private.protect_issued_invoice() returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if old.status <> 'issued' then
    return case when tg_op = 'DELETE' then old else new end;
  end if;
  if tg_op = 'DELETE' then
    raise exception 'Une facture émise ne peut pas être supprimée.' using errcode = '42501';
  end if;
  if (new.club_id is not null and new.club_id is distinct from old.club_id)
     or (new.payment_id is not null and new.payment_id is distinct from old.payment_id)
     or (to_jsonb(new) - 'club_id' - 'payment_id')
        is distinct from (to_jsonb(old) - 'club_id' - 'payment_id') then
    raise exception 'Une facture émise ne peut pas être modifiée.' using errcode = '42501';
  end if;
  return new;
end;
$$;

revoke all on function private.protect_issued_invoice() from public, anon, authenticated;

create trigger club_invoices_protect_issued
  before update or delete on public.club_invoices
  for each row execute function private.protect_issued_invoice();

-- Jour civil à Paris : les dates imprimées sont celles de la France.
create function private.paris_day(p_at timestamptz) returns date
language sql immutable
set search_path to ''
as $$ select (p_at at time zone 'Europe/Paris')::date $$;

revoke all on function private.paris_day(timestamptz) from public, anon, authenticated;

-- Pourquoi une facture en attente ne peut pas encore être émise, ou null.
create function private.invoice_blocker(p_invoice public.club_invoices) returns text
language sql stable
set search_path to ''
as $$
  select case
    when p_invoice.status = 'issued' then null
    when not private.invoice_settings_ready() then 'seller'
    when p_invoice.club_id is null then 'club_deleted'
    when not exists (
      select 1 from public.club_subscriptions sub
      where sub.club_id = p_invoice.club_id
        and nullif(btrim(sub.billing_address), '') is not null
    ) then 'buyer_address'
    else null
  end
$$;

revoke all on function private.invoice_blocker(public.club_invoices) from public, anon, authenticated;

-- Émet une facture en attente si tout est renseigné ; renvoie son numéro, ou
-- null si elle doit encore attendre.
create function private.issue_invoice(p_invoice_id uuid) returns text
language plpgsql
set search_path to ''
as $$
declare
  v_invoice public.club_invoices;
  v_settings private.invoice_settings;
  v_buyer_name text;
  v_buyer_address text;
  v_day date := private.paris_day(now());
  v_year integer := extract(year from private.paris_day(now()))::integer;
  v_seq integer;
  v_number text;
begin
  select * into v_invoice from public.club_invoices where id = p_invoice_id for update;
  if not found then
    return null;
  end if;
  if v_invoice.status = 'issued' then
    return v_invoice.number;
  end if;
  if private.invoice_blocker(v_invoice) is not null then
    return null;
  end if;

  select * into v_settings from private.invoice_settings;
  select coalesce(nullif(btrim(sub.billing_name), ''), club.name), btrim(sub.billing_address)
  into v_buyer_name, v_buyer_address
  from public.club_subscriptions sub
  join public.clubs club on club.id = sub.club_id
  where sub.club_id = v_invoice.club_id;

  -- Le verrou de la ligne du compteur sérialise les émissions : pas de trou,
  -- pas de doublon.
  insert into private.invoice_counters as counter (year, last_number)
  values (v_year, 1)
  on conflict (year) do update set last_number = counter.last_number + 1
  returning last_number into v_seq;

  v_number := 'PF-' || v_year || '-' || lpad(v_seq::text, 4, '0');

  update public.club_invoices
  set status = 'issued',
      number = v_number,
      issued_on = v_day,
      seller = jsonb_build_object(
        'name', btrim(v_settings.seller_name),
        'address', btrim(v_settings.seller_address),
        'siret', v_settings.siret,
        'email', btrim(v_settings.contact_email)
      ),
      buyer_name = v_buyer_name,
      buyer_address = v_buyer_address
  where id = p_invoice_id;

  return v_number;
end;
$$;

revoke all on function private.issue_invoice(uuid) from public, anon, authenticated;

-- Chaque paiement noté crée sa facture, émise aussitôt si possible.
create function private.create_invoice_for_payment() returns trigger
language plpgsql security definer
set search_path to ''
as $$
declare
  v_id uuid;
  v_club_name text;
begin
  select club.name into v_club_name from public.clubs club where club.id = new.club_id;

  insert into public.club_invoices (
    club_id, payment_id, amount_cents, payment_method, received_on,
    period_start, period_end, description
  ) values (
    new.club_id, new.id, new.amount_cents, new.method, new.received_on,
    private.paris_day(new.period_end - interval '1 year'),
    private.paris_day(new.period_end),
    'Abonnement annuel à l''application PetitFilet pour le club « '
      || coalesce(v_club_name, 'club') || ' »'
  )
  returning id into v_id;

  perform private.issue_invoice(v_id);
  return new;
end;
$$;

alter function private.create_invoice_for_payment() owner to postgres;
revoke all on function private.create_invoice_for_payment() from public, anon, authenticated;

create trigger club_payments_create_invoice
  after insert on public.club_payments
  for each row execute function private.create_invoice_for_payment();

-- Un paiement supprimé emporte sa facture si elle n'est pas encore émise.
create function private.discard_pending_invoice_of_payment() returns trigger
language plpgsql security definer
set search_path to ''
as $$
begin
  delete from public.club_invoices
  where payment_id = old.id and status = 'pending';
  return old;
end;
$$;

alter function private.discard_pending_invoice_of_payment() owner to postgres;
revoke all on function private.discard_pending_invoice_of_payment() from public, anon, authenticated;

create trigger club_payments_discard_pending_invoice
  before delete on public.club_payments
  for each row execute function private.discard_pending_invoice_of_payment();

-- ---------------------------------------------------------------------------
-- 4. Fonctions de la console de l'éditeur
-- ---------------------------------------------------------------------------

create function public.platform_invoice_settings() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_settings private.invoice_settings;
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  select * into v_settings from private.invoice_settings;
  return jsonb_build_object(
    'seller_name', v_settings.seller_name,
    'seller_address', v_settings.seller_address,
    'siret', v_settings.siret,
    'contact_email', v_settings.contact_email,
    'ready', private.invoice_settings_ready()
  );
end;
$$;

create function public.platform_save_invoice_settings(
  p_seller_name text,
  p_seller_address text,
  p_siret text,
  p_contact_email text
) returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_siret text := regexp_replace(coalesce(p_siret, ''), '\s', '', 'g');
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  if v_siret <> '' and v_siret !~ '^[0-9]{14}$' then
    raise exception 'Le SIRET compte 14 chiffres.' using errcode = '22023';
  end if;
  update private.invoice_settings
  set seller_name = btrim(coalesce(p_seller_name, '')),
      seller_address = btrim(coalesce(p_seller_address, '')),
      siret = v_siret,
      contact_email = btrim(coalesce(p_contact_email, '')),
      updated_at = now();
  return public.platform_invoice_settings();
end;
$$;

create function public.platform_set_club_billing_details(
  p_club_id uuid,
  p_billing_name text,
  p_billing_address text
) returns void
language plpgsql security definer
set search_path to ''
as $$
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  update public.club_subscriptions
  set billing_name = nullif(btrim(coalesce(p_billing_name, '')), ''),
      billing_address = nullif(btrim(coalesce(p_billing_address, '')), ''),
      updated_at = now()
  where club_id = p_club_id;
  if not found then
    raise exception 'Club inconnu.' using errcode = 'P0002';
  end if;
end;
$$;

-- Toutes les factures, émises et en attente, pour la console et l'export
-- comptable. Une facture en attente porte les coordonnées actuelles (aperçu).
create function public.platform_list_invoices() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_settings private.invoice_settings;
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  select * into v_settings from private.invoice_settings;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', inv.id,
      'club_id', inv.club_id,
      'status', inv.status,
      'number', inv.number,
      'issued_on', inv.issued_on,
      'amount_cents', inv.amount_cents,
      'payment_method', inv.payment_method,
      'received_on', inv.received_on,
      'period_start', inv.period_start,
      'period_end', inv.period_end,
      'description', inv.description,
      'seller', coalesce(inv.seller, jsonb_build_object(
        'name', btrim(v_settings.seller_name),
        'address', btrim(v_settings.seller_address),
        'siret', v_settings.siret,
        'email', btrim(v_settings.contact_email)
      )),
      'buyer_name', coalesce(inv.buyer_name,
        nullif(btrim(sub.billing_name), ''), club.name),
      'buyer_address', coalesce(inv.buyer_address, nullif(btrim(sub.billing_address), '')),
      'blocker', private.invoice_blocker(inv)
    ) order by inv.status desc, inv.issued_on desc nulls first, inv.number desc,
               inv.received_on desc, inv.created_at desc)
    from public.club_invoices inv
    left join public.clubs club on club.id = inv.club_id
    left join public.club_subscriptions sub on sub.club_id = inv.club_id
  ), '[]'::jsonb);
end;
$$;

-- Émet, dans l'ordre des paiements, toutes les factures qui peuvent l'être.
create function public.platform_issue_pending_invoices() returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_id uuid;
  v_issued integer := 0;
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  for v_id in
    select id from public.club_invoices
    where status = 'pending'
    order by received_on, created_at
  loop
    if private.issue_invoice(v_id) is not null then
      v_issued := v_issued + 1;
    end if;
  end loop;
  return jsonb_build_object(
    'issued', v_issued,
    'pending', (select count(*) from public.club_invoices where status = 'pending')
  );
end;
$$;

-- Écarte une facture en attente (paiement de test, club de démonstration…).
-- Une facture émise ne s'écarte pas.
create function public.platform_discard_pending_invoice(p_invoice_id uuid) returns void
language plpgsql security definer
set search_path to ''
as $$
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  delete from public.club_invoices where id = p_invoice_id and status = 'pending';
  if not found then
    raise exception 'Seule une facture en attente peut être écartée.' using errcode = '42501';
  end if;
end;
$$;

do $$
declare
  v_signature text;
begin
  foreach v_signature in array array[
    'public.platform_invoice_settings()',
    'public.platform_save_invoice_settings(text,text,text,text)',
    'public.platform_set_club_billing_details(uuid,text,text)',
    'public.platform_list_invoices()',
    'public.platform_issue_pending_invoices()',
    'public.platform_discard_pending_invoice(uuid)'
  ] loop
    execute format('alter function %s owner to postgres', v_signature);
    execute format('revoke all on function %s from public, anon', v_signature);
    execute format('grant execute on function %s to authenticated', v_signature);
  end loop;
end;
$$;
