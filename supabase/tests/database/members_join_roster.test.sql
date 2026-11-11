begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Un membre = un compte = un joueur de l'effectif : valider un compte l'ajoute
-- à l'effectif de la saison ouverte, sans saisie séparée.
create temporary table test_club (id uuid not null) on commit drop;
insert into test_club
select (public.create_club('Club Effectif', 'EFFEC', '#112233', '#FFFFFF', 'Europe/Paris', null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '3c000000-0000-0000-0000-00000000000a', 'admin-effectif@example.invalid',
  jsonb_build_object('first_name', 'Ada', 'last_name', 'Admin'),
  jsonb_build_object('club_id', id) from test_club;
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '3c000000-0000-0000-0000-00000000000b', 'joueur-effectif@example.invalid',
  jsonb_build_object('first_name', 'Joe', 'last_name', 'Joueur'),
  jsonb_build_object('club_id', id) from test_club;

select public.promote_club_founder(
  (select id from test_club), '3c000000-0000-0000-0000-00000000000a'
) is null as promoted;

select set_config('request.jwt.claims',
  '{"sub":"3c000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $$select public.open_or_create_season('2097-2098')$$,
  'l’administrateur ouvre une saison'
);
select is(
  (select count(*) from public.season_players
   where profile_id = '3c000000-0000-0000-0000-00000000000a' and is_active),
  1::bigint,
  'l’ouverture d’une saison place d’emblée les membres actifs dans l’effectif'
);
select is(
  (select count(*) from public.season_players
   where profile_id = '3c000000-0000-0000-0000-00000000000b'),
  0::bigint,
  'un compte encore en attente n’est pas dans l’effectif'
);

select lives_ok(
  $$select public.staff_validate_profile('3c000000-0000-0000-0000-00000000000b')$$,
  'l’administrateur valide le compte'
);
select is(
  (select first_name || ' ' || last_name from public.season_players
   where profile_id = '3c000000-0000-0000-0000-00000000000b' and is_active),
  'Joe Joueur',
  'le compte validé rejoint l’effectif sans autre saisie'
);
select is(
  (select count(distinct player_id) from public.season_players
   where season_id = (select id from public.seasons where status = 'open')),
  (select count(*) from public.season_players
   where season_id = (select id from public.seasons where status = 'open')),
  'chaque membre a sa propre identité de joueur, sans doublon'
);

select lives_ok(
  $$select public.open_or_create_season('2098-2099')$$,
  'la saison suivante s’ouvre'
);
select is(
  (select count(*) from public.season_players sp
   join public.seasons s on s.id = sp.season_id
   where s.name = '2098-2099' and sp.is_active),
  2::bigint,
  'les membres actifs sont reportés dans la nouvelle saison'
);

reset role;
select * from finish();
rollback;
