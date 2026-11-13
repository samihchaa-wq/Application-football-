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

-- ---------------------------------------------------------------------------
-- 1. Valeurs par défaut = comportement d'origine
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"5e000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

create temporary table expected_defaults (key text primary key, value integer) on commit drop;
insert into expected_defaults values
  ('notify_availability_open', 1), ('notify_availability_reminders', 1),
  ('notify_convocation', 1), ('notify_composition', 1),
  ('notify_match_changes', 1), ('notify_live_kickoff', 1),
  ('notify_live_goals', 1), ('notify_prediction_reminder', 1),
  ('notify_motm_open', 1), ('notify_motm_result', 1),
  ('notify_badges', 1), ('notify_admin_signups', 1),
  ('odds_mode', 0), ('odds_draw_factor', 15),
  ('odds_form_memory_days', 180), ('odds_h2h_memory_days', 900),
  ('match_duration_minutes', 90), ('live_pilot_mode', 0),
  ('motm_self_vote', 0), ('wrapped_music', 1);

select is(
  (select count(*) from expected_defaults expected
   join jsonb_array_elements(public.get_club_rules()) rule
     on rule ->> 'key' = expected.key
    and (rule ->> 'value')::int = expected.value
    and (rule ->> 'default')::int = expected.value),
  20::bigint,
  'les 20 nouveaux réglages apparaissent avec la valeur d’origine'
);
select is(
  (select count(*) from jsonb_array_elements(public.get_club_rules())),
  34::bigint,
  'les 14 règles existantes sont toujours là'
);
select is(
  (select count(*) from jsonb_array_elements(public.get_club_rules()) rule
   where rule ->> 'unit' = 'bool'
     and ((rule ->> 'min')::int <> 0 or (rule ->> 'max')::int <> 1)),
  0::bigint,
  'un réglage oui/non ne prend que 0 ou 1'
);
select throws_ok(
  $$select public.admin_set_club_rule('notify_badges', 2)$$,
  '22023', null,
  'un oui/non refuse toute autre valeur'
);
reset role;

-- ---------------------------------------------------------------------------
-- 2. Notifications coupées par le club
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '', true);
select set_config('app.club_id', (select id::text from test_clubs where label = 'a'), true);
select is(
  private.club_disabled_notification_kinds(),
  '{}'::text[],
  'sans réglage, aucune notification n’est coupée'
);
select set_config('app.club_id', '', true);

select set_config('request.jwt.claims',
  '{"sub":"5e000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select lives_ok(
  $$select public.admin_set_club_rule('notify_live_goals', 0)$$,
  'l’administrateur coupe les buts en direct'
);
select lives_ok(
  $$select public.admin_set_club_rule('notify_badges', 0)$$,
  'l’administrateur coupe les badges débloqués'
);
reset role;

select set_config('request.jwt.claims',
  '{"sub":"5e000000-0000-0000-0000-00000000000c","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select throws_ok(
  $$select public.admin_set_club_rule('notify_live_kickoff', 0)$$,
  '42501', null,
  'un simple membre ne coupe aucune notification'
);
reset role;

select set_config('request.jwt.claims', '', true);
select set_config('app.club_id', (select id::text from test_clubs where label = 'a'), true);
select is(
  private.club_disabled_notification_kinds(),
  array['badge_unlocked', 'live_goal_them', 'live_goal_us']::text[],
  'les types coupés sont ceux des deux réglages, et eux seuls'
);
select is(
  public.internal_push_config() -> 'disabled_kinds',
  '["badge_unlocked", "live_goal_them", "live_goal_us"]'::jsonb,
  'la fonction d’envoi reçoit la liste des types coupés du club'
);
select set_config('app.club_id', (select id::text from test_clubs where label = 'b'), true);
select is(
  public.internal_push_config() -> 'disabled_kinds',
  '[]'::jsonb,
  'les notifications coupées par le club A restent actives au club B'
);
select set_config('app.club_id', '', true);

-- ---------------------------------------------------------------------------
-- 3. Calcul des cotes
-- ---------------------------------------------------------------------------
-- Club sans historique : forme 50 %, pas de confrontation. Calcul d'origine :
-- victoire et défaite 2,67, nul 4,00.
select set_config('app.club_id', (select id::text from test_clubs where label = 'a'), true);
select is(
  (public.calculate_match_odds_v5('5e200000-0000-0000-0000-00000000000a', current_date) ->> 'draw')::numeric,
  4.00::numeric,
  'sans réglage, la cote du nul est celle d’origine'
);
select is(
  (public.calculate_match_odds_v5('5e200000-0000-0000-0000-00000000000a', current_date) ->> 'win')::numeric,
  2.67::numeric,
  'sans réglage, la cote de la victoire est celle d’origine'
);
select set_config('app.club_id', '', true);

