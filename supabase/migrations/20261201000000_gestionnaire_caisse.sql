-- Gestionnaire de l'éditeur : registre de caisse, périodes offertes,
-- remboursements et avoirs, réglages de l'offre, suivi de Stripe.
--
-- 1. Paiements : référence (n° de chèque, de virement), détails Stripe
--    (frais, reçu, paiement), montant remboursé.
-- 2. Réglages de l'offre : tarif des nouveaux clubs, parrainage, essai.
-- 3. Périodes offertes : mois gratuits ou essai prolongé, avec un motif.
-- 4. Remboursements et avoirs numérotés (AV-AAAA-NNNN).
-- 5. Suivi de Stripe : événements reçus, alertes (contestation…).
-- 6. Registre de caisse et fiche club détaillée pour la console.
-- 7. Factures : l'adresse postale saisie par le club sert d'adresse de
--    facturation quand l'éditeur n'en a pas saisi.
-- 8. Effacement des clubs impayés : les factures et avoirs sont conservés
--    (obligation de conservation de 10 ans), au lieu d'être supprimés.

-- ---------------------------------------------------------------------------
-- 1. Paiements
-- ---------------------------------------------------------------------------

alter table public.club_payments
  add column reference text
    constraint club_payments_reference_check
      check (reference is null or char_length(reference) between 1 and 120),
  add column stripe_payment_intent_id text unique,
  add column stripe_fee_cents integer
    constraint club_payments_stripe_fee_check
      check (stripe_fee_cents is null or stripe_fee_cents between 0 and 1000000),
  add column stripe_receipt_url text
    constraint club_payments_stripe_receipt_check
      check (stripe_receipt_url is null or stripe_receipt_url ~ '^https://'),
  add column refunded_cents integer not null default 0
    constraint club_payments_refunded_check check (refunded_cents >= 0);

alter table public.club_payments
  add constraint club_payments_refund_limit_check check (refunded_cents <= amount_cents);

comment on column public.club_payments.reference is
  'Référence du paiement : numéro de chèque et banque, référence du virement…';
comment on column public.club_payments.stripe_fee_cents is
  'Frais prélevés par Stripe sur un paiement par carte.';
comment on column public.club_payments.refunded_cents is
  'Montant déjà remboursé sur ce paiement.';

-- ---------------------------------------------------------------------------
-- 2. Réglages de l'offre
-- ---------------------------------------------------------------------------

create table private.billing_settings (
  singleton boolean primary key default true
    constraint billing_settings_singleton_check check (singleton),
  base_price_cents integer not null default 7900
    constraint billing_settings_price_check check (base_price_cents between 0 and 1000000),
  referral_rate_percent integer not null default 5
    constraint billing_settings_rate_check check (referral_rate_percent between 1 and 100),
  referral_cap_percent integer not null default 100
    constraint billing_settings_cap_check check (referral_cap_percent between 1 and 100),
  trial_days integer not null default 30
    constraint billing_settings_trial_check check (trial_days between 0 and 365),
  updated_at timestamptz not null default now()
);

comment on table private.billing_settings is
  'Offre commerciale (ligne unique) : tarif des nouveaux clubs, parrainage, durée de l''essai.';

insert into private.billing_settings default values;

alter table private.billing_settings enable row level security;
revoke all on private.billing_settings from public, anon, authenticated;
grant select on private.billing_settings to club_scope, service_role;
create policy billing_settings_read on private.billing_settings
  for select to club_scope, service_role using (true);

-- Le parrainage suit désormais les réglages (5 % et 100 % par défaut, comme
-- avant). CREATE OR REPLACE conserve propriétaires et droits.
create or replace function private.referral_rate_percent() returns integer
language sql stable set search_path to '' as $$
  select coalesce((select referral_rate_percent from private.billing_settings), 5)
$$;

create or replace function private.referral_cap_percent() returns integer
language sql stable set search_path to '' as $$
  select coalesce((select referral_cap_percent from private.billing_settings), 100)
$$;

-- Nouveau club : essai et tarif tirés des réglages.
create or replace function private.start_club_trial() returns trigger
language plpgsql security definer
set search_path to ''
as $$
declare
  v_settings private.billing_settings;
begin
  perform set_config('app.club_id', new.id::text, true);
  select * into v_settings from private.billing_settings;
  insert into public.club_subscriptions (club_id, trial_ends_at, base_price_cents)
  values (
    new.id,
    now() + make_interval(days => coalesce(v_settings.trial_days, 30)),
    coalesce(v_settings.base_price_cents, 7900)
  )
  on conflict (club_id) do nothing;
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. Périodes offertes
-- ---------------------------------------------------------------------------

create table private.club_grants (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  kind text not null
    constraint club_grants_kind_check check (kind in ('gift', 'trial_extension')),
  months integer not null default 0
    constraint club_grants_months_check check (months between 0 and 36),
  days integer not null default 0
    constraint club_grants_days_check check (days between 0 and 365),
  period_start timestamptz not null,
  period_end timestamptz not null,
  reason text not null
    constraint club_grants_reason_check check (char_length(btrim(reason)) between 2 and 300),
  granted_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint club_grants_length_check check (months > 0 or days > 0)
);

comment on table private.club_grants is
  'Périodes offertes par l''éditeur (mois gratuits, essai prolongé), avec leur motif.';

create index club_grants_club_id_idx on private.club_grants (club_id, created_at desc);

