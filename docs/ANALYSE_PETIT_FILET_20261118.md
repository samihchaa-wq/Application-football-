# Analyse complète de Petit Filet — 18 novembre 2026

Ce document est une photographie à une date donnée. Il distingue toujours
**ce qui a été vérifié** de **ce qui ne l'a pas été** (niveaux de preuve en
section 1). En cas d'écart avec la production, la production fait foi.

## Verdict en cinq lignes

1. **Le socle est sain** : analyse statique sans aucune alerte, 1 382 tests
   Flutter verts, couverture 61 %, base de données entièrement protégée
   ligne par ligne, aucune fonction serveur appelable sans compte.
2. **Le cloisonnement entre clubs est bien conçu** : chaque fonction serveur
   tourne sous un rôle qui ne peut pas contourner les règles d'accès, et le
   club d'un utilisateur vient de son profil, jamais d'un paramètre.
3. **La montée en charge est correcte sur les lectures et les saisies**
   (659 ouvertures d'appli par seconde, 241 saisies de score par seconde sur
   une base de test, zéro échec) mais **les tâches planifiées coûtent
   proportionnellement au nombre de clubs**, même inactifs : c'est le premier
   mur, estimé entre environ 300 et 1 800 clubs selon la machine (section 6).
4. **Je n'ai pas pu jouer 2-3 saisons sur le club de test** : voir section 7.
   Le test de saison de la CI (2 clubs × 10 matchs, de bout en bout) est vert
   et couvre le même parcours.
5. **Rien n'a été testé sur un vrai téléphone ni en navigateur** : écrans,
   notifications reçues, e-mails, mode sombre, PWA installée restent à
   recetter à la main.

## 1. Méthode et niveaux de preuve

| Niveau | Signification |
|---|---|
| **Vérifié ici** | Exécuté ou lu pendant cette analyse (commande, requête en lecture seule, lecture du code) |
| **Vérifié en CI** | Résultat d'un workflow GitHub réel sur `main` ou une PR, consulté ici |
| **Estimé** | Calcul ou extrapolation à partir de mesures, avec hypothèses dites |
| **Non vérifié** | Rien ne le prouve aujourd'hui |

Ce qui a été fait :

- Outils : Flutter 3.47.9 installé ; `dart format`, `flutter analyze --fatal-warnings
  --fatal-infos`, `flutter test --coverage` ; tests Python des dossiers `tool/`.
- Base commerciale (`jvxkhgdopslctpcjrhzw`) : **lectures seules** (catalogue,
  conseillers de sécurité et de performance, durées des tâches planifiées).
  Aucune donnée, aucun réglage et aucune migration n'a été modifié.
- Code : lecture des Edge Functions d'inscription et d'envoi de notifications,
  des fonctions SQL sensibles, du routeur, des modules.
- CI : lecture des dernières exécutions de « Supabase business and RLS tests »
  (5 dernières sur `main`, toutes vertes) et de « Load test » (dernière exécution
  réussie).

## 2. Fonctionnalités

**Ampleur** : 341 fichiers Dart (≈ 83 000 lignes), 61 migrations SQL,
259 fonctions serveur publiques, 9 Edge Functions, 183 fichiers de tests SQL,
253 fichiers de tests Flutter.

| Domaine | Ce que ça fait | Preuve |
|---|---|---|
| Comptes | Inscription (rejoindre un club par code, ou créer un club), validation par un admin, identifiant sans e-mail, e-mail de contact facultatif, mot de passe de 12 caractères minimum | Code lu, tests Flutter et Deno ; essai réel non fait |
| Clubs | Identité (nom, couleurs, logo, maillots joueurs et gardiens), 8 règles réglables (ouverture des dispos, fermeture des pronostics, durée du vote…), 6 modules activables (pronostics, badges, statistiques, homme du match, bilan de saison, météo) | Code lu ; règles SQL testées en CI |
| Calendrier et matchs | Création, report, annulation, saisons archivées en lecture seule, abonnement agenda (.ics), météo | Code lu ; tests CI |
| Avant le match | Disponibilités, indisponibilités à l'avance, convocations, liste d'attente avec crédits manuels, invités sans compte | Tests SQL en CI |
| Composition | Éditeur tactique (26 formations, plus 11 pour les matchs « entre nous »), simulation d'un onze cohérent, publication | Tests Flutter et SQL |
| Match en direct | Pilote unique du Live avec reprise, chronomètre, buts et passes, remplacements | Test de charge en CI (écritures concurrentes) |
| Après le match | Compte rendu validé avec fenêtre de correction, vote anonyme de l'homme du match, statistiques, 90 badges par club, bilan de saison | Test de saison en CI |
| Pronostics | Scores, classement, barème réglable | Tests |
| Notifications | Web Push, historique, coupe-circuit par club, préférences par personne | Tests Deno ; réception réelle non vérifiée |
| Plateforme | Opérateur éditeur : liste des clubs, état, abonnement, santé | Code lu ; contrôle d'accès vérifié (section 5) |

