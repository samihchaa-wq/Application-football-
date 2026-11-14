begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

insert into auth.users(id, email, raw_user_meta_data)
values (
  '42200000-0000-0000-0000-000000000001',
  'live-prekickoff-admin@example.invalid',
  '{"first_name":"Live","last_name":"Prekickoff"}'::jsonb
);

update public.profiles
set role = 'admin',
    status = 'active',
    updated_at = now()
where id = '42200000-0000-0000-0000-000000000001';

update private.app_feature_flags
set enabled = true,
    updated_at = now(),
    updated_by = null
where key = 'sports_management';

insert into public.seasons(id, name, status)
values (
  '42200000-0000-0000-0000-000000000010',
  '2099-2100',
  'open'
);

insert into public.season_players(
  id, season_id, first_name, last_name, is_goalkeeper, is_active, position
)
values
  (
    '42200000-0000-0000-0000-000000000031',
    '42200000-0000-0000-0000-000000000010',
    'Titulaire',
    'Test',
    false,
    true,
    1
  ),
  (
    '42200000-0000-0000-0000-000000000032',
    '42200000-0000-0000-0000-000000000010',
    'Remplacant',
    'Test',
    false,
    true,
    2
  );

insert into public.matches(
  id,
  season_id,
  match_date,
  match_time,
  location,
  planned_duration_minutes,
  status,
  created_by
)
values (
  '42200000-0000-0000-0000-000000000020',
  '42200000-0000-0000-0000-000000000010',
  current_date + 1,
  '20:00'::time,
  'domicile',
  90,
  'a_venir',
  '42200000-0000-0000-0000-000000000001'
);

insert into public.match_sport_workflows(
  match_id,
  availability_opens_at,
  created_by,
  updated_by
)
values (
  '42200000-0000-0000-0000-000000000020',
  now() - interval '1 day',
  '42200000-0000-0000-0000-000000000001',
  '42200000-0000-0000-0000-000000000001'
);

insert into public.match_sport_participants(
  id, match_id, season_player_id, is_eligible, selection_status
)
values
  (
    '42200000-0000-0000-0000-000000000041',
    '42200000-0000-0000-0000-000000000020',
    '42200000-0000-0000-0000-000000000031',
    true,
    'starter'
  ),
  (
    '42200000-0000-0000-0000-000000000042',
    '42200000-0000-0000-0000-000000000020',
    '42200000-0000-0000-0000-000000000032',
    true,
    'substitute'
  );

insert into public.match_compositions(
  match_id,
  formation_code,
  status,
  version,
  has_unpublished_changes,
  published_at,
  published_by,
  last_modified_by
)
values (
  '42200000-0000-0000-0000-000000000020',
  '4-2-1-3',
  'published',
  1,
  false,
  now(),
  '42200000-0000-0000-0000-000000000001',
  '42200000-0000-0000-0000-000000000001'
);

insert into public.match_composition_entries(
  match_id, participant_id, zone, x, y, sort_order
)
values
  (
    '42200000-0000-0000-0000-000000000020',
    '42200000-0000-0000-0000-000000000041',
    'field',
    0.5,
    0.5,
    0
  ),
  (
    '42200000-0000-0000-0000-000000000020',
    '42200000-0000-0000-0000-000000000042',
    'bench',
    null,
    null,
    0
  );

insert into public.match_live_sessions(
  match_id,
  state,
  planned_duration_minutes,
  lineup_revision,
  updated_by
)
values (
  '42200000-0000-0000-0000-000000000020',
  'not_started',
  90,
  3,
  '42200000-0000-0000-0000-000000000001'
);

reset role;
-- Seul le coach de la saison pilote le Live : le compte qui pilote ce test
-- est déclaré coach, sans être ajouté aux matchs déjà créés.
insert into public.season_players(
  id,season_id,first_name,last_name,is_goalkeeper,is_active,is_coach,profile_id
) values (
  '42200000-0000-0000-0000-0000000000c1','42200000-0000-0000-0000-000000000010','Pilote','Coach',false,false,true,'42200000-0000-0000-0000-000000000001'
);
set local session_replication_role=replica;
update public.season_players set is_active=true where id='42200000-0000-0000-0000-0000000000c1';
set local session_replication_role=origin;
select set_config(
  'request.jwt.claims',
  '{"sub":"42200000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated","session_id":"42200000-0000-0000-0000-000000000099"}',
  true
);
set local role authenticated;

select lives_ok(
  $$select public.claim_match_live_pilot(
    '42200000-0000-0000-0000-000000000020',
    90
  )$$,
  'le coach prend la place de pilote avant de modifier la composition'
);

