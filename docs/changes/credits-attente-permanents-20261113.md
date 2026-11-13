# Petit Filet — priorité cumulée des passages en attente (historique, remplacé)

> **Document historique, règle remplacée :** la décision actuellement retenue par le propriétaire est **aucun +1 automatique**. Le correctif préparé par [PR #105](https://github.com/samihchaa-wq/Application-football-/pull/105) désactive l'attribution au coup d'envoi et conserve les crédits manuels. Voir [contrat en vigueur](waitlist-admin-only-correctif-20261113.md). Tant que la migration corrective n'est pas appliquée sur Supabase commercial, le comportement distant peut encore créditer automatiquement. Le texte ci-dessous explique l'ancienne mécanique et ne doit pas être réutilisé comme spécification active.

## Règle unique
- Au **coup d'envoi**, chaque joueur de saison **présent, éligible et toujours dans « Liste d'attente »** gagne **exactement +1**.
- Le +1 est **permanent jusqu'à la fin de cette saison** : une convocation ultérieure ne le retire jamais. Les scores des saisons précédentes restent archivés ; une nouvelle saison commence avec ses propres compteurs à 0.
- Un match ne compte qu'une fois, même avec plusieurs appels, reprise du cron, rafraîchissement de l'interface ou changement de quota. Jamais de crédit pour un absent, un non-éligible, un coach ou un joueur convoqué.
- L'administrateur conserve les boutons **+/-** pour corriger les compteurs ; ces corrections ne déclenchent pas une consommation ultérieure.
- **Aucun rattrapage automatique rétroactif** pour les matchs commencés avant l'activation de cette migration. Les +1 et historiques déjà existants ne sont ni effacés ni remis à zéro.
- Si un match est annulé **avant** son coup d'envoi, aucun +1 n'est attribué. Un +1 déjà acquis n'est pas déduit par un traitement d'annulation.

## Trois modes, une seule priorité sur les +1
1. **Par présence l'an dernier** : d'abord plus grand nombre de +1 de la saison, puis plus grand nombre de matchs joués lors de la saison précédente ; égalité restante par nom/prénom et identifiant.
2. **Ordre d'arrivée** : d'abord plus grand nombre de +1 de la saison, puis l'heure de déclaration de présence pour le match (premiers inscrits prioritaires) ; identifiant stable en dernière égalité.
3. **Par choix** : tous les présents sont initialement convoqués ; l'administrateur déplace manuellement ceux qui doivent attendre. Les +1 sont consultables pour éclairer sa décision mais **ne forcent pas** son choix.

Les rencontres « entre nous » gardent la convocation automatique de tous les disponibles. Si l'admin place malgré tout un joueur présent en attente, il gagne son +1 au coup d'envoi.

## Mise en œuvre
- Migration commerciale **20261116000000_waitlist_permanent_auto_credits.sql**, postérieure à la désactivation historique du 15/11.
- Horloge **serveur PostgreSQL** et tâche **Supabase Cron toutes les minutes** ; le crédit est calculé sur l'état au coup d'envoi, après le verrouillage des convocations. Il peut être enregistré quelques secondes après la minute exacte.
- Verrou du match, registre « match traité une seule fois », journal par joueur, écriture incrémentale atomique, et classement recalculé uniquement si des crédits nouveaux ont été attribués.
- Tous les traitements utilisent l'identité de club du match ; aucun compteur d'un autre club ne doit être modifié.
- Les anciens instantanés `sport_waitlist_start` ne neutralisent plus les points déjà gagnés pendant cette saison ; **le total réel** est la référence.
- Les listes d'attente en consultation restent sans mutation. Les modes sont des règles de sélection du club, les +1 ne sont pas « dépensés ».

## Tests et autorisation de déploiement
- Scénarios SQL pgTAP : aucun crédit avant le coup d'envoi, un seul par joueur/match, priorité « présence », priorité « arrivée », mode « choix », compteur conservé, absence de rattrapage historique.
- **À exécuter sur base isolée** : suite SQL, tests Flutter, deux clubs réels simulés, concurrence Cron/admin et changements de dates/statuts. Vérifier le comportement des triggers de calendrier.
- **Ne pas déployer** tant que CI/revue/sauvegarde/autorisation séparée du propriétaire ne sont pas réunies.
- Toute modification de base est interdite sur l'original AS Grinta ; le changement concerne exclusivement Petit Filet.
