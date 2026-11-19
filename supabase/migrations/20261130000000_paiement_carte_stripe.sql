-- Paiement de l'abonnement par carte (Stripe Checkout).
--
-- Parcours :
--   1. l'administrateur du club appuie sur « Payer par carte » ; la fonction
--      serveur stripe-checkout appelle admin_prepare_card_payment() avec SON
--      jeton : le serveur calcule le montant (réduction de parrainage
--      comprise), la fige dans private.card_checkouts et renvoie l'identifiant ;
--   2. stripe-checkout ouvre une session Stripe de ce montant exact ;
--   3. Stripe confirme le paiement à la fonction stripe-webhook (signature
--      vérifiée), qui appelle stripe_record_card_payment() en service_role :
--      même effet qu'un paiement noté à la main par l'éditeur (année ouverte,
--      club rouvert, facture, parrainage).
--
-- La réduction est figée au clic : un filleul qui paie pendant ce temps ne
-- change pas le montant demandé, et la réduction qu'il apporte reste pour
-- l'année suivante.
--
-- Un club suspendu pour impayé doit pouvoir payer pour rouvrir : les deux
-- fonctions administrateur acceptent ce cas (is_admin() exige un club actif).

-- ---------------------------------------------------------------------------
-- 1. Paiements : moyen « carte » et identifiant Stripe
-- ---------------------------------------------------------------------------

alter table public.club_payments
  drop constraint club_payments_method_check,
  add constraint club_payments_method_check
    check (method in ('virement', 'cheque', 'especes', 'autre', 'carte')),
  add column stripe_checkout_session_id text unique;

comment on column public.club_payments.stripe_checkout_session_id is
  'Session Stripe Checkout à l''origine du paiement (paiement par carte).';

-- ---------------------------------------------------------------------------
-- 2. Paiements par carte en cours
-- ---------------------------------------------------------------------------

create table private.card_checkouts (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  amount_cents integer not null
    constraint card_checkouts_amount_check check (amount_cents between 50 and 1000000),
  discount_percent integer not null
    constraint card_checkouts_discount_check check (discount_percent between 0 and 99),
  welcome_percent integer not null default 0
    constraint card_checkouts_welcome_check check (welcome_percent between 0 and 99),
  status text not null default 'pending'
    constraint card_checkouts_status_check check (status in ('pending', 'paid')),
  stripe_session_id text unique,
  created_by uuid not null,
  created_at timestamptz not null default now(),
  paid_at timestamptz
);

comment on table private.card_checkouts is
  'Paiements par carte demandés par un administrateur : montant et réduction figés au clic.';

create index card_checkouts_club_id_idx on private.card_checkouts (club_id, created_at desc);

alter table private.card_checkouts enable row level security;
revoke all on private.card_checkouts from public, anon, authenticated;
grant all on private.card_checkouts to service_role;

create policy club_isolation on private.card_checkouts
  as restrictive for all to public
  using (club_id = (select private.current_club_id()))
  with check (club_id = (select private.current_club_id()));
create policy club_scope_access on private.card_checkouts
  for all to club_scope using (true) with check (true);

-- ---------------------------------------------------------------------------
-- 3. Enregistrement commun d'un paiement
-- ---------------------------------------------------------------------------

-- Effet d'un paiement reçu, quel que soit le moyen. Reprise exacte du corps
-- de platform_record_offline_payment (20261127010000), avec deux ajouts :
--   * p_frozen_discount / p_frozen_welcome : réduction figée au clic (carte).
--     Null = réduction courante (paiement noté à la main) ;
--   * p_stripe_session : identifiant Stripe, unique (pas de double paiement).
create function private.apply_club_payment(
  p_club_id uuid,
  p_amount_cents integer,
  p_method text,
  p_received_on date,
  p_note text,
  p_recorded_by uuid,
  p_frozen_discount integer default null,
  p_frozen_welcome integer default null,
  p_stripe_session text default null
) returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_sub public.club_subscriptions;
  v_start timestamptz;
  v_end timestamptz;
  v_reopened boolean := false;
  v_discount integer;
  v_welcome integer;
  v_referrals_to_use integer;
