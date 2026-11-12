begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Aucun nom de personne n'est écrit en dur dans la base multiclub : un
-- nom d'archive n'est jamais écarté d'office des joueurs.
select ok(
  not private.is_known_non_player_archive_name('Philippe   Collet'),
  'aucun nom n''est exclu d''office des archives'
);

select ok(
  not exists (
    select 1 from pg_namespace where nspname = 'install_tmp'
  ),
  'le schéma technique d''installation n''existe plus'
);

select * from finish();
rollback;
