# Mission 03 — Registre initial de validation fonctionnelle

**État : INVENTAIRE INITIAL, NON VALIDÉ POUR COMMERCIALISATION**  
**Date : 12 novembre 2026**  
**Référence examinée : branche main, commit aa5b4c7ac89477e7c9f4a807779e2e71183d5971**  
**Périmètre exclusif : samihchaa-wq/Application-football- et projet Supabase commercial jvxkhgdopslctpcjrhzw.**  
**Aucune mutation de la base commerciale. Aucun accès à la base ni au dépôt original AS-Grinta.**

Ce registre reprend les domaines de la PR #25 (audit fonctionnel, encore ouverte lors de la rédaction), les workflows CI, les tests du dépôt et les vérifications en lecture seule de Supabase. La matrice est *initiale* et doit être enrichie par un inventaire écran par écran des routes, interactions et combinaisons d'état. Une suite verte n'est jamais une validation de l'expérience utilisateur ou du service commercial.

## 1. Légende et méthode de preuve

- **CI exécutée** : test effectivement passé dans GitHub Actions, dans un environnement CI isolé, avec URL de preuve. Les périmètres précis sont ceux du fichier de test, pas de l'application réelle.
- **Code/contrat inspecté** : présence d'un test ou d'une garde, sans exécution manuelle de cette fonctionnalité.
- **À exécuter** : scénario non exécuté dans cette mission ; résultat réel inconnu, même si une unité isolée a été testée.
- **Gravité P0** : bloque tout lancement payé ; **P1** : risque important ou défaut de contrôle à traiter avant pilote ; **P2** : traitement requis pour étendre le produit ; **P3** : amélioration. Le niveau indique aussi le *risque d'absence de validation*, sans affirmer l'existence d'un bug.
- **Résultat attendu** : contrat qualité. **Constaté** : observation vérifiable. **Anomalie/lacune** : ne pas confondre anomalie démontrée, défaut déjà inventorié et absence de preuve.

### Inventaire des fichiers (sur main)

| Famille | Nombre | Emplacement | Observation |
|---|---:|---|---|
| Fichiers de tests Flutter | 222 | test/**/*_test.dart | Inclut widgets, logique métier, routeur, réseau, états exhaustifs |
| Fichiers de tests SQL pgTAP | 150 | supabase/tests/database/*.test.sql | Règles métier, droits, RLS, saisons, concurrence, multiclub |
| Fichiers Python unittest commerciaux | 2 | tool/tests/test_commercial_*.py | Préflight de publication et CSP |
| Tests unitaires Deno | 7 | supabase/functions/**/*_test.ts | Notifications, sécurité des requêtes, inscription, météo |
| Contrat statique Edge | 1 script | supabase/tests/edge/verify_edge_security_contract.py | Vérifie notamment les gardes codées |
| Charge | 1 script + pgbench | supabase/tests/load/ | Jeu de charge local, simulations de deux types d'opérations |
| Diagnostic navigateur | 1 workflow Playwright inline | .github/workflows/runtime_diagnostic.yml | Chromium, 4 tailles d'écran, inscription à froid, PWA hors ligne |
| Tests E2E complets avec vrais comptes dans le dépôt | 0 identifié | Aucun dossier integration_test ni suite E2E permanente | Le diagnostic Chromium ne pilote pas un parcours métier authentifié complet |

### Preuves GitHub Actions déjà exécutées (historique ; non relancées ici)

