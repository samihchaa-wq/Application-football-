begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- 300 matchs d'historique saisis par l'administrateur :
--   * les cotes d'un match déjà au calendrier sont recalculées ;
--   * « Simuler composition » retrouve les postes tenus dans ces matchs ;
--   * la saisie reste rapide malgré le volume.

insert into auth.users(id, email, raw_user_meta_data)
values ('f5a10000-0000-0000-0000-000000000001', 'volume-admin@example.invalid', '{"first_name":"Admin"}'::jsonb);
update public.profiles
set role = 'admin', status = 'active'
where id = 'f5a10000-0000-0000-0000-000000000001';

insert into public.seasons(id, name, status)
select 'f5a20000-0000-0000-0000-000000000001', '2026-2027', 'open'
where not exists (select 1 from public.seasons);

-- Onze titulaires : Gaston dans les buts, Bruno en pointe.
insert into public.season_players(id, season_id, first_name, last_name, is_goalkeeper, is_active, position)
select ('f5a40000-0000-0000-0000-0000000000' || lpad(n::text, 2, '0'))::uuid,
  (select id from public.seasons order by name limit 1),
  case n when 1 then 'Gaston' when 11 then 'Bruno' else 'Joueur' || n end,
  'Volume', n = 1, true, n
from generate_series(1, 11) as n;

select set_config('test.gaston', (select player_id::text from public.season_players where id = 'f5a40000-0000-0000-0000-000000000001'), true);
select set_config('test.bruno', (select player_id::text from public.season_players where id = 'f5a40000-0000-0000-0000-000000000011'), true);
select set_config('test.cutoff', private.history_entry_cutoff()::text, true);

-- Un match à venir contre l'adversaire des archives, créé AVANT l'historique.
insert into public.opponents(id, name) values ('f5a30000-0000-0000-0000-000000000001', 'Volume Archives FC');
insert into public.matches(
  id, season_id, opponent_id, match_date, match_time, location,
  planned_duration_minutes, status, match_type, created_by
) values (
  'f5a50000-0000-0000-0000-000000000001',
  (select id from public.seasons order by name desc limit 1),
  'f5a30000-0000-0000-0000-000000000001',
  current_date + 20, '20:00', 'domicile', 90, 'a_venir', 'championnat',
  'f5a10000-0000-0000-0000-000000000001'
);

select set_config('test.odds_before',
  (select odds_victoire_as_grinta::text from public.match_odds
   where match_id = 'f5a50000-0000-0000-0000-000000000001'), true);
select ok(nullif(current_setting('test.odds_before', true), '') is not null,
  'le match à venir a des cotes avant l’ajout de l’historique');

create or replace function pg_temp.as_profile(p_profile uuid)
returns text language sql as $function$
  select set_config('request.jwt.claims',
    jsonb_build_object('sub', p_profile, 'role', 'authenticated', 'aud', 'authenticated')::text, true);
$function$;

-- Le onze type : (x, y) en pourcentage, comme le formulaire d'historique.
create or replace function pg_temp.starters()
returns jsonb language sql stable as $function$
  select jsonb_agg(jsonb_build_object(
    'name', sp.first_name || ' Volume',
    'player_id', sp.player_id,
    'is_gk', sp.is_goalkeeper,
    'x_pct', case sp.position when 1 then 50 when 11 then 37 else 5 + sp.position * 8 end,
    'y_pct', case sp.position when 1 then 89 when 11 then 14 else 30 + (sp.position % 4) * 12 end
  ) order by sp.position)
  from public.season_players sp
  where sp.id::text like 'f5a40000-%';
$function$;

select pg_temp.as_profile('f5a10000-0000-0000-0000-000000000001');
set local role authenticated;

select set_config('test.started', clock_timestamp()::text, true);

-- 300 matchs, un par semaine avant la première saison suivie : 240
-- victoires, 30 nuls, 30 défaites, tous contre le même adversaire.
select lives_ok($$
  select count(public.admin_add_historical_match(jsonb_build_object(
    'opponent', 'Volume Archives FC',
    'date', current_setting('test.cutoff')::date - 7 * n,
    'is_home', n % 2 = 0,
    'score_for', case when n % 10 = 0 then 0 when n % 10 = 5 then 1 else 3 end,
    'score_against', case when n % 10 = 0 then 2 when n % 10 = 5 then 1 else 0 end,
    'formation', '4-4-2 à plat',
    'starters', pg_temp.starters()
  )))
  from generate_series(1, 300) as n
$$, 'l’administrateur ajoute 300 matchs d’historique');

