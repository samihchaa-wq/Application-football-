# Suspension d'un club : droits serveur cohérents

Un administrateur dont le profil restait actif pouvait encore utiliser
certaines RPC après la suspension de son club. `manage-user`, qui utilise une
clé de service pour gérer les comptes, ne consultait pas non plus cet état.

## Comportement

- `private.is_admin()` exige désormais un profil actif, le rôle admin et un
  club actif. Il réutilise `private.is_active_profile()` ; les états viennent
  des tables, pas de métadonnées fournies par le client.
- Les alias publics admin/staff et l'alias historique `is_moderator()`
  convergent vers ce contrôle. Les règles de cloisonnement restent en place.
- `private.can_manage_badges()` utilise le même prédicat pour les utilisateurs
  et garde l'accès technique authentifié `service_role`.
- `manage-user` interroge `is_admin` avec le JWT vérifié du demandeur, avant la
  réinitialisation ou la suppression d'un autre compte. Erreur SQL, réponse
  absente ou autre chose que le booléen `true` : refus sans action privilégiée.
- L'état d'accès du club et l'export de ses propres données restent
  disponibles. La branche d'effacement personnel précède le contrôle admin :
  la suspension ne supprime pas ce parcours. La protection existante du
  dernier administrateur reste applicable ; l'effacement ne peut pas cibler
  un autre utilisateur via `userId`.
- Seul un opérateur déclaré de la plateforme peut réactiver un club. La
  suspension/réactivation est prise en compte au prochain appel, sans attendre
  le renouvellement du JWT. L'autre club conserve ses droits.

## Validation

`active_club_admin_permissions.test.sql` utilise deux clubs fictifs et les
vraies RPC/RLS : joueur, admin en attente/archivé, compte sans profil, admin de
club suspendu, admin actif d'un autre club, opérateur et service technique.
Dix-huit familles de commandes admin sont exercées en refus. La suite couvre
aussi les écritures légitimes, l'isolation A/B, les en-têtes/métadonnées
contradictoires, Storage, l'export personnel et la réactivation.

`manage-user/handler_test.ts` exécute le vrai handler HTTP avec Auth/base
simulés : JWT expiré, refus de permissions et absence d'effets privilégiés,
réinitialisation légitime, cible d'un autre club, mêmes JWT après suspension,
effacement personnel et dernier admin. `index.ts` branche ce handler sur les
dépendances Supabase réelles. Ces tests font partie de la CI SQL/Edge.

Les tests HTTP simulés ne prouvent pas les e-mails, Auth ni les suppressions
de bout en bout sur une infrastructure déployée. Les tests SQL sont destinés
à une base isolée ; aucune donnée fictive à créer dans le commercial.

## Livraison

Migration additive : `20261113005335_active_club_admin_permissions.sql`, créée
par la CLI. Les trois fonctions conservent leurs propriétaires, signatures et
ACL par `CREATE OR REPLACE`. Aucun droit anonyme supplémentaire ni modification
d'une migration existante. Son identifiant est antérieur à certaines migrations
déjà enregistrées : vérifier explicitement le registre et les migrations
absentes lors de la préparation du déploiement, sans renumérotation ni rejeu
aveugle des migrations existantes.

Appliquer et vérifier la migration SQL avant de publier `manage-user` qui
réutilise ce prédicat. Une fusion GitHub seule ne corrige pas la base distante.
Ce lot n'applique pas la migration, ne déploie pas de fonction et ne fusionne
pas de PR ; il prépare le correctif et ses preuves pour revue.