- Flutter CI sur main : **1 164 tests passés**, couverture **16 199 / 27 406 lignes, 59,11 %** ; seuil automatique 56 % ; analyse et compilation Web réussies. https://github.com/samihchaa-wq/Application-football-/actions/runs/43134200159
- Supabase business and RLS tests sur main : workflow réussi, exécution séquentielle des fichiers pgTAP, tests Deno et lint SQL sur base Supabase **locale**. https://github.com/samihchaa-wq/Application-football-/actions/runs/43134200048
- Test de charge sur branche de travail (différente de main) : **200 clubs demandés**, 6 000 comptes, 50 clients ; échantillon de 300 membres sans fuite détectée ; 0 transaction échouée affichée en lecture (moyenne 72,634 ms, 687,47 TPS) et écriture (moyenne 147,159 ms, 339,12 TPS). **Limite :** runner local et script pouvant masquer l'échec du processus pgbench (QA-01). https://github.com/samihchaa-wq/Application-football-/actions/runs/43130064470
- Diagnostic navigateur : workflow vert sur PR #25 (test Chromium et PWA locale ; screenshots produits et contrôles minimaux). https://github.com/samihchaa-wq/Application-football-/actions/runs/43134866578
- Mise en route Supabase : migrations appliquées jusqu'à 20261112050000, coffre initialisé, 8 Edge Functions déployées selon logs. **Ce déploiement n'est pas une validation fonctionnelle.** https://github.com/samihchaa-wq/Application-football-/actions/runs/43134233822

### Constat Supabase commercial en lecture seule

Projet ACTIVE_HEALTHY en région eu-west-3 ; 19 migrations listées, jusqu'à 20261112050000_blocage_serveur_mode_live ; 8 fonctions Edge listées ACTIVE ; tables public listées avec RLS activée et 0 ligne métier. **Aucun club, compte ni notification créés pour l'audit.** État constaté par API Supabase en lecture seule le 12/11/2026. Les informations « fonctions non déployées » dans la version main de docs/HANDOFF.md sont donc périmées : harmoniser la coordination avec les autres fils.

## 2. Matrice fonctionnelle initiale

**Lecture des colonnes :** « existant » = sous-ensemble vérifié par CI ou contrat inspecté ; ce n'est pas une validation intégrée. « Constaté » vaut uniquement pour le périmètre indiqué. Les scénarios à exécuter sont distincts.