alter table private.club_grants enable row level security;
revoke all on private.club_grants from public, anon, authenticated;
grant all on private.club_grants to service_role;
create policy club_isolation on private.club_grants
  as restrictive for all to public
  using (club_id = (select private.current_club_id()))
  with check (club_id = (select private.current_club_id()));
create policy club_scope_access on private.club_grants
  for all to club_scope using (true) with check (true);

-- ---------------------------------------------------------------------------
-- 4. Remboursements et avoirs
-- ---------------------------------------------------------------------------

create table private.club_refunds (
  id uuid primary key default gen_random_uuid(),
  -- Gardés si le club ou le paiement disparaît : l'avoir reste.
  club_id uuid references public.clubs(id) on delete set null,
  payment_id uuid references public.club_payments(id) on delete set null,
  invoice_id uuid references public.club_invoices(id) on delete set null,
  amount_cents integer not null
    constraint club_refunds_amount_check check (amount_cents between 1 and 1000000),
  method text not null
    constraint club_refunds_method_check
      check (method in ('carte', 'virement', 'cheque', 'especes', 'autre')),
  reason text
    constraint club_refunds_reason_check check (reason is null or char_length(reason) <= 300),
  stripe_refund_id text unique,
  refunded_on date not null default private.paris_day(now()),
  credit_note_number text unique,
  credit_note_issued_on date,
  invoice_number text,
  buyer_name text,
  recorded_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint club_refunds_credit_note_check check (
    (credit_note_number is null and credit_note_issued_on is null)
    or (credit_note_number is not null and credit_note_issued_on is not null
        and invoice_number is not null))
);

comment on table private.club_refunds is
  'Remboursements (carte via Stripe, ou hors ligne) et avoirs correspondants.';

create index club_refunds_club_id_idx on private.club_refunds (club_id, created_at desc);
create index club_refunds_payment_id_idx on private.club_refunds (payment_id);

alter table private.club_refunds enable row level security;
revoke all on private.club_refunds from public, anon, authenticated;
grant all on private.club_refunds to service_role;
create policy club_isolation on private.club_refunds
  as restrictive for all to public
  using (club_id = (select private.current_club_id()))
  with check (club_id = (select private.current_club_id()));
create policy club_scope_access on private.club_refunds
  for all to club_scope using (true) with check (true);

create table private.credit_note_counters (
  year integer primary key,
  last_number integer not null
    constraint credit_note_counters_last_check check (last_number > 0)
);

comment on table private.credit_note_counters is
  'Dernier numéro d''avoir attribué pour chaque année.';

alter table private.credit_note_counters enable row level security;
revoke all on private.credit_note_counters from public, anon, authenticated;

-- Attribue un numéro d'avoir si la facture du paiement est émise. Sinon
-- l'avoir attend l'émission de la facture.
create function private.issue_credit_note(p_refund_id uuid) returns text
language plpgsql
set search_path to ''
as $$
declare
  v_refund private.club_refunds;
  v_invoice public.club_invoices;
  v_year integer := extract(year from private.paris_day(now()))::integer;
  v_seq integer;
  v_number text;
begin
  select * into v_refund from private.club_refunds where id = p_refund_id for update;
  if not found then
    return null;
  end if;
  if v_refund.credit_note_number is not null then
    return v_refund.credit_note_number;
  end if;

  select * into v_invoice from public.club_invoices
  where id = v_refund.invoice_id
     or (v_refund.invoice_id is null and payment_id = v_refund.payment_id)
  limit 1;
  if not found or v_invoice.status <> 'issued' then
    return null;
  end if;

  insert into private.credit_note_counters as counter (year, last_number)
  values (v_year, 1)
  on conflict (year) do update set last_number = counter.last_number + 1
  returning last_number into v_seq;

  v_number := 'AV-' || v_year || '-' || lpad(v_seq::text, 4, '0');

  update private.club_refunds
  set credit_note_number = v_number,
      credit_note_issued_on = private.paris_day(now()),
      invoice_id = v_invoice.id,
      invoice_number = v_invoice.number,
      buyer_name = v_invoice.buyer_name
  where id = p_refund_id;

  return v_number;
end;
$$;

revoke all on function private.issue_credit_note(uuid) from public, anon, authenticated;

-- Effet d'un remboursement, quel que soit le moyen. Idempotent par
-- identifiant Stripe.
create function private.apply_refund(
  p_payment_id uuid,
  p_amount_cents integer,
  p_method text,
  p_reason text,
  p_stripe_refund_id text,
  p_recorded_by uuid
) returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_payment public.club_payments;
  v_existing private.club_refunds;
  v_id uuid;
  v_note text;
