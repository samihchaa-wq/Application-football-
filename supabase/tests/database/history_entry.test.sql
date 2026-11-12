begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Saisie de l'historique par l'administrateur : un match passé ajouté à la
-- main apparaît dans les archives et met à jour les statistiques.

insert into auth.users(id, email, raw_user_meta_data)
values
  ('f5910000-0000-0000-0000-000000000001', 'histo-admin@example.invalid', '{"first_name":"Admin"}'::jsonb),
  ('f5910000-0000-0000-0000-000000000002', 'histo-joueur@example.invalid', '{"first_name":"Joueur"}'::jsonb);
update public.profiles
set role = case when id = 'f5910000-0000-0000-0000-000000000001' then 'admin' else 'pronostiqueur' end,
    status = 'active'
where id in ('f5910000-0000-0000-0000-000000000001', 'f5910000-0000-0000-0000-000000000002');

insert into public.seasons(id, name, status)
select 'f5920000-0000-0000-0000-000000000001', '2026-2027', 'open'
where not exists (select 1 from public.seasons);

insert into public.season_players(id, season_id, first_name, last_name, is_goalkeeper, is_active, position)
select v.id, (select id from public.seasons order by name limit 1), v.first_name, v.last_name, v.gk, true, v.pos
from (values
  ('f5940000-0000-0000-0000-000000000001'::uuid, 'Alice', 'Gardienne', true, 1),
  ('f5940000-0000-0000-0000-000000000002'::uuid, 'Bruno', 'Buteur', false, 2)
) as v(id, first_name, last_name, gk, pos);

select set_config('test.alice', (select player_id::text from public.season_players where id = 'f5940000-0000-0000-0000-000000000001'), true);
select set_config('test.bruno', (select player_id::text from public.season_players where id = 'f5940000-0000-0000-0000-000000000002'), true);
select set_config('test.cutoff', private.history_entry_cutoff()::text, true);

create or replace function pg_temp.as_profile(p_profile uuid)
returns text language sql as $function$
  select set_config('request.jwt.claims',
    jsonb_build_object('sub', p_profile, 'role', 'authenticated', 'aud', 'authenticated')::text, true);
$function$;

create or replace function pg_temp.match(p_date date, p_for int, p_against int, p_extra jsonb default '{}'::jsonb)
returns jsonb language sql stable as $function$
  select jsonb_build_object(
    'opponent', 'Archives FC', 'date', p_date, 'is_home', true,
    'score_for', p_for, 'score_against', p_against) || p_extra;
$function$;

select pg_temp.as_profile('f5910000-0000-0000-0000-000000000001');
set local role authenticated;

select is(
  (public.admin_get_history_entry_context() ->> 'last_allowed_date')::date,
  current_setting('test.cutoff')::date - 1,
  'le formulaire connaît le dernier jour autorisé : la veille de la première saison suivie'
);

-- Match 1 : victoire 2-0, Bruno doublé et homme du match, Alice dans les
-- buts, un ancien joueur sans fiche sur le banc.
select set_config('test.m1', public.admin_add_historical_match(pg_temp.match(
  current_setting('test.cutoff')::date - 60, 2, 0,
  jsonb_build_object(
    'formation', '4-4-2 à plat',
    'starters', jsonb_build_array(
      jsonb_build_object('name', 'Alice Gardienne', 'player_id', current_setting('test.alice'),
        'is_gk', true, 'x_pct', 50, 'y_pct', 89, 'position_code', 'GB'),
      jsonb_build_object('name', 'Bruno Buteur', 'player_id', current_setting('test.bruno'),
        'x_pct', 37, 'y_pct', 14, 'position_code', 'BUG')),
    'bench', jsonb_build_array(jsonb_build_object('name', 'Vieux Joueur')),
    'scorers', jsonb_build_array(jsonb_build_object('name', 'Bruno Buteur',
      'player_id', current_setting('test.bruno'), 'goals', 2)),
    'motm', jsonb_build_array(jsonb_build_object('name', 'Bruno Buteur',
      'player_id', current_setting('test.bruno')))
  )))::text, true);

select is(
  (select count(*)::int from public.get_all_historical_match_results() r
   where r.id = current_setting('test.m1')::uuid and r.opponent_name = 'Archives FC'),
  1, 'le match apparaît dans le calendrier des archives');

select is(
  (select jsonb_array_length(d.present_names) from public.get_historical_match_detail(current_setting('test.m1')::uuid) d),
  3, 'la fiche du match liste les trois présents');

reset role;

select is(
  (select count(*)::int from public.historical_match_players where match_id = current_setting('test.m1')::uuid),
  3, 'chaque présent est relié à une fiche joueur');
