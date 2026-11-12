# Préparer la première publication commerciale

**État au 12 novembre 2026 — ne pas réactiver le déploiement sans suivre cette liste.**

Le dépôt \`Application-football-\` est la version multiclub d'AS Grinta. Les deux produits
doivent rester **totalement séparés** : aucun client commercial ne se connecte
à la base de l'ancien club, aucun déploiement ne vise l'URL d'AS Grinta.

## Ce qui existe déjà

- Socle Supabase SQL neuf, 17 migrations dans \`supabase/migrations/\`.
- Clubs, codes d'invitation, administrateurs, règles et modules par club.
- Cloisonnement SQL et Storage à tester en environnement réel, Edge Functions.
- Logo et couleurs personnalisés ; système d'essai de 30 jours.
- Tests Flutter/Supabase et charge locale sur plusieurs centaines de clubs.
- Aucune base Supabase commerciale branchée dans \`config/production.json\`.
- Déploiement GitHub Pages **désactivé** dans
  \`.github/workflows-disabled/deploy_pages.yml\`.
- Paiements Stripe **non intégrés** : la gestion d'abonnement est encore manuelle.

Un test local vert n'est pas une validation de production.

## 1. Créer un projet Supabase neuf et isolé

1. Dans l'organisation **Pro commerciale**, créer un projet neuf dans la
   région adaptée à la clientèle (Paris, \`eu-west-3\`, est la région prévue).
2. Ne **jamais** copier les données, comptes, objets Storage ou secrets d'AS
   Grinta. Ne jamais utiliser son URL ou sa clé publique dans ce dépôt.
3. Relier la CLI au **nouveau** projet en vérifiant son identifiant avant
   toute migration. Appliquer et vérifier les migrations sur cette base neuve.
4. Ne jamais exécuter \`supabase/seed.sql\` sur cette base : le seed crée un
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
  \`config/production.json\` : \`SUPABASE_URL\`, \`SUPABASE_ANON_KEY\`,
  \`USERNAME_DOMAIN\`, \`PUBLIC_APP_URL\`.
- Exécuter \`python3 tool/check_commercial_deploy.py\` : le contrôle doit
  **échouer** tant que le projet commercial n'est pas configuré et refuser
  toute connexion aux bases personnelles.
- Le futur workflow Pages exécute \`tool/stamp_commercial_csp.py\` **avant**
  \`flutter build web\` : les origines HTTPS et WebSocket dans le CSP
  deviennent celles du nouveau projet. Ne jamais livrer le placeholder
  \`a-remplacer.supabase.co\`.
- Configurer les secrets d'Edge Functions, l'e-mail transactionnel,
  les clés Web Push, le coffre Vault, l'opérateur de la plate-forme et les
  éventuels fournisseurs OAuth, d'après \`docs/exploitation.md\`.
- Activer les sauvegardes et la surveillance, puis tester une restauration.
  La présence de workflows programmés n'implique pas que leurs secrets
  soient configurés ni que les sauvegardes fonctionnent.

## 4. Avant toute commercialisation

- Renseigner et faire valider les mentions légales / CGU / politique de
  confidentialité : \`lib/features/legal/domain/legal_documents.dart\`
  contient encore des **champs à compléter**.
- Confirmer le modèle économique : le code prépare actuellement un prix
  indicatif de **10 € par joueur et par an**, pas un tarif validé.
- Choisir et intégrer les paiements, ou assumer explicitement un paiement
  hors ligne. Le code Stripe n'est pas opérationnel.
- Choisir le nom définitif du produit ; des noms techniques historiques
  \`as_grinta\` peuvent rester dans les sources sans être visibles, mais les
  libellés montrés aux clubs doivent être neutres.
- Tester en conditions réelles les notifications sur iOS/Android et les
  connexions en direct, l'espace fichiers et la restauration.
- Ne déplacer \`deploy_pages.yml\` dans \`.github/workflows/\` **qu'après**
  les tests, l'identité commerciale, le CSP et les validations juridiques.

## 5. Contrôles avant d'autoriser une PR de déploiement

\`\`\`bash
python3 -m unittest discover -s tool/tests -p 'test_commercial_*.py' -v
python3 tool/check_commercial_deploy.py
flutter pub get --enforce-lockfile
flutter analyze --fatal-warnings --fatal-infos
flutter test
\`\`\`

Les deux premières commandes ont des rôles différents : les tests unitaires
doivent passer **avant** la configuration réelle ; le préflight doit d'abord
échouer sur les placeholders, puis passer une fois la base commerciale
correctement branchée.

**Règle absolue :** aucune opération distante, création d'utilisateur ou
migration ne cible AS Grinta ou Carte soirée.
