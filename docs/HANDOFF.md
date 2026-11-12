# Relais entre assistants (Claude ↔ ChatGPT)

Mis à jour le 12/11/2026. À relire **en entier** avant toute action, et à
mettre à jour à chaque étape importante.

## Règles absolues

1. Ne **jamais** toucher AS Grinta ni Carte soirée : ni leurs dépôts, ni leurs
   bases Supabase (`ovzijmqrnsgcmryinkfa`, `yqfewxadpyulgxehhpcu`), ni leur site.
   Tout le travail se fait dans `samihchaa-wq/Application-football-`.
2. Annoncer tout coût à Samih **avant** d'agir (création de projet, option
   payante, service tiers).
3. Aucune migration ou écriture sur la base commerciale sans accord de Samih.
   Ne jamais exécuter `supabase/seed.sql` sur la base en ligne.
4. Migrations déjà appliquées = immuables : toute correction passe par une
   nouvelle migration datée.
5. Samih n'est pas développeur : réponses en français, simples, concises ;
   dire ce qui n'est pas testé.
6. Fusionner une PR seulement quand tous les contrôles GitHub sont verts.

## État actuel

- **Base commerciale** : projet Supabase `application-football`, ref
  `jvxkhgdopslctpcjrhzw`, organisation Pro, région Paris (eu-west-3).
  Coût : inclus dans l'abonnement Pro (~25 $/mois), aucun supplément tant que
  c'est le seul projet de l'organisation.
  - Migrations appliquées jusqu'à `20261112050000_blocage_serveur_mode_live`
    (enregistrées dans `supabase_migrations.schema_migrations`). Lecture seule du 12/11 :
    0 club, 0 profil, 0 match, 0 utilisateur Auth, 0 abonnement.
  - Schéma `install_tmp` restant (inaccessible à l'appli) : à supprimer depuis
    l'éditeur SQL Supabase, `drop schema install_tmp cascade;`.
  - Huit Edge Functions sont **déployées et ACTIVE** selon Supabase au 12/11 :
    `account-email`, `calendar-feed`, `claim-account`, `claim-club`,
    `manage-user`, `register-account`, `send-prediction-reminders`, `send-push`.
    **Secrets VAPID/Push, Auth, e-mails, cron, URL publique, compte éditeur et
    réussite en production non vérifiés** ; ACTIVE ne vaut pas test fonctionnel.
- **PR fusionnées** : #1 à #22 (socle multiclub, réglages, sécurité de
  publication).
- **PR #23** : nom du club dans les notifications au lieu de « AS Grinta »,
  lien d'agenda, nom du fichier du bilan.
- **PR #25 ouverte** (branche `claude/project-thread-isgvly`) : audit
  fonctionnel documentaire enrichi (164 entrées) et cahier des charges fil 02.
  Les documents de cette PR ne sont pas intégrés à `main` avant fusion.
- Le blocage serveur du mode live apparaît dans la migration commerciale
  `20261112050000`, enregistrée dans Supabase. Vérifier séparément les PR
  concurrentes avant toute adaptation.
- Déploiement GitHub Pages **désactivé** (`.github/workflows-disabled/`).

## Mission 01 — audit en cours de validation documentaire (12/11/2026)

- **Annexe des parcours** : `docs/AUDIT_ROUTES_ET_PARAMETRES.md`
  (**41 entrées de routes et redirections**, 7 interrupteurs de modules,
  8 règles configurables avec valeurs/bornes, matrice des commandes visibles).
  Inventaire statique : la vérification bouton par bouton et API reste fil 03.
- **PR #25** : `docs/AUDIT_FONCTIONNALITES.md` (analyse initiale),
  `docs/AUDIT_FONCTIONNALITES_DETAILLE.md` (**164 fonctions, classification,
  état de preuve, risques, priorité**) et `docs/CAHIER_DES_CHARGES_FIL_02.md`
  (**30 tâches d'adaptation, critères d'acceptation et coordination inter-fils**).
