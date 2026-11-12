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
    (19 migrations, vérifié dans Supabase le 12/11 à 10 h 35 UTC). Base vide
    à la lecture du 12/11 : aucun club, aucun utilisateur.
  - Schéma `install_tmp` restant (inaccessible à l'appli) : à supprimer depuis
    l'éditeur SQL Supabase, `drop schema install_tmp cascade;`.
  - Faits le 12/11 via le workflow « Supabase commercial : mise en route » :
    migrations jusqu'à `20261112050000`, coffre (project_url,
    push_internal_token, clés VAPID), 8 Edge Functions et leurs secrets.
  - Pas encore faits : réglages d'authentification (URL du site, e-mails),
    compte éditeur (`private.platform_operators`).
- **PR fusionnées** : #1 à #22 (socle multiclub, réglages, sécurité de
  publication).
- **PR #23** : nom du club dans les notifications au lieu de « AS Grinta »,
  lien d'agenda, nom du fichier du bilan.
- **PR #24** fusionnée : blocage serveur du mode live, `config/production.json`
  relié à la base commerciale, workflow Pages en publication manuelle.
- **PR #48** fusionnée : liste d'attente en trois modes et saisie de
  l'historique par l'admin.
- **PR #25** (audit fonctionnel, documents seulement) : voir section suivante.
- Déploiement GitHub Pages : workflow réactivé en **publication manuelle uniquement** (PR #24), pour un test à clubs fictifs. Site cible : https://samihchaa-wq.github.io/Application-football-/ — publié seulement après lancement manuel et vérification. GitHub Pages **n'autorise pas** l'hébergement d'un SaaS commercial : un autre hébergeur sera nécessaire avant toute vente.

## Audit fonctionnel (fil 1, PR #25) — 12/11/2026

- Index lisible : `docs/AUDIT_FONCTIONNALITES.md`. Référentiel unique :
  `docs/AUDIT_FONCTIONNALITES_DETAILLE.md` (164 fonctions classées).
  Pages et réglages : `docs/AUDIT_ROUTES_ET_PARAMETRES.md`. Tâches du fil 2 :
  `docs/CAHIER_DES_CHARGES_FIL_02.md` (F2-00 à F2-29). Ne pas créer de
  tableau concurrent.
- Audit fait par **lecture du code** et requêtes Supabase en lecture seule.
  Aucun parcours testé dans l'appli, aucune notification réelle, aucun test
  de cloisonnement entre deux clubs : c'est le rôle des fils 3 et 4.
- Décisions réservées à Samih (DEC-01 à DEC-08) : une équipe ou plusieurs
  par espace ; foot à 11 seul ou aussi 8/7/5 ; identifiants de connexion
  (aujourd'hui uniques sur toute la plateforme, 20 homonymes maximum) ;
  maillots personnalisables ; nom neutre pour « Homme du match » et les
  badges genrés ; clips joueurs ; prix et paiement ; nom et droits des médias.
- Alertes Supabase : 157 fonctions serveur accessibles aux comptes connectés
  (nombre de fonctions, pas des failles prouvées) ; à instruire par le fil 4.

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
