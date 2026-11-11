-- Le mode live (suivi du match en direct) devient une fonctionnalité que
-- l'administrateur du club peut désactiver, comme les badges ou la météo.
create or replace function private.club_module_keys() returns text[]
language sql immutable
set search_path to ''
as $$
  select array[
    'predictions',       -- pronostics et leur classement
    'badges',            -- badges et armoire
    'statistics',        -- statistiques de l'équipe et des joueurs
    'man_of_the_match',  -- vote de l'homme du match
    'season_wrapped',    -- bilan de fin de saison
    'weather',           -- météo du match
    'live_mode'          -- suivi du match en direct (et alertes de but)
  ];
$$;
