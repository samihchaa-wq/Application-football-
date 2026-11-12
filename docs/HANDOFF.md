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
  - Constat M04 du 12/11 : **8 Edge Functions sont ACTIVE** dans l'API Supabase ;
    cela ne prouve **ni leurs secrets ni leur fonctionnement réel**. Les
    réglages Auth/e-mail, le compte éditeur et les secrets opérationnels
    restent **à vérifier**, sans les divulguer.
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

## Mission 04 — sécurité et résilience (audit en lecture seule, 12/11/2026)

Rapport et registre : [`docs/M04_SECURITE_RESILIENCE_20261112.md`](M04_SECURITE_RESILIENCE_20261112.md), dans la PR de la mission 04.

**Constaté :** RLS active sur 59 tables `public` et 24 `private`, dix vues
`security_invoker`, aucune RPC applicative exécutable par `anon` dans
`public`/`private`. Linter : 157 avertissements SECURITY DEFINER en
`public` (à examiner individuellement), et un pour `install_tmp.apply`.
Le projet Supabase commercial est sain mais vide (aucun club réel testé).
12 cron actifs ; les exécutions présentes dans l'historique consulté ont réussi.

**Corrections à préparer (fil 02, aucune migration exécutée) :**
- M04-01 : journal `admin_recent_client_incidents` global non filtré par club.
- M04-02 : `private.is_admin()` n'intègre pas l'état suspendu du club ;
  plusieurs RPC de réglage restent potentiellement accessibles.
- M04-08 : tests de cloisonnement des appels `service_role`.

**À valider (fil 03) :** comptes fictifs clubs A et B, permissions, suspension,
Storage, RPC/Edge, invitations, notifications, charge, backup + restauration.

**À traiter (fil 09 et fil 00) :** sauvegardes des objets Storage absentes des
exports SQL, surveillance d'usage commerciale désactivée, secret et alerte
de monitoring non vérifiés, choix d'hébergement compatible SaaS, dépôt public
à inventorier avec le fil 07 avant la vente.

**Décision M04 : NO-GO pour les premiers clubs réels** à cette étape.
Aucun test intrusif ni écriture, aucun déploiement et aucun coût engagé.
Les migrations, tests A/B en base commerciale, dépôts privés et services
externes exigent les autorisations du propriétaire. Voir aussi la PR #29 de
pilotage (`docs/CHANTIER.md`, encore non fusionnée à cette date).
