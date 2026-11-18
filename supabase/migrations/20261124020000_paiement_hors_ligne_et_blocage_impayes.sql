-- Paiement hors ligne et blocage des clubs impayés.
--
-- Le paiement en ligne n'est pas branché : les clubs paient par virement,
-- chèque ou espèces, et l'éditeur note chaque paiement reçu depuis sa
-- console. Un paiement noté ouvre (ou prolonge) une année d'abonnement.
--
-- Un club qui n'a pas payé à l'échéance (fin d'essai ou fin d'année) garde
-- l'accès pendant un délai de grâce, puis il est suspendu automatiquement
-- chaque nuit. Ses données sont conservées. Noter un paiement le rouvre
-- aussitôt. Une suspension décidée à la main par l'éditeur n'est jamais
-- levée automatiquement.
--
-- Si l'éditeur rouvre à la main un club suspendu pour impayé, le club n'est
-- plus suspendu automatiquement tant qu'aucun nouveau paiement n'a été noté.

-- ---------------------------------------------------------------------------
-- 1. Échéance et délai de grâce
-- ---------------------------------------------------------------------------

-- Délai entre l'échéance non payée et la suspension. Un seul endroit à
-- changer pour l'allonger ou le raccourcir.
create function private.unpaid_grace_period() returns interval
language sql immutable
set search_path to ''
as $$ select interval '15 days' $$;

-- Date à partir de laquelle un abonnement non payé est suspendu, ou null si
-- rien n'est dû (abonnement actif sans date de fin saisie).
create function private.club_suspension_due_at(
  p_status text,
  p_trial_ends_at timestamptz,
  p_current_period_end timestamptz
) returns timestamptz
language sql immutable
set search_path to ''
as $$
  select case p_status
    when 'trialing' then p_trial_ends_at
    when 'active' then p_current_period_end
    else coalesce(p_current_period_end, p_trial_ends_at)
  end + private.unpaid_grace_period()
$$;

revoke all on function private.unpaid_grace_period() from public;
revoke all on function private.club_suspension_due_at(text, timestamptz, timestamptz) from public;
grant execute on function private.unpaid_grace_period() to club_scope;
grant execute on function private.club_suspension_due_at(text, timestamptz, timestamptz) to club_scope;

-- Club suspendu automatiquement pour impayé (et non par décision de
-- l'éditeur) : seul ce cas est levé par un paiement.
alter table public.club_subscriptions
  add column auto_suspended_at timestamptz;

comment on column public.club_subscriptions.auto_suspended_at is
  'Date de la suspension automatique pour impayé ; vide si le club n''a pas été suspendu automatiquement depuis son dernier paiement.';

-- ---------------------------------------------------------------------------
-- 2. Registre des paiements reçus hors ligne
-- ---------------------------------------------------------------------------

create table public.club_payments (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  amount_cents integer not null
    constraint club_payments_amount_check check (amount_cents between 0 and 1000000),
  method text not null
    constraint club_payments_method_check
      check (method in ('virement', 'cheque', 'especes', 'autre')),
  received_on date not null,
  period_end timestamptz not null,
  note text constraint club_payments_note_check check (char_length(note) <= 500),
  recorded_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

comment on table public.club_payments is
  'Paiements d''abonnement reçus hors ligne (virement, chèque, espèces), notés par l''éditeur.';

create index club_payments_club_id_idx on public.club_payments (club_id, received_on desc);
create index club_payments_recorded_by_idx on public.club_payments (recorded_by)
  where recorded_by is not null;

alter table public.club_payments enable row level security;
revoke all on public.club_payments from public, anon, authenticated;
grant select on public.club_payments to authenticated;
grant all on public.club_payments to service_role;
grant select, insert, update, delete on public.club_payments to club_scope;

-- Même cloisonnement que l'abonnement : lecture réservée aux administrateurs
-- du club, écriture réservée à l'éditeur (par sa fonction dédiée).
create policy club_isolation on public.club_payments
  as restrictive for all to public
  using (club_id = (select private.current_club_id()))
  with check (club_id = (select private.current_club_id()));
create policy active_authenticated_profile_only on public.club_payments
  as restrictive for all to authenticated
  using ((select private.is_active_profile()))
  with check ((select private.is_active_profile()));
create policy club_scope_access on public.club_payments
  for all to club_scope using (true) with check (true);
create policy club_payments_admin_read on public.club_payments
  for select to authenticated
  using ((select private.is_admin()));

-- ---------------------------------------------------------------------------
-- 3. Noter un paiement reçu
-- ---------------------------------------------------------------------------

-- L'année payée commence à la fin de ce qui est déjà acquis (essai en cours
-- ou année en cours), ou aujourd'hui si l'échéance est passée : payer en
-- avance ne fait perdre aucun jour.
create function public.platform_record_offline_payment(
  p_club_id uuid,
  p_amount_cents integer,
  p_method text,
  p_received_on date default current_date,
  p_note text default null
) returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_sub public.club_subscriptions;
  v_start timestamptz;
  v_end timestamptz;
  v_reopened boolean := false;
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  if p_amount_cents is null or p_amount_cents not between 0 and 1000000 then
    raise exception 'Montant invalide.' using errcode = '22023';
  end if;
  if p_method is null or p_method not in ('virement', 'cheque', 'especes', 'autre') then
    raise exception 'Moyen de paiement invalide.' using errcode = '22023';
  end if;
  if p_received_on is null or p_received_on > current_date + 1 then
    raise exception 'Date de réception invalide.' using errcode = '22023';
  end if;

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
    club_id, amount_cents, method, received_on, period_end, note, recorded_by
  ) values (
    p_club_id, p_amount_cents, p_method, p_received_on, v_end,
    nullif(btrim(coalesce(p_note, '')), ''), private.uid()
  );

  return jsonb_build_object('period_end', v_end, 'reopened', v_reopened);
