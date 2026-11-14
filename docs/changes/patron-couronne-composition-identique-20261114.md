# Couronne Homme du match : patron = composition, sans approximation

## Constat
La composition utilise `PhotoCrown` (`lib/core/widgets/match_contribution_icons.dart`) : **emoji 👑**, taille `22 * photoSize / 52` et position verticale `topOffset(photoSize) = -16 * photoSize / 52` par rapport au haut de l'avatar (photo 58 px). Le patron avait à tort un dessin vectoriel blanc à pointes inventées, sans rapport avec le terrain.

## Correctif
- `PortraitAlignmentGuide` **réutilise le composant PhotoCrown d'origine**, sans reproduire ses contours ni créer une deuxième définition.
- Dans le recadrage, la couronne a le même ratio qu'en composition. Pour représenter fidèlement son décalage **au-dessus** de la photo, un espace extérieur au carré est réservé : `crownSpace = -PhotoCrown.topOffset(300)`. Le haut de la photo est à `crownSpace`; le haut de la couronne est à zéro. Ainsi `crown.top - photo.top == PhotoCrown.topOffset(300)`, quelle que soit l'échelle du téléphone.
- Le carré photo reste de 300×300 logique, avec zoom/translation inchangés. La couronne n'est **pas découpée** par le carré photo, et son débord sert à anticiper le rendu sur le terrain. L'export JPEG/PNG reste strictement la photo source recadrée, sans emoji ni maillot.
- Aucun guide des yeux/visage, cercle facial, ligne de hauteur, carte Conseils ou exemples n'est réintroduit.
- Sur petits écrans, le dialogue est plus haut pour accueillir la couronne extérieure ; le contenu reste défilable si la hauteur disponible ne suffit pas.

## Validation
- Tests Flutter : présence de `PhotoCrown` et de l'emoji 👑, calcul de l'écart relatif photo/couronne à la même échelle, export brut préservé.
- Validation visuelle réelle iOS/PWA : **à effectuer** après publication Cloudflare. Le style exact de l'emoji dépend de la police de la plateforme ; le composant utilisé est toutefois le **même** que celui de la composition, dans la même exécution.
- La PR est indépendante de la PR #111, en cours de revue sur les portraits avec maillot universel.

Aucune migration Supabase, aucun déploiement automatique, aucune modification AS Grinta.