select is(
  (select player_id::text from public.historical_match_players
   where match_id = current_setting('test.m1')::uuid and source_name = 'Bruno Buteur'),
  current_setting('test.bruno'), 'le joueur choisi dans la liste garde sa fiche');

select is(
  (select format('%s/%s/%s/%s', matches_played, wins, goals, hdm) from public.historical_player_statistics
   where scope = 'all_time' and player_name = 'Bruno Buteur'),
  '1/1/2/1', 'Bruno : 1 match, 1 victoire, 2 buts, 1 homme du match');
select is(
  (select format('%s/%s', is_goalkeeper, clean_sheets) from public.historical_player_statistics
   where scope = 'all_time' and player_name = 'Alice Gardienne'),
  't/1', 'Alice est comptée gardienne avec un match sans but encaissé');

select pg_temp.as_profile('f5910000-0000-0000-0000-000000000001');
set local role authenticated;
select is(
  (select goals from public.v_statistics_players where period_key = 'all_time' and player_name = 'Bruno Buteur'),
  2, 'l’écran Statistiques « Toutes saisons » compte les buts saisis');
select is(
  (select format('%s/%s', matches_played, wins) from public.v_statistics_team where period_key = 'all_time'),
  '1/1', 'le bilan d’équipe « Toutes saisons » compte le match saisi');
reset role;

-- Match 2 : défaite 0-1 plus tard.
select pg_temp.as_profile('f5910000-0000-0000-0000-000000000001');
set local role authenticated;
select lives_ok(format($$select public.admin_add_historical_match(pg_temp.match(%L::date, 0, 1,
  jsonb_build_object('present', jsonb_build_array(jsonb_build_object('name', 'Bruno Buteur',
    'player_id', %L)))))$$,
  current_setting('test.cutoff')::date - 30, current_setting('test.bruno')),
  'ajout d’un second match, avec seulement l’effectif');
reset role;

select is(
  (select format('%s/%s/%s/%s/%s', matches_played, wins, losses, best_win_streak, array_to_string(recent_results, ''))
   from public.historical_team_statistics where scope = 'all_time'),
  '2/1/1/1/VD', 'le bilan d’équipe suit les deux matchs dans l’ordre');
select is(
  (select format('%s/%s', matches_played, goals) from public.historical_player_statistics
   where scope = 'all_time' and player_name = 'Bruno Buteur'),
  '2/2', 'Bruno : 2 matchs joués');

-- Refus
select pg_temp.as_profile('f5910000-0000-0000-0000-000000000001');
set local role authenticated;
select throws_ok(format($$select public.admin_add_historical_match(pg_temp.match(%L::date, 1, 0))$$, current_date + 1),
  '22023', null, 'un match à venir est refusé');
select throws_ok(format($$select public.admin_add_historical_match(pg_temp.match(%L::date, 1, 0))$$,
  current_setting('test.cutoff')),
  '22023', null, 'un match d’une saison suivie dans l’application est refusé');
select throws_ok(format($$select public.admin_add_historical_match(pg_temp.match(%L::date, 1, 0,
  jsonb_build_object('scorers', jsonb_build_array(jsonb_build_object('name', 'Bruno Buteur', 'goals', 2)))))$$,
  current_setting('test.cutoff')::date - 10),
  '22023', null, 'plus de buts que le score est refusé');
select throws_ok($$select public.admin_add_historical_match('{"date":"2001-01-01","score_for":1,"score_against":0}'::jsonb)$$,
  '22023', null, 'un match sans adversaire est refusé');
reset role;

select pg_temp.as_profile('f5910000-0000-0000-0000-000000000002');
set local role authenticated;
select throws_ok(format($$select public.admin_add_historical_match(pg_temp.match(%L::date, 1, 0))$$,
  current_setting('test.cutoff')::date - 10),
  '42501', null, 'un joueur non administrateur ne peut pas saisir de match');
select throws_ok(format($$select public.admin_delete_historical_match(%L)$$, current_setting('test.m1')),
  '42501', null, 'un joueur non administrateur ne peut pas supprimer de match');
reset role;

-- Suppression d'une erreur de saisie
select pg_temp.as_profile('f5910000-0000-0000-0000-000000000001');
set local role authenticated;
select ok(public.admin_delete_historical_match(current_setting('test.m1')::uuid),
  'l’administrateur supprime un match saisi par erreur');
reset role;
select is(
  (select format('%s/%s/%s', matches_played, goals, hdm) from public.historical_player_statistics
   where scope = 'all_time' and player_name = 'Bruno Buteur'),
  '1/0/0', 'les statistiques sont recalculées après la suppression');
select is(
  (select count(*)::int from public.historical_player_statistics where player_name = 'Alice Gardienne'),
  0, 'un joueur sans match d’archive n’a plus de ligne');

select * from finish();
rollback;
