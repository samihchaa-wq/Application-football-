# Audit sécurité et stabilité — 12/11/2026

Base contrôlée : projet Supabase commercial `jvxkhgdopslctpcjrhzw` (lecture
seule, base vide : 0 club, 0 compte). Dépôt : `Application-football-`.

## Ce qui a été vérifié et tient

- **Cloisonnement entre clubs** : toutes les tables métier ont une règle
  restrictive `club_isolation` ; les fonctions serveur appartiennent au rôle
  `club_scope`, qui ne contourne pas ces règles. Seules 6 fonctions gardent
  les pleins droits, toutes contrôlées (club de l'utilisateur, éditeur).
- **Visiteur non connecté** : aucun accès en lecture ou écriture aux tables,
  aucune fonction appelable.
- **Vues statistiques** : toutes en mode `security_invoker` (elles respectent
  le cloisonnement).
- **Fichiers** : photos de profil privées ; règle restrictive par club et
  quota par club. Logos et images de badges sont publics par lien (voulu :
  affichage sans connexion), limités en taille et en type d'image.
- **Fonctions Edge** : celles ouvertes sans connexion vérifient un jeton
  (envoi de notifications : jeton interne comparé à temps constant ;
  agenda : jeton UUID par abonné), ou limitent les essais (inscription :
  5/heure et 15/jour par adresse ; e-mails : limite dédiée). Les fonctions
  qui utilisent la clé de service bornent chaque requête au club de l'appelant.
- **Secrets** : aucun secret (clé de service, mot de passe de base, jeton)
  trouvé dans l'historique Git. Coffre Supabase complet (4 secrets).
- **Tâches planifiées** : 13 tâches, aucune en échec sur 2 h, toutes < 0,05 s.
- **Workflows GitHub** : droits en lecture seule, actions épinglées,
  aucun déclenchement par des PR externes avec accès aux secrets.

## Corrigé dans cette PR

- Schéma `install_tmp` supprimé par migration (`20261112210000`), objet par
  objet, sans `CASCADE`. Inventaire des dépendances, comparaison des
  empreintes avec les fichiers du dépôt et essai sur base locale isolée dans
  l'en-tête de la migration.
- Noms de famille réels de joueurs d'AS Grinta remplacés par des noms fictifs
  dans les tests Dart, deux tests SQL et un commentaire du code.
  **Cela ne purge pas l'historique Git public** : les anciens commits gardent
  ces noms.

## Laissé volontairement en l'état

- `private.is_known_non_player_archive_name` écarte encore des archives une
  personne de l'ancien club, désignée par son nom (et son test pgTAP garde ce
  nom). Changer cette règle métier relève du fil d'adaptation multiclub :
  il faut un critère par club (rôle « staff »), pas un nom écrit en dur.
- Les 157 fonctions `SECURITY DEFINER` appelables par un utilisateur connecté
  signalées par Supabase ne sont pas 157 failles : elles appartiennent à
  `club_scope` et restent soumises au cloisonnement. Une matrice fonction par
  fonction existe dans `supabase/SECURITY_RPC_MATRIX.md` ; elle n'a pas été
  revérifiée une à une ici.

## Reste à faire (action de Samih)

Par ordre d'importance :

1. **Dépôt public (décision du 12/11 : il reste public).** Conséquences et
   limites : l'historique Git garde les noms de joueurs réels d'AS Grinta
   (anciens commits et anciennes migrations, non modifiables) et l'adresse
   e-mail de l'auteur des commits. Remédiations sans réécriture d'historique :
   continuer à assainir les fichiers courants, ne plus citer de noms réels
   dans les PR et commentaires publics, utiliser l'adresse « noreply » de
   GitHub pour les prochains commits. Une purge de l'historique demanderait
   une réécriture, à décider séparément. Les sauvegardes hebdomadaires
   (artefacts téléchargeables par tout compte GitHub) restent chiffrées :
   la phrase secrète doit être longue.
2. **Jeton `SUPABASE_ACCESS_TOKEN`** : il donne accès à *tous* les projets
   Supabase du compte, AS Grinta compris. Le recréer avec une date
   d'expiration courte, ou le révoquer entre deux mises en route.
3. **Double authentification** sur GitHub et Supabase (le vrai point d'entrée
   d'un pirate est le compte de l'administrateur).
4. **Réglages Auth Supabase** : désactiver « Allow new users to sign up »
   (l'appli crée les comptes elle-même) ; renseigner Site URL / Redirect URLs ;
   brancher un service d'e-mail (SMTP).
5. **Garder le plafond de dépenses** (Spend cap) activé dans l'organisation Pro.
6. **Sauvegardes** : ajouter `PRODUCTION_DB_URL` et `BACKUP_PASSPHRASE`
   (au moins 32 caractères, gardée hors de GitHub ; le workflow refuse
   désormais une phrase plus courte) puis tester une restauration.
7. **Protections GitHub gratuites pour un dépôt public** (Settings › Code
   security) : activer *Secret scanning* et *Push protection* (bloque un envoi
   qui contiendrait une clé secrète), et *Dependabot alerts* (alerte sur une
   bibliothèque vulnérable, sans ouvrir de PR automatiques).
8. **Adresse e-mail des commits** : dans GitHub › Settings › Emails, cocher
   « Keep my email addresses private » pour que les prochains commits
   n'exposent plus l'adresse personnelle.

## Requêtes de contrôle (12/11/2026, lecture seule, base vide)

- Tables `public`/`storage` sans RLS : aucune (`pg_class.relrowsecurity`).
- Droits du rôle `anon` sur les tables et fonctions de `public` : aucun
  (`information_schema.role_table_grants`, `has_function_privilege`).
- Fonctions `SECURITY DEFINER` exécutables par `authenticated` et non
  possédées par `club_scope` : 6 (`current_club_id`, `is_platform_operator`,
  `get_my_club_access`, `platform_health`, `platform_list_clubs`,
  `platform_update_club`), corps relus.
- Table `public` sans règle `club_isolation` : seulement `clubs`, filtrée sur
  le club de l'utilisateur.
- Historique Git : recherche par motifs (JWT, `sb_secret_`, `sbp_`, URL
  Postgres avec mot de passe, clé privée, `ghp_`, `sk_live_`) : seule l'URL
  de la base locale de développement (`postgres:postgres@127.0.0.1`).
- `cron.job_run_details` sur 2 h : 13 tâches, 0 échec.

## Non testé

- Test réel avec deux clubs et de vrais comptes sur la base en ligne (base
  vide pour l'instant) : à faire au premier club test.
- Réglages d'authentification Supabase : non lisibles depuis cette session.
- Résistance à une vraie charge : seule la charge locale (200 clubs) a été
  mesurée ; la base en ligne est la plus petite taille, suffisante pour
  quelques clubs.
