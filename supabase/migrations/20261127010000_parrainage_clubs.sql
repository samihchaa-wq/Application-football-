-- Parrainage entre clubs.
--
-- Décision de l'éditeur (18/11/2026) : chaque club a un code parrain. Un
-- nouveau club qui le saisit à sa création devient filleul. Quand l'éditeur
-- note le premier paiement du filleul, le parrain gagne 5 % de réduction sur
-- son prochain renouvellement, jusqu'à 100 % (20 filleuls : année offerte).
-- La réduction est consommée au paiement suivant du parrain.
--
-- Le paiement reste hors ligne : l'appli affiche le montant à payer après
-- réduction, à l'administrateur du club et à l'éditeur.

-- ---------------------------------------------------------------------------
-- 1. Règles
-- ---------------------------------------------------------------------------

create function private.referral_rate_percent() returns integer
language sql immutable set search_path to '' as $$ select 5 $$;

create function private.referral_cap_percent() returns integer
language sql immutable set search_path to '' as $$ select 100 $$;

revoke all on function private.referral_rate_percent() from public, anon, authenticated;
revoke all on function private.referral_cap_percent() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. Code parrain de chaque club
-- ---------------------------------------------------------------------------

-- « PF » + 6 caractères, sans 0, 1, I, O : distinct du code d'invitation des
-- joueurs (8 caractères) et lisible au téléphone.
create function private.generate_referral_code() returns text
language plpgsql volatile
set search_path to ''
as $$
declare
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
begin
  loop
    select 'PF' || string_agg(
      substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1), ''
    )
    into v_code
    from generate_series(1, 6);
    exit when not exists (select 1 from public.clubs where referral_code = v_code);
  end loop;
  return v_code;
end;
$$;

revoke all on function private.generate_referral_code() from public, anon, authenticated;

alter table public.clubs add column referral_code text;

update public.clubs set referral_code = private.generate_referral_code()
where referral_code is null;

alter table public.clubs
  alter column referral_code set not null,
  add constraint clubs_referral_code_check check (referral_code ~ '^PF[A-Z2-9]{6}$');
create unique index clubs_referral_code_uidx on public.clubs (referral_code);

comment on column public.clubs.referral_code is
  'Code parrain du club, à donner à un autre club qui s''inscrit.';

create function private.set_club_referral_code() returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if new.referral_code is null then
    new.referral_code := private.generate_referral_code();
  end if;
  return new;
end;
$$;

revoke all on function private.set_club_referral_code() from public, anon, authenticated;

create trigger clubs_set_referral_code
  before insert on public.clubs
  for each row execute function private.set_club_referral_code();

-- Un code saisi à la main : majuscules, sans espaces ni tirets.
create function private.normalize_referral_code(p_code text) returns text
language sql immutable
set search_path to ''
as $$ select upper(regexp_replace(coalesce(p_code, ''), '[\s-]', '', 'g')) $$;

revoke all on function private.normalize_referral_code(text) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Registre des parrainages
-- ---------------------------------------------------------------------------

create table private.club_referrals (
  referred_club_id uuid primary key references public.clubs(id) on delete cascade,
  referrer_club_id uuid not null references public.clubs(id) on delete cascade,
  created_at timestamptz not null default now(),
  -- Premier paiement du filleul noté par l'éditeur : la réduction est acquise.
  qualified_at timestamptz,
  -- Réduction utilisée sur un paiement du parrain.
  used_at timestamptz,
  -- Réduction de bienvenue du filleul (−5 % sur sa première année) utilisée
  -- à son premier paiement.
  welcome_used_at timestamptz,
  constraint club_referrals_not_self check (referred_club_id <> referrer_club_id),
  constraint club_referrals_used_after_qualified check (used_at is null or qualified_at is not null)
);

create index club_referrals_referrer_idx on private.club_referrals (referrer_club_id);

comment on table private.club_referrals is
  'Parrainages entre clubs : un filleul n''a qu''un parrain ; la réduction est acquise au premier paiement du filleul et utilisée au paiement suivant du parrain.';

