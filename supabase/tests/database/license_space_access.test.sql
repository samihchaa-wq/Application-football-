begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Espace Licence : licences payées, dépenses du club et paiements de ces
-- dépenses. Seuls les administrateurs du club lisent et écrivent ; un joueur
-- du même club ne voit rien ; un autre club ne voit ni ne touche rien.
-- La transaction est annulée à la fin.
create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;

insert into test_clubs
select 'a', (public.create_club('Club Licence Alpha', 'LICA', '#112233', '#FFFFFF', 'Europe/Paris', null)).id;
insert into test_clubs
select 'b', (public.create_club('Club Licence Bravo', 'LICB', '#332211', '#000000', 'Europe/Paris', null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select u.id, u.email,
       jsonb_build_object('first_name', u.first_name, 'last_name', u.last_name),
       jsonb_build_object('club_id', c.id)
from (values
  ('7a000000-0000-0000-0000-00000000000a'::uuid, 'licence-admin-a@example.invalid', 'Admin', 'Alpha', 'a'),
  ('7a000000-0000-0000-0000-0000000000aa'::uuid, 'licence-joueur-a@example.invalid', 'Joueur', 'Alpha', 'a'),
  ('7a000000-0000-0000-0000-00000000000b'::uuid, 'licence-admin-b@example.invalid', 'Admin', 'Bravo', 'b')
) as u(id, email, first_name, last_name, club)
join test_clubs c on c.label = u.club;

update public.profiles set status = 'active', role = 'pronostiqueur'
where id = '7a000000-0000-0000-0000-0000000000aa';
update public.profiles set status = 'active', role = 'admin'
where id in ('7a000000-0000-0000-0000-00000000000a', '7a000000-0000-0000-0000-00000000000b');

insert into public.seasons (id, name, status, club_id)
select '7b000000-0000-0000-0000-00000000000a', '2097-2098', 'open', id from test_clubs where label = 'a';
insert into public.seasons (id, name, status, club_id)
select '7b000000-0000-0000-0000-00000000000b', '2097-2098', 'open', id from test_clubs where label = 'b';

-- Saison précédente d'Alpha, avec le même joueur.
insert into public.seasons (id, name, status, club_id)
select '7b000000-0000-0000-0000-0000000000a0', '2096-2097', 'terminee', id from test_clubs where label = 'a';
insert into public.season_players (id, season_id, first_name, last_name, club_id)
select '7c000000-0000-0000-0000-0000000000a0', '7b000000-0000-0000-0000-0000000000a0',
       'Joueur', 'Alpha', id
from test_clubs where label = 'a';

insert into public.season_players (id, season_id, first_name, last_name, club_id, profile_id)
select '7c000000-0000-0000-0000-00000000000a', '7b000000-0000-0000-0000-00000000000a',
       'Joueur', 'Alpha', id, '7a000000-0000-0000-0000-0000000000aa'
from test_clubs where label = 'a';
insert into public.season_players (id, season_id, first_name, last_name, club_id)
select '7c000000-0000-0000-0000-00000000000b', '7b000000-0000-0000-0000-00000000000b',
       'Joueur', 'Bravo', id
from test_clubs where label = 'b';

-- ---------------------------------------------------------------------------
-- Administrateur d'Alpha : tout est possible dans son club.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"7a000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $$insert into public.club_license_expenses (id, season_id, label)
    values ('7d000000-0000-0000-0000-00000000000a', '7b000000-0000-0000-0000-00000000000a', 'Survêtement')$$,
  'l’admin crée une dépense pour son club'
);
select is(
  (select club_id from public.club_license_expenses where id = '7d000000-0000-0000-0000-00000000000a'),
  (select id from test_clubs where label = 'a'),
  'la dépense est rangée dans le club de l’admin'
);
select lives_ok(
  $$update public.club_license_expenses set label = 'Survêtement 2098'
    where id = '7d000000-0000-0000-0000-00000000000a'$$,
  'l’admin renomme la dépense'
);
select throws_ok(
  $$insert into public.club_license_expenses (season_id, label)
    values ('7b000000-0000-0000-0000-00000000000a', ' ')$$,
  '23514', null,
  'un intitulé vide est refusé'
);
select lives_ok(
  $$insert into public.season_player_licenses (season_player_id, license_paid)
    values ('7c000000-0000-0000-0000-00000000000a', true)$$,
  'l’admin marque la licence d’un joueur de son club comme payée'
);
select lives_ok(
  $$insert into public.season_player_expense_payments (expense_id, season_player_id)
    values ('7d000000-0000-0000-0000-00000000000a', '7c000000-0000-0000-0000-00000000000a')$$,
  'l’admin marque la dépense comme payée par ce joueur'
);
select is(
  (select count(*) from public.season_player_licenses where license_paid), 1::bigint,
  'l’admin relit la licence payée'
);
select is(
  (select count(*) from public.season_player_expense_payments), 1::bigint,
  'l’admin relit le paiement de la dépense'
);
select throws_ok(
  $$insert into public.season_player_licenses (season_player_id, license_paid)
    values ('7c000000-0000-0000-0000-00000000000b', true)$$,
  '42501', null,
  'l’admin ne peut pas suivre la licence d’un joueur d’un autre club'
);

-- Chaque saison a ses propres dépenses.
select throws_ok(
  $$insert into public.club_license_expenses (label) values ('Sans saison')$$,
  '23502', null,
  'une dépense sans saison est refusée'
);
select throws_ok(
  $$insert into public.club_license_expenses (season_id, label)
    values ('7b000000-0000-0000-0000-00000000000b', 'Chez Bravo')$$,
  '42501', null,
  'l’admin ne peut pas créer de dépense dans une saison d’un autre club'
);
select throws_ok(
  $$insert into public.season_player_expense_payments (expense_id, season_player_id)
    values ('7d000000-0000-0000-0000-00000000000a', '7c000000-0000-0000-0000-0000000000a0')$$,
  '23514', null,
  'une dépense de cette saison ne peut pas être payée par une fiche de la saison précédente'
);
select lives_ok(
  $$insert into public.club_license_expenses (id, season_id, label)
    values ('7d000000-0000-0000-0000-0000000000a0', '7b000000-0000-0000-0000-0000000000a0', 'Survêtement')$$,
  'la saison précédente peut avoir sa propre dépense du même nom'
);
select is(
  (select count(*) from public.club_license_expenses
   where season_id = '7b000000-0000-0000-0000-00000000000a'),
  1::bigint,
  'la dépense de la saison précédente n’apparaît pas dans la saison en cours'
);

reset role;

-- ---------------------------------------------------------------------------
-- Joueur d'Alpha : le suivi des paiements ne lui est pas visible.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"7a000000-0000-0000-0000-0000000000aa","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select is((select count(*) from public.club_license_expenses), 0::bigint,
  'un joueur du club ne voit pas les dépenses');
