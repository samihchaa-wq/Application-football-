# Recadrage de photo minimal — deux patrons uniquement

Décision utilisateur du 14 novembre 2026. Implémentée dans `photo_crop_preview.dart` et `portrait_alignment_guide.dart`.

## Affichage demandé
- **Patron de maillot réaliste** : la tenue de l'équipe (joueur ou gardien) se superpose sous le cou, sans modifier la photo.
- **Patron de couronne « Homme du match »** : contour fin, centré au-dessus de la tête. Il est seulement un repère de cadrage et **n'est pas exporté**.
- Le damier de transparence, le déplacement et le zoom sont conservés.

## Éléments supprimés
- Carte d'explication « Patron de cadrage » et texte associé.
- Carte « Conseils ».
- Exemples « Correct », « Trop haut », « Décalé ».
- Bloc « Aperçu final ».
- Pointillés horizontaux et verticaux, hauteur des yeux, sommet de la tête, base du menton, ligne « Haut du maillot », ellipse de visage et coins d'alignement.

## Comportement technique
- Fenêtre compacte, un seul aperçu manipulable et les boutons de confirmation/annulation.
- L'export PNG/JPEG reste calculé **exclusivement à partir de la photo d'origine et de sa matrice de recadrage** ; aucun guide, maillot ou couronne n'est enregistré.
- `CrownPlacementPainter` dessine uniquement le contour de la couronne : il ne participe pas aux gestes et ne modifie ni portrait ni photos sur disque.
- Le pictogramme du maillot dans « Info » reste inchangé.
- Aucune modification Supabase ni de l'application AS Grinta d'origine.

## Contrôles
Tests Flutter sur la présence des deux calques, l'absence des libellés et panneaux supprimés, la transparence du patron hors couronne, le déplacement sous les patrons et l'intégrité des pixels exportés.
Validation visuelle sur Safari iOS/PWA : encore à effectuer après publication de la PR.
