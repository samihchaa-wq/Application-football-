import 'package:flutter/material.dart';

/// Contenu d'une ligne de menu (`PopupMenuItem`) : une icône et un texte.
///
/// À utiliser à la place d'un `ListTile` dans un `PopupMenuItem` : le
/// `ListTile` ajoute sa propre zone cliquable, qui entre en conflit avec
/// celle de la ligne de menu ; le nom de l'action disparaissait alors de
/// l'arbre d'accessibilité et le lecteur d'écran annonçait des lignes vides.
class PfMenuItemLabel extends StatelessWidget {
  const PfMenuItemLabel({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 16),
        Flexible(child: Text(label)),
      ],
    );
  }
}
