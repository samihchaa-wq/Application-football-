-- Nettoyage de sécurité de la base commerciale.
--
-- 1. Le schéma technique `install_tmp` a servi une seule fois à installer la
--    base. Il contient une copie des fichiers de migration et une fonction
--    signalée par le contrôle de sécurité Supabase. Il n'est plus utilisé.
-- 2. Une fonction héritée d'AS Grinta écartait des statistiques une personne
--    réelle de l'ancien club, désignée par son nom. Dans l'application
--    multiclub, aucun nom ne doit être écrit en dur : un homonyme dans un
--    autre club disparaîtrait des archives, et le nom d'une personne réelle
--    n'a rien à faire dans le produit.

drop schema if exists install_tmp cascade;

create or replace function private.is_known_non_player_archive_name(p_name text)
returns boolean
language sql
immutable
strict
set search_path to ''
as $$
  select false;
$$;

revoke all on function private.is_known_non_player_archive_name(text) from public;