begin
  select * into v_sub
  from public.club_subscriptions sub
  where sub.club_id = p_club_id
  for update;
  if not found then
    raise exception 'Club inconnu.' using errcode = 'P0002';
  end if;

  v_start := greatest(
    now(),
    case when v_sub.status = 'trialing' then v_sub.trial_ends_at end,
    case when v_sub.status = 'active' then v_sub.current_period_end end
  );
  v_end := v_start + interval '1 year';

  update public.club_subscriptions
  set status = 'active',
      current_period_end = v_end,
      auto_suspended_at = null,
      updated_at = now()
  where club_id = p_club_id;

  -- Seule une suspension pour impayé est levée par un paiement.
  if v_sub.auto_suspended_at is not null then
    update public.clubs
    set status = 'active'
    where id = p_club_id and status = 'suspended';
    v_reopened := found;
  end if;

  insert into public.club_payments (
    club_id, amount_cents, method, received_on, period_end, note, recorded_by,
    stripe_checkout_session_id
  ) values (
    p_club_id, p_amount_cents, p_method, p_received_on, v_end,
    nullif(btrim(coalesce(p_note, '')), ''), p_recorded_by, p_stripe_session
  );

  -- Réduction utilisée par ce paiement : la bienvenue (club parrainé) d'abord,
  -- puis les filleuls payés, les plus anciens d'abord.
  v_discount := coalesce(p_frozen_discount,
                         private.club_referral_discount_percent(p_club_id));
  v_welcome := coalesce(p_frozen_welcome,
                        private.club_referral_welcome_percent(p_club_id));
  if v_welcome > 0 then
    update private.club_referrals referral
    set welcome_used_at = now()
    where referral.referred_club_id = p_club_id
      and referral.welcome_used_at is null;
  end if;
  v_referrals_to_use := case
    when p_frozen_discount is null
      then (private.referral_cap_percent() - v_welcome) / private.referral_rate_percent()
    else greatest(0, (v_discount - v_welcome) / private.referral_rate_percent())
  end;
  update private.club_referrals referral
  set used_at = now()
  where referral.referred_club_id in (
    select candidate.referred_club_id
    from private.club_referrals candidate
    where candidate.referrer_club_id = p_club_id
      and candidate.qualified_at is not null
      and candidate.used_at is null
    order by candidate.qualified_at, candidate.referred_club_id
    limit v_referrals_to_use
  );

  -- Premier paiement d'un filleul : son parrain gagne sa réduction.
  if p_amount_cents > 0 then
    update private.club_referrals referral
    set qualified_at = now()
    where referral.referred_club_id = p_club_id
      and referral.qualified_at is null;
  end if;

  return jsonb_build_object(
    'period_end', v_end,
    'reopened', v_reopened,
    'referral_discount_percent', v_discount
  );
end;
$$;

alter function private.apply_club_payment(uuid, integer, text, date, text, uuid, integer, integer, text)
  owner to postgres;
revoke all on function private.apply_club_payment(uuid, integer, text, date, text, uuid, integer, integer, text)
  from public, anon, authenticated;

