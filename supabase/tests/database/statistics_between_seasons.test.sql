begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Club A vient de clôturer ; B a toujours une saison ouverte. Les consultations
-- se font sous de vrais rôles authentifiés, sans écriture distante.
create temporary table interseason_clubs(label text, id uuid);
insert into interseason_clubs values
  ('a', (public.create_club('Interseason A', 'ISA')).id),
  ('b', (public.create_club('Interseason B', 'ISB')).id);
grant select on interseason_clubs to authenticated;

insert into auth.users(id,email,raw_user_meta_data,raw_app_meta_data)
select ('fa010000-0000-0000-0000-00000000000' || label)::uuid,
  'interseason-' || label || '@example.invalid',
  jsonb_build_object('first_name', 'Player' || label),
  jsonb_build_object('club_id', id)
from interseason_clubs;
update public.profiles set role='admin',status='active',is_test_account=false
where id in ('fa010000-0000-0000-0000-00000000000a',
             'fa010000-0000-0000-0000-00000000000b');

set local session_replication_role = replica;
insert into public.seasons(id,name,status,club_id)
select ('fa020000-0000-0000-0000-00000000000' || label)::uuid,
  '2090-2091',case label when 'a' then 'archived' else 'open' end,id
from interseason_clubs;
insert into public.seasons(id,name,status,club_id)
select 'fa020000-0000-0000-0000-000000000001','2089-2090','archived',id
from interseason_clubs where label='a';
insert into public.season_players(id,season_id,profile_id,first_name,last_name,
  is_active,club_id)
select ('fa030000-0000-0000-0000-00000000000' || label)::uuid,
  ('fa020000-0000-0000-0000-00000000000' || label)::uuid,
  ('fa010000-0000-0000-0000-00000000000' || label)::uuid,
  'Player' || label,'Interseason',true,id
from interseason_clubs;
insert into public.matches(id,season_id,match_date,match_time,kickoff_at,location,
  planned_duration_minutes,status,score_as_grinta,score_adverse,created_by,
  match_type,competition,club_id)
select ('fa040000-0000-0000-0000-00000000000' || label)::uuid,
  ('fa020000-0000-0000-0000-00000000000' || label)::uuid,
  '2090-10-01','20:00','2090-10-01 18:00:00+00','domicile',90,
  'termine',3,1,('fa010000-0000-0000-0000-00000000000' || label)::uuid,
  'amical','championnat',id
from interseason_clubs;
insert into public.match_attendance(match_id,season_player_id,club_id)
select ('fa040000-0000-0000-0000-00000000000' || label)::uuid,
  ('fa030000-0000-0000-0000-00000000000' || label)::uuid,id
from interseason_clubs;
insert into public.match_player_stats(match_id,season_player_id,goals,assists,club_id)
select ('fa040000-0000-0000-0000-00000000000' || label)::uuid,
  ('fa030000-0000-0000-0000-00000000000' || label)::uuid,2,1,id
from interseason_clubs;
insert into public.match_predictions(match_id,profile_id,predicted_score_as_grinta,
  predicted_score_adverse,is_filled,club_id)
select ('fa040000-0000-0000-0000-00000000000' || label)::uuid,
  ('fa010000-0000-0000-0000-00000000000' || label)::uuid,3,1,true,id
from interseason_clubs;
insert into public.match_odds(match_id,odds_victoire_as_grinta,odds_nul,
  odds_victoire_adverse,club_id)
select ('fa040000-0000-0000-0000-00000000000' || label)::uuid,
  1.28,3,4,id from interseason_clubs;
-- Un deuxième pronostic de A sur une saison plus ancienne doit s'ajouter
-- uniquement à Toutes, jamais à Précédente.
insert into public.matches(id,season_id,match_date,match_time,kickoff_at,location,
  planned_duration_minutes,status,score_as_grinta,score_adverse,created_by,
  match_type,competition,club_id)
select 'fa040000-0000-0000-0000-000000000001',
  'fa020000-0000-0000-0000-000000000001','2089-10-01','20:00',
  '2089-10-01 18:00:00+00','domicile',90,'archive',0,0,
  'fa010000-0000-0000-0000-00000000000a','amical','championnat',id
from interseason_clubs where label='a';
insert into public.match_predictions(match_id,profile_id,predicted_score_as_grinta,
  predicted_score_adverse,is_filled,club_id)
select 'fa040000-0000-0000-0000-000000000001',
  'fa010000-0000-0000-0000-00000000000a',1,0,true,id
from interseason_clubs where label='a';
set local session_replication_role = origin;

select set_config('request.jwt.claims',
  '{"sub":"fa010000-0000-0000-0000-00000000000a","role":"authenticated"}',true);
