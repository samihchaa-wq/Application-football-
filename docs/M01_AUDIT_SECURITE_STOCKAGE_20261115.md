# M01 — Sécurité/fiabilité commerciale : revue indépendante du 15/11/2026

Périmètre strict : dépôt commercial `samihchaa-wq/Application-football-`, Supabase `jvxkhgdopslctpcjrhzw`. **Aucune intervention sur AS Grinta original.** Observations distantes en lecture seule ; aucune migration, aucun déploiement, aucune fusion.

## Sources contrôlées

- Projet Supabase `ACTIVE_HEALTHY`, PostgreSQL 17.11, région `eu-west-3`. Deux clubs existent ; toutes les tables publiques inspectées sont en RLS.
- Advisors sécurité : **165** `authenticated_security_definer_function_executable`, **1** `auth_leaked_password_protection`, **1** INFO `rls_enabled_no_policy` sur un journal privé inaccessible.
- Catalogue SQL : 223 fonctions `SECURITY DEFINER` en `public`, dont 165 exécutables par `authenticated`, **0** par `anon`. Parmi les 165 : 161 propriétaires `club_scope`, 4 `postgres`.
- `club_scope` n'est ni superutilisateur, ni `BYPASSRLS`, ni connectable directement. Sur 59 tables, la policy **PERMISSIVE** `club_scope_access USING (true)` coexiste avec la policy **RESTRICTIVE** `club_isolation` attribuée à `PUBLIC` et applicable aussi à `club_scope`. **La règle restrictive continue à imposer `club_id = private.current_club_id()`** : la policy permissive ne la neutralise pas. Il est inexact de conclure que `club_scope` peut lire tous les clubs. Les RPC propriétaires doivent néanmoins vérifier leurs paramètres métier et les policies doivent être conservées. Les deux tables privées `waitlist_auto_*` appartiennent à `club_scope` sans `FORCE RLS` ; revue supplémentaire de leurs accès requise.
- Les quatre RPC propriétaire `postgres` ont été relues : `get_my_club_access` borne sa recherche à `private.uid()` ; `platform_health`, `platform_list_clubs`, `platform_update_club` appellent `private.is_platform_operator()`. Le contrôle des branches, paramètres et abus reste nécessaire.
- Buckets : `profile-photos` privé (5 Mo), `badge-images` public (5 Mo), `app-assets` public (10 Mo). Les policies `club_files_isolation` et `club_files_folder_*` sont déjà **RESTRICTIVE**, ce qui empêche de conclure à un contournement à partir des seules policies permissives d'administration.

## Renforcement M01-STORAGE-01 — contrôle explicite des chemins Storage

**Priorité : défense en profondeur (P2). Aucune exploitation interclub démontrée.**

`private.storage_path_in_current_club` (migration historique `20261113020000`) ne compare pas lui-même `club_id` sur les profils, invités ou joueurs de saison. Un premier examen a suggéré à tort qu'un `club_scope_access USING (true)` suffisait à élargir la lecture. **Contre-vérification SQL :** les mêmes tables possèdent une policy `club_isolation` **RESTRICTIVE** `TO PUBLIC`, qui s'applique au rôle `club_scope` (il n'est pas `BYPASSRLS`). L'existence d'un élément d'un autre club est donc déjà masquée par RLS. Le commentaire de la migration historique est cohérent avec les policies actuellement en place. **Il n'existe, à ce stade, aucune preuve d'upload interclub permis par cette fonction.**

**Durcissement proposé, non appliqué :** migration `20261122090000_storage_target_club_guard.sql` ajoutant une comparaison explicite `club_id = v_club` aux trois recherches, afin de conserver un second verrou en cas de régression future des policies. Ce n'est pas la réparation d'une fuite actuelle démontrée. Tests : contrat pgTAP `storage_target_club_guard.test.sql`, comportement avec deux clubs fictifs `storage_target_club_behavior.test.sql` et test HTTP Auth/RLS/Storage existant `tool/qa/tenant_http_smoke.py`. Les scénarios comportementaux devraient également passer sur le code actuel si la policy restrictive est correcte. Tous ces tests sont à rejouer sur le dernier SHA de PR, en base locale isolée.

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

1. **P2** — Revoir la PR de défense en profondeur Storage sur SHA exact et les tests HTTP locaux ; intégration facultative après revue, autorisation explicite obligatoire pour la migration distante.
2. **P0** — Revue exhaustive par familles des RPC `club_scope` sensibles (admin, suppression, paiement, data export, saisons, pronostics) et des Edge publiques ; tests négatifs A/B et utilisateur suspendu.
3. **P0** — Validation du postcheck et des mesures de charge de #144 ; relecture des artefacts, puis charge progressive autorisée **sur préproduction indépendante**, non sur les clubs commerciaux.
4. **P0** — Sauvegarde complète et restauration de référence sur environnement isolé, octets Storage comparés, stratégie de rétention privée et RTO/RPO acceptés.
5. **P0** — Activation et vérification de la protection de mots de passe compromis, cycle de récupération de compte, rate limiting et gestion de sessions.
6. **P1** — Recette end-to-end admin/joueur sur mobile/PWA : matchs, composition, Live, pronostics, badges, classement, attente manuelle, clôture/ouverture de saison, options par club, réseau intermittent, conflits d'écritures.
7. **P1** — Vérifications exploitation : alertes, journaux, retour arrière et pilotage sans écriture sur AS Grinta.

**Statut de la mission : investigation et correctif proposés, absence de certification.** Cette branche ne remplace ni les tableaux M00, ni la PR #144, ni les décisions de l'éditeur.
