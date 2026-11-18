begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Le client ne doit jamais pouvoir invoquer un SECURITY DEFINER en anonyme.
select is((
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prosecdef
    and has_function_privilege('anon', p.oid, 'EXECUTE')
), 0::bigint, 'aucune RPC SECURITY DEFINER publique n est executable en anonyme');

-- Le role majoritaire de proprietaire ne doit jamais contourner les RLS.
select ok(
  exists (select 1 from pg_roles where rolname = 'club_scope'
    and not rolbypassrls and not rolsuper and not rolcanlogin),
  'club_scope est un role non connectable sans bypassrls ni superutilisateur'
);

select is((
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  join pg_roles r on r.oid = p.proowner
  where n.nspname = 'public' and p.prosecdef
    and has_function_privilege('authenticated', p.oid, 'EXECUTE')
    and (r.rolbypassrls or r.rolsuper)
    and p.proname not in (
      'get_my_club_access', 'platform_health', 'platform_list_clubs',
      'platform_update_club', 'platform_record_offline_payment',
      'platform_club_billing', 'platform_control_overview'
    )
), 0::bigint, 'aucune nouvelle RPC exposee ne contourne les RLS');

select is((
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prosecdef
    and has_function_privilege('authenticated', p.oid, 'EXECUTE')
    and (p.proconfig is null or array_position(p.proconfig, 'search_path=""') is null)
), 0::bigint, 'toutes les RPC SECURITY DEFINER ont un search_path explicitement vide');

select ok(
  not has_schema_privilege('anon', 'private', 'USAGE'),
  'le schema des aides internes n est pas utilisable en anonyme'
);

-- Les RPC operateur PostgreSQL ont le controle de droits qui fait leur securite.
select is((
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in ('platform_health','platform_list_clubs','platform_update_club',
                      'platform_record_offline_payment','platform_club_billing',
                      'platform_control_overview')
    and p.prosecdef
    and position('private.is_platform_operator()' in pg_get_functiondef(p.oid)) = 0
), 0::bigint, 'toutes les RPC de plateforme verifient le statut operateur');

select ok(
  exists(
    select 1
    from pg_proc p
    where p.oid = 'public.get_my_club_access()'::regprocedure
      and p.prosecdef
      and position('private.uid()' in pg_get_functiondef(p.oid)) > 0
  ),
  'la RPC de statut du club conserve le controle sur l utilisateur courant'
);

select is((
  select count(*)
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relkind in ('r','p')
    and not c.relrowsecurity
), 0::bigint, 'aucune table applicative publique ne perd sa RLS');

select * from finish();
rollback;
