begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Une facture pour chaque paiement noté : attente tant que le SIRET ou
-- l'adresse du club manquent, numérotation sans trou, facture émise
-- définitive, lecture réservée aux administrateurs du club.
create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;

insert into test_clubs
select 'a', (public.create_club('Club Facture Alpha', 'FALPHA', null, null, null, null)).id;
insert into test_clubs
select 'b', (public.create_club('Club Facture Bravo', 'FBRAVO', null, null, null, null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select ('4e000000-0000-0000-0000-00000000000' || label)::uuid, 'inv-' || label || '@example.invalid',
  jsonb_build_object('first_name', 'Admin', 'last_name', upper(label)),
  jsonb_build_object('club_id', id)
from test_clubs;
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4e000000-0000-0000-0000-0000000000c1', 'inv-member@example.invalid',
  jsonb_build_object('first_name', 'Membre', 'last_name', 'Alpha'),
  jsonb_build_object('club_id', id)
from test_clubs where label = 'a';
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4e000000-0000-0000-0000-0000000000e1', 'inv-operator@example.invalid',
  jsonb_build_object('first_name', 'Editeur', 'last_name', 'App'),
  jsonb_build_object('club_id', id)
from test_clubs where label = 'b';

update public.profiles set status = 'active' where id::text like '4e000000-%';
update public.profiles set role = 'admin'
where id in ('4e000000-0000-0000-0000-00000000000a', '4e000000-0000-0000-0000-00000000000b');
insert into private.platform_operators (user_id) values ('4e000000-0000-0000-0000-0000000000e1');

create function pg_temp.act_as(p_user text) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_user, 'role', 'authenticated', 'aud', 'authenticated')::text, true);
end;
$$;

-- ---------------------------------------------------------------------------
-- Sans SIRET : facture en attente, invisible du club
-- ---------------------------------------------------------------------------

select pg_temp.act_as('4e000000-0000-0000-0000-0000000000e1');
set local role authenticated;

select is((public.platform_invoice_settings() ->> 'ready')::boolean, false,
  'sans coordonnées ni SIRET, les factures ne sont pas prêtes');

select lives_ok($$
  select public.platform_record_offline_payment(
    (select id from test_clubs where label = 'a'), 7900, 'virement', current_date, null)
$$, 'l''éditeur note un paiement sans SIRET');

select is((select count(*)::int from jsonb_array_elements(public.platform_list_invoices())
           where value ->> 'status' = 'pending' and value ->> 'blocker' = 'seller'),
  1, 'le paiement crée une facture en attente des coordonnées du vendeur');
select is((select value ->> 'number' from jsonb_array_elements(public.platform_list_invoices())),
  null, 'une facture en attente n''a pas de numéro');
reset role;

select pg_temp.act_as('4e000000-0000-0000-0000-00000000000a');
set local role authenticated;
select is((select count(*)::int from public.club_invoices), 0,
  'le club ne voit pas une facture en attente');
reset role;

-- ---------------------------------------------------------------------------
-- Coordonnées : SIRET contrôlé, adresse du club exigée
-- ---------------------------------------------------------------------------

select pg_temp.act_as('4e000000-0000-0000-0000-0000000000e1');
set local role authenticated;

select throws_ok($$
  select public.platform_save_invoice_settings('Petit Filet EI', '1 rue du Test, 31000 Toulouse', '1234', 'contact@example.invalid')
$$, '22023', 'Le SIRET compte 14 chiffres.', 'un SIRET mal formé est refusé');

select is((public.platform_save_invoice_settings(
  'Petit Filet EI', '1 rue du Test, 31000 Toulouse', '123 456 789 00012', 'contact@example.invalid'
) ->> 'ready')::boolean, true, 'avec toutes les coordonnées, les factures sont prêtes');

select is((public.platform_issue_pending_invoices() ->> 'issued')::int, 0,
  'sans adresse du club, la facture reste en attente');
select is((select value ->> 'blocker' from jsonb_array_elements(public.platform_list_invoices())),
  'buyer_address', 'la facture attend l''adresse du club');

select lives_ok($$
  select public.platform_set_club_billing_details(
    (select id from test_clubs where label = 'a'), 'Association Alpha', '2 place du Stade, 31150 Bruguières')
$$, 'l''éditeur saisit les coordonnées de facturation du club');