begin
  if p_stripe_refund_id is not null then
    select * into v_existing from private.club_refunds
    where stripe_refund_id = p_stripe_refund_id;
    if found then
      return jsonb_build_object('refund_id', v_existing.id, 'already_recorded', true,
        'credit_note_number', v_existing.credit_note_number);
    end if;
  end if;

  select * into v_payment from public.club_payments where id = p_payment_id for update;
  if not found then
    raise exception 'Paiement inconnu.' using errcode = 'P0002';
  end if;
  if p_amount_cents is null or p_amount_cents < 1
     or p_amount_cents > v_payment.amount_cents - v_payment.refunded_cents then
    raise exception 'Montant à rembourser invalide (au plus % centimes).',
      v_payment.amount_cents - v_payment.refunded_cents using errcode = '22023';
  end if;
  if p_method is null or p_method not in ('carte', 'virement', 'cheque', 'especes', 'autre') then
    raise exception 'Moyen de remboursement invalide.' using errcode = '22023';
  end if;
  if p_reason is not null and char_length(p_reason) > 300 then
    raise exception 'Motif trop long (300 caractères au plus).' using errcode = '22023';
  end if;

  insert into private.club_refunds (
    club_id, payment_id, invoice_id, amount_cents, method, reason,
    stripe_refund_id, recorded_by
  ) values (
    v_payment.club_id, v_payment.id,
    (select id from public.club_invoices where payment_id = v_payment.id limit 1),
    p_amount_cents, p_method, nullif(btrim(coalesce(p_reason, '')), ''),
    p_stripe_refund_id, p_recorded_by
  )
  returning id into v_id;

  update public.club_payments
  set refunded_cents = refunded_cents + p_amount_cents
  where id = v_payment.id;

  v_note := private.issue_credit_note(v_id);

  return jsonb_build_object('refund_id', v_id, 'already_recorded', false,
    'credit_note_number', v_note);
end;
$$;

alter function private.apply_refund(uuid, integer, text, text, text, uuid) owner to postgres;
revoke all on function private.apply_refund(uuid, integer, text, text, text, uuid)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 5. Suivi de Stripe
-- ---------------------------------------------------------------------------

create table private.stripe_events (
  id text primary key,
  type text not null,
  livemode boolean not null default false,
  ok boolean not null default true,
  error text constraint stripe_events_error_check check (char_length(error) <= 500),
  received_at timestamptz not null default now()
);

comment on table private.stripe_events is
  'Événements reçus de Stripe : type, mode réel ou test, traitement réussi ou non.';

create index stripe_events_received_at_idx on private.stripe_events (received_at desc);

alter table private.stripe_events enable row level security;
revoke all on private.stripe_events from public, anon, authenticated;