-- Un match à venir, créé avant tout réglage des cotes.
select set_config('request.jwt.claims',
  '{"sub":"5e000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select set_config('test.match', public.admin_create_match_complete(
  '5e100000-0000-0000-0000-00000000000a', '5e200000-0000-0000-0000-00000000000a',
  ((now() + interval '10 days') at time zone 'Europe/Paris')::date,
  time '20:00',
  'domicile', 2, 3, 4, null, null, false, 'championnat', null)::text, true);
select is(
  (select odds_nul from public.match_odds where match_id = current_setting('test.match')::uuid),
  4.00::numeric,
  'le match à venir a la cote du nul d’origine'
);
select is(
  (select planned_duration_minutes from public.matches where id = current_setting('test.match')::uuid),
  90,
  'sans réglage, un match dure 90 minutes'
);

select lives_ok(
  $$select public.admin_set_club_rule('odds_draw_factor', 20)$$,
  'l’administrateur augmente le poids du match nul'
);
select is(
  (select odds_nul from public.match_odds where match_id = current_setting('test.match')::uuid),
  5.00::numeric,
  'la cote du nul du match à venir est recalculée aussitôt'
);
select is(
  (select odds_victoire_as_grinta from public.match_odds where match_id = current_setting('test.match')::uuid),
  2.50::numeric,
  'les autres cotes du match à venir sont recalculées avec'
);

select lives_ok(
  $$select public.admin_set_club_rule('odds_mode', 1)$$,
  'l’administrateur passe le club sans cotes'
);
select is(
  (select array[odds_victoire_as_grinta, odds_nul, odds_victoire_adverse]
   from public.match_odds where match_id = current_setting('test.match')::uuid),
  array[1.00, 1.00, 1.00]::numeric[],
  'sans cotes, chaque issue vaut 1'
);

select lives_ok(
  $$select public.admin_set_club_rule('odds_mode', null)$$,
  'retour aux cotes calculées'
);
select lives_ok(
  $$select public.admin_set_club_rule('odds_draw_factor', null)$$,
  'retour au poids du nul d’origine'
);
select is(
  (select odds_nul from public.match_odds where match_id = current_setting('test.match')::uuid),
  4.00::numeric,
  'revenir aux valeurs par défaut redonne les cotes d’origine'
);

-- ---------------------------------------------------------------------------
-- 4. Durée d'un match
-- ---------------------------------------------------------------------------
select lives_ok(
  $$select public.admin_set_club_rule('match_duration_minutes', 70)$$,
  'l’administrateur règle des matchs de 70 minutes'
);
select set_config('test.internal', public.create_internal_match(
  '5e100000-0000-0000-0000-00000000000a',
  ((now() + interval '12 days') at time zone 'Europe/Paris')::date,
  time '20:00', null)::text, true);
select is(
  (select planned_duration_minutes from public.matches where id = current_setting('test.internal')::uuid),
  70,
  'un nouveau match prend la durée réglée par le club'
);
select is(
  (select planned_duration_minutes from public.matches where id = current_setting('test.match')::uuid),
  90,
  'un match déjà créé garde sa durée'
);
reset role;

-- ---------------------------------------------------------------------------
-- 5. Qui pilote le direct
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"5e000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
select ok(
  not private.is_match_live_pilot_coach(current_setting('test.match')::uuid),
  'sans réglage, un administrateur qui n’est pas coach ne pilote pas le direct'
);

set local role authenticated;
select lives_ok(
  $$select public.admin_set_club_rule('live_pilot_mode', 1)$$,
  'l’administrateur ouvre le pilotage du direct aux administrateurs'
);
reset role;

select ok(
  private.is_match_live_pilot_coach(current_setting('test.match')::uuid),
  'avec le réglage, l’administrateur peut piloter le direct'
);
select set_config('request.jwt.claims',
  '{"sub":"5e000000-0000-0000-0000-00000000000c","role":"authenticated","aud":"authenticated"}', true);
select ok(
  not private.is_match_live_pilot_coach(current_setting('test.match')::uuid),
  'un simple membre ne pilote toujours pas le direct'
);
select set_config('request.jwt.claims',
  '{"sub":"5e000000-0000-0000-0000-00000000000b","role":"authenticated","aud":"authenticated"}', true);
select ok(
  not private.is_match_live_pilot_coach(current_setting('test.match')::uuid),
  'l’administrateur d’un autre club ne pilote pas ce direct'
);
select set_config('request.jwt.claims', '', true);

-- ---------------------------------------------------------------------------
-- 6. Étoile du match : voter pour soi
-- ---------------------------------------------------------------------------
-- Le parcours complet du vote est couvert par sports_management_motm_vote ;
-- ici on vérifie que le refus du vote pour soi dépend bien de la règle.
select ok(
  pg_get_functiondef('private.cast_match_motm_vote(uuid,uuid)'::regprocedure)
    like '%club_rule(''motm_self_vote'') = 0%',
  'le refus du vote pour soi dépend de la règle motm_self_vote'
);

select * from finish();
rollback;
