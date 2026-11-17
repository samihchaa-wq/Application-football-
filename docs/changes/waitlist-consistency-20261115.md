# Liste d'attente : corrections issues de l'audit du 15 novembre

Correctif commercial de ATT-01, ATT-02 et ATT-03 du rapport
`docs/AUDIT_AUTOMATISMES_20261115.md` (PR #137).

## Résultat attendu

- Les boutons +/− envoient un delta au compteur courant, plutôt qu'un total
  calculé sur une ancienne lecture de l'écran.
- Le serveur renvoie le classement après la modification ; l'écran adopte
  immédiatement cet ordre et ces compteurs.
- Un identifiant conservé pendant la confirmation d'un geste empêche un +1
  supplémentaire si sa réponse réseau est perdue. L'écran n'annonce pas un
  faux échec et ne permet pas de nouveaux gestes tant que le précédent reste
  incertain ; « Réessayer » confirme le même identifiant.
- Un changement effectif du mode d'attente rééquilibre les matchs encore
  ouverts, y compris les effectifs publiés. Les choix manuels sont conservés,
  les matchs gelés ne sont pas réécrits et les autres clubs ne changent pas.
- Les +1 restent exclusivement manuels.

## Compatibilité et sécurité

La RPC absolue `admin_set_waitlist_manual_count(uuid,integer)` reste présente
pour les clients installés ; la nouvelle interface utilise
`admin_adjust_waitlist_manual_count(uuid,integer,uuid)`. Les anciens clients
doivent être actualisés pour bénéficier des deltas concurrents.

Le moteur interne et les RPC utilisent le propriétaire `club_scope`, les
contrôles d'admin actif, le cloisonnement existant et un `search_path` vide.
Le moteur privé n'est pas exécutable par les rôles clients. Les identifiants de
gestes sont indexés dans le journal privé existant : aucune nouvelle table
exposée, aucun ancien compteur remis à zéro et aucun audit réécrit.

La nouvelle migration `20261115173541_waitlist_consistent_manual_adjustments.sql`+a été créée par la CLI. Son identifiant est inférieur à certaines migrations
historiques datées dans le futur ; aucune définition qu'elle corrige n'est
remplacée par celles-ci. Le déploiement doit comparer l'ensemble des versions
appliquées, pas seulement une version maximale. Le pilote commercial existant
traite déjà les fichiers absents du registre ; son contrôle distant doit
néanmoins réussir avant toute écriture.

## Vérifications

- Tests widget : nouvel ordre sans rafraîchissement, double clic, réponse perdue
  puis confirmation du même geste, refus explicite, lecture seule.
- pgTAP : réponse autoritaire, pas de double crédit ni d'audit supplémentaire,
  refus des deltas invalides/négatifs, trois modes appliqués via RPC publique,
  désistement, retour, choix admin préservé, retour au réglage par défaut,
  gel avant match et permissions (dont compte/club inactif).
- Test PostgreSQL à sessions distinctes : deux admins sur le même compteur,
  même geste simultané, joueurs distincts et reclassement, +/− concurrents,
  refus d'un autre club. La cible est codée en dur sur la pile locale jetable
  de CI ; aucun paramètre de connexion à une base distante n'est accepté.
- Contrôles complets Flutter/SQL/ACL/RLS et build à lire sur le SHA exact de
  la PR #138. Les fichiers de tests ajoutés ne sont pas eux-mêmes une preuve
  de réussite : le statut final est consigné dans la description de la PR.

La lecture Supabase commerciale est refusée dans cette session. Aucune
migration distante, fusion ou publication ne fait partie de la validation
annoncée ici. AS Grinta original et ses données restent intacts.
