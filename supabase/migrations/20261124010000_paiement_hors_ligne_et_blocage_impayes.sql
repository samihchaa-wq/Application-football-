-- Paiement hors ligne (virement, chèque, lien de paiement Stripe) et blocage
-- automatique des clubs qui n'ont pas payé. Décision du propriétaire du
-- 18/11/2026.
--
-- 1. L'éditeur note un paiement reçu en un geste : l'abonnement devient
--    actif pour un an, le paiement est journalisé, et un club bloqué pour
--    impayé est rouvert.
-- 2. L'éditeur peut prolonger l'essai d'un club.
-- 3. Chaque nuit, un club est suspendu 15 jours après la fin de son essai ou
--    de sa période payée s'il n'a pas payé. Ses données sont conservées.
--    Une suspension décidée à la main par l'éditeur n'est jamais levée par
--    un paiement : seuls les blocages pour impayé le sont.

-- ---------------------------------------------------------------------------
-- 1. Traces
-- ---------------------------------------------------------------------------

alter table public.club_subscriptions
  add column suspended_for_nonpayment_at timestamptz;

comment on column public.club_subscriptions.suspended_for_nonpayment_at is
  'Date du blocage automatique pour impayé ; vide si le club n''est pas bloqué pour cette raison.';

-- Journal des paiements notés par l'éditeur, pour la comptabilité.
create table private.club_payments (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  recorded_at timestamptz not null default now(),
  recorded_by uuid references auth.users(id) on delete set null,
  amount_cents integer not null check (amount_cents >= 0),
  period_end timestamptz not null
);

create index club_payments_club_idx on private.club_payments (club_id, recorded_at desc);

alter table private.club_payments enable row level security;
revoke all on private.club_payments from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. Ce que voit l'administrateur du club
-- ---------------------------------------------------------------------------

-- Délai entre la fin de l'essai (ou de la période payée) et le blocage.
create function private.nonpayment_grace() returns interval
language sql immutable
set search_path to ''
as $$ select interval '15 days' $$;

revoke all on function private.nonpayment_grace() from public;
grant execute on function private.nonpayment_grace() to club_scope;

-- Même calcul qu'avant, plus :
-- * une période payée échue repasse en « to_pay » ;
-- * access_ends_at : date à laquelle l'accès sera coupé sans paiement.
create or replace function private.club_subscription_summary() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_sub public.club_subscriptions;
  v_players integer := private.club_billable_players();
  v_state text;
  v_due timestamptz;
begin
  select * into v_sub
  from public.club_subscriptions sub
  where sub.club_id = private.current_club_id();

  if not found then
    return null;
  end if;

  v_state := case
    when v_sub.status = 'trialing' and v_sub.trial_ends_at > now() + interval '7 days' then 'trial'
    when v_sub.status = 'trialing' and v_sub.trial_ends_at > now() then 'trial_ending'
    when v_sub.status = 'trialing' then 'to_pay'
    when v_sub.status = 'active' and v_sub.current_period_end is not null
      and v_sub.current_period_end <= now() then 'to_pay'
    else v_sub.status
  end;

  v_due := case
    when v_sub.status = 'trialing' then v_sub.trial_ends_at
    else v_sub.current_period_end
  end;

  return jsonb_build_object(
    'state', v_state,
    'status', v_sub.status,
    'trial_ends_at', v_sub.trial_ends_at,
    'trial_days_left', greatest(0, ceil(extract(epoch from v_sub.trial_ends_at - now()) / 86400))::integer,
    'current_period_end', v_sub.current_period_end,
    'access_ends_at', v_due + private.nonpayment_grace(),
    'billable_players', v_players,
    'price_per_player_cents', v_sub.price_per_player_cents,
    'base_price_cents', v_sub.base_price_cents,
    'yearly_amount_cents', v_sub.base_price_cents + v_players * v_sub.price_per_player_cents
  );
end;
$$;

alter function private.club_subscription_summary() owner to club_scope;
revoke all on function private.club_subscription_summary() from public;

-- ---------------------------------------------------------------------------
-- 3. Actions de l'éditeur
-- ---------------------------------------------------------------------------

