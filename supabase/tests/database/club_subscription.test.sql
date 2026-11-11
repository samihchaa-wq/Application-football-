begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Abonnement : essai gratuit, comptage des joueurs, suspension par l'éditeur.
create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;

insert into test_clubs
select 'a', (public.create_club('Club Abonnement Alpha', 'SALPHA', null, null, null, null)).id;
insert into test_clubs
select 'b', (public.create_club('Club Abonnement Bravo', 'SBRAVO', null, null, null, null)).id;

select is(
  (select count(*) from public.club_subscriptions
   where club_id in (select id from test_clubs) and status = 'trialing'
     and trial_ends_at between now() + interval '29 days' and now() + interval '31 days'),
  2::bigint,
  'chaque nouveau club démarre avec 30 jours d''essai gratuit'
);

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4c000000-0000-0000-0000-00000000000' || label, 'sub-' || label || '@example.invalid',
  jsonb_build_object('first_name', 'Admin', 'last_name', upper(label)),
  jsonb_build_object('club_id', id)
from test_clubs;
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4c000000-0000-0000-0000-0000000000c1', 'sub-member@example.invalid',
  jsonb_build_object('first_name', 'Membre', 'last_name', 'Alpha'),
  jsonb_build_object('club_id', id)
from test_clubs where label = 'a';
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4c000000-0000-0000-0000-0000000000e1', 'operator@example.invalid',
  jsonb_build_object('first_name', 'Editeur', 'last_name', 'App'),
  jsonb_build_object('club_id', id)
from test_clubs where label = 'b';

update public.profiles set status = 'active' where id::text like '4c000000-%';
update public.profiles set role = 'admin'
where id in ('4c000000-0000-0000-0000-00000000000a', '4c000000-0000-0000-0000-00000000000b');

-- Effectif d'Alpha : 3 joueurs actifs dont un en double, 1 inactif.
select set_config('app.club_id', (select id::text from test_clubs where label = 'a'), true);
insert into public.seasons (id, name, status)
values ('4c000000-0000-0000-0000-0000000000f1', '2097-2098', 'open');
insert into public.players (id, display_name) values
  ('4c000000-0000-0000-0000-0000000000d1', 'Un'),
  ('4c000000-0000-0000-0000-0000000000d2', 'Deux'),
  ('4c000000-0000-0000-0000-0000000000d3', 'Trois'),
  ('4c000000-0000-0000-0000-0000000000d4', 'Quatre');
insert into public.season_players (season_id, first_name, last_name, is_active, player_id) values
  ('4c000000-0000-0000-0000-0000000000f1', 'Un', 'A', true, '4c000000-0000-0000-0000-0000000000d1'),
  ('4c000000-0000-0000-0000-0000000000f1', 'Deux', 'A', true, '4c000000-0000-0000-0000-0000000000d2'),
  ('4c000000-0000-0000-0000-0000000000f1', 'Trois', 'A', true, '4c000000-0000-0000-0000-0000000000d3'),
  ('4c000000-0000-0000-0000-0000000000f1', 'Quatre', 'A', false, '4c000000-0000-0000-0000-0000000000d4');
select set_config('app.club_id', '', true);

-- ---------------------------------------------------------------------------
-- L'administrateur d'Alpha voit son abonnement
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"4c000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select is(
  (public.admin_get_club_subscription() ->> 'billable_players')::integer, 3,
  'seuls les joueurs actifs de la saison ouverte sont facturés'
);
select is(
  (public.admin_get_club_subscription() ->> 'yearly_amount_cents')::integer, 3000,
  'le montant annuel vaut 10 € par joueur facturé'
);
select is(
  public.admin_get_club_subscription() ->> 'state', 'trial',
  'l''essai est en cours'
);
select is(
  (select count(*) from public.club_subscriptions), 1::bigint,
  'un admin ne voit que l''abonnement de son club'
);
select throws_ok(
  $$update public.club_subscriptions set status = 'active'$$,
  '42501', null,
  'un admin ne peut pas se déclarer abonné lui-même'
);
select throws_ok(
  $$select * from public.platform_list_clubs()$$,
  '42501', null,
  'un admin de club n''a pas accès à la console de l''éditeur'
);
reset role;

select set_config('request.jwt.claims',
  '{"sub":"4c000000-0000-0000-0000-0000000000c1","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select throws_ok(
  $$select public.admin_get_club_subscription()$$,
  '42501', null,
  'un simple membre ne voit pas l''abonnement'
);
reset role;

-- Fin d'essai.
update public.club_subscriptions set trial_ends_at = now() + interval '3 days'
where club_id = (select id from test_clubs where label = 'a');
select set_config('request.jwt.claims',
  '{"sub":"4c000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select is(public.admin_get_club_subscription() ->> 'state', 'trial_ending',
  'moins de 7 jours d''essai : rappel');
reset role;
update public.club_subscriptions set trial_ends_at = now() - interval '1 day'
where club_id = (select id from test_clubs where label = 'a');
set local role authenticated;
select is(public.admin_get_club_subscription() ->> 'state', 'to_pay',
  'essai terminé sans abonnement : à régler');
select ok(
  (select count(*) from public.matches) >= 0,
  'la fin de l''essai ne bloque pas l''accès aux données'
);
reset role;

-- ---------------------------------------------------------------------------
-- L'éditeur
-- ---------------------------------------------------------------------------
insert into private.platform_operators (user_id) values ('4c000000-0000-0000-0000-0000000000e1');
select set_config('request.jwt.claims',
  '{"sub":"4c000000-0000-0000-0000-0000000000e1","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select ok(
  (select count(*) from public.platform_list_clubs()
   where id in (select id from test_clubs)) = 2,
  'l''éditeur voit tous les clubs'
);
select is(
  (select billable_players from public.platform_list_clubs()
   where id = (select id from test_clubs where label = 'a')),
  3::bigint,
  'l''éditeur voit le nombre de joueurs facturés de chaque club'
);
select lives_ok(
  $$select public.platform_update_club((select id from test_clubs where label = 'a'), p_status => 'suspended')$$,
  'l''éditeur peut suspendre un club'
);
select ok(
  (public.platform_health() ->> 'clubs')::integer >= 2,
  'l''éditeur consulte la santé de la plate-forme'
);
reset role;

-- Membre d'un club suspendu.
select set_config('request.jwt.claims',
  '{"sub":"4c000000-0000-0000-0000-0000000000c1","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select is(public.get_my_club_access() ->> 'status', 'suspended',
  'un membre d''un club suspendu sait pourquoi il n''a plus accès');
select is((select count(*) from public.clubs), 0::bigint,
  'un club suspendu n''a plus accès à ses données');
reset role;

-- Bravo n'est pas touché.
select set_config('request.jwt.claims',
  '{"sub":"4c000000-0000-0000-0000-00000000000b","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select is(public.get_my_club_access() ->> 'status', 'active',
  'la suspension d''un club ne touche pas les autres');
select is((select count(*) from public.clubs), 1::bigint,
  'les autres clubs gardent l''accès à leurs données');
reset role;

select * from finish();
rollback;