create table private.payment_alerts (
  id uuid primary key default gen_random_uuid(),
  kind text not null
    constraint payment_alerts_kind_check
      check (kind in ('dispute', 'refund_unmatched', 'payment_failed', 'other')),
  stripe_object_id text unique,
  club_name text,
  amount_cents integer,
  message text not null constraint payment_alerts_message_check check (char_length(message) <= 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references auth.users(id) on delete set null
);

comment on table private.payment_alerts is
  'Alertes de paiement à traiter par l''éditeur (contestation de carte…).';

alter table private.payment_alerts enable row level security;
revoke all on private.payment_alerts from public, anon, authenticated;

-- Traces de la fonction stripe-webhook (service_role).
create function public.stripe_log_event(
  p_event_id text,
  p_type text,
  p_livemode boolean,
  p_ok boolean,
  p_error text default null
) returns void
language plpgsql security definer
set search_path to ''
as $$
begin
  if coalesce(private.jwt() ->> 'role', '') <> 'service_role' then
    raise exception 'Réservé au serveur.' using errcode = '42501';
  end if;
  insert into private.stripe_events (id, type, livemode, ok, error)
  values (left(p_event_id, 255), left(coalesce(p_type, ''), 120), coalesce(p_livemode, false),
          coalesce(p_ok, true), left(p_error, 500))
  on conflict (id) do update
    set ok = excluded.ok, error = excluded.error, received_at = now();
end;
$$;

-- Détails d'un paiement par carte connus après coup : identifiant du
-- paiement Stripe, frais, reçu.
create function public.stripe_attach_card_details(
  p_session_id text,
  p_payment_intent_id text,
  p_fee_cents integer,
  p_receipt_url text
) returns void
language plpgsql security definer
set search_path to ''
as $$
begin
  if coalesce(private.jwt() ->> 'role', '') <> 'service_role' then
    raise exception 'Réservé au serveur.' using errcode = '42501';
  end if;
  update public.club_payments
  set stripe_payment_intent_id = coalesce(nullif(p_payment_intent_id, ''), stripe_payment_intent_id),
      stripe_fee_cents = case when p_fee_cents between 0 and 1000000
                              then p_fee_cents else stripe_fee_cents end,
      stripe_receipt_url = case when p_receipt_url ~ '^https://'
                                then p_receipt_url else stripe_receipt_url end
  where stripe_checkout_session_id = p_session_id;
end;
$$;

-- Remboursement fait dans Stripe (depuis le tableau de bord Stripe ou par la
-- console) : enregistré une seule fois.
create function public.stripe_record_refund(
  p_payment_intent_id text,
  p_refund_id text,
  p_amount_cents integer,
  p_reason text
) returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_payment public.club_payments;
begin
  if coalesce(private.jwt() ->> 'role', '') <> 'service_role' then
    raise exception 'Réservé au serveur.' using errcode = '42501';
  end if;
  if exists (select 1 from private.club_refunds where stripe_refund_id = p_refund_id) then
    return jsonb_build_object('already_recorded', true);
  end if;
  select * into v_payment from public.club_payments
  where stripe_payment_intent_id = p_payment_intent_id;
  if not found then
    insert into private.payment_alerts (kind, stripe_object_id, amount_cents, message)
    values ('refund_unmatched', p_refund_id, p_amount_cents,
            'Remboursement Stripe sans paiement correspondant dans l''appli.')
    on conflict (stripe_object_id) do nothing;
    return jsonb_build_object('matched', false);
  end if;
  return private.apply_refund(v_payment.id, p_amount_cents, 'carte',
    coalesce(nullif(p_reason, ''), 'Remboursement Stripe'), p_refund_id, null);
end;
$$;

-- Contestation (litige) d'un paiement par carte : alerte pour l'éditeur.
create function public.stripe_record_dispute(
  p_dispute_id text,
  p_payment_intent_id text,
  p_amount_cents integer,
  p_reason text,
  p_status text
) returns void
language plpgsql security definer
set search_path to ''
as $$
declare
  v_club text;
begin
  if coalesce(private.jwt() ->> 'role', '') <> 'service_role' then
    raise exception 'Réservé au serveur.' using errcode = '42501';
  end if;
  select club.name into v_club
  from public.club_payments payment
  join public.clubs club on club.id = payment.club_id
  where payment.stripe_payment_intent_id = p_payment_intent_id;

  insert into private.payment_alerts (kind, stripe_object_id, club_name, amount_cents, message)
  values ('dispute', p_dispute_id, v_club, p_amount_cents,
          left('Contestation de carte (' || coalesce(p_reason, 'motif inconnu') || ') : '
               || coalesce(p_status, 'ouverte') || '.', 500))
  on conflict (stripe_object_id) do update
    set message = excluded.message,
        updated_at = now(),
        -- Une contestation qui évolue redevient à traiter.
        resolved_at = null,
        resolved_by = null;
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. Console : actions et lectures
-- ---------------------------------------------------------------------------

-- Paiement reçu hors ligne, avec sa référence.
create function public.platform_record_manual_payment(
  p_club_id uuid,
  p_amount_cents integer,
  p_method text,
  p_received_on date,
  p_note text default null,
  p_reference text default null
) returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_result jsonb;
  v_reference text := nullif(btrim(coalesce(p_reference, '')), '');
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  if v_reference is not null and char_length(v_reference) > 120 then
    raise exception 'Référence trop longue (120 caractères au plus).' using errcode = '22023';
  end if;

  v_result := public.platform_record_offline_payment(
    p_club_id, p_amount_cents, p_method, p_received_on, p_note);

  if v_reference is not null then
    update public.club_payments
    set reference = v_reference
    where id = (
      select id from public.club_payments
      where club_id = p_club_id
      order by created_at desc
      limit 1
    );
  end if;
  return v_result;
end;
$$;

-- Offrir des mois gratuits, ou prolonger l'essai d'un club qui y est encore.
create function public.platform_grant_free_period(
  p_club_id uuid,
  p_months integer,
  p_days integer,
  p_reason text
) returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_sub public.club_subscriptions;
  v_months integer := coalesce(p_months, 0);
  v_days integer := coalesce(p_days, 0);
  v_reason text := btrim(coalesce(p_reason, ''));
  v_kind text;
  v_from timestamptz;
  v_to timestamptz;
  v_reopened boolean := false;
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  if v_months not between 0 and 36 or v_days not between 0 and 365
     or (v_months = 0 and v_days = 0) then
    raise exception 'Durée invalide.' using errcode = '22023';
  end if;
  if char_length(v_reason) not between 2 and 300 then
    raise exception 'Indique un motif (2 à 300 caractères).' using errcode = '22023';
  end if;

  select * into v_sub from public.club_subscriptions where club_id = p_club_id for update;
  if not found then
    raise exception 'Club inconnu.' using errcode = 'P0002';
  end if;

  v_kind := case when v_sub.status = 'trialing' then 'trial_extension' else 'gift' end;
  v_from := greatest(
    now(),
    case when v_sub.status = 'trialing' then v_sub.trial_ends_at end,
    case when v_sub.status = 'active' then v_sub.current_period_end end
  );
  v_to := v_from + make_interval(months => v_months, days => v_days);

  if v_kind = 'trial_extension' then
    update public.club_subscriptions
    set trial_ends_at = v_to, auto_suspended_at = null, updated_at = now()
    where club_id = p_club_id;
  else
    update public.club_subscriptions
    set status = 'active', current_period_end = v_to,
        auto_suspended_at = null, updated_at = now()
    where club_id = p_club_id;
  end if;

  -- Comme un paiement : seule une suspension pour impayé est levée.
  if v_sub.auto_suspended_at is not null then
    update public.clubs set status = 'active'
    where id = p_club_id and status = 'suspended';
    v_reopened := found;
  end if;

  insert into private.club_grants (
    club_id, kind, months, days, period_start, period_end, reason, granted_by
  ) values (
    p_club_id, v_kind, v_months, v_days, v_from, v_to, v_reason, private.uid()
  );

  return jsonb_build_object('kind', v_kind, 'period_end', v_to, 'reopened', v_reopened);
end;
$$;

-- Remboursement hors ligne (chèque, virement…), noté par l'éditeur.
create function public.platform_record_refund(
  p_payment_id uuid,
  p_amount_cents integer,
  p_method text,
  p_reason text,
  p_stripe_refund_id text default null
) returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_method text;
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  select method into v_method from public.club_payments where id = p_payment_id;
  if not found then
    raise exception 'Paiement inconnu.' using errcode = 'P0002';
  end if;
  -- Une carte se rembourse par Stripe (identifiant obligatoire).
  if (p_method = 'carte') <> (p_stripe_refund_id is not null) then
    raise exception 'Un remboursement par carte passe par Stripe.' using errcode = '22023';
  end if;
  return private.apply_refund(p_payment_id, p_amount_cents, p_method, p_reason,
    p_stripe_refund_id, private.uid());
end;
$$;

-- Contrôle avant un remboursement par carte (fonction stripe-refund, au nom
-- de l'éditeur) : renvoie le paiement Stripe et le montant remboursable.
create function public.platform_prepare_card_refund(
  p_payment_id uuid,
  p_amount_cents integer
) returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_payment public.club_payments;
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  select * into v_payment from public.club_payments where id = p_payment_id;
  if not found then
    raise exception 'Paiement inconnu.' using errcode = 'P0002';
  end if;
  if v_payment.method <> 'carte' or v_payment.stripe_payment_intent_id is null then
    raise exception 'Ce paiement n''a pas été fait par carte via Stripe.' using errcode = '22023';
  end if;
  if p_amount_cents is null or p_amount_cents < 1
     or p_amount_cents > v_payment.amount_cents - v_payment.refunded_cents then
    raise exception 'Montant à rembourser invalide.' using errcode = '22023';
  end if;
  return jsonb_build_object(
    'payment_intent_id', v_payment.stripe_payment_intent_id,
    'refundable_cents', v_payment.amount_cents - v_payment.refunded_cents
  );
end;
$$;

-- Alertes non traitées et état des confirmations Stripe.
create function public.platform_payment_alerts() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'alerts', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', alert.id, 'kind', alert.kind, 'club_name', alert.club_name,
        'amount_cents', alert.amount_cents, 'message', alert.message,
        'created_at', alert.created_at, 'updated_at', alert.updated_at
      ) order by alert.updated_at desc)
      from private.payment_alerts alert
      where alert.resolved_at is null
    ), '[]'::jsonb),
    'stripe', jsonb_build_object(
      'last_event_at', (select max(received_at) from private.stripe_events),
      'last_livemode', (select livemode from private.stripe_events
                        order by received_at desc limit 1),
      'events_7d', (select count(*) from private.stripe_events
                    where received_at > now() - interval '7 days'),
      'failures_7d', (select count(*) from private.stripe_events
                      where not ok and received_at > now() - interval '7 days'),
      'last_failure', (select jsonb_build_object('type', type, 'error', error,
                         'received_at', received_at)
                       from private.stripe_events where not ok
                       order by received_at desc limit 1)
    ),
    'card_payments_7d', coalesce((
      select jsonb_agg(jsonb_build_object(
        'club_id', payment.club_id, 'club_name', club.name,
        'amount_cents', payment.amount_cents, 'received_on', payment.received_on,
        'created_at', payment.created_at
      ) order by payment.created_at desc)
      from public.club_payments payment
      join public.clubs club on club.id = payment.club_id
      where payment.method = 'carte'
        and payment.created_at > now() - interval '7 days'
    ), '[]'::jsonb),
    'pending_invoices', (select count(*) from public.club_invoices where status = 'pending'),
    'pending_credit_notes', (select count(*) from private.club_refunds
                             where credit_note_number is null)
  );
