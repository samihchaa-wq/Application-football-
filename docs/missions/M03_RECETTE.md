# M03 — Recette fonctionnelle et non-régression

Rapport du **16 novembre 2026, Europe/Paris**. Mission en cours ; **GO pilote non accordé**.
Version examinée : `5f404e70f70b4e99d754f7064b567d027d66fe03` (`main`, application `0.3.3+97`).
Plan appliqué : [PR #147](https://github.com/samihchaa-wq/Application-football-/pull/147), branche `docs/pilotage-mars-ete-2027`, SHA `dd26ace17dc42c1af8bd9773f578f20e5a29067d`, prompt Fil 03.

## Résultat et limites

Les contrôles automatisés examinés passent. **Aucun parcours authentifié dans l'interface, aucun appareil physique ni aucun envoi d'e-mail/push n'a été testé par cette mission.** Aucun défaut applicatif nouveau n'a été reproduit. L'absence de défaut reproduit n'est pas une acceptation des parcours.

Sources lues : AGENTS.md, HANDOFF.md, CHANTIER.md, inventaire M01 `AUDIT_FONCTIONNALITES_DETAILLE.md`, `QA_REGISTRE_VALIDATION.md`, dossiers de recette du 13/11 et rapport sécurité/concurrence du 15/11. Les états anciens ne sont pas repris comme états actuels.

- [Matrice : 164 identifiants M01 et résultat E2E explicite](M03_COUVERTURE.md).
- [Protocoles reproductibles restant à exécuter](M03_SCENARIOS.md).
- [Journaux des exécutions locales](preuves/m03/).

## Exécuté pendant cette mission

Environnement : copie locale du dépôt commercial, Python et Node ; fixtures fictives et dépendances simulées. Aucun accès à la base commerciale. Journaux renouvelés le 16/11 après une première exécution le 15/11.

| Contrôle | Commande | Résultat obtenu | Portée réelle |
|---|---|---|---|
| Outils et contrats | `python3 -m unittest discover -s tool/tests -p 'test_*.py' -v` | **55/55 PASS** | Contrats Auth, publication, migrations, textes et traçabilité documentaire ; pas une recette écran |
| Garde-fous QA | `python3 -m unittest discover -s tool/qa -p 'test_*.py' -v` | **36/36 PASS** | Fixtures d'archives, empreintes, refus de mauvaises destinations ; pas une restauration de production |
| Banc de charge | `python3 -m unittest discover -s supabase/tests/load -p 'test_*.py' -v` | **13/13 PASS** | Faux psql/pgbench, remontée des erreurs et contrôles finaux ; aucune charge DB exécutée ici |
| Deno local sans manage-user | Neuf fichiers de tests listés dans le journal `deno-isolated-tests.log`, commande `npx --yes deno test …` | BLOCKED, résolution dépendance npm inaccessible ; aucun résultat de test déduit du journal | Fonctions pures, aucun envoi réel ; handler manage-user bloqué par JSR |
| Sécurité Edge | `python3 supabase/tests/edge/verify_edge_security_contract.py` | PASS | Analyse de contrat du code |
| Cohérence mot de passe | `python3 tool/check_auth_password_contract.py` | PASS, 12–72 caractères | Contrat Flutter/Edge ; délivrabilité non testée |
| Syntaxe | `bash -n supabase/tests/load/run.sh` ; `node --check web/sw.js` | PASS | Syntaxe uniquement |

La suite Deno complète locale est **BLOQUÉE avant exécution** : import JSR de `@supabase/supabase-js` inaccessible depuis `manage-user/handler.ts`. Ce problème d’environnement ne prouve pas une panne du produit ; les 94 résultats cités ci-dessous proviennent exclusivement de la CI. Le sous-ensemble sans cet import fait l’objet du journal `deno-isolated-tests.log`, à distinguer de la suite entière.

Les lignes `::error::` du journal des outils sont les sorties attendues des cas négatifs de publication : la suite termine avec code 0. Aucun secret commercial n'a été fourni. La vérification initiale Node visait par erreur `web/service-worker.js` ; invocation corrigée vers `web/sw.js`, sans changement du produit.

## CI antérieure réellement examinée, non relancée par M03

SHA exact commun : `5f404e70f70b4e99d754f7064b567d027d66fe03`. Étapes et journaux téléchargés et lus le 15/11 ; ces résultats ne sont pas des exécutions locales ni des essais de production.

| Preuve | Résultat constaté | Limite |
|---|---|---|
| [Flutter CI, job 132981054585](https://github.com/samihchaa-wq/Application-football-/actions/runs/43769196815/job/132981054585) | **1 290 tests PASS**, 574 fichiers formatés sans changement, analyse sans erreur, build Web réussi ; couverture **61,13 %**, 18 057/29 538 lignes | Unitaires/widgets et contrats ; la couverture de lignes ne mesure pas la couverture fonctionnelle |
| [SQL et Edge, job 132981054943](https://github.com/samihchaa-wq/Application-football-/actions/runs/43769196869/job/132981054943) | **176 fichiers pgTAP, 2 602 assertions PASS** ; **94 tests Deno PASS** ; étape concurrence liste d'attente réussie ; lint sans erreur réelle, 7 exceptions pg_temp connues | Stack Supabase éphémère, identités simulées ; pas un parcours navigateur avec JWT obtenu par connexion |
| Saison SQL à deux clubs | `season_two_clubs_simulation.test.sql` : **23 assertions PASS**, 20 matchs, deux clubs de 20 joueurs + admin ; contrôles buts, pronostics, badges, clôture | Horloge et fixtures manipulées directement ; ne valide ni Live mobile, ni vidéos, ni installation PWA, ni e-mails |

## Vérification des corrections intégrées et dépendances M02

| Livraison intégrée | Preuve indépendante sur le main examiné | Verdict M03 |
|---|---|---|
| #138, compteurs attente atomiques | Suite de concurrence exécutée en CI ; `waitlist_consistent_manual_adjustments` 20 assertions et `waitlist_manual_credits_only` 9 assertions réussies | **Testé en CI** ; gestes concurrents dans deux navigateurs NON EXÉCUTÉS |
| #140, #141, #143, calendrier et accès à la synchronisation | Tests `calendar_actions_bar_test.dart` et `more_page_test.dart` présents dans le journal Flutter réussi | **Testé en CI** ; abonnement effectif Apple/Google et retour arrière sur téléphone NON EXÉCUTÉS |
| Maillots et historique | `match_kit_snapshots` 21 assertions, `kits_illimites` 5 assertions réussies en CI | **Testé en CI** ; rendu des gardiens, vidéo et cache après modification NON EXÉCUTÉS |
| Retry et cycle match | `finalization_retry_idempotency` 16 assertions, `match_lifecycle_cross_stage_regressions` 19 assertions réussies en CI | **Testé en CI** ; coupure réseau au moment de valider NON EXÉCUTÉE |
| Modules désactivés | `club_modules_off_background` 21 assertions réussies en CI | **Testé en CI** ; désactivation pendant action mobile NON EXÉCUTÉE |

Au dernier relevé des PR ouvertes le 16/11, aucun nouveau rapport `docs/missions/M01_…` / `M02_…` ni PR de correction rattachée au nouveau Fil 02 n'était disponible. La matrice reprend donc les **164 unités de l'inventaire M01 existant**, sans les présenter comme un contrat 2027 approuvé. M01 doit confirmer le périmètre, notamment OAuth, formats, mini-vidéos et éléments historiques. M02 doit fournir ses nouveaux SHA et scénarios ; ils restent **à retester**, sans validation anticipée. Le rapport d'automatismes #137 est une dépendance de revue, pas une correction fusionnée.

## Journal des écarts, blocages et retests

| ID | Nature et gravité | Attendu / obtenu | Responsable et sortie |
|---|---|---|---|
| M03-B01 | Preuve manquante, bloque GO pilote | Saison jouée par admin/joueur à l'écran ; aucune séance exécutée ici | M02/M03/M08 : préproduction isolée avec comptes fictifs et provenance du build, puis S01–S10 |
| M03-B02 | Preuve appareil manquante, bloque parcours promis | Réception push, liens mail, ICS et installation réels ; NON EXÉCUTÉS | M03/M08/M09 : essais iPhone/Safari/PWA, Android/Chrome et ordinateur, S11–S12 |
| M03-B03 | Contrat contradictoire, P1 documentaire | Délais Étoile : AGENTS ancre la fermeture au coup d'envoi ; README SQL mentionne validation +24 h | M01 fixe l'attendu, M02 trace la fonction effective, M03 teste les deux frontières ; aucune panne horaire reproduite |
| M03-B04 | Paramètres commerciaux historiques, P1 documentaire | Inventaire/registre parlent essai 30 jours, 10 €/joueur/an et publication désactivée ; nouveau plan impose année gratuite puis annuel par club | M00/M01/M06 réconcilient ; aucun test d'abonnement ne vaut validation de la nouvelle offre |
| M03-B05 | Dépendance à livrer | Nouveaux inventaire M01 et correctifs M02 non disponibles au relevé | Mettre à jour la matrice et retester sur chaque SHA fourni |

Les anciennes QA-01…QA-08 ne sont pas toutes déclarées ouvertes : QA-01 dispose désormais de tests locaux de non-régression réussis ; l'ancienne observation `protected=false` n'est plus actuelle (lecture GitHub : `main` protégée). QA-02, restauration, charge et sécurité complète appartiennent aussi à M09/M04 : statut à confirmer par leurs preuves courantes. Les 165 warnings ne sont pas qualifiés ici de 165 failles.

## Suite et règle de sortie

Priorité : recevoir le contrat M01 et les SHA M02 ; jouer S01 sur une préproduction autorisée, puis S02–S12 avec preuves par rôle, club et appareil. Enregistrer chaque défaut avec attendu/obtenu, version, étapes, gravité et lien ; retester le correctif et les parcours voisins. P0 : fuite/perte ou activité essentielle impossible sans contournement ; P1 : dégradation majeure ; P2 : gêne secondaire. Une lacune de preuve n'est pas un bug reproduit.

**GO M03 uniquement** si toutes les fonctions promises ont un verdict explicite sur la version candidate, tous les parcours essentiels passent et aucun P0/P1 applicatif n'est ouvert. Les gates sécurité, conformité et exploitation restent sous M04/M07/M09. Pas de pourcentage de fiabilité ni de certification absolue.

Livraison documentaire par branche/PR seulement. Aucun changement du code applicatif, des migrations, de main, des paramètres ou données Supabase ; aucune fusion, publication, dépense ou invitation. AS Grinta original et Carte soirée n'ont pas été consultés ni modifiés pendant cette mission. Aucun arbitrage propriétaire requis pour publier ce rapport.