Types de rencontre : championnat, amical, « entre nous ». **Pas de coupe.**

## 3. Limites connues

### Fonctionnelles

- **Football à 11 uniquement** ; pas de coupe ; une seule saison ouverte à la fois.
- **Nom de saison** imposé : `AAAA-AAAA+1`, années 2000 à 2100.
- **Ouvrir une saison archive la précédente**, ce que le serveur refuse tant
  qu'un match est non terminé ou dans sa fenêtre de correction (24 h par
  défaut). Une saison avec des données historiques ne peut pas être rouverte.
- **Inscription limitée par adresse réseau : 5 par heure, 15 par jour.** Un
  club qui inscrit ses membres depuis le même Wi-Fi (stade, vestiaire) sera
  bloqué au sixième pendant une heure.
- **Mot de passe : 12 caractères minimum** avec majuscule, minuscule et
  chiffre. Sûr, mais exigeant pour des amateurs sur mobile.
- **L'abonnement n'est pas appliqué par le serveur** : un essai de 30 jours
  démarre à la création du club et l'état « à payer » s'affiche, mais rien ne
  suspend un club dont l'essai est fini ; seul l'opérateur peut le faire à la main. Aucun paiement
  n'est branché.
- **N'importe qui peut créer un club** (limité seulement par l'adresse réseau),
  sans paiement ni validation. Chaque club ajoute du travail planifié (section 6).

### Techniques

- Base **Supabase Pro**, machine **à 60 connexions maximum** (la plus petite
  taille, en général), Auth limité à 10 connexions : à relever avant une montée en charge réelle.
- 64 Mo de données aujourd'hui : aucune pression de volume.
- Temps réel : le forfait limite les connexions simultanées ; le modèle de
  coût du dépôt (`tool/qa/m09_capacity_model.py`) suppose des dépassements au-delà
  de 500 connexions de pointe. **Non mesuré.**
- Dette de nommage visible d'un développeur : colonnes SQL `…_as_grinta`,
  valeurs `as_grinta` du contrat serveur, identifiants JS `asGrinta…` du
  service worker, fixtures de test « AS Grinta ». Détail en section 8.
- **Fonctions SQL en versions empilées** : `admin_create_match_complete` (v1),
  `_v2` et `_v3` s'appellent en chaîne, idem pour la mise à jour d'un match et
  la création d'un match « entre nous ». Les anciennes versions restent
  appelables par les utilisateurs connectés alors que l'appli n'utilise que les
  plus récentes.

## 4. Fiabilité du code

| Contrôle | Résultat | Preuve |
|---|---|---|
| Formatage | 599 fichiers, 0 à corriger | Vérifié ici |
| Analyse statique stricte | 0 alerte | Vérifié ici |
| Tests Flutter | 1 382 verts | Vérifié ici |
| Couverture de lignes | 61,3 % (plancher de la CI : 56 %) | Vérifié ici |
| Tests Python (`tool/`) | 109 verts | Vérifié ici |
| Tests SQL (pgTAP) | 5 dernières exécutions sur `main` vertes | Vérifié en CI |
| Fichiers Dart jamais utilisés | 2 (dont 1 déjà retiré, 1 volontairement gardé) | Vérifié ici |
| `TODO`, `FIXME`, `// ignore` | 0 | Vérifié ici |
| Traces de débogage | 7 `debugPrint` de gestion d'erreur (bilan, musique) | Vérifié ici |
| Secrets dans le dépôt | aucun (clés JWT, jetons, clés privées) | Vérifié ici (balayage par motifs) |

Le dépôt est **public** (décision notée dans `docs/HANDOFF.md`) ;
`docs/CHANTIER.md` signale que l'historique contient d'anciennes données de
l'application d'origine. **À examiner avant l'ouverture commerciale.**

## 5. Sécurité

### Ce qui est solide (vérifié ici, en lecture seule sur la base commerciale)

