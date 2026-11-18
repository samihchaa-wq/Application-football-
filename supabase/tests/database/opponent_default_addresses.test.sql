begin;

-- Ancienne(s) RPC retirée(s) aux comptes connectés par la migration
-- 20261125000000 (l'appli ne les appelle plus). Ce test exerce encore leur
-- logique interne : le droit est rendu le temps du test, annulé au rollback.
grant execute on function public.admin_set_match_address(uuid,text,boolean) to authenticated;

set local search_path = public, extensions, pg_catalog;
select plan(2);

select has_function(
  'public',
  'admin_set_match_address',
  array['uuid', 'text', 'boolean'],
  'le RPC accepte le choix explicite de mémorisation'
);

select ok(
  not has_function_privilege(
    'anon',
    'public.admin_set_match_address(uuid,text,boolean)',
    'EXECUTE'
  ),
  'le RPC reste inaccessible aux anonymes'
);

select * from finish();
rollback;
