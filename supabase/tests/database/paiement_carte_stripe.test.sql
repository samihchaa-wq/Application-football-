begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Paiement par carte (Stripe) : montant figé au clic avec le parrainage,
-- confirmation réservée au serveur, idempotente, club suspendu qui rouvre,
-- année offerte à 100 %.

select ok(
  not has_function_privilege('anon', 'public.admin_prepare_card_payment()', 'EXECUTE'),
  'un visiteur anonyme ne prépare pas de paiement'
);
select ok(
  not has_function_privilege('authenticated', 'public.stripe_record_card_payment(uuid,text,integer,text)', 'EXECUTE'),
  'un compte connecté ne peut pas confirmer un paiement à la place de Stripe'
);
select ok(
  not has_function_privilege('authenticated',
    'private.apply_club_payment(uuid,integer,text,date,text,uuid,integer,integer,text)', 'EXECUTE'),
  'l’enregistrement commun d’un paiement reste interne'
);

create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;
insert into test_clubs
select 'parrain', (public.create_club('Club Carte Parrain', 'CPAR', null, null, null, null)).id;
insert into test_clubs
select 'filleul', (public.create_club('Club Carte Filleul', 'CFIL', null, null, null, null)).id;
insert into test_clubs
select 'autre', (public.create_club('Club Carte Autre', 'CAUT', null, null, null, null)).id;
select public.attach_club_referral(
  (select id from test_clubs where label = 'filleul'),
  (select referral_code from public.clubs where id = (select id from test_clubs where label = 'parrain'))
);

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select v.id::uuid, v.id || '@example.invalid',
  jsonb_build_object('first_name', 'Test', 'last_name', v.label),
  jsonb_build_object('club_id', (select id from test_clubs where label = v.club))
from (values
  ('7a000000-0000-0000-0000-000000000001', 'AdminParrain', 'parrain'),
  ('7a000000-0000-0000-0000-000000000002', 'AdminFilleul', 'filleul'),
  ('7a000000-0000-0000-0000-000000000003', 'Membre', 'filleul'),
  ('7a000000-0000-0000-0000-000000000004', 'AdminAutre', 'autre')
) as v(id, label, club);
update public.profiles set status = 'active' where id::text like '7a000000-%';
update public.profiles set role = 'admin'
where id in ('7a000000-0000-0000-0000-000000000001', '7a000000-0000-0000-0000-000000000002',
             '7a000000-0000-0000-0000-000000000004');

create function pg_temp.act_as(p_id text) returns void language sql as $$
  select set_config('request.jwt.claims',
    format('{"sub":"%s","role":"authenticated","aud":"authenticated"}', p_id), true);
$$;
create function pg_temp.as_server() returns void language sql as $$
  select set_config('request.jwt.claims', '{"role":"service_role"}', true);
$$;
create temporary table checkouts (label text primary key, payload jsonb) on commit drop;
grant all on checkouts to authenticated, service_role;

-- Un simple membre ne prépare rien.
select pg_temp.act_as('7a000000-0000-0000-0000-000000000003');
set local role authenticated;
select throws_ok($$select public.admin_prepare_card_payment()$$, '42501', null,
  'un simple membre ne peut pas payer pour le club');
reset role;

-- L'admin du filleul : −5 % de bienvenue, figés au clic.
select pg_temp.act_as('7a000000-0000-0000-0000-000000000002');
set local role authenticated;
insert into checkouts select 'filleul', public.admin_prepare_card_payment();
reset role;
select is((select (payload ->> 'amount_cents')::int from checkouts where label = 'filleul'), 7505,
  'le club parrainé paie 75,05 € par carte');

-- Un autre admin connecté ne peut pas confirmer ; le serveur oui.
select pg_temp.act_as('7a000000-0000-0000-0000-000000000004');
select throws_ok(
  format($$select public.stripe_record_card_payment(%L, 'cs_test_x', 7505, 'eur')$$,
         (select payload ->> 'checkout_id' from checkouts where label = 'filleul')),
  '42501', null, 'seul le serveur confirme un paiement'
);

select pg_temp.as_server();
select throws_ok(
  format($$select public.stripe_record_card_payment(%L, 'cs_test_1', 100, 'eur')$$,
         (select payload ->> 'checkout_id' from checkouts where label = 'filleul')),
  '22023', null, 'un montant différent du montant figé est refusé'
);
select is(
  (public.stripe_record_card_payment(
     (select (payload ->> 'checkout_id')::uuid from checkouts where label = 'filleul'),
     'cs_test_1', 7505, 'EUR') ->> 'already_recorded'),
  'false', 'le paiement confirmé par Stripe est enregistré'
);
select is(
  (public.stripe_record_card_payment(
     (select (payload ->> 'checkout_id')::uuid from checkouts where label = 'filleul'),
     'cs_test_1', 7505, 'eur') ->> 'already_recorded'),
  'true', 'une confirmation reçue deux fois ne crée pas un second paiement'
);
select is(
  (select count(*)::int from public.club_payments
   where club_id = (select id from test_clubs where label = 'filleul') and method = 'carte'),
  1, 'un seul paiement par carte noté'
);
select is(
  (select status from public.club_subscriptions where club_id = (select id from test_clubs where label = 'filleul')),
  'active', 'l’abonnement du filleul est actif'
);
select is(private.club_amount_due_cents((select id from test_clubs where label = 'filleul')), 7900,
  'la réduction de bienvenue est utilisée');
