begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Seuils des badges à paliers réglables par l'administrateur, pour son seul
-- club, en gardant l'ordre des paliers.

create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;
insert into test_clubs
select 'a', (public.create_club('Club Seuils A', 'SEUA', '#112233', '#FFFFFF', 'Europe/Paris', null)).id;
insert into test_clubs
select 'b', (public.create_club('Club Seuils B', 'SEUB', '#332211', '#000000', 'Europe/Paris', null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4e000000-0000-0000-0000-00000000000a', 'seuils-admin-a@example.invalid',
  jsonb_build_object('first_name', 'Ada', 'last_name', 'Seuil'),
  jsonb_build_object('club_id', id) from test_clubs where label = 'a';
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4e000000-0000-0000-0000-00000000000c', 'seuils-joueur-a@example.invalid',
  jsonb_build_object('first_name', 'Jo', 'last_name', 'Seuil'),
  jsonb_build_object('club_id', id) from test_clubs where label = 'a';
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4e000000-0000-0000-0000-00000000000b', 'seuils-admin-b@example.invalid',
  jsonb_build_object('first_name', 'Bob', 'last_name', 'Seuil'),
  jsonb_build_object('club_id', id) from test_clubs where label = 'b';
update public.profiles set role = 'admin', status = 'active'
where id in ('4e000000-0000-0000-0000-00000000000a', '4e000000-0000-0000-0000-00000000000b');
update public.profiles set status = 'active'
where id = '4e000000-0000-0000-0000-00000000000c';

-- Administrateur du club A
select set_config('request.jwt.claims',
  '{"sub":"4e000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select is(
  (select threshold from public.badges where code = 'goals__50'),
  50,
  'au départ, le palier « Canonnier » demande 50 buts'
);
select is(
  public.staff_update_badge_threshold('goals__50', 40) ->> 'threshold',
  '40',
  'l’administrateur passe le palier à 40 buts'
);
select is(
  (select threshold from public.badges where code = 'goals__50'),
  40,
  'le nouveau seuil est enregistré'
);
select is(
  (select description from public.badges where code = 'goals__50'),
  'Atteindre 40 buts marqués avec le club.',
  'la description suit le nouveau nombre'
);
select throws_ok(
  $$select public.staff_update_badge_threshold('goals__50', 25)$$,
  '22023', null,
  'le seuil ne peut pas rejoindre le palier inférieur (25)'
);
select throws_ok(
  $$select public.staff_update_badge_threshold('goals__50', 80)$$,
  '22023', null,
  'le seuil ne peut pas dépasser le palier supérieur (75)'
);
select throws_ok(
  $$select public.staff_update_badge_threshold('goals__50', 0)$$,
  '22023', null,
  'un seuil nul est refusé'
);
select throws_ok(
  $$select public.staff_update_badge_threshold('title_top_scorer__1', 2)$$,
  '22023', null,
  'un titre de fin de saison n’a pas de seuil réglable'
);
select throws_ok(
  $$select public.staff_update_badge_threshold('role_goalkeeper', 2)$$,
  '22023', null,
  'un badge manuel n’a pas de seuil réglable'
);
reset role;

-- Simple membre du club A
select set_config('request.jwt.claims',
  '{"sub":"4e000000-0000-0000-0000-00000000000c","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select throws_ok(
  $$select public.staff_update_badge_threshold('goals__50', 45)$$,
  '42501', null,
  'un simple membre ne peut pas changer un seuil'
);
reset role;

-- Administrateur du club B
select set_config('request.jwt.claims',
  '{"sub":"4e000000-0000-0000-0000-00000000000b","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select is(
  (select threshold from public.badges where code = 'goals__50'),
  50,
  'le seuil du club B ne bouge pas quand le club A change le sien'
);
select is(
  (select count(*) from public.badges where code = 'goals__50'),
  1::bigint,
  'le club B ne voit que son propre badge'
);
reset role;

select * from finish();
rollback;