end;
$$;

create function public.platform_resolve_alert(p_alert_id uuid) returns void
language plpgsql security definer
set search_path to ''
as $$
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  update private.payment_alerts
  set resolved_at = now(), resolved_by = private.uid()
  where id = p_alert_id and resolved_at is null;
  if not found then
    raise exception 'Alerte inconnue ou déjà traitée.' using errcode = 'P0002';
  end if;
end;
$$;

-- Réglages de l'offre.
create function public.platform_billing_settings() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_settings private.billing_settings;
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  select * into v_settings from private.billing_settings;
  return jsonb_build_object(
    'base_price_cents', v_settings.base_price_cents,
    'referral_rate_percent', v_settings.referral_rate_percent,
    'referral_cap_percent', v_settings.referral_cap_percent,
    'trial_days', v_settings.trial_days,
    'updated_at', v_settings.updated_at
  );
end;
$$;

create function public.platform_save_billing_settings(
  p_base_price_cents integer,
  p_referral_rate_percent integer,
  p_referral_cap_percent integer,
  p_trial_days integer
) returns jsonb
language plpgsql security definer
set search_path to ''
as $$
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  if p_base_price_cents is null or p_base_price_cents not between 0 and 1000000
     or p_referral_rate_percent is null or p_referral_rate_percent not between 1 and 100
     or p_referral_cap_percent is null or p_referral_cap_percent not between 1 and 100
     or p_referral_rate_percent > p_referral_cap_percent
     or p_trial_days is null or p_trial_days not between 0 and 365 then
    raise exception 'Réglages invalides.' using errcode = '22023';
  end if;
  update private.billing_settings
  set base_price_cents = p_base_price_cents,
      referral_rate_percent = p_referral_rate_percent,
      referral_cap_percent = p_referral_cap_percent,
      trial_days = p_trial_days,
      updated_at = now();
  return public.platform_billing_settings();
end;
$$;

-- Tarif propre à un club (devis particulier) et note interne.
create function public.platform_set_club_terms(
  p_club_id uuid,
  p_base_price_cents integer,
  p_notes text
) returns void
language plpgsql security definer
set search_path to ''
as $$
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  if p_base_price_cents is null or p_base_price_cents not between 0 and 1000000 then
    raise exception 'Tarif invalide.' using errcode = '22023';
  end if;
  if p_notes is not null and char_length(p_notes) > 2000 then
    raise exception 'Note trop longue (2000 caractères au plus).' using errcode = '22023';
  end if;
  update public.club_subscriptions
  set base_price_cents = p_base_price_cents,
      notes = nullif(btrim(coalesce(p_notes, '')), ''),
      updated_at = now()
  where club_id = p_club_id;
  if not found then
    raise exception 'Club inconnu.' using errcode = 'P0002';
  end if;
end;
$$;