- **61 tables publiques, toutes protégées ligne par ligne** (269 règles).
- **Aucune fonction ni table accessible sans compte** (0 droit pour le rôle anonyme).
- **224 fonctions « SECURITY DEFINER », toutes avec un chemin de recherche
  figé**.
- **Le club d'un utilisateur vient de son profil** (`current_club_id`), jamais
  d'un paramètre : un utilisateur ne peut pas changer de club.
- **Les fonctions tournent sous le rôle `club_scope`, qui ne contourne pas les
  règles d'accès** (parmi les fonctions appelables par un compte connecté, seules 4 fonctions
  publiques et 2 internes appartiennent à `postgres`). Même une fonction mal écrite reste cloisonnée par club.
- Les 3 fonctions « opérateur plateforme » refusent tout autre que l'éditeur.
- Les 22 fonctions de la liste d'alerte que mon filtre par motifs n'a pas
  reconnues (badges, préférences, notifications…) s'appuient toutes sur
  l'identité de l'appelant (`private.uid()`) ou sur `can_manage_badges()`
  (22 sur 22 par recherche dans le code, 6 relues en entier).
- Inscription : corps limité à 4 Ko, validations strictes, nettoyage en cas
  d'échec, quota par origine sans compteur global partageable.
- Envoi de notifications : jeton interne comparé en temps constant, corps borné.
- Test de cloisonnement en CI : 300 membres tirés au hasard sur 200 clubs,
  aucune fuite.

### À surveiller

| Sujet | Gravité | Détail |
|---|---|---|
| 166 fonctions « SECURITY DEFINER » appelables par un compte connecté | Moyenne (par conception) | Alerte du conseiller Supabase. Chacune doit vérifier son appelant ; 144 citent un contrôle reconnu par motifs, les 22 autres s'appuient sur l'identité de l'appelant. **Aucun test automatique ne vérifie que toute nouvelle fonction fait ce contrôle.** |
| 48 fonctions exposées mais jamais appelées par l'appli | Moyenne | Anciennes versions (création de match avec cotes, ×2…). Elles agrandissent la surface d'attaque. Retirer l'accès `authenticated` aux versions jamais appelées demande une migration : **non faite**, car la chaîne v3→v2→v1 doit être traitée d'abord. |
| `supabase/SECURITY_RPC_MATRIX.md` périmée | Faible | Audit de juillet 2026 sur l'application d'origine (parle encore de ×2 et de cotes). Elle ne décrit plus la base actuelle. |
| Adresse réseau de l'inscription lue dans des en-têtes | Faible | `cf-connecting-ip` puis `x-forwarded-for`. Sûr tant que la plate-forme les pose elle-même ; à revoir si l'accès direct est possible. |
| Création de club ouverte | Moyenne | Pas de validation ni de paiement : un abus coûte du travail planifié à toute la plate-forme. |
| Dépôt public avec historique d'origine | À qualifier | Voir section 4. |
| Fonctions Edge sans vérification de jeton (`register-account`, `account-email`, `calendar-feed`, `send-push`) | Faible | Voulu (inscription publique, flux d'agenda, appel interne). `send-push` et `register-account` relus ; `account-email`, `calendar-feed`, `claim-club` seulement survolés, mais couverts par `verify_edge_security_contract.py` en CI. |

Non fait : test d'intrusion, relecture de chaque fonction Edge, vérification
des réglages d'authentification de Supabase (limites de connexion, durée des
sessions), examen du stockage de fichiers au-delà du catalogue (3 buckets, dont
2 publics).

## 6. Montée en charge

### Mesures (CI, base éphémère, 200 clubs, 6 000 comptes, 4 000 matchs, 50 connexions)

| Mesure | Résultat |
|---|---|
| Ouverture de l'appli (profil, réglages, modules, notifications, prochains matchs, Live) | **659 par seconde**, 75 ms en moyenne, 0 échec |
| Saisie de buts simultanée dans les Live | **241 par seconde**, 207 ms en moyenne, 0 échec, 0 score parasite |
| Fuite entre clubs | aucune (300 membres tirés au hasard) |
| Tâches planifiées, un passage pour 200 clubs | 11,6 % d'un cœur par minute au total ; la plus lourde (`prediction-j5-reminders`) prend 6,5 s |
| Création d'un club avec ses données de test | ≈ 9 s par club (inclut le remplissage de test) |

