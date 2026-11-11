begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Parcours d'inscription : créer un club, le rejoindre par son code, changer
-- le code. La transaction est annulée à la fin.
create temporary table test_club on commit drop as
select * from public.create_club('FC Création Tests', null, null, null, null, null);
grant select on test_club to authenticated;

select matches(
  (select invite_code from test_club), '^[A-Z2-9]{8}$',
  'un nouveau club reçoit un code d’invitation lisible'
);
select is(
  (select short_name from test_club), 'FCT',
  'le nom court par défaut reprend les initiales du club'
);

-- Le code retrouve le club, quelle que soit la casse saisie.
select is(
  (select id from public.club_for_invite_code(lower((select invite_code from test_club)))),
  (select id from test_club),
  'le code d’invitation retrouve son club'
);
select is(
  (select count(*) from public.club_for_invite_code('ZZZZZZZZ')), 0::bigint,
  'un code inconnu ne retrouve aucun club'
);

-- Ces fonctions sont réservées au serveur d'inscription.
select ok(
  not has_function_privilege('authenticated', 'public.club_for_invite_code(text)', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.promote_club_founder(uuid,uuid)', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.discard_empty_club(uuid)', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.create_club(text,text,text,text,text,uuid)', 'EXECUTE')
  and not has_function_privilege('anon', 'public.club_for_invite_code(text)', 'EXECUTE'),
  'un compte ordinaire ne peut ni créer un club, ni chercher un club par code, ni se promouvoir'
);

-- Le club d'un compte vient de la zone réservée au serveur. Ce que le compte
-- écrit lui-même dans ses informations est ignoré.
create temporary table other_club on commit drop as
select * from public.create_club('Autre Club Tests', null, null, null, null, null);

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select
  '1d000000-0000-0000-0000-000000000001', 'fondateur-tests@example.invalid',
  jsonb_build_object('first_name', 'Fonda', 'last_name', 'Teur',
                     'club_id', (select id from other_club)),
  jsonb_build_object('club_id', (select id from test_club));

select is(
  (select club_id from public.profiles where id = '1d000000-0000-0000-0000-000000000001'),
  (select id from test_club),
  'le club d’un nouveau compte est celui fixé par le serveur, pas celui annoncé par le client'
);
select is(
  (select status from public.profiles where id = '1d000000-0000-0000-0000-000000000001'),
  'pending',
  'un nouveau compte attend sa validation'
);

-- Le service d'authentification crée d'abord le compte, puis y inscrit le
-- club dans un second temps : le profil apparaît à ce moment-là.
select set_config('app.club_id', '', true);
create temporary table saved_default on commit drop as
select * from private.local_default_club;
delete from private.local_default_club;

insert into auth.users (id, email, raw_user_meta_data)
values (
  '1d000000-0000-0000-0000-000000000003', 'deux-temps-tests@example.invalid',
  '{"first_name":"Deux","last_name":"Temps"}'::jsonb
);
select is(
  (select count(*) from public.profiles where id = '1d000000-0000-0000-0000-000000000003'),
  0::bigint,
  'sans club connu, un compte n’obtient pas de profil'
);

update auth.users
set raw_app_meta_data = jsonb_build_object('club_id', (select id from test_club))
where id = '1d000000-0000-0000-0000-000000000003';
select is(
  (select club_id from public.profiles where id = '1d000000-0000-0000-0000-000000000003'),
  (select id from test_club),
  'le profil est créé dès que le serveur rattache le compte à un club'
);

update auth.users
set raw_app_meta_data = jsonb_build_object('club_id', (select id from other_club))
where id = '1d000000-0000-0000-0000-000000000003';
select is(
  (select club_id from public.profiles where id = '1d000000-0000-0000-0000-000000000003'),
  (select id from test_club),
  'un profil existant ne change pas de club par ce biais'
);

delete from auth.users where id = '1d000000-0000-0000-0000-000000000003';
insert into private.local_default_club select * from saved_default;

-- Le créateur devient le premier administrateur.
select lives_ok(
  $$select public.promote_club_founder(
      (select id from test_club), '1d000000-0000-0000-0000-000000000001')$$,
  'le créateur du club est promu'
);
select is(
  (select role || '/' || status from public.profiles
   where id = '1d000000-0000-0000-0000-000000000001'),
  'admin/active',
  'le créateur est administrateur et actif'
);
select is(
  (select created_by from public.clubs where id = (select id from test_club)),
  '1d000000-0000-0000-0000-000000000001'::uuid,
  'le club retient son créateur'
);

-- Un second inscrit ne peut pas être promu de la même façon.
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select
  '1d000000-0000-0000-0000-000000000002', 'joueur-tests@example.invalid',
  jsonb_build_object('first_name', 'Jou', 'last_name', 'Eur'),
  jsonb_build_object('club_id', (select id from test_club));

select throws_ok(
  $$select public.promote_club_founder(
      (select id from test_club), '1d000000-0000-0000-0000-000000000002')$$,
  '22023', null,
  'un club qui a déjà un membre actif ne peut plus être « fondé »'
);
select throws_ok(
  $$select public.promote_club_founder(
      (select id from other_club), '1d000000-0000-0000-0000-000000000002')$$,
  '22023', null,
  'on ne peut pas fonder un club auquel on n’appartient pas'
);
select throws_ok(
  $$select public.discard_empty_club((select id from test_club))$$,
  '22023', null,
  'un club qui a des membres ne peut pas être effacé par l’annulation'
);
select lives_ok(
  $$select public.discard_empty_club((select id from other_club))$$,
  'un club resté vide peut être annulé'
);
select is(
  (select count(*) from public.clubs where id = (select id from other_club)), 0::bigint,
  'le club annulé a disparu'
);

-- L'administrateur change le code ; un simple membre ne le peut pas.
update public.profiles set status = 'active'
where id = '1d000000-0000-0000-0000-000000000002';

select set_config(
  'request.jwt.claims',
  '{"sub":"1d000000-0000-0000-0000-000000000002","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;
select throws_ok(
  $$select public.admin_regenerate_club_invite_code()$$,
  '42501', null,
  'un simple membre ne peut pas changer le code d’invitation'
);
select is(
  (select invite_code from public.clubs), (select invite_code from test_club),
  'un membre actif voit le code de son club, inchangé'
);
reset role;

select set_config(
  'request.jwt.claims',
  '{"sub":"1d000000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;
create temporary table new_code on commit drop as
select public.admin_regenerate_club_invite_code() as code;
select matches((select code from new_code), '^[A-Z2-9]{8}$', 'le nouveau code est valide');
select isnt(
  (select code from new_code), (select invite_code from test_club),
  'le code a bien changé'
);
select is(
  (select invite_code from public.clubs), (select code from new_code),
  'le club porte le nouveau code'
);
reset role;

select is(
  (select count(*) from public.club_for_invite_code((select invite_code from test_club))),
  0::bigint,
  'l’ancien code ne permet plus de rejoindre le club'
);

select * from finish();
rollback;