| ID | Fonction / scénarios existants | Résultat attendu | Résultat constaté | Anomalie ou lacune identifiée | Gravité | Tests complémentaires indispensables |
|---|---|---|---|---|---|---|
| F01 | Création de club, code d'invitation (club_creation.sql, auth_register_page_test.dart) | Créateur admin, code correct, espace isolé | Tests SQL/Flutter CI verts ; pas de vraie création commerciale | Parcours authentification + Edge + SQL jamais parcouru de bout en bout | P0 | Créer deux clubs fictifs en environnement explicitement autorisé, joindre par invitation, contrôler collisions et erreurs |
| F02 | Inscription, validation, connexion, mot de passe et e-mail (profile_identity_registration.sql, tests auth, Deno register-account) | Aucune donnée métier avant validation ; connexions robustes | Tests isolés verts | Fournisseur OAuth, délivrabilité mail et récupération réelle non éprouvés ; limite homonymes globale notée dans PR #25 | P0 | Comptes fictifs, récupération mail, expiration des liens, 21 homonymes interclubs, sessions multiples et réinitialisation |
| F03 | Rôles admin/joueur, compte en attente/inactif (role_access_matrix_complete.sql et RLS) | Toute action interdite échoue au serveur | Matrice RLS locale exécutée avec succès | Équivalence des JWT réels et de la surface HTTP non démontrée commercialement | P0 | API REST/RPC/Storage réelle depuis comptes A/B, pending, suspendu, supprimé, session périmée |
| F04 | Isolation A/B des profils, classements, matchs (club_isolation.sql, business_rls.sql) | Aucune lecture ni mutation entre clubs | pgTAP local vert ; 300 membres échantillonnés au test de charge | Séparation Auth, Edge, realtime et URL de fichiers non éprouvée sur la vraie infrastructure | P0 | Parcours croisés directs REST/RPC, photos et événements Realtime des clubs A et B |
| F05 | Identité du club : nom, logo, couleurs, code (club_settings_page_test.dart, club_settings_admin.sql) | Chaque club ne voit que son identité et ses changements | Widget avec faux repository et SQL isolé verts | Pas de validation de propagation en multi-appareils / cache | P1 | Changer nom, couleurs, blason sur A, vérifier écrans et B sans recharger, upload non valide et retour erreur |
| F06 | Modules activables/désactivables (feature_flags, prediction_module_off, feature_flag_live_session) | Frontend et serveur appliquent immédiatement la même règle | Tests unitaires + SQL verts | Croisements de modules non inventoriés et changements pendant une action | P1 | Matrice toutes combinaisons raisonnables : live/pronos/stats/badges/météo/HDM/bilan ; toggle pendant ouverture, envoi ou vote |
| F07 | Saisons : ouverture, clôture, archivage, bascule (exhaustive_season_lifecycle, season_archive_atomicity) | Une seule saison active ; archives et stats cohérentes | SQL local vert | Reprise d'interface, erreurs partielles et changement rétroactif non testés en E2E | P1 | Saison vide, joueurs supprimés, changement d'année, réouverture refusée, concurrents admin, archives multimillésimes |
| F08 | Matchs : création/édition/suppression (match_form_page, match_edit_optimistic_lock, match_deletion_window) | Historique et droits cohérents, conflits explicites | Tests ciblés verts | Parcours complet calendrier → match → annulation → calendrier/notifications non exécuté | P1 | Deux admins éditent même match, annulation pendant live, dates limites, tournoi/amical/entre nous |
| F09 | Calendrier et flux ICS (calendar tests, calendar-feed Edge) | Calendrier cohérent et abonnement valide pour chaque club | Tests locaux et fonction Edge déployée | Aucun abonnement réel iOS/Google, URL Pages commerciale non vérifiée | P1 | Import ICS, changement d'horaire, retrait d'un événement, révocation et isolation A/B |
| F10 | Disponibilités, déclaration d'absence (exhaustive_availability, sports_management_availability_workflow) | Statuts et délais exacts par club | SQL + modèles Flutter verts | Frontière temporelle et transaction concurrente en conditions réelles non testées | P1 | J-6 11:59/12:00, horaires différents par club, admin dérogation, réseau coupé à l'enregistrement |
| F11 | Convocations / effectif / invités (convocation, guests, effectif tests) | Places, réservistes, gel et staff corrects | Tests locaux verts | Club vide, 1 membre, 80 membres et interruptions non parcourus | P1 | 0/1/13/14/15/80 joueurs, ajout tardif, 2 admins, retrait d'invité, publication simultanée |
| F12 | Liste d'attente, tri et promotion (waitlist_three_rules, exhaustive_waitlist_withdrawal) | Ordre déterministe et promotions sans doublon | pgTAP vert pour trois modes | Maquette réelle admin, ordre d'arrivée égal et action simultanée non validés en E2E | P1 | Comparer trois règles sur même effectif, retrait concurrent, notifications, reconfiguration en milieu de match |
| F13 | Compositions et formations (football_formation_test, exhaustive_composition) | Postes non chevauchés et publication autorisée | Tests Flutter/SQL verts pour foot à 11 | Format foot à 7/8/5 non disponible selon PR #25 | P2 | Tests tactiles grands/petits écrans, matchs internes, postes vacants, formats supplémentaires une fois développés |
| F14 | Animation de composition / médias | Animation complète, médias corrects, aucune erreur | Présence d'assets et tests de logique de présentation | Lecture réelle, taille et transition vidéo non certifiées par CI | P2 | iPhone/Android, faible débit, média absent, 0 joueur, 11 joueurs, rotations écran |
| F15 | Live : chrono, buts, passes, remplacements (live_single_pilot, idempotence, UI state) | Un pilote autorisé ; événements ordonnés ; aucune double saisie | Tests SQL + Flutter verts | Sessions réelles mobiles et déconnexion pendant match non validées | P1 | Deux pilotes concurrents, horloge dérivante, reprise hors ligne, but simultané, annulation |
| F16 | Live désactivé (feature_flag_live_session + migration 20261112050000) | Refus serveur et masquage UI | Migration présente sur base commerciale et tests en local ; aucun test HTTP réel | Garde déployée, comportement réel non vérifié | P1 | Désactiver pendant session, essayer RPC directement, réactiver, vérifier état de match intact |
| F17 | Compte rendu, score, buteurs, validation (match_sport_report, finalization_retry_idempotency) | Résultat final unique, stats et états cohérents | SQL ciblé vert | Pas de parcours réel erreur serveur après validation partielle | P1 | Double validation, correction 24 h, résultat 0-0/10-10, modifications rétroactives et effets sur badges/pronos |
| F18 | Homme du match : vote, secret, clôture (exhaustive_motm, motm_private_boundary) | Votes privés jusqu'à résultat ; module optionnel | SQL isolé vert | Horloge réelle, notifications et changements de module manquants | P1 | Vote au seuil, égalité, abandon, réouverture, badge/notification, A/B |
| F19 | Pronostics, cotes, classement (prediction_scoring, prediction_window, prediction_retry_idempotency) | Fermeture horaire et points exacts, aucune écriture après seuil | Flutter state-space 9 604 cas scoring + SQL vert | Décalage horaire, faux état réseau « enregistré », changements rétroactifs non éprouvés | P1 | T-15/T-14, résultat rectifié, saisons anciennes, 0 historique, 100 joueurs, doubles clics |
| F20 | Statistiques joueurs/club, palmarès (stats et rollover SQL) | Données justes par saison et club | Tests de calcul et archives verts | Validité de toutes projections après annulation/rétroactivité non démontrée | P1 | Recalcul complet historique, buts annulés, joueurs non liés, multi-saisons, modules OFF |
| F21 | Badges automatiques/manuels, armoire (badge_access, catalog, notifications, Flutter badges) | Déblocages sans doublon, restrictions admin, images isolées | Tests locaux verts | E2E cycle complet et visibilité de badges manuels non testés sur base commerciale | P1 | Attribution par deux admins, retrait/erreur, photo absente, 65 modèles, impact saison |
| F22 | Bilan personnel de saison / partage (season_wrapped tests) | Statistiques fidèles et média partageable | Tests de modèle et widgets verts | Export réel téléphone, absence de données, média/musique et dimensions non validés | P2 | Saison vide, records atypiques, partage iOS/Android, interruption, désactivation module |
| F23 | Notifications en-app : boîte, préférences, historique (notification_history, Flutter notifications) | Bon destinataire et bon écran | Tests locaux verts | Interactions sur vrais comptes et plusieurs navigateurs non jouées | P1 | Ouvrir chaque catégorie, désactiver préférences, anciennes notifications, A/B |
| F24 | Web push : abonnement, livraison, résilience (push_* SQL, Deno) | Envoi au bon appareil, sans fuite entre clubs | Tests politiques/SQL verts ; fonction send-push ACTIVE | Aucune preuve de réception iOS/Android, permissions ou VAPID en conditions réelles | P0 | PWA Chrome Android, PWA installée iOS, permissions accordées/refusées/révoquées, déconnexion, seconde session |
| F25 | Météo / géocodage (weather_refresh_test.ts, widgets) | Adresse du stade correctement géolocalisée, pas de blocage | Tests unitaires Deno et widget | Appel véritable Open-Meteo et absence d'adresse non validés | P2 | Terrain sans adresse, mauvaise ville, API indisponible, basculement module OFF |
| F26 | Fiches joueurs, profils/photos, Storage (storage_access_matrix + widget photo) | Fichiers sûrs, pas de fuite A/B, cache cohérent | RLS local et widgets verts | Téléversement authentifié, limites 5 Mo, session renouvelée non éprouvés | P1 | Upload/replace/delete vrais fichiers fictifs, URL directe, nom path forgé, rafraîchissement multi-appareils |
| F27 | Gestion admin : comptes, suspension, changement rôles (admin UI, SQL) | Un joueur ne peut agir comme admin ; dernier admin protégé | Tests d'accès existants verts | Couverture écran par écran des boutons et messages d'erreurs incomplète | P1 | Matrice de chaque commande : 3 rôles/états, erreur serveur, concurrence, suppression du dernier admin |
| F28 | Abonnement, essai, suspension / espace éditeur (club_subscription tests) | Décisions correctes, données conservées à expiration | Tests Flutter/SQL verts | Paiement non intégré, console éditeur non testée sur compte réel | P0 pour vente | Expiration à J30, suspension en plein match, réactivation, décompte joueurs, contrat paiement |
| F29 | RGPD : export / suppression (personal_data SQL, profile test) | Accès limité à sa donnée ; suppression et export cohérents | SQL et widget verts | Export complet depuis mobile, liens, délais et caches non validés | P0 pour vente | Compte ayant 4 saisons, fichiers, messages, avis/archives, refus d'un tiers |
| F30 | PWA / navigation / récupération hors ligne (runtime_diagnostic et Flutter routes) | Fonctionne sur chemins Pages, tailles et navigateurs prévus | Chromium headless : 320x568, 390x844, 844x390, 1440x900 ; un smoke PWA offline vert | Diagnostic local monté à la racine (/), avec fonctions métier non authentifiées ; pas de vrais appareils ni du chemin /Application-football-/ | P1 | Test sur chemin Pages, Safari iOS, Chrome Android, Firefox, PWA ajoutée à l'accueil, cache/maj et orientation |
| F31 | Réseau, retry, messages (network_resilience, confirmed_write, request_burst_guard) | État autoritaire après échec ou tentative répétée | Tests Flutter unitaires verts | Mode avion/serveur 500 pendant actions métier non démontré en E2E | P1 | Coupure avant/après confirmation, double soumission, latence 10 s, conflit 409, expiration de JWT |
| F32 | Tâches programmées, rappels et changement d'heure (SQL cron, reminders) | Un seul traitement, bon horaire par club, reprise d'incident | Tests SQL locaux ciblés verts | Exécution planifiée réelle + heure d'été/hiver + observation de livraison non confirmées | P1 | Horloge simulée, DST Europe/Paris, tâche rejouée, 0 match et 200 clubs, échec/retry |
| F33 | Sauvegarde / surveillance / restauration (production_watch/backup) | Alerte opérationnelle et restauration démontrée | Dernier monitoring CI « success » mais étape de vérification sautée (secret DB absent), restauration non prouvée | **Anomalie de signal de santé : workflow vert sans contrôle opérationnel** | P0 pour vente | Configurer secrets autorisés et sonde réelle, alerte simulée, sauvegarde chiffrée et restauration sur environnement jetable |
| F34 | Accessibilité et présentation générale (quelques contrats typographiques/layout) | Textes lisibles, boutons utilisables, lecteurs d'écran | Widgets unitaires et captures Chromium smoke | Aucun audit complet clavier, VoiceOver/TalkBack, grossissement | P2 | Plan d'acceptation WCAG, zoom 200 %, lecteur d'écran, erreurs formulaire, contraste couleurs personnalisées |

