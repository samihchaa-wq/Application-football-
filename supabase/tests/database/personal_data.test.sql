begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Acceptation des conditions et export de ses propres données.
create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
insert into test_clubs
select 'a', (public.create_club('Club Données Alpha', 'DALPHA', null, null, null, null)).id;
insert into test_clubs
select 'b', (public.create_club('Club Données Bravo', 'DBRAVO', null, null, null, null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select ('5c000000-0000-0000-0000-00000000000' || label)::uuid, 'data-' || label || '@example.invalid',
  jsonb_build_object('first_name', 'Membre', 'last_name', upper(label)),
  jsonb_build_object('club_id', id)
from test_clubs;
update public.profiles set status = 'active' where id::text like '5c000000-%';

select set_config('app.club_id', (select id::text from test_clubs where label = 'a'), true);
insert into public.seasons (id, name, status)
values ('5c000000-0000-0000-0000-0000000000f1', '2095-2096', 'open');
insert into public.players (id, display_name) values ('5c000000-0000-0000-0000-0000000000d1', 'Membre A');
insert into public.season_players (season_id, first_name, last_name, is_active, player_id, profile_id)
values ('5c000000-0000-0000-0000-0000000000f1', 'Membre', 'A', true,
        '5c000000-0000-0000-0000-0000000000d1', '5c000000-0000-0000-0000-00000000000a');
insert into public.push_subscriptions (profile_id, endpoint, p256dh, auth)
values ('5c000000-0000-0000-0000-00000000000a', 'https://push.example.invalid/secret', 'cle-secrete', 'auth-secret');
select set_config('app.club_id', '', true);

select set_config('request.jwt.claims',
  '{"sub":"5c000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $$select public.accept_terms('2026-11-12', 'parental_consent')$$,
  'un membre accepte les conditions avec l''accord d''un parent'
);
select is(
  (select terms_version || '/' || age_confirmation from public.profiles
   where id = '5c000000-0000-0000-0000-00000000000a'),
  '2026-11-12/parental_consent',
  'la version acceptée et la déclaration d''âge sont enregistrées'
);
select throws_ok(
  $$select public.accept_terms('2026-11-12', 'moins_de_15')$$,
  '22023', null,
  'une déclaration d''âge inconnue est refusée'
);

select is(
  (public.export_my_data() -> 'profile' ->> 'id'),
  '5c000000-0000-0000-0000-00000000000a',
  'l''export contient le profil du membre'
);
select is(
  jsonb_array_length(public.export_my_data() -> 'season_players'),
  1,
  'l''export contient sa place dans l''effectif'
);
select is(
  jsonb_array_length(public.export_my_data() -> 'push_subscriptions'),
  1,
  'l''export liste ses abonnements de notification'
);
select ok(
  not (public.export_my_data() -> 'push_subscriptions' -> 0 ? 'p256dh')
  and not (public.export_my_data() -> 'push_subscriptions' -> 0 ? 'endpoint'),
  'les secrets des notifications ne sont jamais exportés'
);
select ok(
  not ((public.export_my_data() -> 'club') ? 'invite_code'),
  'le code d''invitation du club n''est pas exporté'
);
reset role;

-- Un autre membre, d'un autre club, n'obtient que ses propres données.
select set_config('request.jwt.claims',
  '{"sub":"5c000000-0000-0000-0000-00000000000b","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select is(
  (public.export_my_data() -> 'profile' ->> 'id'),
  '5c000000-0000-0000-0000-00000000000b',
  'chacun n''exporte que ses propres données'
);
select ok(
  not (public.export_my_data() ? 'season_players'),
  'rien d''un autre membre ou d''un autre club dans l''export'
);
reset role;

select set_config('request.jwt.claims', '', true);
select throws_ok(
  $$select public.export_my_data()$$,
  '42501', null,
  'l''export exige d''être connecté'
);

select * from finish();
rollback;
