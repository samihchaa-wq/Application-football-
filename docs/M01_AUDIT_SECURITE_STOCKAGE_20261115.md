# M01 — Sécurité/fiabilité commerciale : revue indépendante du 15/11/2026

Périmètre strict : dépôt commercial `samihchaa-wq/Application-football-`, Supabase `jvxkhgdopslctpcjrhzw`. **Aucune intervention sur AS Grinta original.** Observations distantes en lecture seule ; aucune migration, aucun déploiement, aucune fusion.

## Sources contrôlées

- Projet Supabase `ACTIVE_HEALTHY`, PostgreSQL 17.11, région `eu-west-3`. Deux clubs existent ; toutes les tables publiques inspectées sont en RLS.
- Advisors sécurité : **165** `authenticated_security_definer_function_executable`, **1** `auth_leaked_password_protection`, **1** INFO `rls_enabled_no_policy` sur un journal privé inaccessible.
- Catalogue SQL : 223 fonctions `SECURITY DEFINER` en `public`, dont 165 exécutables par `authenticated`, **0** par `anon`. Parmi les 165 : 161 propriétaires `club_scope`, 4 `postgres`.
- `club_scope` n'est ni superutilisateur, ni `BYPASSRLS`, ni connectable directement. Toutefois 59 tables ont une policy permissive `club_scope_access` avec `USING (true)` : les RPC propriétaires doivent **vérifier elles-mêmes le périmètre métier**, la RLS n'est pas une isolation suffisante pour ce rôle. Les deux tables privées `waitlist_auto_*` appartiennent également à `club_scope` sans `FORCE RLS` ; revue supplémentaire requise des accès fonctionnels à leurs helpers.
- Les quatre RPC propriétaire `postgres` ont été relues : `get_my_club_access` borne sa recherche à `private.uid()` ; `platform_health`, `platform_list_clubs`, `platform_update_club` appellent `private.is_platform_operator()`. Le contrôle des branches, paramètres et abus reste nécessaire.
- Buckets : `profile-photos` privé (5 Mo), `badge-images` public (5 Mo), `app-assets` public (10 Mo). Les policies `club_files_isolation` et `club_files_folder_*` sont déjà **RESTRICTIVE**, ce qui empêche de conclure à un contournement à partir des seules policies permissives d'administration.

## Constat M01-STORAGE-01 — chemin d'un autre club

**Priorité : élevée, correctif à valider avant clients.**

`private.storage_path_in_current_club` (migration historique `20261113020000`) vérifie qu'un identifiant de profil, d'invité ou de joueur de saison existe, mais pas `club_id = private.current_club_id()`. Cette fonction s'exécute avec les privilèges `club_scope` ; or les policies `club_scope_access` permettent de voir les éléments de tous les clubs. Le commentaire de l'ancienne migration supposant que la RLS restreint automatiquement ce rôle est donc incorrect. Avec une identité autorisée à écrire un fichier, un chemin utilisant l'ID d'un élément étranger peut être accepté dans la validation du **nom du dossier**. Le contrôle par propriétaire du fichier est distinct, et reste actif : ceci ne démontre ni lecture ni destruction d'un fichier déjà présent dans l'autre club.

**Correction proposée, non appliquée :** nouvelle migration `20261122090000_storage_target_club_guard.sql` ajoutant explicitement `club_id = v_club` aux trois recherches, sans toucher aux fichiers ou aux migrations déjà appliquées. Nouveau test pgTAP de contrat `storage_target_club_guard.test.sql`. Vérifier également le test HTTP Auth/RLS/Storage à deux clubs `tool/qa/tenant_http_smoke.py` (déjà présent), qui refuse l'upload dans le dossier d'un autre compte. Les tests doivent s'exécuter **sur le SHA de cette PR**, en base locale isolée ; aucune validation CI nouvelle n'était acquise au moment de la rédaction.

## État PR #144

