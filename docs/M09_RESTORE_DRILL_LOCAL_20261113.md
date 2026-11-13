# M09 — Exercice de restauration de données et fichiers (isolé)

## Objectif

Une sauvegarde n'est utile que si sa restauration est vérifiée. Ce test
exécute, dans une instance **Supabase CLI locale et jetable**, les opérations :

1. Créer deux lignes PostgreSQL fictives et deux images PNG sans donnée réelle,
   dans le bucket privé `profile-photos`.
2. Exporter les lignes du schéma jetable `qa_restore` au format PostgreSQL COPY
   et récupérer les **octets binaires** des deux images via l'API Storage.
3. Produire une archive chiffrée AES-256 avec une phrase secrète aléatoire
   créée pour l'exécution ; ne rien envoyer vers un dépôt public.
4. Supprimer les deux fichiers et le schéma `qa_restore` pour constater
   leur disparition.
5. Déchiffrer, restaurer les deux lignes et réimporter les deux images ;
   vérifier le nombre de lignes et les empreintes SHA-256, octet pour octet.

Code : `tool/qa/local_restore_drill.py`
CI : `.github/workflows/local_restore_drill.yml`
Tests sans réseau : `tool/qa/test_local_restore_safety.py`

## Portée et limite critique

**Ce n'est pas encore la preuve d'une restauration complète de production.**
Le script couvre un schéma synthétique et deux fichiers fictifs, pas l'ensemble
de `auth`, `public`, `private`, les extensions et les objets Storage d'une
sauvegarde commerciale. Il ne teste pas non plus une restauration Supabase
Pro sur une autre infrastructure.

La sauvegarde de production actuelle
`.github/workflows/production_backup.yml` exporte PostgreSQL mais **pas
les octets des objets Storage**. Un vrai plan de reprise reste donc
**à compléter** : copie chiffrée des objets, index/manifest SHA-256, destination
de conservation privée, restauration séparée des API Storage, test de
correspondance métadonnées/objets et preuve de restauration depuis une
sauvegarde de production. Le dépôt GitHub est public ; aucun fichier réel
ne doit être publié en clair.

Conserver un feu rouge lancement client tant que ce plan n'est pas réellement
implémenté et éprouvé. L'exercice ne modifie ni Supabase commercial ni AS Grinta.
