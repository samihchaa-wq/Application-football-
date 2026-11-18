# Petit Filet

Application de gestion d’un club de football à 11, utilisable par plusieurs
clubs sur la même plate-forme : organisation des matchs, effectif,
composition d’équipe, match en direct, statistiques et vie du club. Chaque club
a son identité (nom, couleurs, maillots, réglages) et ses données, strictement
séparées de celles des autres. Les pronostics entre membres restent une
fonctionnalité complémentaire.

C’est une PWA (application web installable sur le téléphone) écrite en
Flutter, avec Supabase comme source de vérité pour toutes les données.

> **Origine.** Le code est issu de l’application d’un club (AS Grinta), rendue
> multi-clubs. Certains noms techniques en gardent la trace : colonnes SQL
> `…_as_grinta` (le score de l’équipe du club), valeurs `as_grinta` échangées
> avec le serveur, identifiants JavaScript `asGrinta…` du service worker. Ils
> font partie du contrat avec la base déjà en ligne et ne se renomment pas sans
> migration dédiée ; dans le code Dart, l’équipe du club se dit `own…`.

## Ce que fait l’application

### Avant le match

- Calendrier de la saison, saisons archivées consultables en lecture seule,
  abonnement depuis son agenda (Apple, Google, Outlook), mis à jour tout seul.
- Disponibilités des joueurs, et indisponibilités déclarées à l’avance sur une
  période.
- Convocations, liste d’attente avec rotation, invités de match sans compte.
- Météo du prochain match.

### Composition

- Éditeur tactique : dispositifs, placement des joueurs, banc.
- Simulation d’un onze cohérent à partir des postes réellement occupés par
  chaque joueur au fil des saisons, avec rotation des remplaçants.

### Jour de match

- Live : chronomètre, buts et passes décisives, remplacements, composition
  réelle.
- Compte rendu validé en fin de match, qui alimente la fiche du match et les
  statistiques.

### Après le match

- Vote anonyme de l’Homme du match, clos 24 heures après le coup d’envoi.
- Statistiques individuelles et collectives, saison par saison et toutes
  saisons confondues.
- Badges automatiques et manuels, armoire à trophées, bilan de saison animé.

### Pour tout le club

- Pronostics de score et classement entre membres.
- Notifications sur le téléphone : ouverture des disponibilités, convocation,
  liste d’attente, rappels, vote de l’Homme du match.
- Comptes validés par un administrateur ; deux niveaux d’accès (Utilisateur et
  Admin), le coach pilotant le Live de sa saison.
- Mode « Voir l’app comme un joueur » pour les administrateurs.

Le fonctionnement détaillé de chaque module est décrit dans
`docs/regles-metier.md`.

## Architecture

- Application : Flutter (version web/PWA), Riverpod, `go_router`.
- Serveur : Supabase — PostgreSQL avec règles d’accès ligne par ligne (RLS),
  Auth, Storage et Realtime. Chaque club est isolé par `club_id` ; les
  fonctions serveur s’exécutent sous un rôle sans contournement des règles
  d’accès (`club_scope`).
- Edge Functions (TypeScript, Deno) : inscription, notifications Web Push,
  flux d’agenda, e-mails de compte, rappels.
- Tâches planifiées : `pg_cron`, une passe par club et par minute pour les
  rappels, la clôture des votes et les bilans de saison.
- Hébergement : Cloudflare Pages pour l’application commerciale (publiée par
  `auto_release_commercial.yml` après contrôles, ou à la main) ; GitHub Pages
  pour le site de test à clubs fictifs (publication manuelle).

### Organisation du dépôt

```text
lib/
  app/        routeur et navigation principale
  core/       briques partagées : thème, composants `Pf…` (barre, chargement,
              états vides…), réseau, journalisation, notifications push
  features/   une fonctionnalité par dossier, en trois couches :
              data (accès aux données), domain (règles), presentation (écrans)
test/         même arborescence que lib/, plus :
  architecture/  règles vérifiées sur l’ensemble du code
  web/           page d’accueil PWA et service worker
supabase/     migrations SQL, Edge Functions, tests de la base (pgTAP)
web/          coquille de la PWA, service worker, page d’abonnement agenda
tool/         scripts de maintenance et de contrôle
docs/         documentation (voir plus bas)
config/       valeurs publiques de configuration de production
```

