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

select * from finish();
rollback;