alter table private.club_referrals enable row level security;
revoke all on private.club_referrals from public, anon, authenticated;
-- Un club ne voit que les parrainages où il est parrain ou filleul. Lu par
-- le résumé d'abonnement, qui s'exécute avec le rôle des fonctions serveur
-- (club_scope). Aucun accès direct pour les comptes.
create policy club_isolation on private.club_referrals
  as restrictive for all to public
  using (
    referrer_club_id = (select private.current_club_id())
    or referred_club_id = (select private.current_club_id())
  )
  with check (
    referrer_club_id = (select private.current_club_id())
    or referred_club_id = (select private.current_club_id())
  );
create policy club_scope_access on private.club_referrals
  for all to club_scope using (true) with check (true);

-- Réduction de bienvenue d'un club parrainé : −5 % jusqu'à son premier
-- paiement.
create function private.club_referral_welcome_percent(p_club_id uuid) returns integer
language sql stable
set search_path to ''
as $$
  select case when exists (
    select 1
    from private.club_referrals referral
    where referral.referred_club_id = p_club_id
      and referral.welcome_used_at is null
  ) then private.referral_rate_percent() else 0 end
$$;

revoke all on function private.club_referral_welcome_percent(uuid) from public, anon, authenticated;

-- Réduction acquise et pas encore utilisée, en pourcentage (0 à 100) :
-- 5 % par filleul payé, plus 5 % la première année si le club a été parrainé.
create function private.club_referral_discount_percent(p_club_id uuid) returns integer
language sql stable
set search_path to ''
as $$
  select least(
    private.referral_cap_percent(),
    private.club_referral_welcome_percent(p_club_id)
      + private.referral_rate_percent() * count(*)::integer
  )
  from private.club_referrals referral
  where referral.referrer_club_id = p_club_id
    and referral.qualified_at is not null
    and referral.used_at is null
$$;

revoke all on function private.club_referral_discount_percent(uuid) from public, anon, authenticated;

-- Montant à payer pour la prochaine année, réduction de parrainage déduite.
create function private.club_amount_due_cents(p_club_id uuid) returns integer
language sql stable
set search_path to ''
as $$
  select (sub.base_price_cents * (100 - private.club_referral_discount_percent(p_club_id)) / 100)::integer
  from public.club_subscriptions sub
  where sub.club_id = p_club_id
$$;