Limites de cette mesure : machine de CI, sans le réseau, sans la couche d'accès
HTTP de Supabase, sans Realtime, sans les Edge Functions.

### Mesure sur la vraie base (2 clubs, dernières 24 h, lecture seule)

Les tâches planifiées de la production coûtent **environ 5 fois plus par club**
que dans le test de CI : `prediction-j5-reminders` ≈ 136 ms par passage pour
2 clubs (≈ 68 ms par club, contre 32 ms en CI). Aucun échec sur 24 h.

### Estimation du premier mur (à confirmer par un test de charge dédié)

Toutes les minutes, **chaque tâche parcourt tous les clubs actifs l'un après
l'autre, même sans match**. Deux seuils :

| Hypothèse | La tâche la plus lourde dépasse 60 s | Les tâches occupent un cœur entier |
|---|---|---|
| Coût de la production (68 ms par club pour la tâche la plus lourde, ≈ 200 ms par club et par minute au total) | ≈ 900 clubs | ≈ 300 clubs |
| Coût de la CI (32 ms par club) | ≈ 1 850 clubs | ≈ 1 700 clubs |

Au-delà, les passages se chevauchent et les rappels et clôtures de vote prennent
du retard. **Pistes** : ne traiter que les clubs ayant un match proche ou un
vote ouvert ; passer certaines tâches à 5 minutes ; mesurer la machine réelle.

### Pour « beaucoup d'utilisateurs en même temps »

- **Lectures et saisies** : très en dessous de la capacité mesurée. 1 000
  personnes ouvrant l'appli dans la même minute représentent ≈ 17 ouvertures
  par seconde, soit 3 % de ce que la base de test absorbe.
- **Pointe du samedi** : tous les clubs jouent aux mêmes heures. Les saisies
  de score mesurées (241/s) couvrent largement plusieurs centaines de clubs en Live.
- **Connexions** : 60 connexions de base et 10 pour l'authentification. Un pic de
  connexions (ouverture simultanée après une notification) est le point
  à tester en conditions réelles. **Non mesuré.**
- **Temps réel** : limite de connexions simultanées du forfait. **Non mesuré.**
- **Notifications** : un envoi par personne ; capacité de `send-push` face à
  des milliers de destinataires simultanés **non mesurée**.

## 7. Fonctionnement sur 2-3 saisons du club de test (avec le compte alphat)

### Ce que je voulais faire

Jouer trois saisons complètes dans « Club Test A » (compte `alphat`, 21
membres) en passant uniquement par les fonctions serveur normales, avec
l'identité de chaque joueur : disponibilités, pronostics, effectif, composition,
compte rendu, vote de l'homme du match, clôture de saison.

### Ce qui s'est passé

- **Le club est utilisé en ce moment** : sa saison ouverte (2027-2028) contient
  un match dont le résultat a été validé le 18/11 à 00 h 17. Le serveur interdit
  d'archiver une saison pendant les 24 h de correction : **il est impossible
  d'ouvrir une nouvelle saison avant le 19/11 à 00 h 17 (UTC)** sans modifier
  cette donnée, ce que je n'ai pas voulu faire.
