# Petit Filet — couleurs de maillots dans les compositions (issue #67)

## Étendue du lot

La sélection de la tenue via `jersey_note` reste propre au match. L'API Flutter `MatchCompositionKitScope` lit cette sélection sans modifier les photos existantes ; `CompositionKitScope` transmet les deux jeux de couleurs aux seuls éléments de composition.

- **Avant-match** : effectif publié et terrain administrateur.
- **Live** : terrain spectateur avant le coup d'envoi, composition affichée pendant le direct. Les changements de gardien restent déterminés par le champ `isGoalkeeper` sur les entrées.
- **Après-match** : compositions publiées visibles depuis le résultat.
- **Vidéo** : la tenue résolue est incluse dans `CompositionPresentationData` et la silhouette sans photo reçoit les couleurs de champ ou de gardien.
- **Entre nous** : deux scopes distincts empêchent que la tenue de l'équipe 1 s'applique à l'équipe 2.
- **Autres photos** : les avatars génériques ne sont pas recolorés ; les portraits alternatifs des joueurs ne sont pas fabriqués ou repeints.

## Limites bloquantes pour une clôture de #67

1. La migration de maillots gardien `20261115010000_couleurs_maillot_gardien.sql` (PR #80) doit encore faire l'objet d'un déploiement Supabase **autorisé séparément**.
2. Un **snapshot historique par match et par équipe** doit figer les couleurs et le maillot de gardien au moment du match, notamment pour les rencontres « entre nous ». En l'absence de snapshot, les anciens matchs reflètent encore potentiellement un changement ultérieur des couleurs du club.
3. Les maillots et les placements pendant un remplacement au poste de gardien, les photos alternatives, les archives importées et l'affichage sur iOS/Android/PWA demandent une revue E2E.
4. Tester deux clubs avec maillots distincts, déconnexion/reconnexion, saison précédente et changement rétroactif de couleurs.

## Sécurité et livraison

Aucune écriture sur le projet AS Grinta original ou sur Supabase commercial. Aucun déploiement Cloudflare. Les tests Flutter de la PR ne remplacent pas la revue des cas historiques et multiclubs.