## 3. Anomalies et risques transversaux

| ID | Statut / preuve | Cause ou diagnostic | Gravité | Correctif proposé / responsable |
|---|---|---|---|---|
| QA-01 | **Anomalie démontrée dans le banc de charge**, supabase/tests/load/run.sh | Les deux pipelines pgbench terminent par « || true ». Même avec pipefail, un échec de pgbench peut devenir succès. Reproduction du comportement Bash effectuée hors du dépôt (pipeline false -> grep -> || true renvoie code 0). | P1 | Retirer l'ignorance d'erreur, garder l'affichage filtré sans masquer le code de retour, ajouter test de non-régression qui injecte un faux pgbench en échec. PR spécifique avant de se fier au signal de charge ; coordination fil 2/fil 4. |
| QA-02 | **Signal opérationnel trompeur observé**, run 43133882260 | « Production watch » vert, mais étape « Check scheduled jobs and notifications » skipped (PRODUCTION_DB_URL absent au moment du run). | P0 vente | Afficher « non configuré » de façon explicite, puis exiger le secret et une sonde effective avant vente ; vérifier aussi backup et restauration. |
| QA-03 | **Risque de dépôt observé**, GET branches/main : protected=false, protection.enabled=false | Aucune protection serveur de main détectée ; le garde Flutter post-push n'empêche pas a priori un push direct. | P1 | Protection/ruleset GitHub avec PR et checks obligatoires, suivi fil 4 ; ne pas considérer le workflow d'origine de commits comme une protection serveur. |
| QA-04 | **Absence de preuve E2E**, inventaire de l'arbre | Tests widget avec faux repositories et base SQL isolée ; diagnostic Chromium sans parcours métier à vrais comptes. | P0 pilote | Automatiser un parcours complet de deux clubs et tests manuels appareils sur une instance de test explicitement autorisée. |
| QA-05 | **Risque de livraison PWA**, runtime_diagnostic.yml | Le diagnostic utilise base-href « / », serveur local en racine, alors que Pages est sous /Application-football-/. | P1 | Smoke du build à la sous-racine réelle et test d'installation/mise à jour PWA. |
| QA-06 | **Blocage de vente connu**, docs COMMERCIAL_LAUNCH_CHECKLIST et PR #25 | Paiement absent, mentions légales à compléter, fournisseur Auth/mail réel à confirmer, noms/maillots/format foot à adapter selon cible. | P0 vente | Fil 2 pour adaptations ; fil juridique/commercial pour contrats ; validations QA après PR. |
| QA-07 | **Documentation périmée**, docs/HANDOFF.md sur main vs API Supabase | HANDOFF indique Edge non déployées ; run 43134233822 et API Supabase confirment 8 ACTIVE et migration 50000. | P2 | Mettre à jour HANDOFF après coordination, sans écraser changements des autres fils. |
| QA-08 | **Manque de preuve réelle**, notifications PWA | Tests de politique d'envoi et préférences, pas de mesure de réception par téléphone. | P0 pilote | Plan de tests Android/iPhone avec permission, navigateur, PWA installée, appareil déconnecté et reconnexion. |

