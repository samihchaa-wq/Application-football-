begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Les trois modes de liste d'attente réglables par le club.
--
-- Classement de saison : Alice n°1, Bruno n°2, Chloé n°3, Damien n°4.
-- Deux places pour quatre disponibles. Ordre d'arrivée des réponses :
-- Alice, puis Bruno, puis Chloé, puis Damien.

select vault.create_secret('test-token', 'push_internal_token')
where not exists (
  select 1 from vault.secrets secret where secret.name = 'push_internal_token'
);

insert into auth.users(id, email, raw_user_meta_data)
values
  ('f5810000-0000-0000-0000-000000000001', 'modes-admin@example.invalid', '{"first_name":"Admin"}'::jsonb),
  ('f5810000-0000-0000-0000-000000000002', 'modes-alice@example.invalid', '{"first_name":"Alice"}'::jsonb),
  ('f5810000-0000-0000-0000-000000000003', 'modes-bruno@example.invalid', '{"first_name":"Bruno"}'::jsonb),
  ('f5810000-0000-0000-0000-000000000004', 'modes-chloe@example.invalid', '{"first_name":"Chloé"}'::jsonb),
  ('f5810000-0000-0000-0000-000000000005', 'modes-damien@example.invalid', '{"first_name":"Damien"}'::jsonb);

update public.profiles
set role = case when id = 'f5810000-0000-0000-0000-000000000001' then 'admin' else 'pronostiqueur' end,
    status = 'active', updated_at = now()
where id between 'f5810000-0000-0000-0000-000000000001' and 'f5810000-0000-0000-0000-000000000005';

insert into public.seasons(id, name, status)
values ('f5820000-0000-0000-0000-000000000001', '2703-2704', 'open');
insert into public.opponents(id, name)
values ('f5830000-0000-0000-0000-000000000001', 'Modes FC');

insert into public.season_players(id, season_id, first_name, last_name, is_goalkeeper, is_active, position, profile_id)
values
  ('f5840000-0000-0000-0000-000000000001', 'f5820000-0000-0000-0000-000000000001', 'Alice', 'Mode', false, true, 1, 'f5810000-0000-0000-0000-000000000002'),
  ('f5840000-0000-0000-0000-000000000002', 'f5820000-0000-0000-0000-000000000001', 'Bruno', 'Mode', false, true, 2, 'f5810000-0000-0000-0000-000000000003'),
  ('f5840000-0000-0000-0000-000000000003', 'f5820000-0000-0000-0000-000000000001', 'Chloé', 'Mode', false, true, 3, 'f5810000-0000-0000-0000-000000000004'),
  ('f5840000-0000-0000-0000-000000000004', 'f5820000-0000-0000-0000-000000000001', 'Damien', 'Mode', false, true, 4, 'f5810000-0000-0000-0000-000000000005');

insert into public.sport_waitlist_entries(season_id, season_player_id, position, source, created_by, updated_by)
select player.season_id, player.id, player.position, 'manual',
  'f5810000-0000-0000-0000-000000000001', 'f5810000-0000-0000-0000-000000000001'
from public.season_players player
where player.season_id = 'f5820000-0000-0000-0000-000000000001';

update private.app_feature_flags
set enabled = true, updated_at = now(), updated_by = 'f5810000-0000-0000-0000-000000000001'
where key = 'sports_management';

create or replace function pg_temp.effectif(p_match uuid)
returns text language sql stable as $function$
  select string_agg(player.first_name || ' ' || participant.convocation_status::text,
    ' / ' order by player.position)
  from public.match_sport_participants participant
  join public.season_players player on player.id = participant.season_player_id
  where participant.match_id = p_match;
$function$;

create or replace function pg_temp.as_admin()
returns text language sql as $function$
  select set_config('request.jwt.claims',
    '{"sub":"f5810000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}', true);
$function$;

select pg_temp.as_admin();
set local role authenticated;

select set_config('test.match',
  public.create_match_with_odds_and_sport_limit(
    'f5820000-0000-0000-0000-000000000001', 'f5830000-0000-0000-0000-000000000001',
    ((now() + interval '4 days') at time zone 'Europe/Paris')::date,
    ((now() + interval '4 days') at time zone 'Europe/Paris')::time,
    'domicile', 2.10, 3.20, 2.90, 2
  )::text, true);