end;
$$;

alter function public.platform_record_offline_payment(uuid, integer, text, date, text) owner to postgres;
revoke all on function public.platform_record_offline_payment(uuid, integer, text, date, text)
  from public, anon;
grant execute on function public.platform_record_offline_payment(uuid, integer, text, date, text)
  to authenticated;

-- Fiche de facturation d'un club pour la console : date de suspension
-- prévue, suspension automatique en cours et derniers paiements.
create function public.platform_club_billing(p_club_id uuid) returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_sub public.club_subscriptions;
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

  return jsonb_build_object(
    'base_price_cents', v_sub.base_price_cents,
    'suspension_on', private.club_suspension_due_at(
      v_sub.status, v_sub.trial_ends_at, v_sub.current_period_end),
    'auto_suspended_at', v_sub.auto_suspended_at,
    'payments', coalesce((
      select jsonb_agg(jsonb_build_object(
        'amount_cents', payment.amount_cents,
        'method', payment.method,
        'received_on', payment.received_on,
        'period_end', payment.period_end,
        'note', payment.note
      ) order by payment.received_on desc, payment.created_at desc)
      from (
        select * from public.club_payments
        where club_id = p_club_id
        order by received_on desc, created_at desc
        limit 20
      ) payment
    ), '[]'::jsonb)
  );
end;
$$;

alter function public.platform_club_billing(uuid) owner to postgres;
revoke all on function public.platform_club_billing(uuid) from public, anon;
grant execute on function public.platform_club_billing(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Suspension automatique, chaque nuit
-- ---------------------------------------------------------------------------

-- Lancée par la tâche planifiée (rôle postgres), jamais par un compte.
create function private.suspend_unpaid_clubs(p_now timestamptz default now())
returns integer
language plpgsql
set search_path to ''
as $$
declare
  v_count integer;
begin
  with overdue as (
    update public.club_subscriptions sub
    set auto_suspended_at = p_now,
        updated_at = p_now
    from public.clubs club
    where club.id = sub.club_id
      and club.status = 'active'
      and sub.auto_suspended_at is null
      and private.club_suspension_due_at(
            sub.status, sub.trial_ends_at, sub.current_period_end) <= p_now
    returning sub.club_id
  )
  update public.clubs club
  set status = 'suspended'
  from overdue
  where club.id = overdue.club_id;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function private.suspend_unpaid_clubs(timestamptz) from public, anon, authenticated;

select cron.schedule(
  'suspend-unpaid-clubs',
  '23 4 * * *',
  $cron$select private.suspend_unpaid_clubs(now());$cron$
);

-- ---------------------------------------------------------------------------
-- 5. Ce que voient l'administrateur et les membres
-- ---------------------------------------------------------------------------

-- Résumé de l'administrateur : ajoute la date de suspension prévue.
create or replace function private.club_subscription_summary() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_sub public.club_subscriptions;
  v_players integer := private.club_billable_players();
  v_state text;
begin
  select * into v_sub
  from public.club_subscriptions sub
  where sub.club_id = private.current_club_id();

  if not found then
    return null;
  end if;

  -- trial : essai en cours ; trial_ending : moins de 7 jours d'essai ;
  -- to_pay : essai fini sans abonnement ; active ; past_due : paiement à
  -- régulariser ; canceled : abonnement arrêté.
  v_state := case
    when v_sub.status = 'trialing' and v_sub.trial_ends_at > now() + interval '7 days' then 'trial'
    when v_sub.status = 'trialing' and v_sub.trial_ends_at > now() then 'trial_ending'
    when v_sub.status = 'trialing' then 'to_pay'
    else v_sub.status
  end;

  return jsonb_build_object(
    'state', v_state,
    'status', v_sub.status,
    'trial_ends_at', v_sub.trial_ends_at,
    'trial_days_left', greatest(0, ceil(extract(epoch from v_sub.trial_ends_at - now()) / 86400))::integer,
    'current_period_end', v_sub.current_period_end,
    'billable_players', v_players,
    'price_per_player_cents', v_sub.price_per_player_cents,
    'base_price_cents', v_sub.base_price_cents,
    'yearly_amount_cents', v_sub.base_price_cents + v_players * v_sub.price_per_player_cents,
    'suspension_on', private.club_suspension_due_at(
      v_sub.status, v_sub.trial_ends_at, v_sub.current_period_end)
  );
end;
$$;

-- État du club pour l'écran de suspension : précise si c'est un impayé.
create or replace function public.get_my_club_access() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_status text;
  v_unpaid boolean;
begin
  if private.uid() is null then
    return jsonb_build_object('status', 'signed_out');
  end if;
  select club.status, sub.auto_suspended_at is not null
  into v_status, v_unpaid
  from public.profiles profile
  join public.clubs club on club.id = profile.club_id
  left join public.club_subscriptions sub on sub.club_id = club.id
  where profile.id = private.uid();
  return jsonb_build_object(
    'status', coalesce(v_status, 'unknown'),
    'reason', case when v_status = 'suspended' and v_unpaid then 'unpaid' end
  );
end;
$$;