select is(private.club_referral_discount_percent((select id from test_clubs where label = 'parrain')), 5,
  'le filleul payé par carte fait gagner 5 % à son parrain');
select is(
  (select count(*)::int from public.club_invoices
   where club_id = (select id from test_clubs where label = 'filleul') and payment_method = 'carte'),
  1, 'une facture (émise ou en attente) suit le paiement par carte'
);

-- Le parrain : réduction figée au clic, puis un nouveau filleul paie avant
-- la confirmation : sa réduction reste pour l'année suivante.
select pg_temp.act_as('7a000000-0000-0000-0000-000000000001');
set local role authenticated;
insert into checkouts select 'parrain', public.admin_prepare_card_payment();
reset role;
select is((select (payload ->> 'amount_cents')::int from checkouts where label = 'parrain'), 7505,
  'le parrain paie 75,05 € par carte');
select is((select (payload ->> 'discount_percent')::int from checkouts where label = 'parrain'), 5,
  'la réduction figée est de 5 %');

insert into test_clubs
select 'filleul2', (public.create_club('Club Carte Filleul 2', 'CFI2', null, null, null, null)).id;
select public.attach_club_referral(
  (select id from test_clubs where label = 'filleul2'),
  (select referral_code from public.clubs where id = (select id from test_clubs where label = 'parrain'))
);
select private.apply_club_payment((select id from test_clubs where label = 'filleul2'),
  7505, 'virement', current_date, null, null);
select is(private.club_referral_discount_percent((select id from test_clubs where label = 'parrain')), 10,
  'un second filleul paie pendant que le parrain est sur la page de paiement');

select pg_temp.as_server();
select lives_ok(
  format($$select public.stripe_record_card_payment(%L, 'cs_test_2', 7505, 'eur')$$,
         (select payload ->> 'checkout_id' from checkouts where label = 'parrain')),
  'le parrain paie le montant figé'
);
select is(private.club_referral_discount_percent((select id from test_clubs where label = 'parrain')), 5,
  'seule la réduction figée est utilisée ; celle du second filleul reste pour l’an prochain');

-- Club suspendu pour impayé : son admin peut payer pour rouvrir.
update public.club_subscriptions
set auto_suspended_at = now(), status = 'trialing', trial_ends_at = now() - interval '20 days'
where club_id = (select id from test_clubs where label = 'autre');
update public.clubs set status = 'suspended' where id = (select id from test_clubs where label = 'autre');

select pg_temp.act_as('7a000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into checkouts select 'autre', public.admin_prepare_card_payment();
reset role;
select is((select (payload ->> 'amount_cents')::int from checkouts where label = 'autre'), 7900,
  'l’admin d’un club suspendu pour impayé peut payer');
select pg_temp.as_server();
select is(
  (public.stripe_record_card_payment(
     (select (payload ->> 'checkout_id')::uuid from checkouts where label = 'autre'),
     'cs_test_3', 7900, 'eur') ->> 'reopened'),
  'true', 'le paiement par carte rouvre le club'
);
select is((select status from public.clubs where id = (select id from test_clubs where label = 'autre')),
  'active', 'le club est de nouveau actif');

-- Année offerte : seulement à 100 %.
select pg_temp.act_as('7a000000-0000-0000-0000-000000000004');
set local role authenticated;
select throws_ok($$select public.admin_claim_free_year()$$, '22023', null,
  'pas d’année offerte tant qu’il reste un montant à payer');
reset role;

update public.club_subscriptions set base_price_cents = 0
where club_id = (select id from test_clubs where label = 'parrain');
update public.club_subscriptions set current_period_end = now() + interval '10 days'
where club_id = (select id from test_clubs where label = 'parrain');
select pg_temp.act_as('7a000000-0000-0000-0000-000000000001');
set local role authenticated;
select throws_ok($$select public.admin_prepare_card_payment()$$, '22023', null,
  'rien à payer : pas de paiement par carte');
select lives_ok($$select public.admin_claim_free_year()$$,
  'à 100 %, l’admin active lui-même son année offerte');
select throws_ok($$select public.admin_claim_free_year()$$, '22023', null,
  'l’année offerte ne se réclame pas deux fois d’avance');
reset role;

-- Le paiement noté à la main refuse la carte.
select ok(
  not exists (select 1 from public.club_payments where method = 'carte' and stripe_checkout_session_id is null),
  'tout paiement par carte porte son identifiant Stripe'
);

select * from finish();
rollback;
