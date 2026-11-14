# Refonte du portrait habillé : matière tricotée et jonction visage (14/11/2026)

## Problème réellement observé

Les captures iPhone de Petit Filet montraient un maillot trop proche d'une illustration et une découpe **horizontale/rectangulaire sous le visage**, parfois en plein sur la joue ou la barbe. Le peintre du maillot en PR #109 avait un fond presque uni, quelques ombres et une microtrame de lignes ; la photo était coupée net à **61,3 %** de la hauteur en dehors du cou.

## Correction du rendu

- **Carte de matière textile réelle en pixels** (`assets/composition/jersey_fabric_luma.png`, 256×256, image en niveaux de gris). Le tricot, le relief, les petites irrégularités et l'éclairage diffus proviennent d'une carte de matière et non de simples bandes vectorielles plates. Carte procédurale embarquée (sans source tierce, coût réseau ou licence externe).
- Décodage **une seule fois** et partagé par tous les `KitPortrait` ; peinture avec `BlendMode.multiply` sous les coutures et le col : les pixels de matière modulent les **couleurs et motifs configurés par le club**, y compris maillot de gardien et les variantes de match. Le visage ne passe jamais dans la couche de matière.
- **Masque de tête organique**, entièrement en courbes de Bézier, sans la ligne horizontale située avant au niveau des joues. Le haut du visage et son contour restent la photo d'origine, le cou s'insère dans le col. La coupe s'adapte aux **photographies cadrées** mais ne réalise pas de segmentation automatique des cheveux/la peau sur tous les JPEG.
- Ajout de **plis diffus** avec ombres floues sur les pectoraux, emmanchures et dessous d'épaule ; les gros contours/cartouches sont évités.
- **Col côtelé** avec dégradé de lumière, fibres discrètes, joint de cou et couture de bord. Le patron de cadrage, le profil, l'effectif, la composition, le Live et la vidéo utilisent le même `KitPortrait` : les corrections se répercutent partout.
- Si la carte de matière ne peut pas être lue, le maillot conserve un rendu de repli ; aucun écran ne dépend d'un téléchargement réseau. La photo recadrée enregistrée continue à être l'originale, **sans maillot ni couronne**.
- **Info maillots** : rendu simple `KitJersey` inchangé.

## Critères de vérification

- Test de décodage de l'asset et différence des pixels de tissu avec/sans matière, sans opacité peinte sur le visage.
- Test de géométrie pour la suppression du trait horizontal du masque.
- Tous les tests historiques de couleur, du col, des gardiens, du Live et des compositions doivent rester verts.
- **Contrôle visuel à effectuer avec des photos réelles** : PNG détouré, JPEG à fond opaque, visage décentré/barbe/cheveux longs, petit écran Safari iPhone et vidéo. Le rendu « photoréaliste » n'est pas garanti : il s'agit d'une amélioration substantielle basée sur une carte de matière et des reliefs, pas d'un moteur de segmentation ML ou de photomontage 3D.
- **PR #113 (couronne HDM)** distincte : la présente PR ne change pas la couronne, qui doit rester celle de `PhotoCrown` utilisée en composition.

## Impact et sécurité

Flutter UI + asset ; pas de SQL ni de migration, pas de nouveaux packages, pas de coûts, aucune modification de l'AS Grinta original ni de ses données. Aucune publication Cloudflare automatique.

## Déblocage de la PR #114

Le contrôle Flutter échouait sur `le col est plus large et laisse le vrai cou visible` : l'ombre floutée du bord intérieur déposait une opacité de 2/255 dans l'ouverture du cou. Le flou est désormais limité à la bande de tissu du col, sans modifier son intensité ni assouplir l'assertion de transparence. Le test historique couvre les portraits de 90, 180 et 360 pixels. Analyse, tests et compilation Web doivent être relancés sur le commit corrigé avant fusion.
