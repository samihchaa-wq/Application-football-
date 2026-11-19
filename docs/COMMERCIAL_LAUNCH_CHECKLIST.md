# Préparer la première publication commerciale

**État au 12 novembre 2026 — ne pas réactiver le déploiement sans suivre cette liste.**

Le dépôt `Application-football-` est la version multiclub d'AS Grinta. Les deux produits
doivent rester **totalement séparés** : aucun client commercial ne se connecte
à la base de l'ancien club, aucun déploiement ne vise l'URL d'AS Grinta.

## Ce qui existe déjà

- Socle Supabase SQL neuf, migrations dans `supabase/migrations/`.
- Clubs, codes d'invitation, administrateurs, règles et modules par club.
- Cloisonnement SQL et Storage à tester en environnement réel, Edge Functions.
- Logo et couleurs personnalisés ; système d'essai de 30 jours.
- Tests Flutter/Supabase et charge locale sur plusieurs centaines de clubs.
- Base Supabase commerciale créée le 12/11/2026 : projet `application-football`
  (`jvxkhgdopslctpcjrhzw`), organisation Pro, région Paris. Les migrations
  jusqu'à `20261112040000` y sont appliquées (sans seed) et enregistrées dans
  `supabase_migrations.schema_migrations`. `config/production.json` pointe
  vers elle (URL et clé **publique** uniquement).
- Reste dans cette base un schéma technique `install_tmp` (copie des fichiers
  de migration utilisée pour l'installation), inaccessible à l'application.
  À supprimer depuis l'éditeur SQL : `drop schema install_tmp cascade;`.
- Déploiement GitHub Pages **désactivé** dans
  `.github/workflows-disabled/deploy_pages.yml`.
- Paiements Stripe **non intégrés** : la gestion d'abonnement est encore manuelle.

Un test local vert n'est pas une validation de production.

## 1. Créer un projet Supabase neuf et isolé

1. Dans l'organisation **Pro commerciale**, créer un projet neuf dans la
   région adaptée à la clientèle (Paris, `eu-west-3`, est la région prévue).
2. Ne **jamais** copier les données, comptes, objets Storage ou secrets d'AS
   Grinta. Ne jamais utiliser son URL ou sa clé publique dans ce dépôt.
3. Relier la CLI au **nouveau** projet en vérifiant son identifiant avant
   toute migration. Appliquer et vérifier les migrations sur cette base neuve.
4. Ne jamais exécuter `supabase/seed.sql` sur cette base : le seed crée un
   club fictif destiné aux tests locaux.

## 2. Contrôler la séparation de deux clubs tests

Créer deux clubs A et B avec administrateurs et joueurs distincts. Vérifier :

- Un membre ou admin du club A ne lit/modifie **aucune** donnée du club B,
  même en appelant directement REST et RPC.
- Les profils en attente, comptes supprimés, sessions expirées et clubs
  suspendus ne donnent pas d'accès imprévu.
- Photos, écussons, Web Push, historiques, Realtime, invitations, matchs
  et statistiques restent propres à leur club.
- La création d'un club, l'inscription, la validation d'un membre et la
  récupération d'un compte fonctionnent vraiment sur la nouvelle base.

## 3. Configurer le site et les services

- Renseigner uniquement les paramètres **publics** dans
  `config/production.json` : `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
  `USERNAME_DOMAIN`, `PUBLIC_APP_URL`.
- Exécuter `python3 tool/check_commercial_deploy.py` : le contrôle doit
  **échouer** tant que le projet commercial n'est pas configuré et refuser
  toute connexion aux bases personnelles.
- Le futur workflow Pages exécute `tool/stamp_commercial_csp.py` **avant**
  `flutter build web` : les origines HTTPS et WebSocket dans le CSP
  deviennent celles du nouveau projet. Ne jamais livrer le placeholder
  `a-remplacer.supabase.co`.
- Configurer les secrets d'Edge Functions, l'e-mail transactionnel,
  les clés Web Push, le coffre Vault, l'opérateur de la plate-forme et les
  éventuels fournisseurs OAuth, d'après `docs/exploitation.md`.
- Activer les sauvegardes et la surveillance, puis tester une restauration.
  La présence de workflows programmés n'implique pas que leurs secrets
  soient configurés ni que les sauvegardes fonctionnent.

## 4. Avant toute commercialisation

- Renseigner et faire valider les cinq textes légaux (mentions, CGU,
  confidentialité, conditions d'abonnement, accord sur les données) :
  `lib/features/legal/domain/legal_documents.dart` contient encore des
  **champs à compléter**. Voir `docs/legal/README.md`.
- Modèle économique **décidé le 18/11/2026 : forfait de 79 € par club et
  par an**, quel que soit le nombre de joueurs (migration
  `20261124010000_forfait_annuel_club.sql`, conditions d'abonnement en
  version `2026-11-19`).
- Paiement **hors ligne** retenu le 18/11/2026 (virement, chèque, espèces) :
  l'éditeur note chaque paiement reçu depuis la fiche équipe du poste de
  contrôle, ce qui ouvre une année d'abonnement. Les administrateurs
  reçoivent un e-mail 10 jours avant l'échéance ; un club impayé est suspendu
  **le jour de l'échéance** et rouvert dès qu'un paiement est noté. Ses
  données sont gardées 3 ans, puis effacées automatiquement (tâche de nuit
  `purge-expired-clubs`). Migrations `20261124020000_…`, `20261127000000_…`
  et `20261127020000_poste_controle_editeur.sql`. Le code Stripe
  n'est pas opérationnel. Reste à fournir aux clubs un moyen de contact et
  des coordonnées de paiement (l'appli dit seulement « contacte-nous »).
- Comptes inactifs (migration `20261128000000_suppression_comptes_inactifs.sql`,
  action `inactive-accounts` de la fonction `account-email`) : avertissement
  par e-mail un mois avant les 3 ans sans utilisation, puis suppression.
  Testé sur une base locale ; à déployer, puis vérifier un premier passage
  réel dans les journaux de la fonction. Désactiver le suivi d'ouverture des
  e-mails dans Brevo.
- Choisir le nom définitif du produit ; des noms techniques historiques
  `as_grinta` peuvent rester dans les sources sans être visibles, mais les
  libellés montrés aux clubs doivent être neutres.
- Tester en conditions réelles les notifications sur iOS/Android et les
  connexions en direct, l'espace fichiers et la restauration.
- Ne déplacer `deploy_pages.yml` dans `.github/workflows/` **qu'après**
  les tests, l'identité commerciale, le CSP et les validations juridiques.

## 5. Contrôles avant d'autoriser une PR de déploiement

```bash
python3 -m unittest discover -s tool/tests -p 'test_commercial_*.py' -v
python3 tool/check_commercial_deploy.py
flutter pub get --enforce-lockfile
flutter analyze --fatal-warnings --fatal-infos
flutter test
```

Les deux premières commandes ont des rôles différents : les tests unitaires
doivent passer **avant** la configuration réelle ; le préflight doit d'abord
échouer sur les placeholders, puis passer une fois la base commerciale
correctement branchée.

**Règle absolue :** aucune opération distante, création d'utilisateur ou
migration ne cible AS Grinta ou Carte soirée.
