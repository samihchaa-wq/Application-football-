# M09 — Préparation de la reprise commerciale DB + Storage

**Date d'observation :** 14 novembre 2026. **État : PROPOSITION TECHNIQUE, NON EXÉCUTÉE sur la base commerciale.**  
**Périmètre exclusif :** `samihchaa-wq/Application-football-`, base `jvxkhgdopslctpcjrhzw`. AS Grinta original et ses données sont exclus.

## 1. Risque bloquant retrouvé

- `.github/workflows/production_backup.yml` (ancien) exportait uniquement trois fichiers PostgreSQL et les déposait chiffrés en artefact. Il n'incluait **aucun octet d'image ou autre objet** dans les buckets Supabase Storage.
- Le test local `tool/qa/local_restore_drill.py` est utile, mais effectue une suppression et restauration de **données fictives** et de deux PNG locaux, **pas** de la vraie sauvegarde commerciale.
- Au contrôle initial, la base commerciale contenait **deux clubs** et **quatre entrées `storage.objects`** ; cela ne prouve pas la récupération des quatre fichiers. Le champ `storage.objects` n'est que la métadonnée, pas les octets.
- Migration des maillots `20261120000000_kits_illimites_par_club.sql` présente sur `main` mais **absente** du registre distant et contrainte SQL toujours fixée à trois ensembles.

## 2. Correction préparée par cette PR

Le workflow `production_backup.yml` est renforcé, mais **ne prouve aucune sauvegarde réussie avant exécution réelle** :

1. Refuser toute URL `PRODUCTION_DB_URL` n'identifiant pas strictement le projet commercial Supabase (hôte direct ou session pooler avec utilisateur `postgres.<ref>`), tout accès Supabase absent, et toute phrase de chiffrement de longueur inférieure à 48 caractères ou répétitive.
2. Lire la liste exacte des buckets et des objets `storage.buckets`/`storage.objects` en SELECT. Inclure tous les buckets réellement peuplés, sans liste codée en dur.
3. Exporter `roles.sql`, `schema.sql`, `data.sql` avec la CLI Supabase via une connexion explicite à Petit Filet ; télécharger les octets via la CLI `storage cp` en lecture.
4. Reprendre l'inventaire après la copie et **échouer** si un objet est ajouté, supprimé, ou modifié pendant le transfert ; **échouer** si le répertoire téléchargé contient un objet manquant, supplémentaire, dupliqué ou un lien symbolique.
5. Calculer `SHA-256` et taille de chaque objet, `SHA-256` des trois exports SQL, et enregistrer les identifiants et inventaires uniquement **dans la future archive chiffrée**.
6. Compresser et chiffrer avec GPG AES-256, puis déchiffrer temporairement la copie et vérifier l'archive + le manifeste. Supprimer les fichiers clairs dans un runner éphémère à la sortie de la commande.
7. Conserver uniquement le `.tar.gz.gpg` et son empreinte externe dans un artefact GitHub de durée maximale de 90 jours. Un artefact chiffré dans un dépôt public **n'est pas une destination privée durable**. Un stockage privé externe doit encore être choisi et validé (coût et RGPD) avant le commercial à grande échelle.

**Limite technique :** la comparaison de deux inventaires Storage détecte des changements de ces objets pendant la copie, mais **n'est pas un instantané transactionnel unique** du PostgreSQL + Storage. Pour la restauration de référence, prévoir maintenance/gel d'écritures ou une méthode de snapshots cohérents, selon le niveau de service choisi.

## 3. Tests réalisés et non réalisés

