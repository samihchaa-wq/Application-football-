begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Barème des pronostics réglable par club : sans réglage, le barème
-- d'origine (cote × 2 / × 1,5 / × 1,5 / × 1) ; le réglage d'un club ne touche
-- pas l'autre ; le classement suit le nouveau barème.

create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;
insert into test_clubs
select 'a', (public.create_club('Club Barème A', 'BARA', '#112233', '#FFFFFF', 'Europe/Paris', null)).id;
insert into test_clubs
select 'b', (public.create_club('Club Barème B', 'BARB', '#332211', '#000000', 'Europe/Paris', null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4d000000-0000-0000-0000-00000000000a', 'bareme-admin-a@example.invalid',
  jsonb_build_object('first_name', 'Ada', 'last_name', 'Bareme'),
  jsonb_build_object('club_id', id) from test_clubs where label = 'a';
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4d000000-0000-0000-0000-00000000000c', 'bareme-joueur-a@example.invalid',
  jsonb_build_object('first_name', 'Jo', 'last_name', 'Bareme'),
  jsonb_build_object('club_id', id) from test_clubs where label = 'a';
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4d000000-0000-0000-0000-00000000000b', 'bareme-admin-b@example.invalid',
  jsonb_build_object('first_name', 'Bob', 'last_name', 'Bareme'),
  jsonb_build_object('club_id', id) from test_clubs where label = 'b';
update public.profiles set role = 'admin', status = 'active', is_test_account = false
where id in ('4d000000-0000-0000-0000-00000000000a', '4d000000-0000-0000-0000-00000000000b');
update public.profiles set status = 'active', is_test_account = false
where id = '4d000000-0000-0000-0000-00000000000c';

-- Un match terminé 2-1 par club, cote de la victoire 2,00. Écrit directement :
-- seul le calcul des points est testé ici.
set local session_replication_role = replica;

select set_config('app.club_id', (select id::text from test_clubs where label = 'a'), true);
insert into public.seasons (id, name, status)
values ('4d100000-0000-0000-0000-00000000000a', '2301-2302', 'open');
insert into public.opponents (id, name)
values ('4d200000-0000-0000-0000-00000000000a', 'Barème FC');
insert into public.matches (
  id, season_id, opponent_id, match_date, match_time, kickoff_at, location,
  planned_duration_minutes, status, score_as_grinta, score_adverse,
  created_by, match_type, competition, result_validated_at
) values (
  '4d300000-0000-0000-0000-00000000000a', '4d100000-0000-0000-0000-00000000000a',
  '4d200000-0000-0000-0000-00000000000a', date '2015-04-01', time '21:00',
  timestamptz '2015-04-01 19:00:00+00', 'domicile', 90, 'termine', 2, 1,
  '4d000000-0000-0000-0000-00000000000a', 'amical', 'championnat', now()
);
insert into public.match_odds (match_id, odds_victoire_as_grinta, odds_nul, odds_victoire_adverse)
values ('4d300000-0000-0000-0000-00000000000a', 2.00, 3.00, 4.00);
insert into public.match_predictions (
  match_id, profile_id, predicted_score_as_grinta, predicted_score_adverse, is_filled
) values
  -- score exact
  ('4d300000-0000-0000-0000-00000000000a', '4d000000-0000-0000-0000-00000000000a', 2, 1, true),
  -- bon vainqueur et bon écart
  ('4d300000-0000-0000-0000-00000000000a', '4d000000-0000-0000-0000-00000000000c', 3, 2, true);

select set_config('app.club_id', (select id::text from test_clubs where label = 'b'), true);
insert into public.seasons (id, name, status)
values ('4d100000-0000-0000-0000-00000000000b', '2301-2302', 'open');
insert into public.opponents (id, name)
values ('4d200000-0000-0000-0000-00000000000b', 'Barème FC');
insert into public.matches (
  id, season_id, opponent_id, match_date, match_time, kickoff_at, location,
  planned_duration_minutes, status, score_as_grinta, score_adverse,
  created_by, match_type, competition, result_validated_at
) values (
  '4d300000-0000-0000-0000-00000000000b', '4d100000-0000-0000-0000-00000000000b',
  '4d200000-0000-0000-0000-00000000000b', date '2015-04-01', time '21:00',
  timestamptz '2015-04-01 19:00:00+00', 'domicile', 90, 'termine', 2, 1,
  '4d000000-0000-0000-0000-00000000000b', 'amical', 'championnat', now()
);
insert into public.match_odds (match_id, odds_victoire_as_grinta, odds_nul, odds_victoire_adverse)
values ('4d300000-0000-0000-0000-00000000000b', 2.00, 3.00, 4.00);
insert into public.match_predictions (
  match_id, profile_id, predicted_score_as_grinta, predicted_score_adverse, is_filled
) values
  ('4d300000-0000-0000-0000-00000000000b', '4d000000-0000-0000-0000-00000000000b', 2, 1, true);

set local session_replication_role = origin;
select set_config('app.club_id', '', true);

-- Club A, barème d'origine
select set_config('request.jwt.claims',
  '{"sub":"4d000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select is(
  (select points from public.v_match_prediction_points
   where profile_id = '4d000000-0000-0000-0000-00000000000a'),
  4.0::numeric,
  'sans réglage, un score exact vaut la cote × 2'
);
select is(
  (select points from public.v_match_prediction_points
   where profile_id = '4d000000-0000-0000-0000-00000000000c'),
  3.0::numeric,
  'sans réglage, le bon écart vaut la cote × 1,5'
);
select is(
  (select (r ->> 'value')::int from jsonb_array_elements(public.get_club_rules()) r
   where r ->> 'key' = 'prediction_points_exact'),
  20,
  'le réglage du score exact apparaît dans les règles du club, en dixièmes'
);

select lives_ok(
  $$select public.admin_set_club_rule('prediction_points_exact', 30)$$,
  'l’administrateur passe le score exact à × 3'
);
select lives_ok(
  $$select public.admin_set_club_rule('prediction_points_goal_difference', 10)$$,
  'l’administrateur passe le bon écart à × 1'
);
select throws_ok(
  $$select public.admin_set_club_rule('prediction_points_exact', 51)$$,
  '22023', null,
  'un multiplicateur au-delà de × 5 est refusé'
);

select is(
  (select points from public.v_match_prediction_points
   where profile_id = '4d000000-0000-0000-0000-00000000000a'),
  6.0::numeric,
  'le score exact suit le nouveau barème du club'
);
select is(
  (select points from public.v_match_prediction_points
   where profile_id = '4d000000-0000-0000-0000-00000000000c'),
  2.0::numeric,
  'le bon écart suit le nouveau barème du club'
);
select is(
  (select match_points from public.v_classement_general
   where profile_id = '4d000000-0000-0000-0000-00000000000a'),
  6.0::numeric,
  'le classement général suit le nouveau barème'
);
reset role;

-- Simple membre : ne peut pas changer le barème
select set_config('request.jwt.claims',
  '{"sub":"4d000000-0000-0000-0000-00000000000c","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select throws_ok(
  $$select public.admin_set_club_rule('prediction_points_winner', 50)$$,
  '42501', null,
  'un simple membre ne peut pas changer le barème'
);
reset role;

-- Club B : garde le barème d'origine
select set_config('request.jwt.claims',
  '{"sub":"4d000000-0000-0000-0000-00000000000b","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select is(
  (select points from public.v_match_prediction_points
   where profile_id = '4d000000-0000-0000-0000-00000000000b'),
  4.0::numeric,
  'le barème du club A ne touche pas le club B'
);
select is(
  (select count(*) from public.v_match_prediction_points
   where profile_id <> '4d000000-0000-0000-0000-00000000000b'),
  0::bigint,
  'le club B ne voit aucun point du club A'
);
reset role;

select * from finish();
rollback;