-- Le paiement noté par l'éditeur passe désormais par le même chemin.
-- CREATE OR REPLACE conserve propriétaire (postgres) et droits.
create or replace function public.platform_record_offline_payment(
  p_club_id uuid,
  p_amount_cents integer,
  p_method text,
  p_received_on date default current_date,
  p_note text default null
) returns jsonb
language plpgsql security definer
set search_path to ''
as $$
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  if p_amount_cents is null or p_amount_cents not between 0 and 1000000 then
    raise exception 'Montant invalide.' using errcode = '22023';
  end if;
  -- La carte n'est jamais notée à la main : elle vient de Stripe.
  if p_method is null or p_method not in ('virement', 'cheque', 'especes', 'autre') then
    raise exception 'Moyen de paiement invalide.' using errcode = '22023';
  end if;
  if p_received_on is null or p_received_on > current_date + 1 then
    raise exception 'Date de réception invalide.' using errcode = '22023';
  end if;

  return private.apply_club_payment(
    p_club_id, p_amount_cents, p_method, p_received_on, p_note, private.uid()
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Côté administrateur du club
-- ---------------------------------------------------------------------------

-- Administrateur du club connecté, y compris d'un club suspendu pour impayé
-- (il doit pouvoir payer pour rouvrir). Renvoie l'identifiant du club.
create function private.billing_admin_club_id() returns uuid
language sql stable security definer
set search_path to ''
as $$
  select club.id
  from public.profiles profile
  join public.clubs club on club.id = profile.club_id
  join public.club_subscriptions sub on sub.club_id = club.id
  where profile.id = (select private.uid())
    and profile.status = 'active'
    and profile.role = 'admin'
    and (club.status = 'active'
         or (club.status = 'suspended' and sub.auto_suspended_at is not null))
$$;

alter function private.billing_admin_club_id() owner to postgres;
revoke all on function private.billing_admin_club_id() from public, anon, authenticated;

-- Fige le montant à payer par carte et renvoie de quoi ouvrir la session
-- Stripe. Appelée par la fonction serveur stripe-checkout avec le jeton de
-- l'administrateur.
create function public.admin_prepare_card_payment() returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_club_id uuid := private.billing_admin_club_id();
  v_club public.clubs;
  v_sub public.club_subscriptions;
  v_discount integer;
  v_welcome integer;
  v_amount integer;
  v_id uuid;
begin
  if v_club_id is null then
    raise exception 'Réservé aux administrateurs du club.' using errcode = '42501';
  end if;
  select * into v_club from public.clubs where id = v_club_id;
  select * into v_sub from public.club_subscriptions where club_id = v_club_id;
  if v_sub.status = 'canceled' then
    raise exception 'Abonnement arrêté : contacte l''éditeur.' using errcode = '22023';
  end if;

  v_discount := private.club_referral_discount_percent(v_club_id);
  v_welcome := private.club_referral_welcome_percent(v_club_id);
  v_amount := private.club_amount_due_cents(v_club_id);
  if v_amount is null or v_amount <= 0 then
    raise exception 'Rien à payer : active ton année offerte.' using errcode = '22023';
  end if;
  if v_amount < 50 then
    raise exception 'Montant trop faible pour un paiement par carte.' using errcode = '22023';
  end if;

  insert into private.card_checkouts (
    club_id, amount_cents, discount_percent, welcome_percent, created_by
  ) values (
    v_club_id, v_amount, v_discount, v_welcome, private.uid()
  )
  returning id into v_id;

  return jsonb_build_object(
    'checkout_id', v_id,
    'club_id', v_club_id,
    'club_name', v_club.name,
    'amount_cents', v_amount,
    'discount_percent', v_discount
  );
end;
$$;

alter function public.admin_prepare_card_payment() owner to postgres;
revoke all on function public.admin_prepare_card_payment() from public, anon;
grant execute on function public.admin_prepare_card_payment() to authenticated;

-- Réduction de 100 % (année offerte par le parrainage) : rien à payer par
-- carte, l'administrateur ouvre lui-même son année.
create function public.admin_claim_free_year() returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_club_id uuid := private.billing_admin_club_id();
  v_amount integer;
begin
  if v_club_id is null then
    raise exception 'Réservé aux administrateurs du club.' using errcode = '42501';
  end if;
  v_amount := private.club_amount_due_cents(v_club_id);
  if v_amount is null or v_amount > 0 then
    raise exception 'L''année n''est pas offerte : il reste un montant à payer.'
      using errcode = '22023';
  end if;
  -- Une année offerte ne peut pas être réclamée plusieurs fois d'avance.
  if exists (
    select 1 from public.club_subscriptions sub
    where sub.club_id = v_club_id
      and sub.status = 'active'
      and sub.current_period_end > now() + interval '60 days'
  ) then
    raise exception 'L''abonnement est déjà payé pour cette période.'
      using errcode = '22023';
  end if;

  return private.apply_club_payment(
    v_club_id, 0, 'autre', current_date,
    'Année offerte par le parrainage', private.uid()
  );
end;
$$;

alter function public.admin_claim_free_year() owner to postgres;
revoke all on function public.admin_claim_free_year() from public, anon;
grant execute on function public.admin_claim_free_year() to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Confirmation de Stripe (fonction serveur stripe-webhook, service_role)
-- ---------------------------------------------------------------------------

create function public.stripe_record_card_payment(
  p_checkout_id uuid,
  p_session_id text,
  p_amount_cents integer,
  p_currency text
) returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_checkout private.card_checkouts;
  v_result jsonb;
begin
  if coalesce(private.jwt() ->> 'role', '') <> 'service_role' then
    raise exception 'Réservé au serveur.' using errcode = '42501';
  end if;
  if p_session_id is null or btrim(p_session_id) = '' then
    raise exception 'Session Stripe manquante.' using errcode = '22023';
  end if;

  select * into v_checkout
  from private.card_checkouts checkout
  where checkout.id = p_checkout_id
  for update;
  if not found then
    raise exception 'Paiement inconnu.' using errcode = 'P0002';
  end if;

  -- Stripe renvoie parfois deux fois le même événement : rien de plus.
  if v_checkout.status = 'paid' then
    return jsonb_build_object('already_recorded', true);
  end if;
  if lower(coalesce(p_currency, '')) <> 'eur'
     or p_amount_cents is distinct from v_checkout.amount_cents then
    raise exception 'Montant ou devise différents du paiement demandé.'
      using errcode = '22023';
  end if;

  v_result := private.apply_club_payment(
    v_checkout.club_id, v_checkout.amount_cents, 'carte', current_date,
    'Paiement par carte (Stripe)', v_checkout.created_by,
    v_checkout.discount_percent, v_checkout.welcome_percent, p_session_id
  );

  update private.card_checkouts
  set status = 'paid', stripe_session_id = p_session_id, paid_at = now()
  where id = v_checkout.id;

  return v_result || jsonb_build_object('already_recorded', false);
end;
$$;

alter function public.stripe_record_card_payment(uuid, text, integer, text) owner to postgres;
revoke all on function public.stripe_record_card_payment(uuid, text, integer, text)
  from public, anon, authenticated;
grant execute on function public.stripe_record_card_payment(uuid, text, integer, text)
  to service_role;
