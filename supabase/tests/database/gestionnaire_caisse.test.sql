begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Gestionnaire de l'éditeur : réglages de l'offre, périodes offertes,
-- paiement avec référence, remboursements et avoirs, suivi Stripe,
-- registre de caisse, conservation des factures à l'effacement.

create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;
insert into test_clubs
select 'a', (public.create_club('Club Caisse Alpha', 'CCA', null, null, null, null)).id;
insert into test_clubs
select 'b', (public.create_club('Club Caisse Bravo', 'CCB', null, null, null, null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select v.id::uuid, v.id || '@example.invalid',
  jsonb_build_object('first_name', v.first_name, 'last_name', 'Tests'),
  jsonb_build_object('club_id', (select id from test_clubs where label = v.club))
from (values
  ('8c000000-0000-0000-0000-00000000000a', 'Admin', 'a'),
  ('8c000000-0000-0000-0000-0000000000e1', 'Editeur', 'b')
) as v(id, first_name, club);
update public.profiles set status = 'active' where id::text like '8c000000-%';
update public.profiles set role = 'admin' where id = '8c000000-0000-0000-0000-00000000000a';
insert into private.platform_operators (user_id) values ('8c000000-0000-0000-0000-0000000000e1');

create function pg_temp.act_as(p_id text) returns void language sql as $$
  select set_config('request.jwt.claims',
    format('{"sub":"%s","role":"authenticated","aud":"authenticated"}', p_id), true);
$$;
create function pg_temp.as_server() returns void language sql as $$
  select set_config('request.jwt.claims', '{"role":"service_role"}', true);
$$;
create function pg_temp.club(p_label text) returns uuid language sql as $$
  select id from test_clubs where label = p_label
$$;

-- Un administrateur de club n'a accès à rien.
select pg_temp.act_as('8c000000-0000-0000-0000-00000000000a');
set local role authenticated;
select throws_ok($$select public.platform_ledger(current_date - 30, current_date)$$,
  '42501', null, 'un administrateur de club ne lit pas la caisse');
select throws_ok(
  format($$select public.platform_grant_free_period(%L, 3, 0, 'test')$$, pg_temp.club('a')),
  '42501', null, 'un administrateur de club ne s''offre pas de mois gratuits');
select throws_ok($$select public.platform_save_billing_settings(1, 5, 100, 30)$$,
  '42501', null, 'un administrateur de club ne change pas l''offre');
reset role;

select ok(
  not has_function_privilege('authenticated', 'public.stripe_record_refund(text,text,integer,text)', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.stripe_record_dispute(text,text,integer,text,text)', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.stripe_log_event(text,text,boolean,boolean,text)', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.stripe_attach_card_details(text,text,integer,text)', 'EXECUTE'),
  'les fonctions de Stripe sont réservées au serveur'
);

-- ---------------------------------------------------------------------------
-- Réglages de l'offre
-- ---------------------------------------------------------------------------

select pg_temp.act_as('8c000000-0000-0000-0000-0000000000e1');
set local role authenticated;
select is((public.platform_billing_settings() ->> 'base_price_cents')::int, 7900,
  'tarif par défaut : 79 €');
select throws_ok($$select public.platform_save_billing_settings(7900, 50, 10, 30)$$,
  '22023', null, 'un taux de parrainage au-dessus du plafond est refusé');
select is(
  (public.platform_save_billing_settings(8900, 10, 100, 60) ->> 'trial_days')::int, 60,
  'l''éditeur change l''offre');
reset role;

select set_config('request.jwt.claims', '', true);
insert into test_clubs
select 'nouveau', (public.create_club('Club Caisse Nouveau', 'CCN', null, null, null, null)).id;
select is(
  (select base_price_cents from public.club_subscriptions where club_id = pg_temp.club('nouveau')),
  8900, 'un nouveau club reçoit le tarif des réglages');
select ok(
  (select trial_ends_at from public.club_subscriptions where club_id = pg_temp.club('nouveau'))
    between now() + interval '59 days' and now() + interval '61 days',
  'et la durée d''essai des réglages');
select is(private.referral_rate_percent(), 10, 'le parrainage suit les réglages');
select is(
  (select base_price_cents from public.club_subscriptions where club_id = pg_temp.club('a')),
  7900, 'les clubs existants gardent leur tarif');
update private.billing_settings set base_price_cents = 7900, referral_rate_percent = 5, trial_days = 30;

-- ---------------------------------------------------------------------------
-- Périodes offertes
-- ---------------------------------------------------------------------------

select pg_temp.act_as('8c000000-0000-0000-0000-0000000000e1');
set local role authenticated;
select throws_ok(
  format($$select public.platform_grant_free_period(%L, 1, 0, '')$$, pg_temp.club('a')),
  '22023', null, 'un motif est obligatoire');
select throws_ok(
  format($$select public.platform_grant_free_period(%L, 0, 0, 'Rien')$$, pg_temp.club('a')),
  '22023', null, 'une durée nulle est refusée');
select is(
  public.platform_grant_free_period(pg_temp.club('a'), 0, 15, 'Essai prolongé : rentrée') ->> 'kind',
  'trial_extension', 'en essai : l''essai est prolongé');
reset role;
select ok(
  (select trial_ends_at from public.club_subscriptions where club_id = pg_temp.club('a'))
    between now() + interval '44 days' and now() + interval '46 days',
  'l''essai de 30 jours passe à 45 jours');

-- Club suspendu pour impayé : 3 mois offerts le rouvrent.
update public.club_subscriptions
set status = 'active', current_period_end = now() - interval '2 days', auto_suspended_at = now()
where club_id = pg_temp.club('b');
update public.clubs set status = 'suspended' where id = pg_temp.club('b');
select pg_temp.act_as('8c000000-0000-0000-0000-0000000000e1');
set local role authenticated;
select is(
  public.platform_grant_free_period(pg_temp.club('b'), 3, 0, 'Geste commercial') ->> 'reopened',
  'true', 'des mois offerts rouvrent un club suspendu pour impayé');
reset role;
select is((select status from public.clubs where id = pg_temp.club('b')), 'active',
  'le club est rouvert');
select ok(
  (select current_period_end from public.club_subscriptions where club_id = pg_temp.club('b'))
    between now() + interval '88 days' and now() + interval '93 days',
  '3 mois à partir d''aujourd''hui');
select is((select count(*)::int from public.club_payments where club_id = pg_temp.club('b')), 0,
  'une période offerte n''est pas un paiement (pas de facture)');

-- ---------------------------------------------------------------------------
-- Paiement avec référence, remboursement et avoir
-- ---------------------------------------------------------------------------

update private.invoice_settings
set seller_name = 'Éditeur Test', seller_address = '1 rue Test, Paris',
    siret = '12345678900012', contact_email = 'editeur@example.invalid';
-- Adresse postale saisie par le club : sert d'adresse de facturation.
update public.club_settings set postal_address = '3 rue du Stade, 31000 Toulouse'
where club_id = pg_temp.club('a');

select pg_temp.act_as('8c000000-0000-0000-0000-0000000000e1');
set local role authenticated;
select lives_ok(
  format($$select public.platform_record_manual_payment(%L, 7900, 'cheque', current_date, null, 'Chèque n° 1234567, Crédit Agricole')$$,
         pg_temp.club('a')),
  'l''éditeur note un chèque avec sa référence');
reset role;
select is(
  (select reference from public.club_payments where club_id = pg_temp.club('a')),
  'Chèque n° 1234567, Crédit Agricole', 'la référence est enregistrée');
select is(
  (select status from public.club_invoices where club_id = pg_temp.club('a')),
  'issued', 'la facture est émise grâce à l''adresse postale du club');
select is(
  (select buyer_address from public.club_invoices where club_id = pg_temp.club('a')),
  '3 rue du Stade, 31000 Toulouse', 'avec l''adresse saisie par le club');

-- Identifiant du paiement lu hors session simulée (le cloisonnement entre
-- clubs le cache à l'éditeur quand il interroge la table directement).
create temporary table test_payment on commit drop as
select id from public.club_payments where club_id = pg_temp.club('a');
grant select on test_payment to authenticated;

select pg_temp.act_as('8c000000-0000-0000-0000-0000000000e1');
set local role authenticated;
select throws_ok(
  format($$select public.platform_record_refund(%L, 9000, 'cheque', 'trop')$$,
         (select id from test_payment)),
  '22023', null, 'on ne rembourse pas plus que le paiement');
select throws_ok(
  format($$select public.platform_record_refund(%L, 100, 'carte', 'sans Stripe')$$,
         (select id from test_payment)),
  '22023', null, 'une carte ne se rembourse pas à la main');
select ok(
  public.platform_record_refund(
    (select id from test_payment),
    2900, 'cheque', 'Geste : 5 joueurs de moins') ->> 'credit_note_number' ~ '^AV-[0-9]{4}-[0-9]{4}$',
  'un remboursement partiel crée un avoir numéroté');
reset role;
select is((select refunded_cents from public.club_payments where club_id = pg_temp.club('a')), 2900,
  'le paiement garde la trace du montant remboursé');
select is(
  (select invoice_number from private.club_refunds where club_id = pg_temp.club('a')),
  (select number from public.club_invoices where club_id = pg_temp.club('a')),
  'l''avoir renvoie à sa facture');

-- ---------------------------------------------------------------------------
-- Suivi Stripe
-- ---------------------------------------------------------------------------

-- Paiement par carte simulé, puis détails, remboursement et contestation.
select private.apply_club_payment(pg_temp.club('b'), 7900, 'carte', current_date,
  'Paiement par carte (Stripe)', null, 0, 0, 'cs_test_caisse');
select pg_temp.as_server();
select lives_ok(
  $$select public.stripe_attach_card_details('cs_test_caisse', 'pi_test_caisse', 145, 'https://pay.stripe.com/receipts/test')$$,
  'le serveur ajoute frais et reçu au paiement par carte');
select is(
  (select stripe_fee_cents from public.club_payments where stripe_checkout_session_id = 'cs_test_caisse'),
  145, 'les frais Stripe sont connus');
select is(
  public.stripe_record_refund('pi_test_caisse', 're_test_1', 1000, 'requested_by_customer') ->> 'already_recorded',
  'false', 'un remboursement fait dans Stripe est enregistré');
select is(
  public.stripe_record_refund('pi_test_caisse', 're_test_1', 1000, 'requested_by_customer') ->> 'already_recorded',
  'true', 'reçu deux fois, il ne compte qu''une fois');
select is(
  public.stripe_record_refund('pi_inconnu', 're_test_2', 500, null) ->> 'matched',
  'false', 'un remboursement sans paiement connu devient une alerte');
select lives_ok(
  $$select public.stripe_record_dispute('dp_test_1', 'pi_test_caisse', 7900, 'fraudulent', 'needs_response')$$,
  'une contestation est enregistrée');
select lives_ok(
  $$select public.stripe_log_event('evt_test_1', 'checkout.session.completed', false, true)$$,
  'chaque événement Stripe est tracé');
reset role;

select pg_temp.act_as('8c000000-0000-0000-0000-0000000000e1');
set local role authenticated;
select is(
  jsonb_array_length(public.platform_payment_alerts() -> 'alerts'), 2,
  'deux alertes à traiter : contestation et remboursement inconnu');
select is(
  (public.platform_payment_alerts() #>> '{stripe,events_7d}')::int, 1,
  'l''éditeur voit que Stripe envoie bien ses confirmations');
reset role;
create temporary table test_alert on commit drop as
select id from private.payment_alerts where stripe_object_id = 'dp_test_1';
grant select on test_alert to authenticated;
set local role authenticated;
select lives_ok(
  format($$select public.platform_resolve_alert(%L)$$, (select id from test_alert)),
  'l''éditeur marque la contestation comme traitée');
reset role;
select pg_temp.as_server();
select public.stripe_record_dispute('dp_test_1', 'pi_test_caisse', 7900, 'fraudulent', 'lost');
reset role;
select is(
  (select resolved_at from private.payment_alerts where stripe_object_id = 'dp_test_1'), null,
  'une contestation qui évolue redevient à traiter');

-- ---------------------------------------------------------------------------
-- Registre de caisse
-- ---------------------------------------------------------------------------

-- Lu au nom de l'éditeur (le contrôle d'accès suit le jeton simulé).
select pg_temp.act_as('8c000000-0000-0000-0000-0000000000e1');
create temporary table ledger on commit drop as
select public.platform_ledger(current_date - 1, current_date + 1) as value;
select is((select (value #>> '{totals,collected_cents}')::int from ledger), 15800,
  'encaissé : un chèque et une carte de 79 €');
select is((select (value #>> '{totals,refunded_cents}')::int from ledger), 3900,
  'remboursé : 29 € + 10 €');
select is((select (value #>> '{totals,fees_cents}')::int from ledger), 145,
  'frais Stripe : 1,45 €');
select is((select (value #>> '{totals,net_cents}')::int from ledger), 15800 - 3900 - 145,
  'net = encaissé − remboursé − frais');
select is((select (value #>> '{totals,gifts}')::int from ledger), 2,
  'les deux périodes offertes figurent au registre');
select is((select (value #>> '{totals,by_method,cheque}')::int from ledger), 7900,
  'répartition par moyen de paiement');

-- ---------------------------------------------------------------------------
-- Effacement d'un club impayé : factures et avoirs gardés
-- ---------------------------------------------------------------------------

select set_config('request.jwt.claims', '', true);
update public.club_subscriptions set auto_suspended_at = now() - interval '3 years 1 day'
where club_id = pg_temp.club('a');
update public.clubs set status = 'suspended' where id = pg_temp.club('a');
select is(private.purge_expired_clubs(), 1, 'le club impayé depuis 3 ans est effacé');
select is(
  (select count(*)::int from public.club_invoices
   where buyer_name = 'Club Caisse Alpha' and status = 'issued' and club_id is null),
  1, 'sa facture émise est conservée');
select is(
  (select count(*)::int from private.club_refunds
   where credit_note_number is not null and club_id is null and buyer_name = 'Club Caisse Alpha'),
  1, 'son avoir aussi');

select * from finish();
rollback;
