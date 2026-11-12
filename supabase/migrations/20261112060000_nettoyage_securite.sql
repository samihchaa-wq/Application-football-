-- Suppression du schéma technique `install_tmp`.
--
-- Ce schéma a servi une seule fois à installer la base commerciale. Inventaire
-- en lecture seule du 12/11/2026 (pg_class, pg_proc, pg_type, pg_depend) :
--   - table install_tmp.files (18 lignes : copies des fichiers de
--     supabase/migrations/, conservés dans Git) et sa clé primaire ;
--   - fonction install_tmp.apply(text) (signalée par le contrôle de sécurité
--     Supabase : search_path modifiable) ;
--   - aucun objet extérieur au schéma ne dépend de ces objets.
--
-- Pas de CASCADE : chaque objet est nommé. Si un objet imprévu existe dans le
-- schéma, la dernière instruction échoue et la migration est annulée en bloc.
-- Restauration : inutile pour l'application ; le contenu de `files` se
-- reconstruit depuis les fichiers de migration du dépôt.

drop function if exists install_tmp.apply(text);
drop table if exists install_tmp.files;
drop schema if exists install_tmp restrict;