| Contrôle | Source de preuve | Statut |
| --- | --- | --- |
| Contrat Python de la cible commerciale et rejet AS Grinta original | `tool/qa/test_commercial_backup_bundle.py` | **À confirmer CI du SHA exact** |
| Inventaires cohérents, objets manquants/supplémentaires, données modifiées, symlinks et parcours malveillants | Même suite Python | **À confirmer CI du SHA exact** |
| Workflow d'enregistrement et chiffrement (analyse statique) | `tool/tests/test_commercial_production_failclosed.py` | **À confirmer CI du SHA exact** |
| Création réelle d'une archive depuis Petit Filet commercial | Journal d'un workflow `Production backup` avec secret commercial valide, artefact et empreinte | **NON EXÉCUTÉ** |
| Contrôle des octets et du manifeste d'une vraie archive après déchiffrement | Archive réelle vérifiée sur environnement isolé | **NON EXÉCUTÉ** |
| Restauration **complète** de la même archive avec Auth, rôles, RLS, RPC et objets Storage | Rapport d'un exercice de restauration local isolé avec réimport binaire, comptes et tests | **NON EXÉCUTÉ** |
| Compatibilité de la migration des maillots appliquée en production | Séparément, après les sauvegardes/restaurations | **NON EXÉCUTÉ** |
| Version Web déployée et testée | Preuve de publication Cloudflare, SHA et parcours admin/club | **NON EXÉCUTÉ** |

Une CI verte et une archive chiffrée dont la liste des fichiers s'ouvre **ne remplacent pas** l'exercice de restauration.

## 4. Procédure de validation pour lever le NO-GO

**Étape A — Contrats de confidentialité et accès.** Choisir une destination de sauvegarde privée (ou accepter explicitement le risque temporaire d'artefact chiffré public), confirmer le coût éventuel, la conservation, l'accès exclusif à la phrase forte et la rotation des clés. Le workflow refusera de s'exécuter sans `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`, `PRODUCTION_DB_URL`, `BACKUP_PASSPHRASE`. Aucun de ces secrets n'est nécessaire pour les tests unitaires de cette PR. Vérifier que l'URL DB vise **seulement** `jvxkhgdopslctpcjrhzw` ; la valeur ne doit jamais figurer dans un commentaire ou un log.

**Étape B — Sauvegarde réelle.** Après revue et fusion de cette PR si la sécurité est jugée adéquate, lancer manuellement `Production backup`, relever les volumes et les empreintes sans identité/photo/chemin privé dans le rapport. Une copie complète doit échouer si un seul objet manque. Toute interruption/erreur de la CLI = NO-GO. Garder le fichier chiffré dans un lieu indépendant du projet.

**Étape C — Restauration véritable.** Déchiffrer dans un runner/ordinateur **isolé à droits restreints**, démarrer Supabase CLI local avec version compatible `auth`/`storage` avec la production (Postgres 17 et schéma Auth récent). Rejouer le backup SQL avec `ON_ERROR_STOP=1` et transaction adaptée ; réimporter les objets Storage **via une API ou outil de restauration** dans le bucket correspondant sans toucher le serveur commercial, comparer `SHA-256` et nombre d'octets depuis `manifest.json`. Tester des connexions fictives si autorisées, isolation RLS A/B, RPC admin refusée à joueur, accessibilité des médias et absence de clés privées exposées. Purger l'environnement isolé après journal d'empreintes non nominatives. **Toute erreur = NO-GO**. La restauration d'une copie de production vers le service local ne doit jamais écraser de données commerciales.

**Étape D — Maillots / mise en ligne.** Revoir la migration de 983 lignes et les tests SQL, ses effets sur les objets privilégiés, les snapshots historiques et les deux clubs existants ; appliquer uniquement la migration commerciale si étapes A/B/C sont prouvées, relire le registre/contraintes/RPC, puis procéder à une publication Cloudflare explicitement autorisée après validation du garde #118. Jouer le parcours maillots réel sur deux clubs et vérifier les choix joueur/gardien, vidéo et historique.

## 5. Condition de fin de mission

**Ne pas déclarer « Sauvegardé », « Restauré », « Migration appliquée » ni « En ligne » à partir du seul code ou de résultats synthétiques.** Le contrat du propriétaire autorise l'opération **seulement si tous les prérequis sont effectivement satisfaits**. En l'état, **aucune écriture Supabase, fusion, exécution manuelle de backup, déploiement ou dépense n'a été faite par cette PR**.

Références : [Supabase Storage — Download Objects](https://supabase.com/docs/guides/storage/management/download-objects), [Supabase — Backup and Restore using the CLI](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore), [issue M09 #91](https://github.com/samihchaa-wq/Application-football-/issues/91).