- Vérifications réalisées sans écriture : lecture des deux dépôts GitHub,
  inspection de la base commerciale (19 migrations, 8 Edge Functions,
  59 tables public et 24 tables private avec RLS, 3 buckets),
  cinq compteurs métier à zéro. **Aucun test E2E, Flutter, SQL en exécution
  ou notification réelle n'a été effectué par ce fil.**
- 157 fonctions SECURITY DEFINER du schéma `public` exécutables par
  `authenticated` (nombre de fonctions, non de vulnérabilités). Advisors
  Supabase signalent notamment les catégories
  `function_search_path_mutable` et
  `authenticated_security_definer_function_executable`. **Fil 04** :
  vérifier les autorisations internes de chaque RPC, RLS/Storage/Realtime
  et prouver l'absence de lecture croisée entre clubs.
- **Fil 02** : commencer par recaler l'état des PR/branches parallèles,
  puis suivre le cahier des charges. Ne pas prendre l'inventaire documentaire
  pour un feu vert de déploiement.
- Aucun fichier d'AS Grinta, aucune donnée Supabase, aucun code applicatif
  ni migration n'a été modifié par la mission 01. Cette PR reste à relire
  avant fusion (contrôles verts exigés).

## Coordination fil 00 — PR #29 (12/11/2026)

- Le fil **00** est chef de projet des neuf missions ; son tableau de pilotage
  est `docs/CHANTIER.md` dans la **PR #29** (branche
  `pilotage/tableau-chantier-20261112`, **non fusionnée** à cette date).
  Il n'existe donc pas encore dans `main` : le lire depuis cette branche.
- Le fil **01** livre dans la **PR #25** : audit initial
  `docs/AUDIT_FONCTIONNALITES.md`, inventaire approfondi
  `docs/AUDIT_FONCTIONNALITES_DETAILLE.md` (164 éléments) et
  `docs/CAHIER_DES_CHARGES_FIL_02.md` (30 lots et critères).
- **État du fil 01 : documentation produite, conformité documentaire à relire,
  vérification technique partielle ; tests E2E non exécutés, validation
  utilisateur non obtenue.** Aucune modification de l'application, de ses
  données ou de l'original.
- **Dépendances explicites** : fil 02 reprend F2-00 à F2-29 avec critères ;
  fil 03 utilise la matrice T01-T18 ; fil 04 audite les droits SQL/RLS,
  Storage, Edge et les 157 RPC privilegiées ; fil 05 tranche identité,
  maillots, libellés ; fil 06 tarification ; fil 07 légalité et médias ;
  fil 08 pilote après feu vert ; fil 09 supervise et restaure.
- **Décisions réservées au propriétaire** : identifiant multiclub, date de
  prise en charge du foot à 5/7/8, appellation du vote et personnalisation
  des maillots, prix/paiement, ouverture réelle du pilote et toute écriture
  dans la base commerciale.
- **Vigilance PR concurrentes** : #24 propose la réactivation Pages,
  #26 rassemble QA, #29 centralise pilotage. Ne pas interpréter leur
  ouverture comme une fusion ou une mise en production.
- Un commentaire de transmission est publié sur la PR #29 à destination
  du fil 00. Ne pas écraser le tableau `docs/CHANTIER.md` depuis cette
  branche du fil 01 : sa mise à jour revient au fil 00.

## Coordination avec fil 00 (PR #29) — état de Mission 01

