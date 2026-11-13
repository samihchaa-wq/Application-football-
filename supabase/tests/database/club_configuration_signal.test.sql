begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Réutilise les contrats du signal de feature flags d'AS Grinta : pas de
-- paramètres sur le canal, relecture autoritaire et clients en lecture seule.
-- Ici chaque modification doit réveiller exclusivement son club.
create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;
insert into test_clubs
select 'a', id from public.create_club('Club Signal A', null, null, null, null, null);
insert into test_clubs
select 'b', id from public.create_club('Club Signal B', null, null, null, null, null);
insert into test_clubs
select 'c', id from public.create_club('Club Signal C', null, null, null, null, null);

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select v.id::uuid, v.email,
       jsonb_build_object('first_name', v.first_name, 'last_name', 'Signal'),
       jsonb_build_object('club_id', club.id)
from (values
  ('6f000000-0000-0000-0000-00000000000a', 'signal-admin-a@example.invalid', 'Admin', 'a'),
  ('6f000000-0000-0000-0000-00000000000b', 'signal-admin-b@example.invalid', 'Admin', 'b'),
  ('6f000000-0000-0000-0000-00000000000c', 'signal-player@example.invalid', 'Joueur', 'a'),
  ('6f000000-0000-0000-0000-00000000000d', 'signal-pending@example.invalid', 'Attente', 'a'),
  ('6f000000-0000-0000-0000-00000000000e', 'signal-archived@example.invalid', 'Archive', 'a')
) as v(id, email, first_name, label)
join test_clubs club on club.label = v.label;
update public.profiles
set status = case first_name when 'Attente' then 'pending' when 'Archive' then 'archived' else 'active' end,
    role = case when first_name = 'Admin' then 'admin' else 'pronostiqueur' end
where id::text like '6f000000-%';

create function pg_temp.act_as(p_id text) returns void language sql as $$
  select set_config('request.jwt.claims',
    format('{"sub":"%s","role":"authenticated","aud":"authenticated"}', p_id), true);
$$;
create function pg_temp.config_revision(p_label text) returns bigint language sql as $$
  select revision from public.feature_flag_change_signals
  where key = 'club_configuration'
    and club_id = (select id from test_clubs where label = p_label);
$$;
create function pg_temp.remember_revision(p_label text) returns void language sql as $$
  select set_config('test.config_before', pg_temp.config_revision(p_label)::text, true);
$$;

select is(
  (select count(*) from public.feature_flag_change_signals
   where key = 'club_configuration' and club_id in (select id from test_clubs)),
  3::bigint, 'chaque nouveau club reçoit un signal de configuration'
);
select ok(
  not has_function_privilege('anon', 'private.signal_club_configuration_change()', 'EXECUTE')
  and not has_function_privilege('authenticated', 'private.signal_club_configuration_change()', 'EXECUTE')
  and not has_function_privilege('service_role', 'private.signal_club_configuration_change()', 'EXECUTE'),
  'le trigger ne devient pas une fonction privilégiée appelable par API'
);
select is(
  (select array_agg(column_name::text order by column_name)
   from information_schema.columns
   where table_schema = 'public' and table_name = 'feature_flag_change_signals'),
  array['club_id', 'key', 'revision', 'updated_at']::text[],
  'le canal transporte uniquement le club, la clé, la révision et la date'
);
select set_config('test.config_b_before', pg_temp.config_revision('b')::text, true);

select pg_temp.act_as('6f000000-0000-0000-0000-00000000000a');
set local role authenticated;
select is((select count(*) from public.feature_flag_change_signals where key = 'club_configuration'),
  1::bigint, 'un administrateur ne voit que la configuration de son club');
select is(pg_temp.config_revision('b'), null, 'le signal du club B reste invisible depuis A');

select pg_temp.remember_revision('a');
select lives_ok($$select public.admin_set_club_module('predictions', false)$$,
  'un administrateur peut couper les pronostics');
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint + 1,
  'la coupure d’un module réveille les appareils du club');
select pg_temp.remember_revision('a');
select public.admin_set_club_module('predictions', false);
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint,
  'réenregistrer la même valeur ne provoque pas de rechargement');
select public.admin_set_club_module('predictions', true);
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint + 1,
  'réactiver le module émet aussi une révision');

select pg_temp.remember_revision('a');
select public.admin_set_club_rule('features_open_days', 3);
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint + 1,
  'une nouvelle règle émet une révision');
select pg_temp.remember_revision('a');
select public.admin_set_club_rule('features_open_days', 4);
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint + 1,
  'modifier une règle émet une révision');
select pg_temp.remember_revision('a');
select public.admin_set_club_rule('features_open_days', null);
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint + 1,
  'le retour à la règle par défaut réveille aussi les appareils');

select pg_temp.remember_revision('a');
select public.admin_update_club_identity('Club Signal Renommé', 'CSR');
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint + 1,
  'le changement de nom est signalé');
select pg_temp.remember_revision('a');
select public.admin_update_club_colors('#AA1234', '#FFFFFF');
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint + 1,
  'le changement de couleurs est signalé');
select pg_temp.remember_revision('a');
select public.admin_set_club_logo('club-logos/' || (select id::text from public.clubs) || '/logo.png');
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint + 1,
  'le changement de logo est signalé');
