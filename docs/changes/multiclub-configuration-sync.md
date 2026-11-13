# Réglages multiclub : cohérence de session et synchronisation

## Problème corrigé

Une succession de comptes A → B pouvait conserver des modules ou des règles
chargés pour A : les providers dépendaient du seul booléen « connecté ».
Un administrateur pouvait aussi modifier les règles, couleurs, maillots ou
modules sans que les autres appareils du club les rechargent.

## Réutilisation et adaptation

Le contrôleur de feature flags, son abonnement Realtime avec reprise sur erreur,
ses tests et le coordinateur de rafraîchissement des données viennent du socle
AS Grinta déjà présent dans Petit Filet. Cette modification les étend plutôt
que d'ajouter un autre abonnement, une nouvelle table ou une tâche planifiée.

| Mécanisme conservé | Adaptation multiclub |
| --- | --- |
| Signal public de révision des feature flags | Clé `club_configuration`, clé primaire composée `(club_id, key)` et filtre du club |
| Relecture par les RPC et RLS existantes | Le signal ne transporte aucune valeur de réglage, code d'invitation ou donnée métier |
| Reprise de l'abonnement et temporisation | Révisions suivies par clé, regroupement des changements de configuration sur 350 ms |
| Garde contre les réponses tardives de l'identité | Dépendance à l'identifiant du compte pour identité, règles, modules et contrôleur de flags |
| Invalidation des caches partagés | Relecture des réglages et des lectures métier affectées par les règles |

Les modules sont fermés pendant un chargement ou une erreur. Un bandeau indique
l'état et permet de réessayer. Les réglages sont relus au retour au premier
plan, y compris après une courte mise en arrière-plan sur iOS.

La première révision de configuration provoque aussi une relecture : elle
rattrape une écriture survenue entre les lectures initiales et l'abonnement.
Les changements suivants ignorent les révisions anciennes ou dupliquées.

## Sécurité SQL

Le trigger reçoit la cible depuis la ligne modifiée, jamais depuis une valeur
envoyée par le client. Cela fonctionne également lorsque l'éditeur agit sur un
autre club. Son propriétaire technique `postgres` est une exception explicite,
limitée à une fonction de trigger sans argument et sans résultat de données ;
l'exécution directe est révoquée pour les rôles API. Les droits de lecture du
signal et toutes les autorisations des écritures métier restent inchangés.

Les écritures sans changement réel ne créent pas de révision supplémentaire.
Les suppressions en cascade ne recréent pas de signal pour un club supprimé.
Les réglages ne réécrivent pas les résultats et compositions historiques.

## Vérification

- Reprise des suites existantes d'identité, feature flags et routage sportif.
- Cas A → B, déconnexion, erreur réseau, réponse tardive de A et actualisation
  distante des modules/règles ; identité et maillots gardent leurs tests existants.
- Révisions de configuration indépendantes du signal sportif, doublons,
  regroupement des changements et rattrapage du premier signal.
- Bandeau de chargement, erreur, nouvelle tentative et absence de requête hors
  connexion ; rejet des réponses de modules incomplètes ou mal typées.
- Une erreur de lecture des règles ne réactive pas le mode live désactivé.
- Les anciens tests d'écran déclarent maintenant leurs modules actifs dans
  leurs fixtures ; un bouton de badges ne lit rien pendant un chargement ou
  une erreur de modules. Aucun défaut permissif n'est réintroduit pour les tests.
- Nouvelle suite SQL : mutations des modules, règles, identité, couleurs, logo,
  maillots, code d'invitation, terrain et quota ; absence de signal sur erreur
  ou écriture identique ; isolement A/B, rôles, suspension, éditeur et cascades.

L'analyse Flutter, la suite Flutter complète, la construction web, la
reconstruction SQL et les tests RLS/Edge sont confiés à la CI du dépôt. Le
démarrage Flutter local a été bloqué par le contrôle automatique de
l'environnement ; aucun succès local de ces vérifications n'est revendiqué.
Les résultats définitifs sont consignés dans la pull request.

## Déploiement

Cette pull request contient du code et une nouvelle migration ; elle ne
déploie rien. Appliquer la migration `20261113103300` avant la nouvelle version
de l'application commerciale. Des migrations du dépôt portent déjà des dates
ultérieures : vérifier l'historique et appliquer seulement les versions
manquantes, sans réécrire les migrations existantes ni le verrou de production
avant confirmation de l'état réel. Sans ce signal côté base, la reprise au
premier plan fonctionne mais pas la propagation immédiate entre appareils.

AS Grinta et ses données ne sont pas modifiés. La tenue en charge de milliers
d'utilisateurs ne peut pas être déduite de cette seule correction : elle
demande les scénarios de charge du dépôt et une mesure de leur exécution.
