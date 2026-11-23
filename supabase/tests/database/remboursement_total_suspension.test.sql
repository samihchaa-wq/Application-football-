begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Remboursement total du dernier paiement : le club est suspendu tout de
-- suite. Remboursement partiel : rien ne change.

create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
insert into test_clubs
select 'a', (public.create_club('Club Rembourse Alpha', 'CRA', null, null, null, null)).id;
insert into test_clubs
select 'b', (public.create_club('Club Rembourse Bravo', 'CRB', null, null, null, null)).id;

create function pg_temp.club(p_label text) returns uuid language sql as $$
  select id from test_clubs where label = p_label
$$;

insert into public.club_payments (club_id, amount_cents, method, received_on, period_end)
values
  (pg_temp.club('a'), 7900, 'cheque', current_date, now() + interval '1 year'),
  (pg_temp.club('b'), 7900, 'cheque', current_date, now() + interval '1 year');
update public.club_subscriptions set status = 'active', current_period_end = now() + interval '1 year'
where club_id in (pg_temp.club('a'), pg_temp.club('b'));

-- Partiel : le club reste actif.
select private.apply_refund(
  (select id from public.club_payments where club_id = pg_temp.club('a')),
  2900, 'cheque', 'geste', null, null);
select is((select status from public.clubs where id = pg_temp.club('a')), 'active',
  'un remboursement partiel ne suspend pas le club');

-- Total (le solde restant) : suspendu, abonnement arrêté.
select is(
  private.apply_refund(
    (select id from public.club_payments where club_id = pg_temp.club('a')),
    5000, 'cheque', 'solde', null, null) ->> 'club_suspended',
  'true', 'le remboursement total le dit');
select is((select status from public.clubs where id = pg_temp.club('a')), 'suspended',
  'remboursement total : le club est suspendu tout de suite');
select is((select status from public.club_subscriptions where club_id = pg_temp.club('a')), 'canceled',
  'l''abonnement est arrêté');
select ok((select current_period_end <= now() from public.club_subscriptions where club_id = pg_temp.club('a')),
  'l''échéance est ramenée à maintenant');
select is((select auto_suspended_at from public.club_subscriptions where club_id = pg_temp.club('a')), null,
  'suspension manuelle : jamais dans la purge des clubs impayés');

-- Total d'un paiement qui n'est pas le dernier : rien ne bouge.
insert into public.club_payments (club_id, amount_cents, method, received_on, period_end, created_at)
values (pg_temp.club('b'), 7900, 'cheque', current_date, now() + interval '2 years', now() + interval '1 hour');
select private.apply_refund(
  (select id from public.club_payments where club_id = pg_temp.club('b') and created_at < now() + interval '30 minutes'),
  7900, 'cheque', 'ancien paiement', null, null);
select is((select status from public.clubs where id = pg_temp.club('b')), 'active',
  'rembourser un ancien paiement ne suspend pas le club');

select * from finish();
rollback;