select public.admin_override_match_availability(current_setting('test.match')::uuid,
  player.id, 'available', null, 'Test')
from (values
  ('f5840000-0000-0000-0000-000000000001'::uuid),
  ('f5840000-0000-0000-0000-000000000002'::uuid),
  ('f5840000-0000-0000-0000-000000000003'::uuid),
  ('f5840000-0000-0000-0000-000000000004'::uuid)) as player(id);

reset role;

-- Une seule transaction : on fixe nous-mêmes l'heure de chaque réponse.
update public.match_sport_participants participant
set availability_updated_at = now() - make_interval(hours => 10 - player.position)
from public.season_players player
where player.id = participant.season_player_id
  and participant.match_id = current_setting('test.match')::uuid;

-- Tous les scénarios passent par les RPC publiques : aucun recalcul privé
-- ajouté par le test pour masquer l'absence d'effet d'un réglage.
select pg_temp.as_admin();
set local role authenticated;

select set_config('test.adjusted_waitlist', public.admin_adjust_waitlist_manual_count(
  'f5840000-0000-0000-0000-000000000001', 1,
  'a00d0000-0000-4000-8000-000000000001'
)::text, true);
select is(
  current_setting('test.adjusted_waitlist')::jsonb #>> '{entries,3,season_player_id}',
  'f5840000-0000-0000-0000-000000000001',
  'la réponse contient déjà le nouvel ordre : Alice passe en bas'
);
select is(
  current_setting('test.adjusted_waitlist')::jsonb #>> '{entries,3,current_season_waitlist_count}',
  '1', 'le +1 se calcule sur la valeur serveur'
);
select public.admin_adjust_waitlist_manual_count(
  'f5840000-0000-0000-0000-000000000001', 1,
  'a00d0000-0000-4000-8000-000000000001'
);
select is(
  (select (e ->> 'current_season_waitlist_count')::integer
   from jsonb_array_elements(public.get_sport_waitlist() -> 'entries') e
   where e ->> 'season_player_id' = 'f5840000-0000-0000-0000-000000000001'),
  1, 'un accusé perdu rejoué ne donne pas un deuxième +1'
);
select throws_ok($$select public.admin_adjust_waitlist_manual_count(
  'f5840000-0000-0000-0000-000000000001', -1,
  'a00d0000-0000-4000-8000-000000000001')$$,
  '22023', null, 'un identifiant ne peut pas désigner un autre geste');
select public.admin_adjust_waitlist_manual_count(
  'f5840000-0000-0000-0000-000000000001', -1,
  'a00d0000-0000-4000-8000-000000000002'
);
select throws_ok($$select public.admin_adjust_waitlist_manual_count(
  'f5840000-0000-0000-0000-000000000001', -1,
  'a00d0000-0000-4000-8000-000000000003')$$,
  '22023', null, 'le compteur ne descend pas sous zéro');
select throws_ok($$select public.admin_adjust_waitlist_manual_count(
  'f5840000-0000-0000-0000-000000000001', 2,
  'a00d0000-0000-4000-8000-000000000004')$$,
  '22023', null, 'le bouton ne peut envoyer que +1 ou -1');
select throws_ok($$select public.admin_adjust_waitlist_manual_count(
  'f5840000-0000-0000-0000-000000000001', null,
  'a00d0000-0000-4000-8000-000000000004')$$,
  '22023', null, 'un delta nul est refusé');
select throws_ok($$select public.admin_adjust_waitlist_manual_count(
  'f5840000-0000-0000-0000-000000000001', 1, null)$$,
  '22023', null, 'un geste sans identifiant est refusé');

-- Publication sans choix forcé, identique à l'écran.
select public.admin_publish_match_effectif(current_setting('test.match')::uuid, 2,
  (select jsonb_agg(jsonb_build_object(
    'season_player_id', p.season_player_id,
    'status', p.convocation_status, 'changed', false))
   from public.match_sport_participants p
   where p.match_id = current_setting('test.match')::uuid), 'Test publication');
reset role;
select is((select convocation_state::text from public.match_sport_workflows
  where match_id = current_setting('test.match')::uuid), 'published',
  'le test exerce un effectif déjà publié');

select pg_temp.as_admin();
set local role authenticated;
select public.admin_set_club_rule('waitlist_mode', 1);
reset role;
select is(pg_temp.effectif(current_setting('test.match')::uuid),
  'Alice convoked / Bruno convoked / Chloé not_convoked / Damien not_convoked',
  'le mode ordre d’arrivée s’applique sans relecture ni recalcul privé');