- Mes trois essais en écriture (même dans une transaction annulée d'office) ont
  **expiré à 60 secondes** avec une consigne ajoutée à la réponse de l'outil
  (« ne rappelez pas l'outil, signalez une question restée sans réponse »). Je
  l'ai traitée comme une information non vérifiée, mais l'effet est le même : les
  écritures n'aboutissent pas depuis cette session, alors que les lectures
  répondent instantanément. Je n'ai donc rien écrit.
- Contrôle après coup : les deux saisons du club, leurs matchs et la date de
  validation du match du jour sont **exactement dans l'état d'avant**.

### Ce qui remplace, faute de mieux

Le test `supabase/tests/database/season_two_clubs_simulation.test.sql` joue déjà
ce parcours en CI sur une base isolée : 2 clubs de 20 joueurs, 10 matchs chacun,
disponibilités, pronostics, effectif, composition, compte rendu, vote, clôture
et bilan, avec vérification du cloisonnement. Il est **vert sur les cinq
dernières fusions** dans `main`. Il ne couvre pas la succession de **trois**
saisons ni le passage de la saison N à N+1 avec recopie de l'effectif.

### Pour le faire pour de bon

1. Attendre le 19/11 après 00 h 17 UTC (ou valider avec le propriétaire d'écraser
   la date de validation du match du jour, ce qui n'est pas recommandé).
2. Autoriser explicitement les écritures de l'outil Supabase pour cette session.
3. Mettre les notifications du club en pause (6 abonnements aux notifications y sont enregistrés), puis
   rejouer ; le script d'essai adapté du test de la CI existe mais n'a pas été
   exécuté jusqu'au bout, donc je ne l'ai pas ajouté au dépôt.

## 8. Nettoyage réalisé

| Lot | Contenu | Vérification |
|---|---|---|
| Code mort | Pastille et champ du bonus ×2 (toujours « faux »), recentrage de photo détourée (jamais appelé), constante d'archive inutilisée | Analyse + tests |
| Nom du paquet | `as_grinta` → `petit_filet` (476 fichiers d'import), description du paquet | Analyse + tests |
| Kit d'interface | `Grinta…` → `Pf…` (barre, chargement, états vides, tableaux, onglets…), fichiers `grinta_*.dart` → `pf_*.dart` | Analyse + tests |
| Équipe du club | `scoreAsGrinta`, `grintaScore`, `grintaIsHome`… → `scoreOwn`, `ownScore`, `ownIsHome`… ; le contrat serveur (`score_as_grinta`) est inchangé | Analyse + tests |
| Commentaires | 23 fichiers qui disaient « AS Grinta » | Relecture |
| Documents | 12 rapports datés, référencés nulle part | Recherche de références |
| Workflows | 3 actions ponctuelles déjà exécutées + 6 copies désactivées d'automatismes de l'application d'origine | Recherche de références, tests Python |
| README | Réécrit pour Petit Filet (bandeau « en construction » retiré, chiffres exacts) | Chaque affirmation recoupée |

### Volontairement non touché

- **Migrations** : historique immuable (règle du projet).
- **`EmailVerificationPanel`** : jamais affiché mais préparé pour la confirmation
  d'adresse (`M05_REVUE_PRIORITES`), conservé.
- **Contrat avec la base** : colonnes et valeurs `as_grinta`, métrique
  `bet_against_grinta`.
- **Service worker et page d'accueil** : `asGrinta…`, `AS_GRINTA_WEB_VERSION`,
  `ASG_PUSH_RECEIVED`, noms de caches `as-grinta-…` : liés au déploiement et aux
  tests de la coquille web, à renommer en bloc dans un lot dédié.
- **Fixtures de test** : le club de test s'appelle « AS Grinta » dans
  `test/flutter_test_config.dart`.
- **Documents** `docs/missions/`, `docs/recette/`, `docs/qa_saison_*`,
  `docs/AUDIT_*` : cités par d'autres documents, par `PLAN_DIRECTEUR_2027_2028`
  et par un test Python (`test_recette_traceability.py`).
- **Six workflows désactivés** (`workflows-disabled/`) : gardes de migrations,
  de fonctions et de consommation, sauvegardes : à réactiver ou supprimer par le
  propriétaire.
- **`docs/production-operations.md`** décrit encore l'exploitation « Supabase
  Free » avec `free_encrypted_backup` (désactivé) : à réaligner sur
  `production_backup.yml` et le forfait Pro.

## 9. Recommandations, par ordre de priorité

**Je peux le faire :**

1. Migration retirant l'accès aux 48 fonctions jamais appelées, après avoir
   traité la chaîne v3→v2→v1 (demande un accord pour toucher la base).
2. Test automatique : toute fonction « SECURITY DEFINER » exposée doit citer un
   contrôle d'appelant.
3. Tâches planifiées : ne parcourir que les clubs actifs ; test de charge à
   500 et 1 000 clubs.
4. Renommage du service worker et de la coquille web en un lot dédié.
5. Mise à jour de `production-operations.md` et de `SECURITY_RPC_MATRIX.md`.

**Il faut une action de votre part :**

1. **Avant de fusionner** : savoir que chaque fusion sur `main` lance la
   publication automatique (sauvegarde, migrations, mise en ligne).
2. Décider du dépôt public et de son historique avant l'ouverture commerciale.
3. Décider de la règle de création de club (validation, paiement) et de
   l'application automatique de l'abonnement.
4. Autoriser l'écriture sur le club de test pour rejouer 3 saisons (après le
   19/11 à 00 h 17 UTC).
5. Recette à la main sur téléphone : installation PWA, notification reçue,
   e-mail, écran étroit, mode sombre.
6. Relever la machine Supabase si la charge réelle approche quelques centaines
   de clubs, et lire les limites Realtime du forfait.