-- Suspendre ou rouvrir un club à la main.
create function public.platform_set_club_access(p_club_id uuid, p_suspended boolean)
returns void
language plpgsql security definer
set search_path to ''
as $$
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  update public.clubs
  set status = case when p_suspended then 'suspended' else 'active' end
  where id = p_club_id;
  if not found then
    raise exception 'Club inconnu.' using errcode = 'P0002';
  end if;
  -- Une suspension à la main n'est pas une suspension pour impayé : elle ne
  -- sera levée ni par un paiement ni automatiquement.
  update public.club_subscriptions
  set auto_suspended_at = null, updated_at = now()
  where club_id = p_club_id;
end;
$$;

-- Fiche de facturation complète d'un club. Reprise de 20261127010000 ;
-- ajoute l'état de l'abonnement, les coordonnées, les détails de chaque
-- paiement, les remboursements et les périodes offertes.
create or replace function public.platform_club_billing(p_club_id uuid) returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_sub public.club_subscriptions;
  v_settings public.club_settings;
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;

  select * into v_sub
  from public.club_subscriptions sub
  where sub.club_id = p_club_id;
  if not found then
    raise exception 'Club inconnu.' using errcode = 'P0002';
  end if;
  select * into v_settings from public.club_settings where club_id = p_club_id;

  return jsonb_build_object(
    'subscription_status', v_sub.status,
    'trial_ends_at', v_sub.trial_ends_at,
    'current_period_end', v_sub.current_period_end,
    'notes', v_sub.notes,
    'base_price_cents', v_sub.base_price_cents,
    'referral_discount_percent', private.club_referral_discount_percent(p_club_id),
    'amount_due_cents', private.club_amount_due_cents(p_club_id),
    'suspension_on', private.club_suspension_due_at(
      v_sub.status, v_sub.trial_ends_at, v_sub.current_period_end),
    'auto_suspended_at', v_sub.auto_suspended_at,
    'billing_name', v_sub.billing_name,
    'billing_address', v_sub.billing_address,
    'contact', jsonb_build_object(
      'name', v_settings.contact_name,
      'email', v_settings.contact_email,
      'phone', v_settings.contact_phone,
      'postal_address', v_settings.postal_address,
      'website', v_settings.website,
      'registration_number', v_settings.registration_number
    ),
    'admins', coalesce((
      select jsonb_agg(jsonb_build_object(
        'name', btrim(profile.first_name || ' ' || profile.last_name),
        'email', profile.contact_email
      ) order by profile.first_name, profile.last_name)
      from public.profiles profile
      where profile.club_id = p_club_id
        and profile.role = 'admin'
        and profile.status = 'active'
    ), '[]'::jsonb),
    'payments', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', payment.id,
        'amount_cents', payment.amount_cents,
        'method', payment.method,
        'received_on', payment.received_on,
        'period_end', payment.period_end,
        'note', payment.note,
        'reference', payment.reference,
        'stripe_fee_cents', payment.stripe_fee_cents,
        'stripe_receipt_url', payment.stripe_receipt_url,
        'refunded_cents', payment.refunded_cents,
        'refundable_by_card', payment.method = 'carte'
          and payment.stripe_payment_intent_id is not null,
        'invoice_number', invoice.number,
        'invoice_status', invoice.status
      ) order by payment.received_on desc, payment.created_at desc)
      from (
        select * from public.club_payments
        where club_id = p_club_id
        order by received_on desc, created_at desc
        limit 50
      ) payment
      left join public.club_invoices invoice on invoice.payment_id = payment.id
    ), '[]'::jsonb),
    'refunds', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', refund.id,
        'payment_id', refund.payment_id,
        'amount_cents', refund.amount_cents,
        'method', refund.method,
        'reason', refund.reason,
        'refunded_on', refund.refunded_on,
        'credit_note_number', refund.credit_note_number
      ) order by refund.created_at desc)
      from private.club_refunds refund
      where refund.club_id = p_club_id
    ), '[]'::jsonb),
    'grants', coalesce((
      select jsonb_agg(jsonb_build_object(
        'kind', grant_row.kind,
        'months', grant_row.months,
        'days', grant_row.days,
        'period_start', grant_row.period_start,
        'period_end', grant_row.period_end,
        'reason', grant_row.reason,
        'created_at', grant_row.created_at
      ) order by grant_row.created_at desc)
      from private.club_grants grant_row
      where grant_row.club_id = p_club_id
    ), '[]'::jsonb)
  );
end;
$$;

