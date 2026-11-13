begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Vraies RPC et politiques RLS, deux clubs et plusieurs statuts de compte.
-- Tous les changements restent dans cette transaction annulée à la fin.
create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;
insert into test_clubs
select 'a', id from public.create_club('Club Permissions Alpha', 'PALPHA', null, null, null, null);
insert into test_clubs
select 'b', id from public.create_club('Club Permissions Bravo', 'PBRAVO', null, null, null, null);

create temporary table test_actors (
  id uuid primary key, label text, club_label text, role text, status text
) on commit drop;
grant select on test_actors to authenticated;
insert into test_actors values
  ('6a000000-0000-0000-0000-000000000001', 'admin A', 'a', 'admin', 'active'),
  ('6a000000-0000-0000-0000-000000000002', 'joueur A', 'a', 'pronostiqueur', 'active'),
  ('6a000000-0000-0000-0000-000000000003', 'admin en attente', 'a', 'admin', 'pending'),
  ('6a000000-0000-0000-0000-000000000004', 'admin archivé', 'a', 'admin', 'archived'),
  ('6b000000-0000-0000-0000-000000000001', 'admin B', 'b', 'admin', 'active'),
  ('6b000000-0000-0000-0000-000000000002', 'membre en attente B', 'b', 'pronostiqueur', 'pending');

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select actor.id, actor.id::text || '@example.invalid',
       jsonb_build_object('first_name', 'Membre', 'last_name', 'Permissions'),
       jsonb_build_object('club_id', club.id)
from test_actors actor join test_clubs club on club.label = actor.club_label;
update public.profiles profile
set role = actor.role, status = actor.status
from test_actors actor where profile.id = actor.id;

create function pg_temp.act_as(p_id uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
    jsonb_build_object('sub', p_id, 'role', 'authenticated', 'aud', 'authenticated')::text, true);
$$;

-- Chaque commande touche une famille d'administration. Les UUID inexistants
-- servent à exiger un refus d'autorisation AVANT la validation métier ; les
-- réglages/badges utilisent aussi des cibles réelles.
create temporary table admin_commands (label text primary key, command text) on commit drop;
grant select on admin_commands to authenticated;
insert into admin_commands values
  ('identité', $$select public.admin_update_club_identity('Nom interdit', 'INTERDIT')$$),
  ('couleurs', $$select public.admin_update_club_colors('#123456', '#FFFFFF')$$),
  ('modules', $$select public.admin_set_club_module('badges', false)$$),
  ('règles', $$select public.admin_set_club_rule('features_open_days', 8)$$),
  ('quota', $$select public.admin_set_club_usual_squad_size(20)$$),
  ('terrain', $$select public.admin_set_club_home_address('Terrain interdit')$$),
  ('invitation', $$select public.admin_regenerate_club_invite_code()$$),
  ('saisons', $$select public.open_or_create_season('2099-2100')$$),
  ('comptes', $$select public.staff_validate_profile('6b000000-0000-0000-0000-000000000002')$$),
  ('matchs', $$select public.delete_match('6a100000-0000-0000-0000-000000000001')$$),
  ('convocations', $$select public.admin_save_match_effectif('6a100000-0000-0000-0000-000000000001', 14, '[]'::jsonb, null)$$),
  ('composition', $$select public.admin_save_match_composition('6a100000-0000-0000-0000-000000000001', '4-4-2', '[]'::jsonb, false, null)$$),
  ('attente', $$select public.admin_set_waitlist_manual_count('6a100000-0000-0000-0000-000000000001', 1)$$),
  ('invités', $$select public.admin_set_guest_archived('6a100000-0000-0000-0000-000000000001', true, null)$$),
  ('notifications', $$select public.admin_set_notifications_paused(true, 'test refus')$$),
  ('texte badges', $$select public.staff_update_badge_text((select min(code) from public.badges), 'Interdit', '')$$),
  ('images badges', $$select public.staff_update_badge_image('badge-test', null)$$),
  ('seuils badges', $$select public.staff_update_badge_threshold('badge-test', 10)$$);