set local role authenticated;
select is((select season_id from public.v_statistics_season_periods
  where period_key='previous'), 'fa020000-0000-0000-0000-00000000000a'::uuid,
  'sans saison ouverte, Précédente désigne la saison qui vient de finir');
select is((select count(*) from public.v_statistics_season_periods
  where period_key='current'),0::bigint,'Actuelle reste vide entre deux saisons');
select is((select matches_played from public.v_statistics_players
  where period_key='previous'),1,'le joueur retrouve sa participation précédente');
select is((select goals from public.v_statistics_players
  where period_key='previous'),2,'les buts précédents sont conservés');
select is((select assists from public.v_statistics_players
  where period_key='previous'),1,'les passes précédentes sont conservées');
select is((select matches_played from public.v_statistics_team
  where period_key='previous'),1,'le bilan équipe ne retombe plus à zéro');
select is((select goals_for from public.v_statistics_team
  where period_key='previous'),3,'les buts de l’équipe précédente sont conservés');
select is((select recent_results from public.v_statistics_team
  where period_key='previous'),array['V'],'la forme précédente conserve le résultat');
select is((select match_pronos from public.v_statistics_predictions
  where period_key='previous'),1::bigint,'Prono précédent exclut les autres saisons');
select is((select match_points from public.v_statistics_predictions
  where period_key='previous'),2.56::numeric,'les points gardent le barème existant');
select is((select match_exacts from public.v_statistics_predictions
  where period_key='previous'),1::bigint,'le score exact précédent est compté');
select is((select match_pronos from public.v_statistics_predictions
  where period_key='all_time'),2::bigint,'Toutes cumule les deux saisons du club');
select is((select count(*) from public.v_statistics_predictions
  where profile_id='fa010000-0000-0000-0000-00000000000b'),0::bigint,
  'aucun pronostic du club B ne fuit dans A');
select is((select count(*) from public.v_statistics_predictions
  where period_key='current'),0::bigint,'Prono actuel reste vide entre deux saisons');
select is(public.get_season_wrapped_state()->>'available','false',
  'la vidéo est indisponible avant la fin du calcul');
reset role;

-- Arrivée asynchrone du bilan : elle doit changer le signal du club A.
select set_config('app.club_id',(select id::text from interseason_clubs where label='a'),true);
create temporary table signal_before as
select revision from public.shared_data_change_signals
where club_id=(select id from interseason_clubs where label='a') and key='global';
insert into public.season_wrapped(season_id,season_player_id,profile_id,
  roster_size,matches_played,wins,draws,losses,goals,motm,clean_matches,versatility)
values('fa020000-0000-0000-0000-00000000000a',
  'fa030000-0000-0000-0000-00000000000a',
  'fa010000-0000-0000-0000-00000000000a',1,1,1,0,0,2,0,0,1);
select ok((select revision from public.shared_data_change_signals
  where club_id=(select id from interseason_clubs where label='a') and key='global')
  > (select revision from signal_before),'le calcul du bilan réveille les clients');
set local role authenticated;
select is(public.get_season_wrapped_state()->>'available','true',
  'la vidéo apparaît malgré la saison ouverte du club B');
select is(public.get_my_season_wrapped()->>'matches_played','1',
  'le bilan personnel de A est lisible');
reset role;

-- Ouverture suivante : l’ancienne saison reste Précédente et la vidéo se cache.
set local session_replication_role = replica;
insert into public.seasons(id,name,status,club_id)
select 'fa020000-0000-0000-0000-000000000002','2091-2092','open',id
from interseason_clubs where label='a';
set local session_replication_role = origin;
set local role authenticated;
select is((select season_id from public.v_statistics_season_periods
  where period_key='previous'),'fa020000-0000-0000-0000-00000000000a'::uuid,
  'ouvrir la suivante ne décale pas les statistiques précédentes');
select is(public.get_season_wrapped_state()->>'available','false',
  'ouvrir la saison suivante masque la vidéo');
reset role;

select set_config('request.jwt.claims',
  '{"sub":"fa010000-0000-0000-0000-00000000000b","role":"authenticated"}',true);
set local role authenticated;
select is((select season_id from public.v_statistics_season_periods
  where period_key='current'),'fa020000-0000-0000-0000-00000000000b'::uuid,
  'B conserve sa propre saison actuelle');
select is((select count(*) from public.v_statistics_players
  where profile_id='fa010000-0000-0000-0000-00000000000a'),0::bigint,
  'les statistiques de A ne sont jamais visibles dans B');
select is(public.get_season_wrapped_state()->>'available','false',
  'B ne reçoit jamais la vidéo personnelle de A');
reset role;
select ok(not has_table_privilege('anon','public.v_statistics_predictions','select'),
  'les pronostics par période ne sont pas publics');
select * from finish();
rollback;
