begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Une fonctionnalité coupée par un club ne doit plus rien produire en
-- arrière-plan pour ce club (notification, vote, appel météo), sans toucher
-- aux autres clubs.

-- ---------------------------------------------------------------------------
-- 1. Chaque tâche automatique vérifie le réglage du club
-- ---------------------------------------------------------------------------
select ok(
  position($$club_module_enabled('predictions')$$
    in pg_get_functiondef('public.push_prediction_j5_notifications()'::regprocedure)) > 0,
  'le rappel de pronostic vérifie que les pronostics sont activés'
);
select ok(
  position($$club_module_enabled('man_of_the_match')$$
    in pg_get_functiondef('private.ensure_match_motm_election(uuid)'::regprocedure)) > 0,
  'aucun vote d’homme du match n’est créé quand la fonction est coupée'
);
select ok(
  position($$club_module_enabled('man_of_the_match')$$
    in pg_get_functiondef('private.push_due_motm_open_notifications(timestamptz)'::regprocedure)) > 0,
  'pas de « Pense à voter » quand l’homme du match est coupé'
);
select ok(
  position($$club_module_enabled('man_of_the_match')$$
    in pg_get_functiondef('private.push_due_motm_result_notifications(timestamptz)'::regprocedure)) > 0,
  'pas d’annonce du résultat quand l’homme du match est coupé'
);
select ok(
  position($$club_module_enabled('badges')$$
    in pg_get_functiondef('private.process_badge_unlock_notifications(timestamptz)'::regprocedure)) > 0,
  'pas de « Badge débloqué » quand les badges sont coupés'
);
select ok(
  position($$club_module_enabled('weather')$$
    in pg_get_functiondef('private.request_match_weather_refresh(uuid)'::regprocedure)) > 0,
  'pas d’appel au service météo quand la météo est coupée'
);

-- ---------------------------------------------------------------------------
-- 2. Badges : deux clubs, un seul coupe la fonction
-- ---------------------------------------------------------------------------
create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
insert into test_clubs
select 'a', id from public.create_club('Club Silence A', null, null, null, null, null);
insert into test_clubs
select 'b', id from public.create_club('Club Silence B', null, null, null, null, null);

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select v.id::uuid, v.email,
       jsonb_build_object('first_name', 'Joueur', 'last_name', 'Silence'),
       jsonb_build_object('club_id', club.id)
from (values
  ('5e000000-0000-0000-0000-00000000000a', 'joueur-a-silence@example.invalid', 'a'),
  ('5e000000-0000-0000-0000-00000000000b', 'joueur-b-silence@example.invalid', 'b')
) as v(id, email, label)
join test_clubs club on club.label = v.label;

select vault.create_secret('test-token', 'push_internal_token')
where not exists (
  select 1 from vault.secrets secret where secret.name = 'push_internal_token'
);

-- Un badge débloqué dans chaque club, chacun dans son propre contexte.
create function pg_temp.as_club(p_label text) returns void language sql as $$
  select set_config('app.club_id', (select id::text from test_clubs where label = p_label), true);
$$;

select pg_temp.as_club('a');
update public.profiles set status = 'active', role = 'pronostiqueur'
where id = '5e000000-0000-0000-0000-00000000000a';
insert into public.badges (code, name, description, emoji, family, auto, kind, category)
values ('test_silence_a', 'Silence A', '', '🏅', 'joueur', false, 'custom', 'faits_de_jeu');
insert into public.profile_badges (profile_id, badge_id, source)
select '5e000000-0000-0000-0000-00000000000a', badge.id, 'manual'
from public.badges badge
where badge.code = 'test_silence_a';

select pg_temp.as_club('b');
update public.profiles set status = 'active', role = 'pronostiqueur'
where id = '5e000000-0000-0000-0000-00000000000b';
insert into public.badges (code, name, description, emoji, family, auto, kind, category)
values ('test_silence_b', 'Silence B', '', '🏅', 'joueur', false, 'custom', 'faits_de_jeu');
insert into public.profile_badges (profile_id, badge_id, source)
select '5e000000-0000-0000-0000-00000000000b', badge.id, 'manual'
from public.badges badge
where badge.code = 'test_silence_b';

select is(
  (select count(*)::integer from private.badge_unlock_push_queue
   where profile_id::text like '5e000000-%'),
  2,
  'un badge débloqué attend son annonce dans chaque club'
);

-- Le club A coupe les badges.
select pg_temp.as_club('a');
insert into private.app_feature_flags (key, enabled, config, updated_at)
values ('badges', false, '{}'::jsonb, now())
on conflict (club_id, key) do update set enabled = false;

