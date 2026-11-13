begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Deux clubs dans la même base : aucun ne doit voir, modifier ou recevoir les
-- données de l'autre, ni par les tables, ni par les vues, ni par les fonctions
-- serveur. La transaction est annulée à la fin.
create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;

insert into test_clubs
select 'a', (public.create_club('Club Alpha Tests', 'ALPHA', '#112233', '#FFFFFF', 'Europe/Paris', null)).id;
insert into test_clubs
select 'b', (public.create_club('Club Bravo Tests', 'BRAVO', '#332211', '#000000', 'Europe/Paris', null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select
  '1c000000-0000-0000-0000-00000000000a', 'admin-alpha@example.invalid',
  jsonb_build_object('first_name', 'Admin', 'last_name', 'Alpha'),
  jsonb_build_object('club_id', id)
from test_clubs where label = 'a';
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select
  '1c000000-0000-0000-0000-00000000000b', 'admin-bravo@example.invalid',
  jsonb_build_object('first_name', 'Admin', 'last_name', 'Bravo'),
  jsonb_build_object('club_id', id)
from test_clubs where label = 'b';

select is(
  (select club_id from public.profiles where id = '1c000000-0000-0000-0000-00000000000a'),
  (select id from test_clubs where label = 'a'),
  'un nouveau compte est rattaché au club indiqué à l’inscription'
);

update public.profiles
set role = 'admin', status = 'active'
where id in (
  '1c000000-0000-0000-0000-00000000000a',
  '1c000000-0000-0000-0000-00000000000b'
);

select is(
  (select count(*) from public.badges where club_id = (select id from test_clubs where label = 'a')),
  (select count(*) from private.badge_templates),
  'chaque club reçoit son propre jeu de badges à la création'
);

-- ---------------------------------------------------------------------------
-- Club Alpha
-- ---------------------------------------------------------------------------
select set_config(
  'request.jwt.claims',
  '{"sub":"1c000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;

select is(
  (select private.current_club_id()),
  (select id from test_clubs where label = 'a'),
  'le club courant est celui du compte connecté'
);

select lives_ok(
  $$select public.get_or_create_opponent('Adversaire Alpha')$$,
  'Alpha crée un adversaire par la fonction serveur'
);
insert into public.seasons (id, name, status)
values ('2c000000-0000-0000-0000-00000000000a', '2098-2099', 'open');

select is(
  (select array_agg(distinct club_id) from (
     select club_id from public.opponents
     union all
     select club_id from public.seasons
   ) created),
  array[(select id from test_clubs where label = 'a')],
  'les lignes créées sans préciser le club sont rangées dans le club du compte'
);

select is((select count(*) from public.clubs), 1::bigint, 'Alpha ne voit qu’un club');
select is(
  (select name from public.clubs), 'Club Alpha Tests', 'Alpha voit son propre club'
);
select is(
  (select count(*) from public.staff_list_profiles()), 1::bigint,
  'les fonctions serveur ne renvoient à Alpha que ses membres'
);
select is(
  (select count(*) from public.badges),
  (select count(*) from public.badges where club_id = (select id from test_clubs where label = 'a')),
  'Alpha ne voit que ses badges'
);

select lives_ok(
  $$select public.log_client_incident('incident-alpha', 'test', 'test', '0')$$,
  'un membre d’Alpha signale un incident de l’application'
);
select is(
  (select count(*) from public.admin_recent_client_incidents()
   where reference = 'incident-alpha'),
  1::bigint,
  'l’administrateur d’Alpha voit les incidents de son club'
);

reset role;

-- ---------------------------------------------------------------------------
-- Club Bravo
-- ---------------------------------------------------------------------------
select set_config(
  'request.jwt.claims',
  '{"sub":"1c000000-0000-0000-0000-00000000000b","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;

select is(
  (select count(*) from public.opponents), 0::bigint,
  'Bravo ne voit pas les adversaires d’Alpha'
);
select is(
  (select count(*) from public.seasons), 0::bigint,
  'Bravo ne voit pas les saisons d’Alpha'
);
select is(
  (select count(*) from public.staff_list_profiles()
   where id = '1c000000-0000-0000-0000-00000000000a'),
  0::bigint,
  'les fonctions serveur ne révèlent pas à Bravo les membres d’Alpha'
);
select is(
  (select count(*) from public.v_classement_general
   where profile_id = '1c000000-0000-0000-0000-00000000000a'),
  0::bigint,
  'les classements de Bravo ne contiennent pas les membres d’Alpha'
);
select is(
  (select count(*) from public.admin_recent_client_incidents()
   where reference = 'incident-alpha'),
  0::bigint,
  'l’administrateur de Bravo ne voit pas les incidents d’Alpha'
);

select throws_ok(
  $$insert into storage.objects (id, bucket_id, name, owner, owner_id, metadata)
    values (
      '3c000000-0000-0000-0000-00000000000b',
      'profile-photos',
      '1c000000-0000-0000-0000-00000000000a/intrus.png',
      '1c000000-0000-0000-0000-00000000000b',
      '1c000000-0000-0000-0000-00000000000b',
      '{"mimetype":"image/png","size":10}'::jsonb
    )$$,
  '42501',
  null,
  'l’administrateur de Bravo ne peut pas déposer dans le dossier photo d’un membre d’Alpha'
);
select throws_ok(
  $$insert into storage.objects (id, bucket_id, name, owner, owner_id, metadata)
    select
      '3c000000-0000-0000-0000-00000000000c',
      'badge-images',
      'club-logos/' || id || '/logo.png',
      '1c000000-0000-0000-0000-00000000000b',
      '1c000000-0000-0000-0000-00000000000b',
      '{"mimetype":"image/png","size":10}'::jsonb
    from test_clubs where label = 'a'$$,
  '42501',
  null,
  'l’administrateur de Bravo ne peut pas déposer dans le dossier logo d’Alpha'
);
select lives_ok(
  $$insert into storage.objects (id, bucket_id, name, owner, owner_id, metadata)
    values (
      '3c000000-0000-0000-0000-00000000000d',
      'profile-photos',
      '1c000000-0000-0000-0000-00000000000b/avatar.png',
      '1c000000-0000-0000-0000-00000000000b',
      '1c000000-0000-0000-0000-00000000000b',
      '{"mimetype":"image/png","size":10}'::jsonb
    )$$,
  'l’administrateur de Bravo dépose dans son propre dossier photo'
);

with touched as (
  update public.opponents set name = 'Piraté'
  where name = 'Adversaire Alpha'
  returning 1
)
select is((select count(*) from touched), 0::bigint, 'Bravo ne peut pas modifier une ligne d’Alpha');

with removed as (
  delete from public.opponents
  where name = 'Adversaire Alpha'
  returning 1
)
select is((select count(*) from removed), 0::bigint, 'Bravo ne peut pas supprimer une ligne d’Alpha');

select throws_ok(
  $$insert into public.seasons (name, status, club_id)
    select '2097-2098', 'terminee', id from test_clubs where label = 'a'$$,
  '42501',
  null,
  'Bravo ne peut pas écrire dans le club Alpha'
);

select throws_ok(
  $$update public.profiles
    set club_id = (select id from test_clubs where label = 'a')
    where id = '1c000000-0000-0000-0000-00000000000b'$$,
  null,
  null,
  'un membre ne peut pas se déplacer lui-même dans un autre club'
);

-- Les règles d'unicité valent par club : même nom de saison, même adversaire.
select lives_ok(
  $$insert into public.seasons (id, name, status)
    values ('2c000000-0000-0000-0000-00000000000b', '2098-2099', 'open')$$,
  'deux clubs peuvent avoir une saison ouverte du même nom'
);
select lives_ok(
  $$select public.get_or_create_opponent('Adversaire Alpha')$$,
  'deux clubs peuvent avoir un adversaire du même nom'
);

reset role;

select is(
  (select count(*) from public.opponents
   where name = 'Adversaire Alpha'
     and club_id in (select id from test_clubs)),
  2::bigint,
  'chaque club garde sa propre ligne, intacte'
);

-- Journal des incidents : la purge quotidienne passe dans chaque club, sans
-- compte connecté, comme la tâche planifiée.
insert into private.client_incident_log (reference, operation, error_type, app_version, created_at, club_id)
select 'ancien-' || label, 'test', 'test', '0', now() - interval '120 days', id from test_clubs;
insert into private.client_incident_log (reference, operation, error_type, app_version, created_at, club_id)
select 'recent-' || label, 'test', 'test', '0', now(), id from test_clubs;
select set_config('request.jwt.claims', '', true);
select is(
  private.purge_client_incident_log_all_clubs(now()),
  2,
  'la purge supprime les incidents anciens des deux clubs'
);
select is(
  (select count(*) from private.client_incident_log where reference like 'recent-%'),
  2::bigint,
  'la purge garde les incidents récents des deux clubs'
);

-- Fichiers : chaque sens, chaque sorte de dossier, et les chemins mal formés.
insert into public.season_players (id, season_id, first_name, last_name, club_id)
values ('5c000000-0000-0000-0000-00000000000a', '2c000000-0000-0000-0000-00000000000a', 'Joueur', 'Alpha',
        (select id from test_clubs where label = 'a'));

create temporary table storage_cases (
  actor text, bucket text, path text, allowed boolean
) on commit drop;
grant select on storage_cases to authenticated;
insert into storage_cases
select 'b', 'profile-photos', '1c000000-0000-0000-0000-00000000000a/x.png', false union all
select 'b', 'profile-photos', 'season/5c000000-0000-0000-0000-00000000000a/x.png', false union all
select 'b', 'profile-photos', 'guest/x.png', false union all
select 'b', 'profile-photos', 'x.png', false union all
select 'b', 'profile-photos', 'pas-un-uuid/x.png', false union all
select 'a', 'profile-photos', 'season/5c000000-0000-0000-0000-00000000000a/x.png', true union all
select 'a', 'profile-photos', '1c000000-0000-0000-0000-00000000000b/x.png', false union all
select 'a', 'badge-images', 'club-logos/' || (select id from test_clubs where label = 'b') || '/x.png', false union all
select 'a', 'badge-images', 'club-logos/' || (select id from test_clubs where label = 'a') || '/x.png', true;

-- Renvoie 'ok' si le dépôt passe, sinon le code d'erreur exact. Un refus
-- n'est compté comme bon que s'il vient de la règle de cloisonnement (42501).
create function pg_temp.storage_try(p_actor text, p_bucket text, p_path text) returns text
language plpgsql as $$
declare
  v_user uuid := ('1c000000-0000-0000-0000-00000000000' || p_actor)::uuid;
  v_state text;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_user, 'role', 'authenticated', 'aud', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    insert into storage.objects (bucket_id, name, owner, owner_id, metadata)
    values (p_bucket, p_path, v_user, v_user, '{"mimetype":"image/png","size":10}'::jsonb);
    execute 'reset role';
    return 'ok';
  exception when others then
    get stacked diagnostics v_state = returned_sqlstate;
    execute 'reset role';
    return v_state;
  end;
end;
$$;

select is(
  (select coalesce(string_agg(format('%s %s/%s => %s', actor, bucket, path, outcome), ', '), '')
   from (
     select actor, bucket, path, allowed, pg_temp.storage_try(actor, bucket, path) as outcome
     from storage_cases
   ) tried
   where outcome is distinct from case when allowed then 'ok' else '42501' end),
  '',
  'chaque dépôt de fichier n’est accepté que dans un dossier de son propre club, et chaque refus vient de la règle de cloisonnement'
);

-- Aucune table métier n'échappe au cloisonnement.
select is(
  (
    select coalesce(string_agg(n.nspname || '.' || c.relname, ', ' order by 1), '')
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where c.relkind in ('r', 'p')
      and n.nspname in ('public', 'private')
      and (n.nspname || '.' || c.relname) not in (
        'public.clubs',
        'private.badge_templates',
        'private.local_default_club',
        'private.registration_attempts',
        'private.prediction_reminder_cron_config',
        'private.sport_waitlist_engine_activation',
        -- Singleton global non lie a un club : identique a l activation moteur.
        'private.waitlist_auto_activation',
        'private.platform_operators',
        'private.client_incident_log_unassigned',
        'private.email_confirmations',
        'private.email_attempts'
      )
      and not exists (
        select 1 from pg_policy p
        where p.polrelid = c.oid
          and p.polname = 'club_isolation'
          and not p.polpermissive
      )
  ),
  '',
  'toute table métier porte la règle de cloisonnement par club'
);

-- Aucune fonction privilégiée ne contourne les règles d'accès, hors la courte
-- liste de relais techniques relus.
select is(
  (
    select coalesce(string_agg(p.oid::regprocedure::text, ', ' order by 1), '')
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    join pg_roles r on r.oid = p.proowner
    where n.nspname in ('public', 'private')
      and p.prosecdef
      and (r.rolbypassrls or r.rolsuper or r.rolname = 'postgres')
      and p.oid::regprocedure::text not in (
        'private.current_club_id()',
        'private.uid()',
        'private.role()',
        'private.jwt()',
        'private.http_post(text,jsonb,jsonb,jsonb,integer)',
        'private.edge_function_url(text)',
        'private.vault_secrets()',
        'private.provision_club(uuid)',
        'private.run_for_each_club(text)',
        'create_club(text,text,text,text,text,uuid)',
        'club_for_invite_code(text)',
        'promote_club_founder(uuid,uuid)',
        'found_club(uuid,uuid,text)',
        'discard_empty_club(uuid)',
        'consume_email_rate_limit(text,text)',
        'request_contact_email(uuid,text,text)',
        'confirm_contact_email(text)',
        'profile_for_recovery_email(text)',
        'handle_new_auth_user()',
        -- Console de l'éditeur, réservée aux comptes de private.platform_operators.
        'platform_list_clubs()',
        'platform_update_club(uuid,text,text,timestamp with time zone,timestamp with time zone,integer,integer,bigint,text)',
        'platform_health()',
        'private.is_platform_operator()',
        -- État du club lisible même quand il est suspendu.
        'get_my_club_access()',
        -- Aide posée par l'amorce des tests, absente d'une vraie base.
        'private.ci_direct_player_identity_default()'
      )
  ),
  '',
  'aucune fonction serveur ne contourne le cloisonnement'
);

select * from finish();
rollback;
