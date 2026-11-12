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
    (enregistrées dans `supabase_migrations.schema_migrations`). Base vide :
    aucun club, aucun utilisateur.
  - Schéma `install_tmp` restant (inaccessible à l'appli) : à supprimer depuis
    l'éditeur SQL Supabase, `drop schema install_tmp cascade;`.
  - État relevé par le fil 9 le 12/11 : 8 Edge Functions actives (déploiement constaté),
    4 entrées Vault comptées sans lire leurs valeurs, 12 tâches cron actives.
    Le fonctionnement des notifications, de l'Auth, du compte éditeur et des
    secrets n'est pas encore validé de bout en bout.
- **PR fusionnées** : #1 à #23 au dernier relevé du fil 9.
- **PR #24** : proposition de réactivation Pages (ouverte au relevé).
- **PR #25** : audit fonctionnel (ouverte au relevé).
- **Pilotage fil 00** : `docs/CHANTIER.md` proposé par la PR #29 (brouillon,
  pas encore sur `main` au relevé du fil 9).
- **Mission 09** : diagnostic et procédures dans
  `docs/MAINTENANCE_SUPPORT_MISSION09.md` (PR #31 en brouillon) ; correctif
  fail-closed des alertes/sauvegardes et tests associés dans la PR #32
  (en brouillon, non activé).
- Déploiement GitHub Pages **désactivé** (`.github/workflows-disabled/`).

## Reste à faire, par priorité

### Bloquant pour un club test
1-2. Mise en route technique **exécutée avec succès** le 12/11 via workflow
   **« Supabase commercial : mise en route »** (run 43134233822) : migrations,
   Vault et déploiement des Edge Functions. Reste à tester leurs comportements
   réels avec deux clubs de démonstration, et à vérifier les paramètres Auth.
   Le workflow reste réservé à la seule base commerciale et ne doit pas être
   relancé avec des opérations d'écriture sans accord explicite.
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
12. **Protection d'exploitation à activer et vérifier** : le run de
    `Production watch` du 12/11 (43133882260) est vert mais son contrôle SQL
    a été **ignoré** car `PRODUCTION_DB_URL` n'était pas disponible.
    Sauvegarde hebdomadaire SQL non validée (`BACKUP_PASSPHRASE` à vérifier),
    aucun test de restauration réalisé. Les fichiers des trois buckets
    Storage ne sont pas inclus dans ce workflow. Voir la Mission 09.

## Contrôles avant fusion

```bash
python3 -m unittest discover -s tool/tests -p 'test_commercial_*.py' -v
python3 tool/check_commercial_deploy.py
flutter analyze --fatal-warnings --fatal-infos   # Flutter 3.47.9
flutter test
```
Tests base de données : workflow GitHub « Supabase business and RLS tests ».
