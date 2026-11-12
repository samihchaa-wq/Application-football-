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

- Schéma `install_tmp` supprimé par migration (plus besoin de l'éditeur SQL).
- Fonction héritée qui écartait une personne réelle d'AS Grinta, par son nom,
  des statistiques : neutralisée.
- Noms et prénoms réels de joueurs d'AS Grinta retirés des tests et d'un
  commentaire du code (remplacés par des noms fictifs).

## Reste à faire (action de Samih)

Par ordre d'importance :

1. **Passer le dépôt en privé.** L'historique Git contient encore les noms de
   joueurs réels d'AS Grinta (anciennes migrations, non modifiables) et
   l'adresse e-mail personnelle de Samih (auteur des commits). Les
   sauvegardes hebdomadaires seraient aussi déposées dans ce dépôt.
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
   (phrase longue, gardée hors de GitHub) puis tester une restauration.

## Non testé

- Test réel avec deux clubs et de vrais comptes sur la base en ligne (base
  vide pour l'instant) : à faire au premier club test.
- Réglages d'authentification Supabase : non lisibles depuis cette session.
- Résistance à une vraie charge : seule la charge locale (200 clubs) a été
  mesurée ; la base en ligne est la plus petite taille, suffisante pour
  quelques clubs.
