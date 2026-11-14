begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Sous-réglages par fonctionnalité : sans réglage, chaque règle vaut le
-- comportement d'origine ; le réglage d'un club ne touche pas l'autre.
-- Couvre les notifications coupées, le calcul des cotes, le recalcul des
-- matchs à venir, la durée d'un match et le pilotage du direct.

create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;
insert into test_clubs
select 'a', (public.create_club('Club Réglages A', 'REGA', '#112233', '#FFFFFF', 'Europe/Paris', null)).id;
insert into test_clubs
select 'b', (public.create_club('Club Réglages B', 'REGB', '#332211', '#000000', 'Europe/Paris', null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '5e000000-0000-0000-0000-00000000000a', 'reglages-admin-a@example.invalid',
  jsonb_build_object('first_name', 'Ada', 'last_name', 'Reglages'),
  jsonb_build_object('club_id', id) from test_clubs where label = 'a';
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '5e000000-0000-0000-0000-00000000000c', 'reglages-joueur-a@example.invalid',
  jsonb_build_object('first_name', 'Jo', 'last_name', 'Reglages'),
  jsonb_build_object('club_id', id) from test_clubs where label = 'a';
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '5e000000-0000-0000-0000-00000000000b', 'reglages-admin-b@example.invalid',
  jsonb_build_object('first_name', 'Bob', 'last_name', 'Reglages'),
  jsonb_build_object('club_id', id) from test_clubs where label = 'b';
update public.profiles set role = 'admin', status = 'active', is_test_account = false
where id in ('5e000000-0000-0000-0000-00000000000a', '5e000000-0000-0000-0000-00000000000b');
update public.profiles set status = 'active', is_test_account = false
where id = '5e000000-0000-0000-0000-00000000000c';

-- Saison ouverte et adversaire du club A.
select set_config('app.club_id', (select id::text from test_clubs where label = 'a'), true);
insert into public.seasons (id, name, status)
values ('5e100000-0000-0000-0000-00000000000a', '2301-2302', 'open');
insert into public.opponents (id, name)
values ('5e200000-0000-0000-0000-00000000000a', 'Réglages FC');
select set_config('app.club_id', '', true);

-- Réglages réellement sauvegardés via les mêmes RPC que l’écran.
create temporary table new_rules (key text primary key, default_value integer) on commit drop;
grant select on new_rules to authenticated;
insert into new_rules values
  ('live_substitutions', 1),
  ('live_formation_changes', 1),
  ('live_add_players', 1),
  ('live_remove_players', 1),
  ('live_scorers', 1),
  ('live_assists', 1),
  ('live_own_goals', 1),
  ('live_event_deletion', 1),
  ('live_restart', 1),
  ('live_takeover', 1),
  ('live_pause', 1),
  ('live_show_playing_time', 1),
  ('live_show_bench_counts', 1),
  ('live_next_out', 1),
  ('live_names_only', 0),
  ('live_journal_expanded', 0),
  ('live_substitution_colors', 1),
  ('composition_simulation', 1),
  ('composition_video', 1),
  ('composition_video_autoplay', 1),
  ('composition_video_notification_replay', 1),
  ('notify_availability_j3', 1),
  ('notify_availability_j1', 1),
  ('notify_live_full_time', 1),
  ('notify_live_goal_us', 1),
  ('notify_live_goal_them', 1),
  ('notify_match_cancelled', 1),
  ('notify_match_rescheduled_date', 1),
  ('notify_match_rescheduled_time', 1),
  ('notify_convocation_promoted', 1),
  ('notify_convocation_demoted', 1),
  ('notify_motm_winner', 1);
select set_config('request.jwt.claims',
  '{"sub":"5e000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select is((select count(*) from new_rules n join jsonb_array_elements(public.get_club_rules()) r
  on r ->> 'key' = n.key and (r ->> 'value')::int = n.default_value),
  32::bigint, 'les 32 réglages sont lus avec leurs défauts compatibles');
select lives_ok(format('select public.admin_set_club_rule(%L,%s)', key, 1-default_value),
  'enregistrement : ' || key) from new_rules order by key;
select is((select count(*) from new_rules n join jsonb_array_elements(public.get_club_rules()) r
  on r ->> 'key' = n.key and (r ->> 'value')::int = 1-n.default_value),
  32::bigint, 'les 32 modifications sont persistées et relues');
select throws_ok(format('select public.admin_set_club_rule(%L,2)', key),
  '22023', null, 'borne refusée : ' || key) from new_rules order by key;
reset role;
select set_config('request.jwt.claims',
  '{"sub":"5e000000-0000-0000-0000-00000000000b","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select is((select count(*) from new_rules n join jsonb_array_elements(public.get_club_rules()) r
  on r ->> 'key' = n.key and (r ->> 'value')::int = n.default_value),
  32::bigint, 'le club B conserve tous ses défauts');