revoke all on function private.club_amount_due_cents(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. Inscription d'un club filleul (fonction serveur register-account)
-- ---------------------------------------------------------------------------

-- Vérifie un code avant de créer quoi que ce soit.
create function public.club_for_referral_code(p_code text)
returns table (id uuid, name text)
language sql stable security definer
set search_path to ''
as $$
  select club.id, club.name
  from public.clubs club
  where club.referral_code = private.normalize_referral_code(p_code)
    and club.status = 'active'
$$;

revoke all on function public.club_for_referral_code(text) from public, anon, authenticated;
grant execute on function public.club_for_referral_code(text) to service_role;

-- Relie un club tout juste créé à son parrain. Renvoie false si le code est
-- inconnu, si c'est le code du club lui-même ou si le club a déjà un parrain.
create function public.attach_club_referral(p_club_id uuid, p_code text) returns boolean
language plpgsql security definer
set search_path to ''
as $$
declare
  v_referrer uuid;
begin
  select club.id into v_referrer
  from public.clubs club
  where club.referral_code = private.normalize_referral_code(p_code)
    and club.status = 'active';
  if v_referrer is null or v_referrer = p_club_id then
    return false;
  end if;
  insert into private.club_referrals (referred_club_id, referrer_club_id)
  values (p_club_id, v_referrer)
  on conflict (referred_club_id) do nothing;
  return found;
end;
$$;

revoke all on function public.attach_club_referral(uuid, text) from public, anon, authenticated;
grant execute on function public.attach_club_referral(uuid, text) to service_role;

-- ---------------------------------------------------------------------------
-- 5. Paiement noté : filleul acquis, réduction du parrain utilisée
-- ---------------------------------------------------------------------------

-- Reprise de 20261124020000 ; ajouts : le parrainage (fin de fonction) et
-- la réduction appliquée dans la réponse.
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
declare
  v_sub public.club_subscriptions;
  v_start timestamptz;
  v_end timestamptz;
  v_reopened boolean := false;
  v_discount integer;
  v_welcome integer;
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

  -- Ce paiement utilise la réduction de parrainage acquise par ce club (au
  -- plus le nombre de filleuls qui fait 100 %), les plus anciens d'abord.
  -- La réduction de bienvenue (club parrainé) passe en premier.
  v_discount := private.club_referral_discount_percent(p_club_id);
  v_welcome := private.club_referral_welcome_percent(p_club_id);
  update private.club_referrals referral
  set welcome_used_at = now()
  where referral.referred_club_id = p_club_id
    and referral.welcome_used_at is null;
  update private.club_referrals referral
  set used_at = now()
  where referral.referred_club_id in (
    select candidate.referred_club_id
    from private.club_referrals candidate
    where candidate.referrer_club_id = p_club_id
      and candidate.qualified_at is not null
      and candidate.used_at is null
    order by candidate.qualified_at, candidate.referred_club_id
    limit (private.referral_cap_percent() - v_welcome) / private.referral_rate_percent()
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

-- Fiche de facturation pour la console : ajoute la réduction de parrainage et
-- le montant à demander.
create or replace function public.platform_club_billing(p_club_id uuid) returns jsonb
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
    'referral_discount_percent', private.club_referral_discount_percent(p_club_id),
    'amount_due_cents', private.club_amount_due_cents(p_club_id),
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

-- ---------------------------------------------------------------------------
-- 6. Ce que voit l'administrateur du club
-- ---------------------------------------------------------------------------

-- Résumé de l'abonnement : ajoute la réduction et le montant à payer.
-- Reprise de 20261124020000.
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
    'referral_discount_percent', private.club_referral_discount_percent(v_sub.club_id),
    'amount_due_cents', private.club_amount_due_cents(v_sub.club_id),
    'suspension_on', private.club_suspension_due_at(
      v_sub.status, v_sub.trial_ends_at, v_sub.current_period_end)
  );
end;
$$;

-- Noms des clubs parrain et filleuls d'un club. Le cloisonnement empêche un
-- club de lire les autres clubs : ce relais (propriétaire postgres) ne livre
-- que leur nom et l'état du parrainage, rien d'autre.
create function private.club_referral_overview(p_club_id uuid) returns jsonb
language sql stable security definer
set search_path to ''
as $$
  select jsonb_build_object(
    'referred_by', (
      select parent.name
      from private.club_referrals referral
      join public.clubs parent on parent.id = referral.referrer_club_id
      where referral.referred_club_id = p_club_id
    ),
    'referrals', coalesce((
      select jsonb_agg(jsonb_build_object(
        'club_name', child.name,
        'joined_at', referral.created_at,
        'state', case
          when referral.used_at is not null then 'used'
          when referral.qualified_at is not null then 'paid'
          else 'trial'
        end
      ) order by referral.created_at desc, child.name)
      from private.club_referrals referral
      join public.clubs child on child.id = referral.referred_club_id
      where referral.referrer_club_id = p_club_id
    ), '[]'::jsonb)
  )
$$;

alter function private.club_referral_overview(uuid) owner to postgres;
revoke all on function private.club_referral_overview(uuid) from public, anon, authenticated;
grant execute on function private.club_referral_overview(uuid) to club_scope;

-- Parrainage du club : code, règles, filleuls et réduction acquise.
create function public.admin_get_club_referrals() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_club uuid := private.current_club_id();
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs du club.' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'code', (select club.referral_code from public.clubs club where club.id = v_club),
    'rate_percent', private.referral_rate_percent(),
    'cap_percent', private.referral_cap_percent(),
    'discount_percent', private.club_referral_discount_percent(v_club),
    'welcome_percent', private.club_referral_welcome_percent(v_club)
  ) || private.club_referral_overview(v_club);
end;
$$;

-- Comme admin_get_club_subscription : rôle soumis au cloisonnement.
alter function public.admin_get_club_referrals() owner to club_scope;
revoke all on function public.admin_get_club_referrals() from public, anon;
grant execute on function public.admin_get_club_referrals() to authenticated;