-- Registre de caisse : encaissements, remboursements et périodes offertes
-- d'une période, avec les totaux.
create function public.platform_ledger(p_from date, p_to date) returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_entries jsonb;
  v_totals jsonb;
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  if p_from is null or p_to is null or p_to < p_from or p_to - p_from > 3700 then
    raise exception 'Période invalide.' using errcode = '22023';
  end if;

  with entries as (
    select
      'payment'::text as kind,
      payment.id,
      payment.received_on as day,
      payment.created_at,
      payment.club_id,
      coalesce(club.name, invoice.buyer_name, 'Club supprimé') as club_name,
      payment.amount_cents as amount_cents,
      payment.method,
      payment.reference,
      payment.note as label,
      coalesce(payment.stripe_fee_cents, 0) as fee_cents,
      payment.refunded_cents,
      payment.stripe_receipt_url as receipt_url,
      invoice.number as document_number,
      invoice.status as document_status,
      null::text as period_label
    from public.club_payments payment
    left join public.clubs club on club.id = payment.club_id
    left join public.club_invoices invoice on invoice.payment_id = payment.id
    where payment.received_on between p_from and p_to
    union all
    select
      'refund', refund.id, refund.refunded_on, refund.created_at, refund.club_id,
      coalesce(club.name, refund.buyer_name, 'Club supprimé'),
      -refund.amount_cents, refund.method, null, refund.reason,
      0, 0, null, refund.credit_note_number,
      case when refund.credit_note_number is null then 'pending' else 'issued' end,
      refund.invoice_number
    from private.club_refunds refund
    left join public.clubs club on club.id = refund.club_id
    where refund.refunded_on between p_from and p_to
    union all
    select
      'gift', grant_row.id, private.paris_day(grant_row.created_at), grant_row.created_at,
      grant_row.club_id, coalesce(club.name, 'Club supprimé'),
      0, null, null, grant_row.reason, 0, 0, null, null, null,
      case
        when grant_row.months > 0 and grant_row.days > 0
          then grant_row.months || ' mois et ' || grant_row.days || ' j'
        when grant_row.months > 0 then grant_row.months || ' mois'
        else grant_row.days || ' j'
      end
        || case when grant_row.kind = 'trial_extension' then ' d''essai' else ' offerts' end
        || ', jusqu''au ' || to_char(private.paris_day(grant_row.period_end), 'DD/MM/YYYY')
    from private.club_grants grant_row
    left join public.clubs club on club.id = grant_row.club_id
    where private.paris_day(grant_row.created_at) between p_from and p_to
  )
  select
    coalesce(jsonb_agg(jsonb_build_object(
      'kind', e.kind, 'id', e.id, 'day', e.day, 'club_id', e.club_id,
      'club_name', e.club_name, 'amount_cents', e.amount_cents, 'method', e.method,
      'reference', e.reference, 'label', e.label, 'fee_cents', e.fee_cents,
      'refunded_cents', e.refunded_cents, 'receipt_url', e.receipt_url,
      'document_number', e.document_number, 'document_status', e.document_status,
      'period_label', e.period_label
    ) order by e.day desc, e.created_at desc), '[]'::jsonb),
    jsonb_build_object(
      'collected_cents', coalesce(sum(e.amount_cents) filter (where e.kind = 'payment'), 0),
      'refunded_cents', coalesce(-sum(e.amount_cents) filter (where e.kind = 'refund'), 0),
      'fees_cents', coalesce(sum(e.fee_cents), 0),
      'net_cents', coalesce(sum(e.amount_cents) - sum(e.fee_cents), 0),
      'payments', count(*) filter (where e.kind = 'payment'),
      'refunds', count(*) filter (where e.kind = 'refund'),
      'gifts', count(*) filter (where e.kind = 'gift'),
      'by_method', coalesce((
        select jsonb_object_agg(method, total)
        from (
          select e2.method, sum(e2.amount_cents) as total
          from entries e2
          where e2.kind = 'payment'
          group by e2.method
        ) per_method
      ), '{}'::jsonb)
    )
  into v_entries, v_totals
  from entries e;

  return jsonb_build_object('from', p_from, 'to', p_to,
    'entries', v_entries, 'totals', v_totals);
end;
$$;

-- Avoirs pour l'export et les PDF.
create function public.platform_list_credit_notes() returns jsonb
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
      'id', refund.id,
      'number', refund.credit_note_number,
      'issued_on', refund.credit_note_issued_on,
      'refunded_on', refund.refunded_on,
      'amount_cents', refund.amount_cents,
      'method', refund.method,
      'reason', refund.reason,
      'invoice_number', refund.invoice_number,
      'buyer_name', coalesce(refund.buyer_name, invoice.buyer_name),
      'buyer_address', invoice.buyer_address,
      'seller', coalesce(invoice.seller, jsonb_build_object(
        'name', btrim(v_settings.seller_name),
        'address', btrim(v_settings.seller_address),
        'siret', v_settings.siret,
        'email', btrim(v_settings.contact_email)
      ))
    ) order by refund.credit_note_issued_on desc nulls first, refund.credit_note_number desc)
    from private.club_refunds refund
    left join public.club_invoices invoice on invoice.id = refund.invoice_id
  ), '[]'::jsonb);
end;
$$;

-- ---------------------------------------------------------------------------
-- 7. Factures : adresse postale du club en secours
-- ---------------------------------------------------------------------------

-- Adresse de facturation du club : celle saisie par l'éditeur, sinon
-- l'adresse postale renseignée par le club dans ses réglages.
create function private.club_billing_address(p_club_id uuid) returns text
language sql stable
set search_path to ''
as $$
  select coalesce(
    nullif(btrim((select billing_address from public.club_subscriptions where club_id = p_club_id)), ''),
    nullif(btrim((select postal_address from public.club_settings where club_id = p_club_id)), '')
  )
$$;

revoke all on function private.club_billing_address(uuid) from public, anon, authenticated;

create or replace function private.invoice_blocker(p_invoice public.club_invoices) returns text
language sql stable
set search_path to ''
as $$
  select case
    when p_invoice.status = 'issued' then null
    when not private.invoice_settings_ready() then 'seller'
    when p_invoice.club_id is null then 'club_deleted'
    when private.club_billing_address(p_invoice.club_id) is null then 'buyer_address'
    else null
  end
$$;

