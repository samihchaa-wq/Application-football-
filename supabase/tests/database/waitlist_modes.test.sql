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

-- ---------------------------------------------------------------------------
-- Mode par défaut : par présence l'an dernier (règle d'origine)
-- ---------------------------------------------------------------------------
select is(private.club_rule('waitlist_mode'), 0,
  'sans réglage, le club reste sur la règle d’origine');

select private.recompute_match_convocations_internal(current_setting('test.match')::uuid, false);
select is(pg_temp.effectif(current_setting('test.match')::uuid),
  'Alice not_convoked / Bruno not_convoked / Chloé convoked / Damien convoked',
  'par présence : les deux derniers du classement de saison sont convoqués');

-- ---------------------------------------------------------------------------
-- Ordre d'arrivée
-- ---------------------------------------------------------------------------
select pg_temp.as_admin();
set local role authenticated;
select lives_ok($$select public.admin_set_club_rule('waitlist_mode', 1)$$,
  'l’administrateur choisit l’ordre d’arrivée');
reset role;

select private.recompute_match_convocations_internal(current_setting('test.match')::uuid, false);
select is(pg_temp.effectif(current_setting('test.match')::uuid),
  'Alice convoked / Bruno convoked / Chloé not_convoked / Damien not_convoked',
  'ordre d’arrivée : les deux premiers à répondre sont convoqués');

select pg_temp.as_admin();
set local role authenticated;
select is(
  (select string_agg((p ->> 'display_name') || '=' || (p ->> 'waitlist_position'), ' ' order by p ->> 'display_name')
   from jsonb_array_elements(public.admin_get_match_convocations(current_setting('test.match')::uuid) -> 'players') p),
  'Alice=4 Bruno=3 Chloé=2 Damien=1',
  'l’écran de l’effectif montre le rang d’arrivée (le dernier arrivé attend le premier)');
reset role;

-- Un convoqué se désiste : le premier arrivé des joueurs en attente (Chloé)
-- prend sa place, pas le mieux classé de la saison.
update public.match_sport_participants
set availability_status = 'absent', availability_updated_at = now()
where match_id = current_setting('test.match')::uuid
  and season_player_id = 'f5840000-0000-0000-0000-000000000002';
select private.recompute_match_convocations_internal(current_setting('test.match')::uuid, false);
select is(pg_temp.effectif(current_setting('test.match')::uuid),
  'Alice convoked / Bruno not_applicable / Chloé convoked / Damien not_convoked',
  'ordre d’arrivée : la place libérée revient au premier arrivé en attente');

-- Il revient : il repasse derrière ceux qui ont répondu avant lui.
update public.match_sport_participants
set availability_status = 'available', availability_updated_at = now()
where match_id = current_setting('test.match')::uuid
  and season_player_id = 'f5840000-0000-0000-0000-000000000002';
select private.recompute_match_convocations_internal(current_setting('test.match')::uuid, false);
select is(pg_temp.effectif(current_setting('test.match')::uuid),
  'Alice convoked / Bruno not_convoked / Chloé convoked / Damien not_convoked',
  'ordre d’arrivée : un joueur qui revient se place en fin de file');

-- ---------------------------------------------------------------------------
-- Par choix de l'administrateur
-- ---------------------------------------------------------------------------
select pg_temp.as_admin();
set local role authenticated;
select lives_ok($$select public.admin_set_club_rule('waitlist_mode', 2)$$,
  'l’administrateur choisit le mode « par choix »');
reset role;

select private.recompute_match_convocations_internal(current_setting('test.match')::uuid, false);
select is(pg_temp.effectif(current_setting('test.match')::uuid),
  'Alice convoked / Bruno convoked / Chloé convoked / Damien convoked',
  'par choix : tous les disponibles sont convoqués au départ');

-- L'administrateur met Damien en attente : son choix est conservé.
update public.match_sport_participants
set convocation_status = 'not_convoked', convocation_manual_override = true
where match_id = current_setting('test.match')::uuid
  and season_player_id = 'f5840000-0000-0000-0000-000000000004';
select private.recompute_match_convocations_internal(current_setting('test.match')::uuid, false);
select is(pg_temp.effectif(current_setting('test.match')::uuid),
  'Alice convoked / Bruno convoked / Chloé convoked / Damien not_convoked',
  'par choix : le joueur mis en attente par l’administrateur y reste');

-- ---------------------------------------------------------------------------
-- Valeurs refusées
-- ---------------------------------------------------------------------------
select pg_temp.as_admin();
set local role authenticated;
select throws_ok($$select public.admin_set_club_rule('waitlist_mode', 3)$$,
  '22023', null, 'un mode inconnu est refusé');
reset role;

select * from finish();
rollback;
