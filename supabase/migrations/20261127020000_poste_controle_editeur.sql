-- Poste de contrôle de l'éditeur :
--   1. compteur de visites (une par personne et par jour) ;
--   2. vue d'ensemble des clubs et chiffres globaux pour la console ;
--   3. effacement automatique d'un club impayé 3 ans après sa suspension.

-- ---------------------------------------------------------------------------
-- 1. Visites
-- ---------------------------------------------------------------------------

-- Une ligne par personne et par jour (heure de Paris) où elle a ouvert l'appli.
-- Rien d'autre n'est noté : ni heure, ni écran, ni appareil.
create table private.profile_daily_visits (
  club_id uuid not null references public.clubs(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  day date not null,
  primary key (profile_id, day)
);

create index profile_daily_visits_club_day_idx on private.profile_daily_visits (club_id, day);

comment on table private.profile_daily_visits is
  'Jours où chaque membre a ouvert l''appli (une ligne par personne et par jour), pour la moyenne de visites du poste de contrôle.';

alter table private.profile_daily_visits enable row level security;
revoke all on private.profile_daily_visits from public, anon, authenticated;
create policy club_isolation on private.profile_daily_visits
  as restrictive for all to public
  using (club_id = (select private.current_club_id()))
  with check (club_id = (select private.current_club_id()));
create policy club_scope_access on private.profile_daily_visits
  for all to club_scope using (true) with check (true);

-- Appelée par l'appli à l'ouverture et au retour au premier plan. Les appels
-- répétés le même jour ne changent rien.
create function public.log_app_visit() returns void
language plpgsql security definer
set search_path to ''
as $$
declare
  v_club uuid := private.current_club_id();
  v_profile uuid := private.uid();
begin
  if v_club is null or v_profile is null then
    return;
  end if;
  insert into private.profile_daily_visits (club_id, profile_id, day)
  select v_club, profile.id, (now() at time zone 'Europe/Paris')::date
  from public.profiles profile
  where profile.id = v_profile
    and profile.club_id = v_club
    and profile.status = 'active'
  on conflict (profile_id, day) do nothing;
end;
$$;
alter function public.log_app_visit() owner to club_scope;
revoke all on function public.log_app_visit() from public, anon;
grant execute on function public.log_app_visit() to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Vue d'ensemble pour la console de l'éditeur
-- ---------------------------------------------------------------------------

-- Durée de conservation des données d'un club qui ne paie plus.
create function private.unpaid_data_retention() returns interval
language sql immutable
set search_path to ''
as $$ select interval '3 years' $$;

revoke all on function private.unpaid_data_retention() from public, anon, authenticated;

create function public.platform_control_overview() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_today date := (now() at time zone 'Europe/Paris')::date;
  v_clubs jsonb;
  v_totals jsonb;
  v_daily jsonb;
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;

  with members as (
    select profile.club_id, count(*) as members
    from public.profiles profile
    where profile.status = 'active'
    group by profile.club_id
  ),
  players as (
    select season_player.club_id, count(distinct season_player.player_id) as players
    from public.season_players season_player
    join public.seasons season on season.id = season_player.season_id
    where season.status = 'open' and season_player.is_active
    group by season_player.club_id
  ),
  visits as (
    select visit.club_id,
           count(*) filter (where visit.day > v_today - 30) as visits_30d,
           count(distinct visit.profile_id) filter (where visit.day > v_today - 7) as people_7d,
           count(*) filter (where visit.day = v_today) as visits_today,
           max(visit.day) as last_visit_on
    from private.profile_daily_visits visit
    group by visit.club_id
  ),
  matches as (
    select match.club_id, count(*) as matches
    from public.matches match
    group by match.club_id
  ),
  payments as (
    select payment.club_id,
           sum(payment.amount_cents) as paid_cents,
           max(payment.received_on) as last_payment_on
    from public.club_payments payment
    group by payment.club_id
  ),
  referrals as (
    select referral.referrer_club_id as club_id,
           count(*) as referrals_total,
           count(*) filter (where referral.qualified_at is not null) as referrals_paid
    from private.club_referrals referral
    group by referral.referrer_club_id
  ),
  rows as (
    select
      club.id, club.name, club.status, club.created_at,
      sub.status as subscription_status, sub.trial_ends_at, sub.current_period_end,
      sub.auto_suspended_at,
      case sub.status
        when 'trialing' then sub.trial_ends_at
        when 'active' then sub.current_period_end
      end as next_due_at,
      coalesce(members.members, 0) as members,
      coalesce(players.players, 0) as players,
      coalesce(visits.visits_30d, 0) as visits_30d,
      round(
        coalesce(visits.visits_30d, 0)::numeric
          / least(30, greatest(1, v_today - (club.created_at at time zone 'Europe/Paris')::date + 1)),
        1
      ) as visits_per_day,
      coalesce(visits.people_7d, 0) as people_7d,
      coalesce(visits.visits_today, 0) as visits_today,
      visits.last_visit_on,
      coalesce(matches.matches, 0) as matches,
      coalesce(payments.paid_cents, 0) as paid_cents,
      payments.last_payment_on,
      coalesce(referrals.referrals_total, 0) as referrals_total,
      coalesce(referrals.referrals_paid, 0) as referrals_paid,
      (select parent.name
       from private.club_referrals link
       join public.clubs parent on parent.id = link.referrer_club_id
       where link.referred_club_id = club.id) as referred_by,
      sub.base_price_cents,
      private.club_referral_discount_percent(club.id) as discount_percent,
      private.club_amount_due_cents(club.id) as amount_due_cents,
      case when club.status = 'suspended' and sub.auto_suspended_at is not null
        then sub.auto_suspended_at + private.unpaid_data_retention()
      end as deletion_at
    from public.clubs club
    left join public.club_subscriptions sub on sub.club_id = club.id
    left join members on members.club_id = club.id
    left join players on players.club_id = club.id
    left join visits on visits.club_id = club.id
    left join matches on matches.club_id = club.id
    left join payments on payments.club_id = club.id
    left join referrals on referrals.club_id = club.id
  )
  select
    coalesce(jsonb_agg(jsonb_build_object(
      'id', r.id,
      'name', r.name,
      'status', r.status,
      'created_at', r.created_at,
      'subscription_status', r.subscription_status,
      'trial_ends_at', r.trial_ends_at,
      'current_period_end', r.current_period_end,
      'next_due_at', r.next_due_at,
      'members', r.members,
      'players', r.players,
      'visits_30d', r.visits_30d,
      'visits_per_day', r.visits_per_day,
      'people_7d', r.people_7d,
      'visits_today', r.visits_today,
      'last_visit_on', r.last_visit_on,
      'matches', r.matches,
      'paid_cents', r.paid_cents,
      'last_payment_on', r.last_payment_on,
      'referrals_total', r.referrals_total,
      'referrals_paid', r.referrals_paid,
      'referred_by', r.referred_by,
      'base_price_cents', r.base_price_cents,
      'discount_percent', r.discount_percent,
      'amount_due_cents', r.amount_due_cents,
      'deletion_at', r.deletion_at
    ) order by r.created_at desc), '[]'::jsonb),
    jsonb_build_object(
      'clubs', count(*),
      'trialing', count(*) filter (where r.status = 'active' and r.subscription_status = 'trialing'),
      'paying', count(*) filter (where r.status = 'active' and r.subscription_status = 'active'),
      'suspended', count(*) filter (where r.status = 'suspended'),
      'new_30d', count(*) filter (where r.created_at > now() - interval '30 days'),
      'trials_ending_7d', count(*) filter (
        where r.status = 'active' and r.subscription_status = 'trialing'
          and r.trial_ends_at between now() and now() + interval '7 days'),
      'due_30d', count(*) filter (
        where r.status = 'active' and r.next_due_at < now() + interval '30 days'),
      'due_30d_cents', coalesce(sum(r.amount_due_cents) filter (
        where r.status = 'active' and r.next_due_at < now() + interval '30 days'), 0),
      'expected_12m_cents', coalesce(sum(r.amount_due_cents) filter (
        where r.status = 'active' and r.next_due_at < now() + interval '1 year'), 0),
      'members', coalesce(sum(r.members), 0),
      'players', coalesce(sum(r.players), 0),
      'visits_today', coalesce(sum(r.visits_today), 0),
      'people_7d', coalesce(sum(r.people_7d), 0),
      'collected_total_cents', (select coalesce(sum(amount_cents), 0) from public.club_payments),
      'collected_year_cents', (
        select coalesce(sum(amount_cents), 0) from public.club_payments
        where extract(year from received_on) = extract(year from v_today)),
      'to_delete_90d', count(*) filter (where r.deletion_at < now() + interval '90 days')
    )
  into v_clubs, v_totals
  from rows r;

  select jsonb_agg(jsonb_build_object('day', series.day::date, 'visits', coalesce(daily.visits, 0))
                   order by series.day)
  into v_daily
  from generate_series(v_today - 29, v_today, interval '1 day') as series(day)
  left join (
    select visit.day, count(*) as visits
    from private.profile_daily_visits visit
    where visit.day > v_today - 30
    group by visit.day
  ) daily on daily.day = series.day::date;

  return jsonb_build_object(
    'generated_at', now(),
    'clubs', v_clubs,
    'totals', v_totals,
    'daily_visits', v_daily
  );
end;
$$;
revoke all on function public.platform_control_overview() from public, anon;
grant execute on function public.platform_control_overview() to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Effacement des clubs impayés depuis 3 ans
-- ---------------------------------------------------------------------------

-- Un club suspendu pour impayé garde toutes ses données pendant 3 ans : s'il
-- paie, il retrouve tout. Au-delà, il est effacé avec ses comptes de
-- connexion (jamais ceux de l'éditeur). Un club suspendu à la main par
-- l'éditeur n'est jamais effacé automatiquement.
--
-- Un simple « delete from public.clubs » échoue dès qu'un club a joué
-- (journal des badges en ajout seul, gardes des matchs terminés) : même
-- méthode que le club de démo, table par table, gardes suspendues pour
-- cette transaction seulement.
create function private.purge_expired_clubs(p_now timestamptz default now()) returns integer
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
  for v_table in
    select namespace.nspname as schema_name, class.relname as table_name
    from pg_attribute attribute
    join pg_class class on class.oid = attribute.attrelid
    join pg_namespace namespace on namespace.oid = class.relnamespace
    where attribute.attname = 'club_id'
      and not attribute.attisdropped
      and class.relkind in ('r', 'p')
      and namespace.nspname in ('public', 'private')
  loop
    execute format('delete from %I.%I where club_id = any($1)', v_table.schema_name, v_table.table_name)
    using v_clubs;
  end loop;
  -- Parrainages où le club effacé était parrain (la colonne ne s'appelle pas
  -- club_id).
  delete from private.club_referrals where referrer_club_id = any(v_clubs) or referred_club_id = any(v_clubs);
  delete from public.clubs where id = any(v_clubs);
  set local session_replication_role = origin;

  delete from auth.users where id = any(v_users);

  return cardinality(v_clubs);
end;
$$;

revoke all on function private.purge_expired_clubs(timestamptz) from public, anon, authenticated;

select cron.schedule(
  'purge-expired-clubs',
  '43 3 * * *',
  $$select private.purge_expired_clubs()$$
);
