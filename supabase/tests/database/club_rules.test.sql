begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Chaque club fixe ses propres règles ; sans réglage, le défaut du club
-- d'origine s'applique.
create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;
insert into test_clubs
select 'a', (public.create_club('Club Règles A', 'RULEA', '#112233', '#FFFFFF', 'Europe/Paris', null)).id;
insert into test_clubs
select 'b', (public.create_club('Club Règles B', 'RULEB', '#332211', '#000000', 'Europe/Paris', null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4c000000-0000-0000-0000-00000000000a', 'regles-a@example.invalid',
  jsonb_build_object('first_name', 'Ada', 'last_name', 'Regle'),
  jsonb_build_object('club_id', id) from test_clubs where label = 'a';
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4c000000-0000-0000-0000-00000000000b', 'regles-b@example.invalid',
  jsonb_build_object('first_name', 'Bob', 'last_name', 'Regle'),
  jsonb_build_object('club_id', id) from test_clubs where label = 'b';
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4c000000-0000-0000-0000-00000000000c', 'joueur-a@example.invalid',
  jsonb_build_object('first_name', 'Jo', 'last_name', 'Joueur'),
  jsonb_build_object('club_id', id) from test_clubs where label = 'a';
update public.profiles set role = 'admin', status = 'active'
where id in ('4c000000-0000-0000-0000-00000000000a', '4c000000-0000-0000-0000-00000000000b');
update public.profiles set status = 'active'
where id = '4c000000-0000-0000-0000-00000000000c';

-- Club A
select set_config('request.jwt.claims',
  '{"sub":"4c000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select is(
  (select (r ->> 'value')::int from jsonb_array_elements(public.get_club_rules()) r
   where r ->> 'key' = 'prediction_close_minutes'),
  15,
  'sans réglage, la règle prend la valeur par défaut'
);
reset role;
select set_config('app.club_id', (select id::text from test_clubs where label = 'a'), true);
select is(
  private.match_prediction_closes_at('2030-05-10 18:00+00'),
  '2030-05-10 17:45+00'::timestamptz,
  'les pronostics ferment 15 minutes avant par défaut'
);
select set_config('request.jwt.claims',
  '{"sub":"4c000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $$select public.admin_set_club_rule('prediction_close_minutes', 60)$$,
  'l’administrateur change une règle'
);
reset role;
select is(
  private.match_prediction_closes_at('2030-05-10 18:00+00'),
  '2030-05-10 17:00+00'::timestamptz,
  'la fermeture des pronostics suit le réglage du club'
);
set local role authenticated;

select lives_ok(
  $$select public.admin_set_club_rule('features_open_days', 3)$$,
  'l’administrateur change le délai d’ouverture'
);
reset role;
select is(
  private.match_features_open_at('2030-05-10 18:00+00'),
  '2030-05-07 10:00+00'::timestamptz,
  'l’ouverture se fait 3 jours avant à 12 h (heure de Paris)'
);
set local role authenticated;

select throws_ok(
  $$select public.admin_set_club_rule('prediction_close_minutes', 9999)$$,
  '22023', null, 'une valeur hors limites est refusée'
);
select throws_ok(
  $$select public.admin_set_club_rule('regle_inventee', 1)$$,
  '22023', null, 'une règle inconnue est refusée'
);

reset role;

-- Un simple joueur ne peut rien modifier
select set_config('request.jwt.claims',
  '{"sub":"4c000000-0000-0000-0000-00000000000c","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select throws_ok(
  $$select public.admin_set_club_rule('motm_window_hours', 48)$$,
  '42501', null, 'un joueur ne peut pas modifier les règles du club'
);
reset role;

-- Club B n'est pas touché
select set_config('request.jwt.claims',
  '{"sub":"4c000000-0000-0000-0000-00000000000b","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
reset role;
select set_config('app.club_id', (select id::text from test_clubs where label = 'b'), true);
select is(
  private.match_prediction_closes_at('2030-05-10 18:00+00'),
  '2030-05-10 17:45+00'::timestamptz,
  'les règles d’un club ne changent pas celles d’un autre'
);
set local role authenticated;
select lives_ok(
  $$select public.admin_set_club_rule('motm_window_hours', 48)$$,
  'le second club fixe ses propres règles'
);
select is(
  (select (r ->> 'value')::int from jsonb_array_elements(public.get_club_rules()) r
   where r ->> 'key' = 'features_open_days'),
  6,
  'le second club garde la valeur par défaut des autres règles'
);
select lives_ok(
  $$select public.admin_set_club_rule('motm_window_hours', null)$$,
  'une règle revient à sa valeur par défaut'
);
reset role;

select * from finish();
rollback;