-- Aucun rôle admin ne vient du client : joueur, pending et archived échouent
-- sur chaque famille d'API, même avec un club parfaitement actif.
create function pg_temp.assert_denied_actor(p_id uuid, p_label text)
returns setof text language plpgsql as $$
begin
  perform pg_temp.act_as(p_id);
  return next is(public.is_admin(), false, p_label || ' : pas de droit admin');
  return next is(public.is_match_staff(), false, p_label || ' : pas de droit staff');
  return next is(public.is_moderator(), false, p_label || ' : alias sans contournement');
  return next is(private.can_manage_badges(), false, p_label || ' : pas de droit badges');
  return query
    select throws_ok(command, '42501', null, p_label || ' : refus ' || label)
    from admin_commands order by label;
end;
$$;

set local role authenticated;
select * from pg_temp.assert_denied_actor('6a000000-0000-0000-0000-000000000002', 'joueur');
select * from pg_temp.assert_denied_actor('6a000000-0000-0000-0000-000000000003', 'admin pending');
select * from pg_temp.assert_denied_actor('6a000000-0000-0000-0000-000000000004', 'admin archived');
select * from pg_temp.assert_denied_actor('6a000000-0000-0000-0000-000000000099', 'compte sans profil');
reset role;

-- Admin actif : le fonctionnement normal et les anciens alias sont conservés.
select pg_temp.act_as('6a000000-0000-0000-0000-000000000001');
set local role authenticated;
select is(public.is_admin(), true, 'admin actif du club actif autorisé');
select is(public.is_match_staff(), true, 'staff conserve le prédicat commun');
select is(public.is_moderator(), true, 'ancien alias reste compatible');
select is(private.can_manage_badges(), true, 'admin actif gère les badges');
select is(public.admin_update_club_colors('#AA0000', '#FFFFFF') ->> 'primary_color',
  '#AA0000', 'une écriture légitime est réellement effectuée');
select lives_ok(
  $$select public.staff_update_badge_text((select min(code) from public.badges), 'Badge Alpha', '')$$,
  'une modification de badge légitime est conservée');
select throws_ok(
  $$select public.staff_validate_profile('6b000000-0000-0000-0000-000000000002')$$,
  'P0002', null, 'admin A ne peut pas valider un membre du club B');
select throws_ok(
  $$select public.platform_update_club((select id from test_clubs where label = 'a'), p_status => 'active')$$,
  '42501', null, 'un admin de club ne devient pas opérateur de plateforme');

-- Un ancien JWT/en-tête mentionnant B ne change ni le club ni les droits.
select set_config('request.jwt.claims', jsonb_build_object(
  'sub', '6a000000-0000-0000-0000-000000000001', 'role', 'authenticated',
  'app_metadata', jsonb_build_object('club_id', (select id from test_clubs where label = 'b')),
  'user_metadata', jsonb_build_object('role', 'admin', 'club_id', (select id from test_clubs where label = 'b'))
)::text, true);
select set_config('app.club_id', (select id::text from test_clubs where label = 'b'), true);
select set_config('request.headers', jsonb_build_object('x-club-id',
  (select id from test_clubs where label = 'b'))::text, true);
select is(private.current_club_id(), (select id from test_clubs where label = 'a'),
  'le profil prévaut sur les métadonnées et les en-têtes');
select is(public.admin_update_club_colors('#BB0000', '#FFFFFF') ->> 'primary_color',
  '#BB0000', 'les paramètres restent ceux de A malgré un en-tête B');
reset role;
select is((select primary_color from public.clubs where id = (select id from test_clubs where label = 'b')),
  '#1F6FEB', 'le club B est inchangé');

-- Suspension en base, sans renouveler le JWT : le prochain appel est refusé.
update public.clubs set status = 'suspended' where id = (select id from test_clubs where label = 'a');
set local role authenticated;
select is(public.get_my_club_access() ->> 'status', 'suspended',
  'l’état de suspension reste consultable');