- **Chef de projet : fil 00**, [tableau `docs/CHANTIER.md` proposé dans la PR #29](https://github.com/samihchaa-wq/Application-football-/pull/29). La PR #29 est **brouillon, non fusionnée** à la lecture du 12/11 ; le suivi est fait via commentaires PR et ces documents, **pas par un travail automatique des fils**.
- **Annexe supplémentaire :** `docs/AUDIT_ROUTES_ET_PARAMETRES.md` recense **41 routes/redirections**, commandes principales, **7 modules** et **8 règles numériques** ; vérification comportementale à confier au fil 03.
- **Livrables fil 01, PR #25 :** `docs/AUDIT_FONCTIONNALITES.md` est l'index de synthèse ; le **référentiel unique de 164 unités** et des 5 classes est `docs/AUDIT_FONCTIONNALITES_DETAILLE.md` ; le **cahier des charges de 30 tickets F2-00…F2-29** est `docs/CAHIER_DES_CHARGES_FIL_02.md`. Ne pas créer de tableau parallèle avec des identifiants concurrents.
- **Corrections d'audit vérifiées par code :** aucun type `coupe` dans le formulaire/modèle actuel ; clips individuels transparents non démontrés comme importables, à distinguer de la présentation animée existante ; les maillots sont trois options fixes ; l'original possède une migration de réglages quota/adresse domicile **non portée telle quelle** au commercial.
- **État :** documentation rédigée sur branche PR #25, revue/acceptation et tests applicatifs réels **non faits**. Requêtes Supabase de lecture seule, aucun nouveau club, aucune migration, aucun utilisateur et aucune suppression. Ne pas présenter `DEP` ou `ACTIVE` comme `E2E vert`.
- **Décisions requises :** DEC-01 une équipe ou plusieurs ; DEC-02 formats 11/8/7/5 ; DEC-03 identité de connexion et homonymies ; DEC-04 types de maillots ; DEC-05 vocabulaire du vote et badges ; DEC-06 clips joueurs ; DEC-07 tarif/paiement ; DEC-08 marque et licences de médias. Voir l'audit détaillé ; le propriétaire tranchera, pas le fil 01.
- **Transmissions :** fil 02 reçoit les tickets et critères ; fil 03 les scénarios de vérification ; fil 04 le contrôle interclub, les 157 fonctions priviligiées et Storage ; fils 05/07 identité + licences ; 06 tarif ; 08 pilotes ; 09 secrets, monitoring, sauvegardes. Le fil 00 arbitre les dépendances et confirme les contrôles avant fusion.

## Reste à faire, par priorité

### Bloquant pour un club test
1-2. Huit Edge Functions et 19 migrations existent déjà sur la base commerciale.
   **Ne pas relancer aveuglément** le workflow « Supabase commercial : mise
   en route » (`.github/workflows/commercial_supabase_setup.yml`) ; d'abord
   vérifier secrets, Vault, VAPID, `PUBLIC_APP_URL`, `USERNAME_DOMAIN`, cron,
   idempotence et état de chaque endpoint. Aucun secret ne doit être affiché.
   Le workflow refuse tout autre projet que la base commerciale.
3. Réglages Auth dans Supabase (action de Samih dans le tableau de bord) :
   URL du site `https://samihchaa-wq.github.io/Application-football-/`, URLs
   de redirection, service d'envoi d'e-mails.
4. Tester deux clubs fictifs A et B sur la vraie base : aucune fuite de
   données, inscriptions, admins, fichiers, notifications
   (`docs/COMMERCIAL_LAUNCH_CHECKLIST.md`, section 2).
5. Réactiver le déploiement Pages seulement après ces tests.

### À corriger, non bloquant
6. Fuseau horaire par club : « Europe/Paris » est écrit en dur (~50 endroits
   SQL, 3 fichiers Dart/fonctions). Sans effet pour la France métropolitaine,
   Belgique, Suisse, Luxembourg. À faire seulement pour un club hors de ce
   fuseau (DOM-TOM, étranger).
7. Nom définitif du produit (provisoire : « Club », `ClubIdentity.appName`).

### Bloquant pour faire payer (décisions de Samih)
8. Paiement : Stripe non intégré.
9. Prix : 10 €/joueur/an dans le code, non validé.
10. Textes légaux : SIRET et coordonnées à compléter
    (`lib/features/legal/domain/legal_documents.dart`).
11. Passer le dépôt en privé (l'historique contient d'anciennes données
    AS Grinta).
12. Secrets GitHub `PRODUCTION_DB_URL` et `BACKUP_PASSPHRASE` pour la
    surveillance et la sauvegarde hebdomadaire.

## Contrôles avant fusion

```bash
python3 -m unittest discover -s tool/tests -p 'test_commercial_*.py' -v
python3 tool/check_commercial_deploy.py
flutter analyze --fatal-warnings --fatal-infos   # Flutter 3.47.9
flutter test
```
Tests base de données : workflow GitHub « Supabase business and RLS tests ».