select set_config('test.elapsed',
  extract(epoch from clock_timestamp() - current_setting('test.started')::timestamptz)::text, true);
select diag('300 matchs saisis en ' || round(current_setting('test.elapsed')::numeric, 1) || ' s');
select ok(current_setting('test.elapsed')::numeric < 120,
  '300 saisies prennent moins de deux minutes au total');

reset role;

select is(
  (select count(*)::int from public.historical_match_scores
   where opponent_id = 'f5a30000-0000-0000-0000-000000000001'),
  300, 'les 300 matchs sont dans les archives');

select is(
  (select matches_played from public.historical_player_statistics
   where scope = 'all_time' and player_id = current_setting('test.bruno')::uuid),
  300, 'les statistiques « Toutes saisons » comptent les 300 matchs');

-- Cotes : le match déjà au calendrier suit l'historique.
select cmp_ok(
  (select odds_victoire_as_grinta from public.match_odds
   where match_id = 'f5a50000-0000-0000-0000-000000000001'),
  '<', current_setting('test.odds_before')::numeric,
  'la cote de victoire du match à venir baisse après 300 matchs largement gagnés');

select cmp_ok(
  (select odds_victoire_adverse from public.match_odds
   where match_id = 'f5a50000-0000-0000-0000-000000000001'),
  '>', (select odds_victoire_as_grinta from public.match_odds
        where match_id = 'f5a50000-0000-0000-0000-000000000001'),
  'une défaite devient plus chère qu’une victoire');

select is(
  (select odds_victoire_as_grinta from public.match_odds
   where match_id = 'f5a50000-0000-0000-0000-000000000001'),
  (public.calculate_match_odds_v5('f5a30000-0000-0000-0000-000000000001', current_date + 20) ->> 'win')::numeric,
  'la cote enregistrée est celle que donnerait un match créé maintenant');

-- Simuler composition : les postes de l'historique sont lus.
select pg_temp.as_profile('f5a10000-0000-0000-0000-000000000001');
set local role authenticated;
select lives_ok($$select public.set_sports_management_enabled(true, 'test historique')$$,
  'le module sportif est activé');

select set_config('test.positions',
  public.admin_get_player_position_history('0001-01-01T00:00:00Z'::timestamptz)::text, true);
select set_config('test.positions_future',
  public.admin_get_player_position_history(now() + interval '1 day')::text, true);
reset role;

select is(
  (select count(*)::int from jsonb_array_elements(current_setting('test.positions')::jsonb) e
   where e ->> 'player_id' = current_setting('test.bruno')),
  300, 'Bruno a 300 titularisations dans l’historique des postes');

select is(
  (select format('%s/%s', min((e ->> 'x')::numeric), max((e ->> 'y')::numeric))
   from jsonb_array_elements(current_setting('test.positions')::jsonb) e
   where e ->> 'player_id' = current_setting('test.bruno')),
  '0.370000/0.140000', 'son poste est ramené sur l’échelle de la feuille de match (0 à 1)');

select is(
  (select count(distinct e ->> 'player_id')::int
   from jsonb_array_elements(current_setting('test.positions')::jsonb) e
   where (e ->> 'player_id') in (
     select player_id::text from public.season_players where id::text like 'f5a40000-%')),
  11, 'les onze titulaires ont un poste connu');

select is(
  (select count(*)::int from jsonb_array_elements(current_setting('test.positions_future')::jsonb) e),
  0, 'la date de départ demandée est respectée');

-- Supprimer un match d'historique recalcule aussi les cotes.
select set_config('test.odds_full',
  (select odds_victoire_as_grinta::text from public.match_odds
   where match_id = 'f5a50000-0000-0000-0000-000000000001'), true);
select pg_temp.as_profile('f5a10000-0000-0000-0000-000000000001');
set local role authenticated;
select lives_ok($$
  select count(public.admin_delete_historical_match(score.id))
  from public.historical_match_scores score
  where score.opponent_id = 'f5a30000-0000-0000-0000-000000000001'
    and score.score_as_grinta > score.score_adverse
$$, 'l’administrateur supprime les 240 victoires');
reset role;

select cmp_ok(
  (select odds_victoire_as_grinta from public.match_odds
   where match_id = 'f5a50000-0000-0000-0000-000000000001'),
  '>', current_setting('test.odds_full')::numeric,
  'sans les victoires, la cote de victoire remonte');

select * from finish();
rollback;