select is(public.is_admin(), false, 'la suspension agit immédiatement malgré un JWT déjà émis');
select * from pg_temp.assert_denied_actor('6a000000-0000-0000-0000-000000000001', 'admin club suspendu');
select throws_ok(
  $$insert into storage.objects(bucket_id, name, owner_id, metadata) values (
    'badge-images', 'club-logos/' || (select id::text from test_clubs where label = 'a') || '/forbidden.png',
    '6a000000-0000-0000-0000-000000000001', '{"mimetype":"image/png","size":10}'::jsonb)$$,
  '42501', null, 'la suspension bloque aussi les écritures Storage de badges');
select is((select count(*) from public.profiles), 0::bigint,
  'la lecture métier directe reste bloquée par RLS');
select is(public.export_my_data() -> 'profile' ->> 'id',
  '6a000000-0000-0000-0000-000000000001', 'exception : export personnel encore disponible');
select ok(not ((public.export_my_data() -> 'club') ? 'invite_code'),
  'l’exception export ne divulgue pas le code d’invitation');
select ok(not has_function_privilege('authenticated', 'public.prepare_profile_for_hard_deletion(uuid)', 'EXECUTE'),
  'la préparation d’effacement reste inaccessible directement au joueur/admin');
select throws_ok(
  $$select public.platform_update_club((select id from test_clubs where label = 'a'), p_status => 'active')$$,
  '42501', null, 'un admin suspendu ne peut pas réactiver son club');
reset role;

-- Les tentatives refusées n’ont ni renommé le club ni changé ses paramètres.
select is((select name from public.clubs where id = (select id from test_clubs where label = 'a')),
  'Club Permissions Alpha', 'aucun renommage après les refus');
select is((select primary_color from public.clubs where id = (select id from test_clubs where label = 'a')),
  '#BB0000', 'aucune modification de couleur après suspension');
select is((select status from public.profiles where id = '6b000000-0000-0000-0000-000000000002'),
  'pending', 'le compte B ciblé est toujours en attente');

-- Autre club actif : droits et fonctionnement préservés.
select pg_temp.act_as('6b000000-0000-0000-0000-000000000001');
set local role authenticated;
select is(public.is_admin(), true, 'la suspension de A ne retire pas les droits de B');
select is(public.admin_set_club_usual_squad_size(18), 18,
  'une opération admin de B fonctionne encore');
select is(public.export_my_data() -> 'profile' ->> 'id',
  '6b000000-0000-0000-0000-000000000001', 'B n’exporte jamais les données personnelles de A');
reset role;

-- Réactivation réservée à l'opérateur déclaré, sans modifier le JWT de A.
insert into private.platform_operators (user_id) values ('6b000000-0000-0000-0000-000000000001');
set local role authenticated;
select lives_ok(
  $$select public.platform_update_club((select id from test_clubs where label = 'a'), p_status => 'active')$$,
  'la réactivation par l’opérateur reste possible');
select pg_temp.act_as('6a000000-0000-0000-0000-000000000001');
select is(public.is_admin(), true, 'la réactivation restaure les droits sans changer de JWT');
select is(public.admin_update_club_colors('#CC0000', '#FFFFFF') ->> 'primary_color',
  '#CC0000', 'une écriture admin fonctionne à nouveau après réactivation');
reset role;

-- Service technique : capacité de maintenance conservée, aucun droit admin
-- implicite pour un appel sans utilisateur.
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select set_config('app.club_id', (select id::text from test_clubs where label = 'a'), true);
set local role service_role;
select is(private.can_manage_badges(), true, 'les traitements techniques conservent la maintenance des badges');
select is(public.is_admin(), false, 'service_role sans utilisateur ne devient pas un admin de club');
reset role;

select set_config('request.jwt.claims', '{}', true);
set local role authenticated;
select is(public.is_admin(), false, 'absence d’identité : aucun droit admin');
select throws_ok($$select public.export_my_data()$$, '42501', null,
  'l’export personnel ne devient pas un accès anonyme');
reset role;

select * from finish();
rollback;