select pg_temp.as_admin();
set local role authenticated;
select public.admin_override_match_availability(current_setting('test.match')::uuid,
  'f5840000-0000-0000-0000-000000000001', 'absent', null, 'Désistement');
reset role;
select is(pg_temp.effectif(current_setting('test.match')::uuid),
  'Alice not_applicable / Bruno convoked / Chloé convoked / Damien not_convoked',
  'le désistement fait monter le premier arrivé encore en attente');
select pg_temp.as_admin();
set local role authenticated;
select public.admin_override_match_availability(current_setting('test.match')::uuid,
  'f5840000-0000-0000-0000-000000000001', 'available', null, 'Retour');
reset role;
select is(pg_temp.effectif(current_setting('test.match')::uuid),
  'Alice not_convoked / Bruno convoked / Chloé convoked / Damien not_convoked',
  'le retour ne déloge pas ceux qui ont répondu avant');

select pg_temp.as_admin();
set local role authenticated;
select public.admin_set_club_rule('waitlist_mode', 0);
select public.admin_publish_match_effectif(current_setting('test.match')::uuid, 2,
  (select jsonb_agg(jsonb_build_object(
    'season_player_id', p.season_player_id,
    'status', case when p.season_player_id = 'f5840000-0000-0000-0000-000000000002'
                   then 'not_convoked' else p.convocation_status::text end,
    'changed', p.season_player_id = 'f5840000-0000-0000-0000-000000000002'))
   from public.match_sport_participants p
   where p.match_id = current_setting('test.match')::uuid), 'Bruno écarté manuellement');
select public.admin_set_club_rule('waitlist_mode', 2);
reset role;
select is(pg_temp.effectif(current_setting('test.match')::uuid),
  'Alice convoked / Bruno not_convoked / Chloé convoked / Damien convoked',
  'le mode par choix conserve la mise en attente manuelle');
select ok((select convocation_manual_override from public.match_sport_participants
  where match_id = current_setting('test.match')::uuid
    and season_player_id = 'f5840000-0000-0000-0000-000000000002'),
  'le choix admin reste identifié comme manuel');

select pg_temp.as_admin();
set local role authenticated;
select public.admin_set_club_rule('waitlist_mode', null);
reset role;
select is(pg_temp.effectif(current_setting('test.match')::uuid),
  'Alice not_convoked / Bruno not_convoked / Chloé convoked / Damien convoked',
  'le retour au réglage par défaut recalcule aussi l’effectif');

-- Un match gelé ne bouge pas lorsqu'on change de mode.
set local session_replication_role = replica;
update public.matches set kickoff_at = now() + interval '5 minutes'
where id = current_setting('test.match')::uuid;
set local session_replication_role = origin;
select pg_temp.as_admin();
set local role authenticated;
select public.admin_set_club_rule('waitlist_mode', 2);
reset role;
select is(pg_temp.effectif(current_setting('test.match')::uuid),
  'Alice not_convoked / Bruno not_convoked / Chloé convoked / Damien convoked',
  'la modification du mode respecte le gel avant match');

select is((select count(*) from private.sport_admin_audit_log
  where metadata ->> 'request_id' = 'a00d0000-0000-4000-8000-000000000001'),
  1::bigint, 'le geste répété n’ajoute qu’une trace d’audit');
select ok(not has_function_privilege('anon',
  'public.admin_adjust_waitlist_manual_count(uuid,integer,uuid)', 'EXECUTE'),
  'aucun accès anonyme au compteur');
select ok(not has_function_privilege('authenticated',
  'private.change_waitlist_manual_count(uuid,integer,integer,uuid)', 'EXECUTE'),
  'le moteur interne n’est pas une RPC de joueur');

select set_config('request.jwt.claims',
  '{"sub":"f5810000-0000-0000-0000-000000000002","role":"authenticated"}', true);
set local role authenticated;
select throws_ok($$select public.admin_adjust_waitlist_manual_count(
  'f5840000-0000-0000-0000-000000000001', 1,
  'a00d0000-0000-4000-8000-000000000005')$$,
  '42501', null, 'un joueur ne peut pas ajouter de +1');
reset role;

select * from finish();
rollback;

