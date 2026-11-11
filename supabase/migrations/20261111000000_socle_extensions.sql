-- Préparation avant la structure.

-- Extensions nécessaires.
create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

-- La structure qui suit accorde explicitement chaque droit. On retire donc
-- d'abord les droits accordés d'office à la création d'un objet, pour que
-- rien ne soit ouvert par défaut aux rôles de l'application.
alter default privileges for role postgres in schema public
  revoke all on tables from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke all on sequences from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke all on functions from anon, authenticated, service_role;
