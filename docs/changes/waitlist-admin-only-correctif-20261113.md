# Petit Filet — correctif de la liste d'attente : +1 réservés aux administrateurs

**Décision produit en vigueur :** aucun +1 automatique. Les changements de crédits
sont faits via les boutons +/− de l'écran administratif et la RPC
`public.admin_set_waitlist_manual_count(uuid,integer)`.

## Diagnostic (code et Supabase commercial, sans écriture)

- Migration `20261115000000_waitlist_credits_admin_only.sql` : mécanismes auto neutralisés.
- Migration **ultérieure** `20261116000000_waitlist_permanent_auto_credits.sql` :
  la fonction de crédit automatique a été **réactivée** et le cron
  `waitlist-credit` a été planifié chaque minute.
- En base commerciale, le cron était actif au contrôle du 13/11/2026.
- La RPC administrative existante vérifie le rôle, interdit les compteurs
  négatifs, journalise les corrections et recalcule l'ordre/les convocations.
- Le moteur de classement utilise déjà `manual_waitlist_count` pour départager
  les joueurs suivant le mode choisi (présence passée, ordre d'arrivée, admin).

## Correction préparée

Migration **nouvelle, postérieure** :
`20261118001000_waitlist_credits_admin_only_final.sql`.

1. Déplanifie le cron `waitlist-credit`.
2. Rend inoffensifs les appels directs aux fonctions automatiques de crédit,
   retrait et rattrapage ; maintient les signatures et permissions utiles.
3. Ne modifie aucune donnée, aucun compteur, aucun classement existant.
4. Ne modifie pas les trois modes de sélection des convocations.
5. Conserve l'ajout/retrait par administrateur, la traçabilité et les
   notifications de changement de convocation réellement intervenu.

Les registres historiques `private.waitlist_auto_processed_matches`,
`private.waitlist_auto_activation` et le ledger sont **conservés**.
Les supprimer ou transformer exigerait une étude distincte ; ici ils servent
notamment d'historique pour les saisons déjà traitées.

## Scénarios de non-régression (SQL en base locale isolée)

- Deux joueurs en attente à la date du match : **0 crédit automatique** ;
  plusieurs finalisations restent inoffensives.
- Administration : **+1 Alice et +1 Bruno**, journal d'audit, ordre actualisé.
- Mode présence passée : priorité aux crédits admin.
- Mode ordre d'arrivée : crédits admin prioritaires, ancienneté en départage.
- Mode par choix : quatre joueurs initialement convoqués, attente manuelle,
  **0 crédit** avant l'action admin ; **+1 Damien** après action.
- Annulation et anciens matchs : aucun retrait ni rattrapage automatique.
- Utilisateur non administrateur : RPC refusée et compteur inchangé.
- Cron désinscrit et fonctions internes sans droit d'exécution utilisateur.

## Déploiement / limites

**Aucune écriture distante et aucun déploiement n'ont été effectués par cette PR.**
Une fusion GitHub ne déploie pas automatiquement Supabase. Avant toute
application à la base commerciale : sauvegarde, vérification des 49 migrations
déjà appliquées, tests SQL locaux verts sur le commit exact et **accord
distinct du propriétaire**.

Après application autorisée, vérifier en lecture seule : le cron est absent,
les fonctions internes retournent 0, les compteurs des deux clubs restent
identiques et les nouvelles corrections admin sont historisées. Ne jamais
toucher à la base ni au code de l'application AS Grinta originale.
