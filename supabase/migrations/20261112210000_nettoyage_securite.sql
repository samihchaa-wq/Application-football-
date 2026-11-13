-- Suppression du schéma technique `install_tmp`.
--
-- Ce schéma a servi une seule fois à installer la base commerciale. Inventaire
-- en lecture seule du 12/11/2026 (pg_class, pg_proc, pg_type, pg_depend) :
--   - table install_tmp.files (18 lignes : copies des fichiers de
--     supabase/migrations/, conservés dans Git) et sa clé primaire ;
--   - fonction install_tmp.apply(text) (signalée par le contrôle de sécurité
--     Supabase : search_path modifiable) ;
--   - aucun objet extérieur au schéma ne dépend de ces objets ;
--   - empreinte md5 de chacune des 18 lignes de `files.content` identique,
--     octet pour octet, au fichier de même nom dans supabase/migrations/
--     (20261111000000 à 20261112040000) : rien n'est perdu.
--
-- Pas de CASCADE : chaque objet est nommé. Si un objet imprévu existe dans le
-- schéma, la dernière instruction échoue et la migration est annulée en bloc.
-- Restauration : jetable. `files` ne contient que des copies des fichiers de
-- migration du dépôt et `apply` ne servait qu'à les rejouer à l'installation ;
-- aucune table, vue, fonction ou tâche de l'application n'y fait référence.
--
-- Essai dans une base PostgreSQL locale isolée (12/11/2026) : avec les objets
-- attendus, la migration réussit ; avec un objet imprévu ajouté au schéma,
-- elle échoue et la table, ses 18 lignes et la fonction restent intactes ;
-- sans schéma (base neuve, CI), elle ne fait rien.

drop function if exists install_tmp.apply(text);
drop table if exists install_tmp.files;
drop schema if exists install_tmp restrict;