select is(
  private.club_module_enabled('badges'), false,
  'le club A a coupé les badges'
);
select is(
  private.process_badge_unlock_notifications(now() + interval '1 minute'),
  0,
  'aucune annonce de badge ne part pour le club A'
);
select is(
  (select count(*)::integer from private.badge_unlock_push_queue
   where profile_id = '5e000000-0000-0000-0000-00000000000a'),
  0,
  'la file du club A est vidée : rien ne sera annoncé d’un coup à la réactivation'
);
select is(
  (select count(*)::integer from public.profile_badges
   where profile_id = '5e000000-0000-0000-0000-00000000000a'),
  1,
  'le badge reste acquis, prêt à réapparaître si le club réactive la fonction'
);

select pg_temp.as_club('b');
select is(
  private.club_module_enabled('badges'), true,
  'le réglage du club A ne coupe pas les badges du club B'
);
select is(
  (select count(*)::integer from private.badge_unlock_push_queue
   where profile_id = '5e000000-0000-0000-0000-00000000000b'),
  1,
  'l’annonce en attente du club B n’est pas touchée'
);

-- Le club B traite sa file (badges activés) : seule sa ligne part, et la
-- file d'un autre club n'est jamais touchée. Préférence coupée pour ne rien
-- envoyer réellement : la ligne est prise puis écartée.
update public.profiles set notify_badges = false
where id = '5e000000-0000-0000-0000-00000000000b';
-- Une annonce en attente dans le club A, posée directement.
select pg_temp.as_club('a');
insert into private.badge_unlock_push_queue (profile_id, badge_id, queued_at)
select '5e000000-0000-0000-0000-00000000000a', badge.id, now() - interval '1 hour'
from public.badges badge where badge.code = 'test_silence_a';
update private.app_feature_flags set enabled = true where key = 'badges';
-- Le club A remet les badges, mais c'est le club B qui est traité.
select pg_temp.as_club('b');
select is(
  private.process_badge_unlock_notifications(now() + interval '1 minute'),
  0,
  'le club B traite sa file sans rien envoyer (préférence coupée)'
);
select is(
  (select count(*)::integer from private.badge_unlock_push_queue
   where profile_id = '5e000000-0000-0000-0000-00000000000b'),
  0,
  'la ligne du club B est traitée'
);
select pg_temp.as_club('a');
select is(
  (select count(*)::integer from private.badge_unlock_push_queue
   where profile_id = '5e000000-0000-0000-0000-00000000000a'),
  1,
  'traiter le club B ne touche jamais la file du club A'
);
select ok(
  position('queue.club_id = (select private.current_club_id())'
    in pg_get_functiondef('private.process_badge_unlock_notifications(timestamptz)'::regprocedure)) > 0,
  'la file des annonces de badges est bornée explicitement au club traité'
);

-- ---------------------------------------------------------------------------
-- 3. Météo coupée : aucune demande, même avec le canal serveur configuré
-- ---------------------------------------------------------------------------
select pg_temp.as_club('a');
insert into private.app_feature_flags (key, enabled, config, updated_at)
values ('weather', false, '{}'::jsonb, now())
on conflict (club_id, key) do update set enabled = false;
select is(
  private.request_match_weather_refresh(null),
  null::bigint,
  'le club A qui a coupé la météo n’envoie aucune demande météo'
);

-- ---------------------------------------------------------------------------
-- 4. Pronostics coupés : la tâche de rappel ne fait rien pour ce club
-- ---------------------------------------------------------------------------
insert into private.app_feature_flags (key, enabled, config, updated_at)
values ('predictions', false, '{}'::jsonb, now())
on conflict (club_id, key) do update set enabled = false;
select is(
  public.push_prediction_j5_notifications(),
  0,
  'aucun rappel de pronostic pour un club qui a coupé les pronostics'
);

-- ---------------------------------------------------------------------------
-- 5. Effectif figé à la même heure que l'ouverture du live (règle du club)
-- ---------------------------------------------------------------------------
select ok(
  not exists (
    select 1
    from unnest(array[
      'private.publish_match_effectif'::regproc,
      'private.rebalance_upcoming_waitlist_matches'::regproc,
      'private.recompute_match_convocations_internal'::regproc,
      'public.admin_remove_match_guest'::regproc
    ]) as fn(oid)
    where position('interval ''15 minutes''' in pg_get_functiondef(fn.oid)) > 0
       or (position('match_prediction_closes_at' in pg_get_functiondef(fn.oid)) = 0
           and position('prediction_close_minutes' in pg_get_functiondef(fn.oid)) = 0)
  ),
  'l’effectif et la liste d’attente se figent à l’heure réglée par le club, plus à T-15 en dur'
);

-- ---------------------------------------------------------------------------
-- 6. Vote de l'homme du match : jamais plus court que le temps de valider
-- ---------------------------------------------------------------------------
select is(
  (select min_value from private.club_rule_catalogue() where key = 'motm_window_hours'),
  6,
  'le vote de l’homme du match dure au moins 6 heures après le coup d’envoi'
);

select * from finish();
rollback;
