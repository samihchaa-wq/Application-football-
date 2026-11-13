# Correctif : maillot trop illustré dans le patron photo (13 novembre 2026)

## Constat sur la capture utilisateur

Le rendu précédent avait un col serré en U dessiné par trois traits très épais et trois bandes jaunes forcées sur toutes les épaules ; les lignes sombres du torse ressemblaient davantage à un dessin qu'à un vêtement photographié.

## Correction

- Col physiquement **plus large** : ouverture entre 33,6 % et 66,4 % du carré de portrait (contre 39,2 % et 60,8 %). Bande de tissu en forme fermée, fine et incurvée, sans trois contours opaques. Le col s'ouvre plus bas sur la poitrine.
- `_PortraitGeometry` centralise le tracé du col et celui du masque photo : les pixels du vrai cou sont conservés sans recouvrir le visage ; les anciennes épaules ne réapparaissent pas.
- Silhouette avec **épaules et trapèzes arrondis** ; les extrémités restent hors cadre, comme sur une photo officielle de joueur.
- Couleur du maillot traitée en dégradé de lumière et d'ombre ; motifs club appliqués sous le même modelé ; emmanchures, plis et coutures doux, microtrame discrète. Suppression des **trois bandes éclatantes obligatoires** et des gros traits du torse.
- Les aperçus « Correct / Trop haut / Décalé » du patron utilisent la même découpe que le grand aperçu, pas une photo entière sous un faux maillot.
- `KitJersey` (Infos, Réglages, choix du match) n'est **pas modifié** : son pictogramme reste simple.
- La même couche `KitPortrait` est utilisée en composition avant/pendant/après, en présentation vidéo et en fiche joueur. Les couleurs de gardien et les motifs suivent leurs paramètres.

## Limites et vérification nécessaire

Ce correctif remplace un rendu vectoriel stylisé par un modelé de tissu plus naturel, **mais n'est pas un véritable photomontage textile photoréaliste** ni une segmentation intelligente de la peau. Le résultat dépend de la photo source et de son cadrage. Il faut confronter des portraits PNG transparents / JPEG, joueurs et gardiens, à la capture de référence sur iPhone/PWA avant d'affirmer que le résultat est visuellement satisfaisant.

Tests automatiques : col ouvert au centre, épaule colorée sans trois grosses rayures, visage non peint, continuité du clip photo et export sans incrustation des guides/maillots.

**Aucune migration Supabase, aucune modification d'AS Grinta, aucun déploiement implicite.** Publication Cloudflare distincte.