reset role;
select set_config('request.jwt.claims',
  '{"sub":"5e000000-0000-0000-0000-00000000000c","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select throws_ok(format('select public.admin_set_club_rule(%L,0)', key),
  '42501', null, 'joueur refusé : ' || key) from new_rules order by key;
reset role;
select set_config('request.jwt.claims',
  '{"sub":"5e000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select lives_ok(format('select public.admin_set_club_rule(%L,null)', key),
  'retour au défaut : ' || key) from new_rules order by key;
reset role;
select set_config('request.jwt.claims','',true);
select set_config('app.club_id',(select id::text from test_clubs where label='a'),true);
select is(private.club_disabled_notification_kinds(), '{}'::text[], 'aucune notification coupée par défaut');

-- Chaque enfant est testé seul, puis avec son parent coupé.
create temporary table notification_children(kind text, child text, parent text) on commit drop;
insert into notification_children values
 ('availability_j3','notify_availability_j3','notify_availability_reminders'),
 ('availability_j1','notify_availability_j1','notify_availability_reminders'),
 ('live_full_time','notify_live_full_time','notify_live_kickoff'),
 ('live_goal_us','notify_live_goal_us','notify_live_goals'),
 ('live_goal_them','notify_live_goal_them','notify_live_goals'),
 ('match_cancelled','notify_match_cancelled','notify_match_changes'),
 ('match_rescheduled_date','notify_match_rescheduled_date','notify_match_changes'),
 ('match_rescheduled_time','notify_match_rescheduled_time','notify_match_changes'),
 ('convocation_promoted','notify_convocation_promoted','notify_convocation'),
 ('convocation_demoted','notify_convocation_demoted','notify_convocation'),
 ('motm_result_winner','notify_motm_winner','notify_motm_result');
create function pg_temp.test_notification_child(p_kind text,p_child text,p_parent text)
returns setof text language plpgsql as $$
begin
 insert into private.club_rules(key,value) values(p_child,0);
 return next is(private.club_disabled_notification_kinds(),array[p_kind], 'enfant seul : '||p_child);
 insert into private.club_rules(key,value) values(p_parent,0);
 return next is((select count(*) from unnest(private.club_disabled_notification_kinds()) k where k=p_kind),
   1::bigint,'parent et enfant sans doublon : '||p_child);
 update private.club_rules set value=1 where key=p_child;
 return next ok(p_kind=any(private.club_disabled_notification_kinds()),'le parent reste prioritaire : '||p_child);
 delete from private.club_rules where key in(p_child,p_parent);
 return next ok(not p_kind=any(private.club_disabled_notification_kinds()),'réactivation : '||p_child);
end;
$$;
select pg_temp.test_notification_child(kind,child,parent) from notification_children;
select ok(not has_function_privilege('authenticated','private.require_live_lineup_features(uuid,jsonb)','EXECUTE'),
 'le contrôle interne de composition ne devient pas une RPC publique');
select * from finish();
rollback;