PR `audit/security-concurrency-20261115`, HEAD `89d32136e19e4cf18ea618bfa9004da4fdeb1a59`, ouverte et non fusionnée.

- `PR quality guard`, `Runtime diagnostic`, `Flutter CI`, `Supabase business and RLS tests` : **SUCCÈS** sur ce SHA lors de la lecture.
- `Load test (hundreds of clubs)` : **EN COURS** à la dernière consultation, artefact absent ; ne pas fusionner tant que le job et le postcheck ne sont pas verts et le rapport exploité.
- Modifications examinées : nouvelle recette pgTAP sur privilèges et propriétaires, transaction pgbench +1/-1 avec deux identifiants, postcheck scores/événements/commandes, propagation des erreurs. Bonne protection, **mais ne couvre pas M01-STORAGE-01**.
- Vérifications concurrentes relatées par cette PR : 7 pronostics distincts, 6 retries d'une même opération, huit refus RPC ; reprises de la documentation de la PR, **pas rejouées indépendamment** par cette mission. Pas de mesure représentative de milliers de clients mobiles.

## Edge Functions, comptes, sauvegardes

- 8 Edge Functions actives ; `account-email`, `calendar-feed`, `register-account` et `send-push` ont `verify_jwt=false` par choix de protocole (liens publics, inscriptions ou secret interne) et doivent être auditées sur leurs propres gardes. `account-email` a un contrôle JWT interne sur `request-confirmation`, un flux public de récupération neutre et une limitation des demandes ; `send-push` contrôle `x-push-token`. L'efficacité contre les abus HTTP et les contournements reste à tester sans toucher aux utilisateurs réels.
- Advisor `auth_leaked_password_protection` : **NON RÉSOLU**. Régler dans la configuration Auth avec autorisation, puis relancer le linter. L'action du connecteur actuellement disponible ne permet pas cette modification.
- Le dépôt contient `.github/workflows/production_backup.yml` pour une archive chiffrée PostgreSQL + octets Storage et un exercice synthétique `tool/qa/local_restore_drill.py`. **Aucun succès de restauration complète de la vraie archive commerciale n'a été constaté ici**. Les artefacts de sauvegarde publiés par erreur, leur rétention, les clés et une destination indépendante restent à vérifier avec M09.
- 91 informations `unused_index`, 1 `no_primary_key` côté performances : pas 92 incidents démontrés ; à trier avant charge réaliste.

## Portes GO/NO-GO avant première facturation

1. **P0** — CI du correctif Storage verte sur SHA exact ; test HTTP avec deux vrais JWT locaux et upload interclub refusé ; déploiement uniquement après autorisation explicite.
2. **P0** — Revue exhaustive par familles des RPC `club_scope` sensibles (admin, suppression, paiement, data export, saisons, pronostics) et des Edge publiques ; tests négatifs A/B et utilisateur suspendu.
3. **P0** — Validation du postcheck et des mesures de charge de #144 ; relecture des artefacts, puis charge progressive autorisée **sur préproduction indépendante**, non sur les clubs commerciaux.
4. **P0** — Sauvegarde complète et restauration de référence sur environnement isolé, octets Storage comparés, stratégie de rétention privée et RTO/RPO acceptés.
5. **P0** — Activation et vérification de la protection de mots de passe compromis, cycle de récupération de compte, rate limiting et gestion de sessions.
6. **P1** — Recette end-to-end admin/joueur sur mobile/PWA : matchs, composition, Live, pronostics, badges, classement, attente manuelle, clôture/ouverture de saison, options par club, réseau intermittent, conflits d'écritures.
7. **P1** — Vérifications exploitation : alertes, journaux, retour arrière et pilotage sans écriture sur AS Grinta.

**Statut de la mission : investigation et correctif proposés, absence de certification.** Cette branche ne remplace ni les tableaux M00, ni la PR #144, ni les décisions de l'éditeur.