select pg_temp.remember_revision('a');
select public.admin_set_club_logo(null);
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint + 1,
  'retirer le logo est aussi signalé');
select pg_temp.remember_revision('a');
select public.admin_update_club_kits('[
  {"slot":"france","label":"Domicile","body":"#AA1234","trim":"#FFFFFF","goalkeeper_body":"#112233","goalkeeper_trim":"#FFFFFF","enabled":true},
  {"slot":"orange","label":"Extérieur","body":"#FFFFFF","trim":"#AA1234","enabled":true},
  {"slot":"blue","label":"Troisième","body":"#111111","trim":"#AA1234","enabled":false}
]'::jsonb);
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint + 1,
  'les maillots des joueurs et gardiens déclenchent le même signal');
select pg_temp.remember_revision('a');
select public.admin_regenerate_club_invite_code();
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint + 1,
  'le renouvellement du code d’invitation est signalé sans transporter le code');

select pg_temp.remember_revision('a');
select public.admin_set_club_home_address('1 rue du Stade');
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint + 1,
  'changer le terrain par défaut émet un signal');
select pg_temp.remember_revision('a');
select public.admin_set_club_home_address('1 rue du Stade');
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint,
  'une adresse inchangée n’émet aucun signal supplémentaire');
select pg_temp.remember_revision('a');
select public.admin_set_club_usual_squad_size(18);
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint + 1,
  'changer le quota sportif émet le signal de configuration');
select ok(exists(select 1 from public.feature_flag_change_signals where key = 'sports_management'),
  'le signal sportif historique reste présent en parallèle');
select pg_temp.remember_revision('a');
select throws_ok($$select public.admin_set_club_rule('features_open_days', 9999)$$,
  '22023', null, 'un réglage invalide est refusé');
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint,
  'un réglage refusé ne publie pas de fausse modification');
reset role;

select is(pg_temp.config_revision('b'), current_setting('test.config_b_before')::bigint,
  'toutes les modifications du club A laissent intacte la révision du club B');

select pg_temp.act_as('6f000000-0000-0000-0000-00000000000c');
set local role authenticated;
select is((select count(*) from public.feature_flag_change_signals where key = 'club_configuration'),
  1::bigint, 'un joueur actif peut écouter les réglages de son club');
select throws_ok($$update public.feature_flag_change_signals set revision = revision + 1$$,
  '42501', null, 'un joueur ne peut pas forger une révision');
select throws_ok($$insert into public.feature_flag_change_signals(key, revision) values ('forged', 1)$$,
  '42501', null, 'un joueur ne peut pas créer un faux signal');
select throws_ok($$delete from public.feature_flag_change_signals$$,
  '42501', null, 'un joueur ne peut pas supprimer les signaux');
select pg_temp.remember_revision('a');
select throws_ok($$select public.admin_set_club_module('predictions', false)$$,
  '42501', null, 'un joueur ne peut pas modifier les réglages via la RPC');
select is(pg_temp.config_revision('a'), current_setting('test.config_before')::bigint,
  'une tentative interdite ne publie pas de signal');
reset role;

select pg_temp.act_as('6f000000-0000-0000-0000-00000000000d');
set local role authenticated;
select is((select count(*) from public.feature_flag_change_signals), 0::bigint,
  'un compte en attente ne reçoit aucune révision');
reset role;
select pg_temp.act_as('6f000000-0000-0000-0000-00000000000e');
set local role authenticated;
select is((select count(*) from public.feature_flag_change_signals), 0::bigint,
  'un compte archivé ne reçoit aucune révision');
reset role;

-- L’éditeur agit sur B depuis son compte A : le trigger doit utiliser la
-- ligne modifiée et non le club de l’appelant.
insert into private.platform_operators(user_id)
values ('6f000000-0000-0000-0000-00000000000a');
select set_config('test.config_a_before', pg_temp.config_revision('a')::text, true);
select pg_temp.remember_revision('b');
select pg_temp.act_as('6f000000-0000-0000-0000-00000000000a');
set local role authenticated;
select lives_ok(
  $$select public.platform_update_club((select id from test_clubs where label = 'b'), p_status => 'suspended')$$,
  'l’éditeur peut suspendre un autre club sans échec du trigger');
reset role;
select is(pg_temp.config_revision('b'), current_setting('test.config_before')::bigint + 1,
  'une action de l’éditeur émet la révision sur le club cible B');
select is(pg_temp.config_revision('a'), current_setting('test.config_a_before')::bigint,
  'l’action sur B ne touche pas le signal du compte éditeur A');
select pg_temp.act_as('6f000000-0000-0000-0000-00000000000b');
set local role authenticated;
select is((select count(*) from public.feature_flag_change_signals), 0::bigint,
  'un membre d’un club suspendu ne reçoit plus les signaux');
reset role;

-- Création/suppression sans membre : les cascades ne recréent pas de signal.
select lives_ok($$delete from public.clubs where id = (select id from test_clubs where label = 'c')$$,
  'la suppression d’un club ne casse pas les cascades des tables de réglages');
select is((select count(*) from public.feature_flag_change_signals
  where club_id = (select id from test_clubs where label = 'c')), 0::bigint,
  'aucun signal orphelin n’est recréé après suppression du club');

select * from finish();
rollback;