## Qualité et fiabilité

Chaque modification passe par une pull request et des contrôles automatiques :

- formatage, analyse statique stricte (aucun avertissement toléré), plus de
  1 300 tests Flutter, plancher de couverture de tests, build web et budget
  de poids de l’application ;
- base de test installée dans un environnement isolé (jamais la production),
  environ 180 fichiers de tests pgTAP (règles métier, cloisonnement entre clubs
  et droits d’accès) et lint SQL ;
- test de charge sur base éphémère (200 clubs, 6 000 comptes, 50 connexions
  simultanées) : lectures, saisies de score simultanées, durée des tâches
  planifiées, absence de fuite entre clubs ;
- garde-fous sur la production : écart de migrations contrôlé avant chaque
  publication, surveillance horaire des tâches planifiées ;
- sauvegarde chiffrée hebdomadaire de la base et des fichiers ;
- actions GitHub épinglées par empreinte et contrôle des avis de sécurité Pub ;
- références d’incident affichées à l’utilisateur et journalisées sans le
  contenu sensible de l’erreur.

## Démarrer en local

Les valeurs clientes publiques de production sont centralisées dans
`config/production.json`.

```bash
flutter pub get --enforce-lockfile
flutter run \
  --dart-define-from-file=config/production.json \
  --dart-define=APP_VERSION=dev
```

Contrôles à lancer avant de proposer un changement :

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-warnings --fatal-infos
flutter test
```

## Travailler sur le projet

### Attention : la fusion publie

Chaque fusion sur `main` déclenche `.github/workflows/auto_release_commercial.yml`
qui, après contrôles, peut sauvegarder la base commerciale, appliquer les
migrations en attente et publier l’application. Une fusion n’est donc jamais
un acte neutre, même pour une modification documentaire (hors `docs/` et
`*.md`, exclus du déclencheur).

### Source de vérité

Le fonctionnement réel de la production prévaut sur la documentation et sur
les anciennes migrations. Les migrations Supabase déjà appliquées restent dans
le dépôt comme historique immuable : elles peuvent décrire d’anciennes règles
qui ne sont plus actives. Les règles de travail détaillées (agents compris)
sont dans `AGENTS.md`.

### Qualité attendue

Les changements applicatifs importants doivent passer au minimum : formatage
Dart, `flutter analyze`, tests Flutter, build web, contrôles Supabase/RLS
concernés, tests runtime applicables. Un contrôle vert n’est pas une raison
pour ignorer un écart observé directement en production.

## Documentation

Références à maintenir à jour :

- `docs/regles-metier.md` — fonctionnement détaillé de chaque module ;
- `docs/NOTIFICATIONS_V2.md` — contrat des notifications ;
- `docs/MATCH_WEATHER.md` — météo du prochain match ;
- `docs/business-security-matrix.md` — invariants de sécurité métier ;
- `docs/privacy-and-retention.md` — données personnelles et conservation ;
- `docs/database-release-process.md` — livraison Supabase et migrations ;
- `docs/dependency-upgrade-plan.md` — politique de mise à jour Pub ;
- `docs/production-operations.md`, `docs/exploitation.md` — exploitation ;
- `docs/observability.md` — références d’incident ;
- `docs/repository-protection.md` — protections GitHub ;
- `docs/ui-foundations.md` — fondations UI.

Pilotage et lancement : `docs/HANDOFF.md`, `docs/CHANTIER.md`,
`docs/COMMERCIAL_LAUNCH_CHECKLIST.md`, `docs/MISE_EN_LIGNE.md`.

`docs/changes/` rassemble les notes de décision et de correctif rédigées au
fil des évolutions marquantes ; `CHANGELOG.md` retrace les versions. Les
rapports d’audit et de recette datés (`docs/missions/`, `docs/recette/`,
`docs/qa_saison_*`, `docs/AUDIT_*`) sont des photographies à une date donnée,
pas des références : vérifier les faits sur GitHub et Supabase.