**Aucune correction applicative n'est déclarée réalisée.** Le défaut QA-01 est une proposition de correction du test lui-même, pas un défaut prouvé de l'application. Les tests CI antérieurs ont été consultés, **aucune suite complète n'a été relancée dans cette mission**.

## 4. Protocole de validation : dépendances et autorisations

1. **Sans données commerciales** : nouvelles PR de code -> Flutter CI, pgTAP/RLS, Deno, lint, tests charge corrigés, contrôle de la configuration ; conserver logs, captures et SHA exact.
2. **Environnement fictif local ou isolé** : préparer deux clubs A et B et leurs comptes ; utiliser des adresses example.invalid pour les tests statiques, des boîtes e-mail de test contrôlées pour les parcours mail ; jamais les données d'AS Grinta.
3. **Base commerciale** : **aucune création, écriture, seed, push test ni scénario perturbateur sans consentement explicite du propriétaire** ; seulement après autorisation, jouer un scénario de bout en bout avec deux clubs fictifs et nettoyage planifié.
4. **Appareils et navigateurs** : Android Chrome/PWA, iOS Safari/PWA, Chrome desktop, Safari macOS et Firefox. Prouver enregistrement réel, réveil depuis notification, mode hors ligne, fond/avant-plan, orientation et réouverture.
5. **Scénarios métier combinés** : créer un match, ouvrir disponibilité, choisir effectif, composer, faire prono, démarrer live, valider score, ouvrir vote, attribuer badge, archiver saison ; à chaque transition, tester un module OFF et un autre club.
6. **Scénarios temporels** : J-6, T-15, délai du HDM, rappels, clôture, 1er/dernier jour de saison, passage heure d'hiver/été, publication rétroactive et répétition de cron.
7. **Concurrence et réseau** : deux admins, double appui, deux navigateurs, latence/timeout/HTTP 5xx, réception Realtime tardive, retry idempotent et état final lu du serveur.
8. **Critère final de sortie** : aucun P0/P1 ouvert sans dérogation documentée, tous les scénarios critiques E2E prouvés, appareils validés, suivi d'incidents et restauration réellement testés, captures/logs liés au SHA de livraison.