select is((select count(*) from public.season_player_licenses), 0::bigint,
  'un joueur du club ne voit pas les licences, même la sienne');
select is((select count(*) from public.season_player_expense_payments), 0::bigint,
  'un joueur du club ne voit pas les paiements');
select throws_ok(
  $$insert into public.club_license_expenses (season_id, label)
    values ('7b000000-0000-0000-0000-00000000000a', 'Chaussettes')$$,
  '42501', null,
  'un joueur ne peut pas créer de dépense'
);
select throws_ok(
  $$insert into public.season_player_licenses (season_player_id, license_paid)
    values ('7c000000-0000-0000-0000-00000000000a', false)$$,
  '42501', null,
  'un joueur ne peut pas modifier sa propre licence'
);

reset role;

-- ---------------------------------------------------------------------------
-- Administrateur de Bravo : rien d'Alpha n'est visible ni modifiable.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"7a000000-0000-0000-0000-00000000000b","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select is((select count(*) from public.club_license_expenses), 0::bigint,
  'Bravo ne voit pas les dépenses d’Alpha');
select is((select count(*) from public.season_player_licenses), 0::bigint,
  'Bravo ne voit pas les licences d’Alpha');
select is((select count(*) from public.season_player_expense_payments), 0::bigint,
  'Bravo ne voit pas les paiements d’Alpha');
select throws_ok(
  $$insert into public.season_player_expense_payments (expense_id, season_player_id)
    values ('7d000000-0000-0000-0000-00000000000a', '7c000000-0000-0000-0000-00000000000b')$$,
  '42501', null,
  'Bravo ne peut pas rattacher un paiement à une dépense d’Alpha'
);

update public.club_license_expenses set label = 'Piratée'
where id = '7d000000-0000-0000-0000-00000000000a';
delete from public.season_player_expense_payments
where expense_id = '7d000000-0000-0000-0000-00000000000a';
-- Personne ne supprime une licence (droit non accordé) : Bravo tente donc
-- de la décocher.
update public.season_player_licenses set license_paid = false
where season_player_id = '7c000000-0000-0000-0000-00000000000a';

reset role;

select is(
  (select label from public.club_license_expenses where id = '7d000000-0000-0000-0000-00000000000a'),
  'Survêtement 2098',
  'la tentative de Bravo ne renomme pas la dépense d’Alpha'
);
select is(
  (select count(*) from public.season_player_expense_payments
   where expense_id = '7d000000-0000-0000-0000-00000000000a'),
  1::bigint,
  'la tentative de Bravo ne supprime pas le paiement d’Alpha'
);
select is(
  (select license_paid from public.season_player_licenses
   where season_player_id = '7c000000-0000-0000-0000-00000000000a'),
  true,
  'la tentative de Bravo ne décoche pas la licence d’Alpha'
);

-- ---------------------------------------------------------------------------
-- Visiteur non connecté : aucun accès.
-- ---------------------------------------------------------------------------
set local role anon;
select throws_ok($$select 1 from public.club_license_expenses$$, '42501', null,
  'un visiteur non connecté ne lit pas les dépenses');
select throws_ok($$select 1 from public.season_player_licenses$$, '42501', null,
  'un visiteur non connecté ne lit pas les licences');
select throws_ok($$select 1 from public.season_player_expense_payments$$, '42501', null,
  'un visiteur non connecté ne lit pas les paiements');
reset role;

-- Supprimer une dépense efface ses paiements (aucun paiement orphelin).
delete from public.club_license_expenses where id = '7d000000-0000-0000-0000-00000000000a';
select is(
  (select count(*) from public.season_player_expense_payments
   where expense_id = '7d000000-0000-0000-0000-00000000000a'),
  0::bigint,
  'supprimer une dépense supprime ses paiements'
);

select * from finish();
rollback;
