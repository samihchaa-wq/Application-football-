# Prototype — 14 fonds premium des badges Petit Filet

Statut : **14 visuels de référence intégrés dans la branche commerciale** ; contrôle technique et publication sécurisée en cours.

## Périmètre

- Refonte des 14 traitements de fond : gris, bronze, argent, or ; bleu clair, bleu, bleu foncé, noir ; orange, rubis, grenat ; diamant ; émeraude, violet.
- Effets peints en Flutter, sans boucle d'animation, sans assets réseau et sans nouvelle dépendance.
- Le composant commun `BadgeEmblem` diffuse les nouveaux traitements dans l'armoire, la fiche joueur, les statistiques, l'administration et les écrans de bilan qui l'utilisent.
- Couleurs `badges.color` d'origine conservées en base ; correspondance en lecture seule par `badgePremiumSkinFor`.
- Texte **entièrement dynamique** : valeur, critère, période, nom long, étoiles et progression ne sont pas réécrits.

## Correspondance sans migration

| Ancienne valeur `color` | Prototype | Groupe |
| --- | --- | --- |
| #6E7A86 / #7A858D | Gris acier | Saison |
| #B87333 / #CD7F32 | Bronze | Saison |
| #C4CBD4 / #C0C0C0 | Argent | Saison |
| #E3B23C / #D4AF37 | Or | Saison |
| #4FA9E8 | Bleu clair | Historique |
| #1E3A8A | Bleu | Historique |
| #7C3AED | Bleu foncé | Historique |
| #1C1C24 | Noir obsidienne | Historique |
| #F1706E | Orange | Exploits |
| #E23B36 | Rubis | Exploits |
| #9E1B1B | Grenat | Exploits |
| #5FC9D9 / #B9F2FF | Diamant | Titres |
| #F2811D | Émeraude | Spéciaux |
| #F97316 | Violet | Mystères |

**Attention** : la correspondance par couleur n'est valable que pour le catalogue observé. Avant production, vérifier si des badges ajoutés manuellement portent d'autres couleurs, ou si certaines catégories réutilisent les mêmes codes couleur. Un futur paramètre explicite `skin_id` serait plus robuste ; il nécessiterait une migration revue séparément.

## Limite majeure : photos déjà composites

Certaines images de badges dans `badge-images` sont des JPEG **opaques** avec l'ancien fond directement imprimé. Dans ces cas, le nouveau fond JPEG placé **derrière** la photo ne sera pas visible au travers du portrait : l'app fournit toujours le cadre et le socle premium sans modifier le visage. Les images détourées transparentes laissent apparaître le nouveau fond.

**Les 14 visuels sont désormais intégrés** sous forme de JPEG légers recadrés dans la planche de référence choisie par le propriétaire. Les fonds de remplacement proviennent des visuels approuvés, et non plus seulement des effets dessinés en Flutter. Les recadrages ne sont pas des masters natifs haute résolution.

Après validation visuelle, il faudra soit :
1. récupérer des originaux détourés fiables, puis placer les illustrations transparentes sur les fonds ;
2. ou reconstruire chaque image composite avec validation humaine, sans altérer les visages.

Ne pas faire de conversion destructive automatique de la production.

## Comportements préservés

- Même hauteur d'emblème (`1.48 × largeur` sans étoile) et de socle, même ordre : illustration → valeur → critère → période.
- Valeur/texte blanc avec contour noir, textes longs adaptés par les composants historiques.
- Étoiles, cadenas, état noir et blanc, badge nouveau et badge arboré.
- Même moteur d'attribution et de déblocage, mêmes données sportives et `profile_badges`.
- Les fonds inconnus (couleurs non reconnues) conservent l'ancien rendu.

## Recette obligatoire avant fusion

- `flutter analyze`
- `flutter test test/features/badges/presentation/badge_emblem_body_test.dart`
- `flutter test test/features/badges/presentation/badge_premium_skins_test.dart`
- `flutter test test/features/badges/`
- Captures des 14 variantes **avec images de joueurs réelles** à 46, 81, 87, 123 px.
- Vérifier iPhone étroit, tablette, PWA, zoom du texte, noms très longs et contraste.
- Vérifier mystères jamais gagnés, connus du club, gagnés, étoilés et arborés.
- Vérifier que le rendu des photos JPEG opaques est jugé acceptable ; sinon ne pas fusionner.

## Garantie de périmètre

Aucune migration SQL, aucune modification des données métier ni aucun téléversement Storage depuis cette PR. La publication éventuelle est effectuée uniquement par le workflow commercial sécurisé après fusion. Le dépôt original AS Grinta et ses données ne sont jamais modifiés.

## Intégration des fonds issus de la planche de référence

- La planche finale de 14 cartes vides du propriétaire a été découpée en images individuelles, nettoyées des titres et encadrés d'infographie, puis encodées en JPEG 180 × 240 légers. Cela reproduit la **texture de la planche**, mais ne constitue pas des masters natifs haute résolution.
- Les 14 fichiers se trouvent dans `assets/images/badge_backgrounds/`. Une correspondance explicite dans `badgePremiumBackgroundAsset` relie chaque famille au bon fichier, sans réécriture SQL ni changement de palmarès.
- Le socle texte conserve le calcul dynamique et un voile sombre semi-transparent pour rester lisible. Les illustrations de joueurs restent au-dessus. Les anciens JPEG opaques contenant déjà leur arrière-plan masqueront encore la texture sous la photo : il faudra les détourer un jour avec l'accord de leur propriétaire.
- Le workflow `badges_visual_qa.yml` exécute `scripts/render_badge_gallery.py` et fournit l'artefact `badges-14-fonds-gallery` : il vérifie les **14 fichiers JPEG réels**, leur décodage et leurs proportions, et affiche leurs textures sans joueur. La suite Flutter vérifie la correspondance des 14 assets, la mise en page des valeurs dynamiques, les intitulés et les badges mystères. Cette galerie **n'est pas une capture de l'application avec photos réelles** : la limite des anciens portraits opaques reste documentée.