## 5. Traçabilité des nouvelles PR et dialogue avec le fil 2

Pour chaque changement fonctionnel du fil 2 : ouvrir/mettre à jour les lignes Fxx et anomalies QAxx affectées, ajouter au minimum un test du chemin normal, un test refus/permission, un cas limite et un scénario d'interaction ; relever le SHA et la CI réelle de la PR. Ne jamais conclure « validé » depuis les seuls tests simulés.

Modèle de fiche d'exécution :

| Champ | Valeur |
|---|---|
| ID scénario | Fxx-Tnn |
| Version | SHA et PR |
| Environnement | Local isolé / QA autorisé / appareil |
| Données | Clubs et comptes fictifs décrits sans secrets |
| Étapes | Chemin utilisateur et/ou API précis |
| Attendu | Comportement métier |
| Constaté | Valeurs/écrans réellement vus |
| Verdict | PASS / FAIL / BLOCKED / NOT RUN |
| Preuve | Lien CI, capture, log expurgé, timestamp |
| Défaut | Issue/PR, responsable et niveau |
| Retest | SHA du correctif, date, verdict |

## 6. Suivi immédiat

- **Fil 1** : intégrer à cette matrice chaque sous-parcours identifié après approfondissement de la PR #25.
- **Fil 2** : prendre en charge les corrections fonctionnelles (identifiants, maillots, formats, réglages incomplets) et accompagner chaque PR de nouveaux tests.
- **Fil 3** : posséder cette matrice, vérifier les tests nouveaux, documenter la preuve d'exécution et ouvrir les anomalies ; premier signal à fiabiliser : QA-01.
- **Fil 4** : protections dépôt, RLS/rôles réels, sauvegarde/restauration/monitoring.
- **Déploiement** : PR #24 ouvre un **pilote de test contrôlé**, pas une validation de vente. Ne pas qualifier le pilote de commercialisation ouverte.

