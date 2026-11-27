begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Abonnement d'un club : note interne et identifiants Stripe réservés à
-- l'éditeur ; message adapté quand un club déjà payé ouvre le paiement carte.

select ok(
  not has_column_privilege('authenticated', 'public.club_subscriptions', 'notes', 'SELECT'),
  'un compte connecté ne lit pas la note interne de l''abonnement'
);
select ok(
  not has_column_privilege('authenticated', 'public.club_subscriptions', 'stripe_customer_id', 'SELECT'),
  'un compte connecté ne lit pas l''identifiant client Stripe'
);
select ok(
  not has_column_privilege('authenticated', 'public.club_subscriptions', 'stripe_subscription_id', 'SELECT'),
  'un compte connecté ne lit pas l''identifiant d''abonnement Stripe'
);
select ok(
  has_column_privilege('authenticated', 'public.club_subscriptions', 'current_period_end', 'SELECT'),
  'la date de fin de période reste lisible'
);

create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;
insert into test_clubs
select 'paye', (public.create_club('Club Reserve Paye', 'RPAYE', null, null, null, null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '7b000000-0000-0000-0000-000000000001', 'reserve-admin@example.invalid',
  jsonb_build_object('first_name', 'Admin', 'last_name', 'Paye'),
  jsonb_build_object('club_id', id)
from test_clubs where label = 'paye';
update public.profiles set status = 'active', role = 'admin'
where id = '7b000000-0000-0000-0000-000000000001';

-- Club offert et payé jusqu'en 2036, avec une note interne et des ids Stripe.
update public.club_subscriptions
set status = 'active',
    base_price_cents = 0,
    current_period_end = '2036-06-30 12:00:00+00',
    notes = 'ne pas facturer ni suspendre',
    stripe_customer_id = 'cus_test_reserve',
    stripe_subscription_id = 'sub_test_reserve'
where club_id = (select id from test_clubs where label = 'paye');

select set_config('request.jwt.claims',
  '{"sub":"7b000000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select is(
  (select count(*) from public.club_subscriptions), 1::bigint,
  'l''admin voit toujours la ligne d''abonnement de son club'
);
select is(
  (select status from public.club_subscriptions), 'active',
  'l''admin lit encore l''état de son abonnement'
);
select throws_ok(
  $$select notes from public.club_subscriptions$$,
  '42501', null,
  'l''admin du club ne lit pas la note interne'
);
select throws_ok(
  $$select stripe_customer_id, stripe_subscription_id from public.club_subscriptions$$,
  '42501', null,
  'l''admin du club ne lit pas les identifiants Stripe'
);
select ok(
  not (public.admin_get_club_subscription() ? 'notes'),
  'le résumé d''abonnement ne contient pas la note interne'
);
select throws_ok(
  $$select public.admin_prepare_card_payment()$$,
  '22023',
  'Ton abonnement est déjà réglé jusqu''au 30/06/2036.',
  'un club déjà payé reçoit la date de fin, pas l''année offerte'
);
reset role;

select * from finish();
rollback;
