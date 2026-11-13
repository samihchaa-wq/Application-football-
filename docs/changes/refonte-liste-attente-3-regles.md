# Refonte de la liste d'attente — historique des règles (novembre 2026)

> **Décision produit actuelle :** seuls les administrateurs modifient les crédits +1 avec les boutons +/−. La migration automatique du 16/11 est remplacée par le [correctif préparé en PR #105](waitlist-admin-only-correctif-20261113.md), **pas encore déployé**. Les passages ci-dessous qui décrivent un moteur de crédits au coup d'envoi sont historiques et ne doivent pas servir de consigne pour un développement nouveau.

> **Décision prioritaire du 13/11/2026 (Petit Filet, issue #68) :** la rotation des convocations peut rester automatique, mais **aucun +1 d’attente ne doit être attribué ni retiré automatiquement**. Seul un administrateur agit avec les boutons +/− dans « Liste d’attente ». Les anciens crédits ne sont pas effacés. La migration préparée `20261115000000_waitlist_credits_admin_only.sql` désactive le cron et neutralise les fonctions automatiques. Les références ci-dessous aux anciennes fenêtres de crédit sont historiques et ne font plus autorité.

> Branche de travail. **Aucune migration sur la production ni activation du nouveau moteur sans tests.**

## Les seules règles métier

1. **Priorité des convocations** — Pour un match et un quota X, les convoqués sont exactement les `min(X, présents)` joueurs déclarés présents ayant les positions les plus basses (numéros les plus élevés) dans la liste d'attente.
2. **Passages en attente** — Le passage en attente n'attribue aucun point. **Un admin attribue ou retire chaque +1 manuellement** via la liste, à son appréciation et selon les règles communiquées par son club. Les annulations, reports, changements de quota et coups d'envoi ne modifient pas ces compteurs.
3. **Ordre de la liste** — Tri ascendant par (a) total des passages en attente, (b) matchs joués lors de la saison précédente, (c) ordre alphabétique du nom, puis prénom. Un identifiant stable départage une homonymie parfaite.

## Contrôle de l'administrateur (décisions du 8 novembre 2026)

- **Liste d'attente — boutons +/−** : l'administrateur peut ajouter ou retirer un +1 à un joueur (inscrit au journal d'audit). Le classement est recalculé aussitôt selon la règle 3 et les convocations des prochains matchs suivent. L'écran montre le nouvel ordre quand on tire la liste vers le bas ou qu'on revient sur la page. Pas de glisser-déposer ni de bouton « Enregistrer », « Recalculer » ou « Actualiser ».
- **Effectif — choix par match** : comme avant la refonte, l'administrateur peut glisser un joueur dans « Convoqués » ou « En attente » pour un match. Ce choix est conservé par les recalculs : un joueur forcé convoqué prend une place, un joueur forcé en attente en libère une ; les autres suivent la règle 1. Le choix s'efface si la disponibilité du joueur change (il répond, se désiste, revient, ou l'admin le déclare absent). Un joueur forcé en attente ne gagne pas automatiquement de +1 ; seul l'admin peut corriger son compteur.
- **Retri automatique de la liste** : uniquement après correction du compteur par un admin, avec recalcul des convocations futures qui restent modifiables selon leurs règles.
- **Mise en ligne sans effet rétroactif** : l'ordre actuel de la liste et les compteurs sont conservés tels quels. Ils servent de point de départ pour la saison en cours : le classement se fait d'abord sur les +1 gagnés depuis la mise en ligne, puis sur l'ordre de départ, puis sur les critères de la règle 3. Les compteurs affichés restent les totaux de la saison. Aucun +1 n'est crédité pour un match joué avant la mise en ligne.
- Une liste toute neuve (nouvelle saison) est triée selon la règle 3, sans point de départ. Un joueur ajouté en cours de saison passe après les joueurs du point de départ à nombre de +1 égal.
- **Matchs « entre nous »** : inchangés, tous les présents sont convoqués.

## Invariants techniques obligatoires

- En amont du verrouillage, aucune dérogation individuelle ni ancien état de promotion ne peut déroger à la règle 1 ; l'administrateur agit uniquement sur l'ordre de la liste et les compteurs.
- L'effectif déjà verrouillé à l'ouverture du Live (T−15) n'est pas recomposé par un crédit automatique (désormais interdit).
- Les transitions de l'état `not_convoked` sont enregistrées **en tant qu'événement**, indépendamment du statut final du joueur.
- L'attribution manuelle d'un +1 utilise le RPC administratif existant et son audit ; aucun traitement au coup d'envoi ou en lecture ne modifie le compteur.
- Le compteur affiché et celui utilisé pour classer les joueurs doivent être la même donnée (pour la saison en cours, le classement en retire la valeur mémorisée à la mise en ligne).
- Les notifications de promotion/rétrogradation conservent leur fonctionnement uniquement sur un changement réel du statut calculé.
- Les données et statistiques de production sont conservées; aucun effacement sans migration justifiée et sauvegarde.

## Problèmes du moteur actuel observés

- `private.finalize_match_waitlist_turns_internal` déplace les joueurs vers la dernière position, sans incrémenter `manual_waitlist_count`, pourtant utilisé par l'interface pour « Recalculer ».
- `private.recompute_match_convocations_internal` sanctuarise `convocation_manual_override`, qui peut faire passer une décision arbitraire avant la priorité de la liste.
- `private.handle_convoked_withdrawal` et `private.restore_returning_convoked_player` opèrent des promotions et des retours particuliers au lieu de s'appuyer systématiquement sur le même calcul.
- Le RPC `private.get_sport_waitlist` ne renvoie pas le champ `current_season_waitlist_count`, alors que le modèle Dart attend ce champ.
- Les opérations d'administration peuvent conserver des dérogations; elles devront être redéfinies pour modifier uniquement les entrées des règles, pas les résultats.

## Points d'intégration à préserver

- Comptes joueurs, saison, coach (hors quota comme actuellement), invités, composition, Live, disponibilités, notification des mouvements, historique.
- Les signatures des RPC publiques jusqu'à migration du client; les anciennes API de dérogation devront retourner un refus explicite plutôt que créer des états incohérents.
- La règle de convocation conserve ses horaires serveur ; les +1 manuels ne dépendent désormais d'aucune fenêtre horaire.

## Plan d'exécution

1. Désactiver les crédits et retraits automatiques sans supprimer l'historique ; préserver la RPC manuelle et l'audit.
2. Remplacer le moteur de sélection par un seul recalcul déterministe et supprimer les dérogations manuelles.
3. Remplacer le déplacement arbitraire de la liste par un tri à partir des compteurs.
4. Adapter l'interface d'administration sans toucher aux autres écrans.
5. Tester (aucun +1 sans action admin, changement de disponibilité, promotion/retrait, report, annulation, quota, double exécution, classement manuel, notifications), auditer les migrations et ne déployer qu'après validation.

## Contrôles bloquants avant fusion

- Exécuter les tests SQL et Flutter, y compris les anciens tests métier qui peuvent nécessiter une adaptation explicite.
- Tester sur une base isolée copie de la structure de production, jamais sur la production.
- Vérifier `EXPLAIN`, la concurrence, les index et les droits des fonctions `SECURITY DEFINER`.
- Examiner les invités. Les matchs « entre nous » gardent volontairement leur exception : tous les présents sont convoqués.
