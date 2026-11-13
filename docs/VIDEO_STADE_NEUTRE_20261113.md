# Correction vidéo — stade Petit Filet, 13 novembre 2026

## Livrable effectivement commité

- `assets/composition/stade.mp4` : **1080 × 2338**, H.264, 30 images/seconde, 451 images, 15,033 secondes.
- `assets/composition/stade-720.mp4` : **720 × 1558**, H.264, 30 images/seconde, 451 images, 15,033 secondes.
- `assets/composition/stade.jpg` : **inchangé** ; inspection visuelle, aucun texte « AS Grinta » observé.
- Algorithme vérifiable : `scripts/neutralize_stadium_video.py`, source des fichiers originaux commerciaux sur `main`, image de référence neutre du même clip à 3,2 secondes.

**Zone corrigée :** deux bandes de tribunes pendant le premier segment (0 à 3,25 s). Les spectateurs forment initialement les lettres « AS Grinta ». Les bandes sont restaurées depuis la même vidéo après disparition de l'inscription ; bords progressifs, terrain non retouché. Aucun texte ou emblème n'est ajouté.

## Preuves de traitement

- Travail initial local sur les deux formats, rendu de 451 images et vérification de la continuité sur planches à 0,3 / 0,5 / 1 / 1,5 / 2 / 2,5 / 2,9 / 3,1 / 3,17 / 3,25 / 3,5 / 4,5 / 7,5 / 14,5 secondes.
- Action GitHub **Neutral stadium media (branch only)** : génération **réussie** et commit des deux fichiers MP4 dans **cette branche exclusivement**.
- Audit indépendant des visuels et poster : [PR #83](https://github.com/samihchaa-wq/Application-football-/pull/83), extraction ffmpeg et planches de contact (action dédiée réussie).

## Non vérifié / conditions de fusion

- Revoir le raccord dynamique à 3,14–3,25 secondes sur appareil réel (iPhone, Android, PWA) et les variantes de couleur de club.
- Tests Flutter/serveur sur le **HEAD final** de la PR ; publier seulement après revue.
- L'original AS Grinta, sa base et ses médias n'ont jamais été modifiés ; aucune opération Supabase.

**La PR ne vaut pas un déploiement : ses MP4 ne seront utilisés par l'application que si la PR est fusionnée et publiée.**
