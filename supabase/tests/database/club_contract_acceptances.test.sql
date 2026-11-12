begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

select ok(
  (select relrowsecurity from pg_class
   where oid = 'public.club_contract_acceptances'::regclass),
  'RLS active sur la preuve d’acceptation du contrat club'
);

select ok(
  not has_table_privilege('authenticated', 'public.club_contract_acceptances', 'SELECT')
  and not has_table_privilege('authenticated', 'public.club_contract_acceptances', 'INSERT')
  and not has_table_privilege('authenticated', 'public.club_contract_acceptances', 'UPDATE')
  and not has_table_privilege('authenticated', 'public.club_contract_acceptances', 'DELETE'),
  'un compte connecté ne lit ni ne modifie la preuve d’acceptation'
);

select ok(
  has_table_privilege('service_role', 'public.club_contract_acceptances', 'INSERT'),
  'les fonctions serveur d’inscription peuvent écrire la preuve'
);

select throws_ok(
  $$insert into public.club_contract_acceptances (club_id, contract_version)
    values (gen_random_uuid(), 'oui')$$,
  '23514',
  null,
  'une version mal formée est refusée'
);

select ok(
  not has_function_privilege('authenticated', 'public.found_club(uuid,uuid,text)', 'EXECUTE')
  and not has_function_privilege('anon', 'public.found_club(uuid,uuid,text)', 'EXECUTE'),
  'seul le serveur d’inscription peut fonder un club'
);

-- Fondation atomique : si la preuve ne peut pas être enregistrée, le créateur
-- n'est pas promu et le club vide peut être supprimé. Aucun club ne reste
-- sans preuve.
create temporary table failed_club on commit drop as
select * from public.create_club('FC Preuve Ratée', null, null, null, null, null);

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select
  '1e000000-0000-0000-0000-000000000001', 'preuve-ratee@example.invalid',
  jsonb_build_object('first_name', 'Pre', 'last_name', 'Uve'),
  jsonb_build_object('club_id', (select id from failed_club));

select throws_ok(
  $$select public.found_club(
      (select id from failed_club), '1e000000-0000-0000-0000-000000000001', 'oui')$$,
  '23514', null,
  'une preuve impossible à enregistrer fait échouer toute la fondation'
);
select ok(
  (select role <> 'admin' and status = 'pending' from public.profiles
   where id = '1e000000-0000-0000-0000-000000000001'),
  'après l’échec, le créateur n’est ni promu ni actif'
);
select is(
  (select count(*) from public.club_contract_acceptances
   where club_id = (select id from failed_club)),
  0::bigint,
  'après l’échec, aucune preuve partielle'
);
select lives_ok(
  $$select public.discard_empty_club((select id from failed_club))$$,
  'le club resté vide peut être supprimé par le serveur'
);
select is(
  (select count(*) from public.clubs where id = (select id from failed_club)),
  0::bigint,
  'aucun club ne subsiste après une fondation ratée'
);

-- Fondation réussie : administrateur actif et une preuve, ensemble.
create temporary table founded_club on commit drop as
select * from public.create_club('FC Preuve Réussie', null, null, null, null, null);

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select
  '1e000000-0000-0000-0000-000000000002', 'preuve-reussie@example.invalid',
  jsonb_build_object('first_name', 'Fon', 'last_name', 'Dateur'),
  jsonb_build_object('club_id', (select id from founded_club));

select lives_ok(
  $$select public.found_club(
      (select id from founded_club), '1e000000-0000-0000-0000-000000000002', '2026-11-12')$$,
  'la fondation réussit avec une version valide'
);
select is(
  (select role || '/' || status from public.profiles
   where id = '1e000000-0000-0000-0000-000000000002'),
  'admin/active',
  'le créateur est administrateur actif'
);
select is(
  (select contract_version from public.club_contract_acceptances
   where club_id = (select id from founded_club)
     and profile_id = '1e000000-0000-0000-0000-000000000002'),
  '2026-11-12',
  'la preuve d’acceptation est enregistrée avec la fondation'
);

select * from finish();
rollback;
