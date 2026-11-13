# Média du stade neutre — contrôle préalable obligatoire

Problème de l'[issue #71](https://github.com/samihchaa-wq/Application-football-/issues/71) : les mots **AS Grinta** sont incrustés dans les pixels des vidéos. Les renommer ou recolorer la scène **ne retire pas** ces inscriptions.

Commande : `bash scripts/audit_stadium_media.sh`.

La CI `Stadium media visual audit` produit des planches contact et un poster pour comparer les deux versions MP4 à cinq instants. **Cette PR ne modifie aucun média**. Le binaire source `stade.mp4` et sa version 720p doivent être retouchés visuellement sur leurs frames, puis réencodés et publiés avec le poster corrigé. Ne pas substituer une vidéo d'un autre club ou un rectangle de cache.

Critères avant clôture :
- Aucune inscription AS Grinta dans les tribunes, ni sur les écrans de stade, drapeaux, affiches ou public ; **pas de texte remplaçant**.
- Même durée, scènes et cadence, codecs web compatibles.
- Poster `stade.jpg` cohérent avec la vidéo ; aucune version non corrigée disponible dans le fallback.
- Les couleurs du club, l'animation, les compositions et la PWA fonctionnent toujours.
- Revue des planches à au moins 5 instants **par version** ; validation visuelle sur téléphone et navigateur.

Sans accès à un outil de retouche vidéo qui puisse écrire les trois binaires, ne pas annoncer le média comme corrigé. Aucun changement AS Grinta original. Aucun coût ni déploiement implicite.