create or replace function private.issue_invoice(p_invoice_id uuid) returns text
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
  select coalesce(nullif(btrim(sub.billing_name), ''), club.name)
  into v_buyer_name
  from public.club_subscriptions sub
  join public.clubs club on club.id = sub.club_id
  where sub.club_id = v_invoice.club_id;
  v_buyer_address := private.club_billing_address(v_invoice.club_id);

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

  -- Un avoir en attente de cette facture peut maintenant être numéroté.
  perform private.issue_credit_note(refund.id)
  from private.club_refunds refund
  where refund.credit_note_number is null
    and (refund.invoice_id = p_invoice_id
         or (refund.invoice_id is null and refund.payment_id = v_invoice.payment_id));

  return v_number;
end;
$$;

create or replace function public.platform_list_invoices() returns jsonb
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
      'buyer_address', coalesce(inv.buyer_address, private.club_billing_address(inv.club_id)),
      'blocker', private.invoice_blocker(inv)
    ) order by inv.status desc, inv.issued_on desc nulls first, inv.number desc,
               inv.received_on desc, inv.created_at desc)
    from public.club_invoices inv
    left join public.clubs club on club.id = inv.club_id
    left join public.club_subscriptions sub on sub.club_id = inv.club_id
  ), '[]'::jsonb);
end;
$$;

-- ---------------------------------------------------------------------------
-- 8. Effacement des clubs impayés : factures et avoirs conservés
-- ---------------------------------------------------------------------------

-- Reprise de 20261127020000. Les factures (public.club_invoices) et les
-- avoirs (private.club_refunds) ne sont plus supprimés avec le club : leur
-- lien vers le club est simplement vidé. Ils gardent tout ce qu'il faut
-- (numéro, montants, client figé) pour la conservation légale de 10 ans.
create or replace function private.purge_expired_clubs(p_now timestamptz default now()) returns integer
language plpgsql security definer
set search_path to ''
as $$
declare
  v_clubs uuid[];
  v_users uuid[];
  v_table record;
begin
  select coalesce(array_agg(club.id), '{}') into v_clubs
  from public.clubs club
  join public.club_subscriptions sub on sub.club_id = club.id
  where club.status = 'suspended'
    and sub.auto_suspended_at is not null
    and sub.auto_suspended_at + private.unpaid_data_retention() <= p_now;

  if cardinality(v_clubs) = 0 then
    return 0;
  end if;

  select coalesce(array_agg(distinct profile.id), '{}') into v_users
  from public.profiles profile
  where profile.club_id = any(v_clubs)
    and profile.id not in (select operator.user_id from private.platform_operators operator);

  set local session_replication_role = replica;
  update public.club_invoices set club_id = null, payment_id = null
  where club_id = any(v_clubs);
  update private.club_refunds set club_id = null, payment_id = null
  where club_id = any(v_clubs);
  for v_table in
    select namespace.nspname as schema_name, class.relname as table_name
    from pg_attribute attribute
    join pg_class class on class.oid = attribute.attrelid
    join pg_namespace namespace on namespace.oid = class.relnamespace
    where attribute.attname = 'club_id'
      and not attribute.attisdropped
      and class.relkind in ('r', 'p')
      and namespace.nspname in ('public', 'private')
      and (namespace.nspname || '.' || class.relname)
          not in ('public.club_invoices', 'private.club_refunds')
  loop
    execute format('delete from %I.%I where club_id = any($1)', v_table.schema_name, v_table.table_name)
    using v_clubs;
  end loop;
  delete from private.club_referrals where referrer_club_id = any(v_clubs) or referred_club_id = any(v_clubs);
  delete from public.clubs where id = any(v_clubs);
  set local session_replication_role = origin;

  delete from auth.users where id = any(v_users);

  return cardinality(v_clubs);
end;
$$;

-- ---------------------------------------------------------------------------
-- Propriétaires et droits
-- ---------------------------------------------------------------------------

do $$
declare
  v_signature text;
begin
  -- Console de l'éditeur : propriétaire postgres (lecture de tous les clubs),
  -- garde private.is_platform_operator() dans chaque fonction.
  foreach v_signature in array array[
    'public.platform_record_manual_payment(uuid,integer,text,date,text,text)',
    'public.platform_grant_free_period(uuid,integer,integer,text)',
    'public.platform_record_refund(uuid,integer,text,text,text)',
    'public.platform_prepare_card_refund(uuid,integer)',
    'public.platform_payment_alerts()',
    'public.platform_resolve_alert(uuid)',
    'public.platform_billing_settings()',
    'public.platform_save_billing_settings(integer,integer,integer,integer)',
    'public.platform_set_club_terms(uuid,integer,text)',
    'public.platform_set_club_access(uuid,boolean)',
    'public.platform_ledger(date,date)',
    'public.platform_list_credit_notes()'
  ] loop
    execute format('alter function %s owner to postgres', v_signature);
    execute format('revoke all on function %s from public, anon', v_signature);
    execute format('grant execute on function %s to authenticated', v_signature);
  end loop;

  -- Fonctions de la fonction serveur stripe-webhook : service_role seulement.
  foreach v_signature in array array[
    'public.stripe_log_event(text,text,boolean,boolean,text)',
    'public.stripe_attach_card_details(text,text,integer,text)',
    'public.stripe_record_refund(text,text,integer,text)',
    'public.stripe_record_dispute(text,text,integer,text,text)'
  ] loop
    execute format('alter function %s owner to postgres', v_signature);
    execute format('revoke all on function %s from public, anon, authenticated', v_signature);
    execute format('grant execute on function %s to service_role', v_signature);
  end loop;
end;
$$;