-- Paiement reçu : un an d'abonnement à partir de la fin de la période en
-- cours (renouvellement anticipé) ou d'aujourd'hui (retard ou premier
-- paiement). Appartient à postgres, comme le reste de la console.
create function public.platform_record_payment(p_club_id uuid) returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_sub public.club_subscriptions;
  v_players integer;
  v_end timestamptz;
  v_reopened boolean := false;
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;

  select * into v_sub
  from public.club_subscriptions sub
  where sub.club_id = p_club_id
  for update;
  if not found then
    raise exception 'Club inconnu.' using errcode = 'P0002';
  end if;

  select count(distinct season_player.player_id)::integer into v_players
  from public.season_players season_player
  join public.seasons season on season.id = season_player.season_id
  where season_player.club_id = p_club_id
    and season.status = 'open'
    and season_player.is_active;

  v_end := greatest(
    case when v_sub.status = 'active' then v_sub.current_period_end end,
    now()
  ) + interval '1 year';

  if v_sub.suspended_for_nonpayment_at is not null then
    update public.clubs set status = 'active'
    where id = p_club_id and status = 'suspended';
    v_reopened := found;
  end if;

  update public.club_subscriptions
  set status = 'active',
      current_period_end = v_end,
      suspended_for_nonpayment_at = null,
      updated_at = now()
  where club_id = p_club_id;

  insert into private.club_payments (club_id, recorded_by, amount_cents, period_end)
  values (
    p_club_id,
    private.uid(),
    v_sub.base_price_cents + coalesce(v_players, 0) * v_sub.price_per_player_cents,
    v_end
  );

  return jsonb_build_object('current_period_end', v_end, 'reopened', v_reopened);
end;
$$;

revoke all on function public.platform_record_payment(uuid) from public, anon;
grant execute on function public.platform_record_payment(uuid) to authenticated;

-- Prolonger l'essai d'un club qui n'a pas encore payé.
create function public.platform_extend_trial(p_club_id uuid, p_days integer default 30)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_sub public.club_subscriptions;
  v_end timestamptz;
  v_reopened boolean := false;
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  if p_days is null or p_days not between 1 and 365 then
    raise exception 'Durée de prolongation invalide.' using errcode = '22023';
  end if;

  select * into v_sub
  from public.club_subscriptions sub
  where sub.club_id = p_club_id
  for update;
  if not found then
    raise exception 'Club inconnu.' using errcode = 'P0002';
  end if;
  if v_sub.status = 'active' then
    raise exception 'Ce club est déjà abonné.' using errcode = '22023';
  end if;

  v_end := greatest(v_sub.trial_ends_at, now()) + make_interval(days => p_days);

  if v_sub.suspended_for_nonpayment_at is not null then
    update public.clubs set status = 'active'
    where id = p_club_id and status = 'suspended';
    v_reopened := found;
  end if;

  update public.club_subscriptions
  set status = 'trialing',
      trial_ends_at = v_end,
      suspended_for_nonpayment_at = null,
      updated_at = now()
  where club_id = p_club_id;

  return jsonb_build_object('trial_ends_at', v_end, 'reopened', v_reopened);
end;
$$;

revoke all on function public.platform_extend_trial(uuid, integer) from public, anon;
grant execute on function public.platform_extend_trial(uuid, integer) to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Blocage automatique des impayés
-- ---------------------------------------------------------------------------

-- Lit et modifie tous les clubs : appartient à postgres, jamais appelable
-- par un compte. Renvoie le nombre de clubs bloqués.
create function private.suspend_unpaid_clubs(p_now timestamptz) returns integer
language plpgsql security definer
set search_path to ''
as $$
declare
  v_count integer;
begin
  with unpaid as (
    select sub.club_id
    from public.club_subscriptions sub
    join public.clubs club on club.id = sub.club_id
    where club.status = 'active'
      and (
        (sub.status = 'trialing'
          and sub.trial_ends_at + private.nonpayment_grace() < p_now)
        or (sub.status in ('active', 'past_due', 'canceled')
          and sub.current_period_end is not null
          and sub.current_period_end + private.nonpayment_grace() < p_now)
      )
    for update of sub, club
  ),
  marked as (
    update public.club_subscriptions sub
    set status = case when sub.status = 'canceled' then 'canceled' else 'past_due' end,
        suspended_for_nonpayment_at = p_now,
        updated_at = p_now
    from unpaid
    where sub.club_id = unpaid.club_id
    returning sub.club_id
  )
  update public.clubs club
  set status = 'suspended'
  from marked
  where club.id = marked.club_id;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function private.suspend_unpaid_clubs(timestamptz) from public, anon, authenticated;

select cron.schedule(
  'suspend-unpaid-clubs',
  '41 4 * * *',
  $cron$select private.suspend_unpaid_clubs(now());$cron$
);