create temporary table live_commands(key text, command text) on commit drop;
insert into live_commands values
 ('live_add_players', $$select public.coach_add_match_live_players('42200000-0000-0000-0000-000000000020','[]',null)$$),
 ('live_formation_changes', $$select public.coach_change_match_live_formation('42200000-0000-0000-0000-000000000020','3-5-2','[]',3)$$),
 ('live_event_deletion', $$select public.coach_delete_match_live_event('42200000-0000-0000-0000-000000000020','42200000-0000-0000-0000-000000000090')$$),
 ('live_restart', $$select public.coach_restart_match_live_session('42200000-0000-0000-0000-000000000020',null)$$),
 ('live_takeover', $$select public.take_over_match_live_pilot('42200000-0000-0000-0000-000000000020')$$),
 ('live_scorers', $$select public.coach_set_match_live_event_scorer('42200000-0000-0000-0000-000000000020','42200000-0000-0000-0000-000000000090',null,false,null)$$),
 ('live_assists', $$select public.coach_set_match_live_event_scorer('42200000-0000-0000-0000-000000000020','42200000-0000-0000-0000-000000000090','42200000-0000-0000-0000-000000000041',false,'42200000-0000-0000-0000-000000000042')$$),
 ('live_own_goals', $$select public.coach_set_match_live_event_scorer('42200000-0000-0000-0000-000000000020','42200000-0000-0000-0000-000000000090',null,true,null)$$),
 ('live_pause', $$select public.coach_set_match_live_clock_state('42200000-0000-0000-0000-000000000020','pause',null)$$),
 ('live_substitutions', $$select public.coach_save_match_live_lineup('42200000-0000-0000-0000-000000000020','[{"participant_id":"42200000-0000-0000-0000-000000000041","zone":"bench","sort_order":0},{"participant_id":"42200000-0000-0000-0000-000000000042","zone":"field","x":0.5,"y":0.5,"sort_order":0}]',null,3)$$),
 ('live_remove_players', $$select public.coach_save_match_live_lineup('42200000-0000-0000-0000-000000000020','[{"participant_id":"42200000-0000-0000-0000-000000000041","zone":"field","x":0.5,"y":0.5,"sort_order":0},{"participant_id":"42200000-0000-0000-0000-000000000042","zone":"not_selected","sort_order":0}]',null,3)$$);
-- Chaque appel est exécuté dans la session authentifiée du vrai pilote.
create function pg_temp.check_live_guard(p_key text,p_command text) returns setof text
language plpgsql as $test$
begin
 perform public.admin_set_club_rule(p_key,0);
 return next throws_ok(p_command,'42501',
   'Cette action est désactivée dans les réglages du club ('||p_key||').',
   'appel direct bloqué : '||p_key);
 perform public.admin_set_club_rule(p_key,null);
end;
$test$;
select pg_temp.check_live_guard(key,command) from live_commands;
select is((select lineup_revision from public.match_live_sessions where match_id='42200000-0000-0000-0000-000000000020'),3,
 'les refus n’altèrent pas la révision');
select is((select count(*) from public.match_live_events where match_id='42200000-0000-0000-0000-000000000020'),0::bigint,
 'les refus ne créent aucun événement');
-- Réactivation : le même échange sans p_substitution réussit avant kickoff.
select lives_ok((select command from live_commands where key='live_substitutions'),
 'réactiver permet réellement le changement de composition');
select is((select zone::text from public.match_composition_entries
 where participant_id='42200000-0000-0000-0000-000000000042'),'field','la nouvelle composition est persistée');
reset role;
update public.match_live_sessions set state='running',started_at=now(),running_since=now()
 where match_id='42200000-0000-0000-0000-000000000020';
set local role authenticated;
select lives_ok($$select public.coach_adjust_match_live_score('42200000-0000-0000-0000-000000000020','us',1,null,'42200000-0000-0000-0000-000000000091')$$,
 'le score reste saisissable sans attribution');
-- Le garde du buteur est également appliqué à l’autre point d’entrée.
select public.admin_set_club_rule('live_scorers',0);
select throws_ok($$select public.coach_adjust_match_live_score('42200000-0000-0000-0000-000000000020','us',1,'42200000-0000-0000-0000-000000000041','42200000-0000-0000-0000-000000000092')$$,
 '42501',null,'l’API du score ne contourne pas l’interdiction de buteur');
select lives_ok($$select public.coach_adjust_match_live_score('42200000-0000-0000-0000-000000000020','us',1,null,'42200000-0000-0000-0000-000000000093')$$,
 'buteurs coupés : le score collectif fonctionne encore');
select public.admin_set_club_rule('live_event_deletion',0);
select throws_ok($$select public.coach_adjust_match_live_score('42200000-0000-0000-0000-000000000020','us',-1,null,'42200000-0000-0000-0000-000000000094')$$,
 '42501',null,'le bouton moins ne contourne pas l’interdiction de suppression');
select is((select count(*) from public.match_live_events where match_id='42200000-0000-0000-0000-000000000020'),2::bigint,
 'désactiver conserve les buts précédents');
select public.admin_set_club_rule('live_event_deletion',null);
select lives_ok($$select public.coach_adjust_match_live_score('42200000-0000-0000-0000-000000000020','us',-1,null,'42200000-0000-0000-0000-000000000095')$$,
 'la correction collective refonctionne après réactivation');
select * from finish();
rollback;
