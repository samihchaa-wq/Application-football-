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
  - Migrations appliquées jusqu'à `20261112040000_notifications_nom_du_club`
    (enregistrées dans `supabase_migrations.schema_migrations`). Base vide :
    aucun club, aucun utilisateur.
  - Schéma `install_tmp` restant (inaccessible à l'appli) : à supprimer depuis
    l'éditeur SQL Supabase, `drop schema install_tmp cascade;`.
  - Pas encore faits sur cette base : fonctions serveur (Edge Functions),
    secrets (VAPID, `push_internal_token` dans Vault, `PUBLIC_APP_URL`,
    `USERNAME_DOMAIN`), réglages d'authentification (URL du site, e-mails),
    compte éditeur (`private.platform_operators`).
- **PR fusionnées** : #1 à #22 (socle multiclub, réglages, sécurité de
  publication).
- **PR #23** : nom du club dans les notifications au lieu de « AS Grinta »,
  lien d'agenda, nom du fichier du bilan.
- **Prochaine PR** (branche `claude/project-thread-q37eby`) : blocage serveur
  du mode live désactivé, `config/production.json` relié à la base
  commerciale, ce document.
- Déploiement GitHub Pages **désactivé** (`.github/workflows-disabled/`).

## Reste à faire, par priorité

### Bloquant pour un club test
1-2. Fonctions serveur, secrets du coffre (`project_url`,
   `push_internal_token`, clés VAPID générées automatiquement) et migrations
   en attente : workflow GitHub **« Supabase commercial : mise en route »**
   (`.github/workflows/commercial_supabase_setup.yml`, lancement manuel).
   Prérequis côté Samih : secret GitHub `SUPABASE_ACCESS_TOKEN` (Supabase >
   Account > Access Tokens). Les assistants ne peuvent pas écrire de secret
   eux-mêmes. Le workflow refuse tout autre projet que la base commerciale.
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
10. Textes légaux : les 5 textes sont rédigés (fil « Blinder l'appli
    juridiquement », `docs/legal/README.md`). Reste : SIRET et coordonnées,
    relecture par un juriste, licence de la vidéo du stade, écran de
    nouvelle acceptation après changement de version.
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
