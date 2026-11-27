# Copie automatique AS Grinta

Mise à jour : 27/11/2026.

## À quoi elle sert

Tant que les joueurs d'AS Grinta utilisent encore l'ancienne application, une
copie recopie leurs données dans le club AS Grinta de Petit Filet. Elle va
dans un seul sens : l'ancienne application n'est jamais modifiée.

- Tâche planifiée : `sync-as-grinta-miroir`, toutes les 5 heures (`0 */5 * * *`, heure UTC).
- Fonction serveur : `sync-as-grinta` (code dans `supabase/functions/sync-as-grinta/`).
- Secret : `AS_GRINTA_SERVICE_KEY` (clé de lecture de l'ancien projet).
- Club visé : AS Grinta (`d309a2dd-5060-42e1-9d07-a2153a5f2519`) ; aucun autre club n'est touché.

Elle recopie 48 tables « sport » (joueurs, saisons, matchs, compositions,
statistiques, badges…) puis supprime côté Petit Filet ce qui a disparu de
l'ancienne application. Tout se fait d'un bloc : si une étape échoue, rien
n'est changé.

Conséquence importante : tout ce qui est modifié directement dans le club AS
Grinta de Petit Filet est écrasé à la copie suivante.

## Ce qui a été réparé (27/11/2026)

- Liste d'attente : la copie échouait en entier dès qu'un joueur changeait de
  rang (ajout en fin de liste, renumérotation au coup d'envoi). La liste
  d'attente est maintenant effacée puis réécrite d'un bloc.
- Compteurs d'id : la copie laissait les compteurs en retard, et l'appli
  reprenait un id déjà pris (« duplicate key » en validant un compte rendu).
  Chaque compteur est recalé à la fin de chaque copie ; la migration
  `20261210050000` les recale une première fois.
- Échec visible : un échec crée (ou rouvre) une alerte « Copie AS Grinta en
  échec » dans l'onglet « À faire » du Poste de contrôle. La tâche planifiée,
  elle, affiche toujours « succeeded ».
- Badges : les images restaient chez l'ancien projet, bloquées par la
  sécurité du navigateur. Elles sont recopiées une fois dans le stockage de
  Petit Filet (dossier `as-grinta/` du seau `badge-images`), puis seulement
  les nouvelles.
- Photos de profil : l'ancienne application enregistre `avatar_<n>.png`, qui
  n'existe pas dans Petit Filet. La copie garde la photo présente dans le
  dossier du joueur, ou aucune photo (initiales). L'appli ne redemande plus
  une photo introuvable pendant 30 minutes.

## Limites connues

- Si la fonction ne répond pas du tout (panne, délai dépassé), aucune alerte
  n'est créée. Pour vérifier à la main : table `net._http_response`, dernières
  lignes, colonne `status_code` (200 attendu).
- « Babinski, lié à Roman, fiche Roman, archivé » (écran Joueurs) n'est pas
  une erreur de copie : Babinski est le surnom du compte de Roman Yassinski,
  la fiche de saison s'appelle Roman et n'est plus active. Les données sont
  identiques à l'ancienne application.

## Mettre la nouvelle version en service

Rien ne change en production tant que ces étapes ne sont pas faites.

1. Appliquer la migration `20261210050000` (workflow « Commercial Supabase
   setup », case « migrations »).
2. Déployer la fonction (même workflow, case « fonctions »). Ce bouton
   déploie toutes les fonctions du dépôt, dont celle-ci.
3. Lancer une copie à la main et vérifier la réponse (`result: ok`) et qu'aucune
   alerte n'apparaît dans « À faire ».

## Arrêter la copie (avant d'inviter les joueurs d'AS Grinta)

À faire dans cet ordre, et avant d'inviter les joueurs sur Petit Filet, sinon
leurs saisies seront écrasées.

1. Arrêter la tâche planifiée, dans l'éditeur SQL de Supabase :
   `select cron.unschedule('sync-as-grinta-miroir');`
   Vérifier : `select jobname from cron.job;` ne la montre plus.
2. Supprimer la fonction : tableau de bord Supabase, Edge Functions,
   `sync-as-grinta`, Delete (ou `supabase functions delete sync-as-grinta`).
3. Supprimer le secret `AS_GRINTA_SERVICE_KEY` : Edge Functions, Secrets (ou
   `supabase secrets unset AS_GRINTA_SERVICE_KEY`). Puis, côté ancien projet,
   régénérer sa clé de service : celle-ci a été copiée.
4. Dans le dépôt : supprimer `supabase/functions/sync-as-grinta/`, son bloc
   dans `supabase/config.toml`, sa ligne dans
   `supabase/tests/edge/verify_edge_security_contract.py`, son test dans
   `.github/workflows/supabase_business_tests.yml` et l'exception
   correspondante de `.gitleaks.toml`.
5. Marquer « Traitée » une éventuelle alerte « Copie AS Grinta en échec ».

## Tests

- Règles pures (sans réseau) : `deno test supabase/functions/sync-as-grinta/logic_test.ts` (lancé en CI).
- Refus sans jeton : `handler_test.ts` (lancé en CI).
- Essai complet sur une base Postgres jetable (liste d'attente renumérotée,
  compteurs, badges, photos, alerte, échec sans écriture partielle) :
  `supabase/functions/sync-as-grinta/handler_db_test.ts`, mode d'emploi en tête
  du fichier. Il efface la base visée : jamais sur une vraie base.
- Base : `supabase/tests/database/as_grinta_copy_sequences_alert.test.sql`.