**Bilan initial :** 374 fichiers Flutter/SQL/Python, 7 tests Deno, tests CI effectivement verts, 59,11 % de couverture de lignes Flutter, une charge locale encourageante mais un harnais faillible. La base commerciale est active et vide ; l'exploitation n'est pas encore démontrée.

## 7. Avancement QA-01 — synchronisation avec le fil 00 (12/11/2026)

Le tableau de pilotage `docs/CHANTIER.md` est proposé par la PR #29. Le fil 03 lui transmet ses preuves sans modifier son fichier de travail afin de ne pas créer de conflit de branches.

- **Correctif proposé en PR #33** : `supabase/tests/load/run.sh` n'utilise plus `|| true` après `pgbench` et laisse remonter les erreurs de lecture/écriture par `set -o pipefail`.
- **Sécurité du banc de test** : refus des URL PostgreSQL non locales **avant** toute commande `psql` susceptible de créer des données fictives. Ne jamais exécuter les seeds de charge sur la base commerciale.
- **Non-régression exécutée** : sur une copie locale du script et de la suite Python, `bash -n` sans erreur et **5/5 tests réussis**, avec binaires fictifs, sans connexion réseau ni base de données : succès lecture/écriture, échec lecture, échec écriture, sortie filtrée et refus d'une URL distante.
- **Non encore validé** : résultats de GitHub Actions sur le SHA définitif de PR #33 et nouvelle charge intégrale. La correction reste en brouillon et **non fusionnée** ; aucune validation finale n'est revendiquée.
- **Suivi** : issue #27, PR #33 ; vérifier tous les contrôles avant revue/fusion par le propriétaire selon `docs/CHANTIER.md`.

**Dépendances QA inter-missions :** fil 09 PR #31 (surveillance et restauration, cf. QA-02/issue #28), fil 08 PR #30 (parcours pilotes), fil 01 PR #25 (inventaire), fil 02 (corrections métier), fil 00 PR #29 (pilotage). L'ensemble des scénarios réels reste bloqué jusqu'à un environnement autorisé. Les décisions nécessaires au propriétaire demeurent la création/utilisation de comptes fictifs sur la base commerciale et l'autorisation de mise en ligne à des fins de tests ; aucune opération n'est présumée autorisée.
