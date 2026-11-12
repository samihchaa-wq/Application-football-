begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

select ok(
  not exists (select 1 from pg_namespace where nspname = 'install_tmp'),
  'le schéma technique d''installation n''existe plus'
);

select * from finish();
rollback;