select is(public.platform_issue_pending_invoices(), '{"issued": 1, "pending": 0}'::jsonb,
  'la facture en attente est émise');
reset role;

select is((select number from public.club_invoices
           where club_id = (select id from test_clubs where label = 'a')),
  'PF-' || extract(year from (now() at time zone 'Europe/Paris'))::int || '-0001',
  'la première facture de l''année porte le numéro 0001');
select is((select seller ->> 'siret' from public.club_invoices
           where club_id = (select id from test_clubs where label = 'a')),
  '12345678900012', 'le SIRET est figé sur la facture');
select is((select buyer_name || ' / ' || buyer_address from public.club_invoices
           where club_id = (select id from test_clubs where label = 'a')),
  'Association Alpha / 2 place du Stade, 31150 Bruguières', 'le client est figé sur la facture');

-- ---------------------------------------------------------------------------
-- Paiement suivant : émis aussitôt, numéro suivant
-- ---------------------------------------------------------------------------

update public.club_subscriptions set billing_address = '3 allée Bravo, 31000 Toulouse'
where club_id = (select id from test_clubs where label = 'b');

select pg_temp.act_as('4e000000-0000-0000-0000-0000000000e1');
set local role authenticated;
select lives_ok($$
  select public.platform_record_offline_payment(
    (select id from test_clubs where label = 'b'), 7900, 'cheque', current_date, null)
$$, 'un paiement noté une fois tout renseigné');
reset role;

select is((select number from public.club_invoices
           where club_id = (select id from test_clubs where label = 'b')),
  'PF-' || extract(year from (now() at time zone 'Europe/Paris'))::int || '-0002',
  'la facture est émise aussitôt avec le numéro suivant');
select is((select buyer_name from public.club_invoices
           where club_id = (select id from test_clubs where label = 'b')),
  'Club Facture Bravo', 'à défaut de nom de facturation, le nom du club est utilisé');

-- ---------------------------------------------------------------------------
-- Facture émise définitive
-- ---------------------------------------------------------------------------

select throws_ok($$
  update public.club_invoices set amount_cents = 1
  where club_id = (select id from test_clubs where label = 'a')
$$, '42501', 'Une facture émise ne peut pas être modifiée.', 'une facture émise ne se modifie pas');
select throws_ok($$
  delete from public.club_invoices where club_id = (select id from test_clubs where label = 'a')
$$, '42501', 'Une facture émise ne peut pas être supprimée.', 'une facture émise ne se supprime pas');

select pg_temp.act_as('4e000000-0000-0000-0000-0000000000e1');
set local role authenticated;
select throws_ok(format(
  'select public.platform_discard_pending_invoice(%L)',
  (select id from public.club_invoices where club_id = (select id from test_clubs where label = 'a'))
), '42501', 'Seule une facture en attente peut être écartée.', 'l''éditeur ne peut pas écarter une facture émise');
reset role;

-- ---------------------------------------------------------------------------
-- Lecture par rôle
-- ---------------------------------------------------------------------------

select pg_temp.act_as('4e000000-0000-0000-0000-00000000000a');
set local role authenticated;
select is((select count(*)::int from public.club_invoices), 1,
  'l''administrateur voit la facture de son club et seulement elle');
select throws_ok($$ select public.platform_list_invoices() $$, '42501', null,
  'un administrateur de club ne voit pas la liste de toutes les factures');
select throws_ok($$ select public.platform_issue_pending_invoices() $$, '42501', null,
  'un administrateur de club ne peut pas émettre de facture');
reset role;

select pg_temp.act_as('4e000000-0000-0000-0000-0000000000c1');
set local role authenticated;
select is((select count(*)::int from public.club_invoices), 0,
  'un membre non administrateur ne voit pas les factures');
reset role;

-- ---------------------------------------------------------------------------
-- Suppression du club : la facture émise reste
-- ---------------------------------------------------------------------------

delete from public.clubs where id = (select id from test_clubs where label = 'a');
select is((select count(*)::int from public.club_invoices
           where number = 'PF-' || extract(year from (now() at time zone 'Europe/Paris'))::int || '-0001'
             and club_id is null and payment_id is null),
  1, 'la facture émise survit à la suppression du club');

select * from finish();
rollback;
