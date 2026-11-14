import 'package:as_grinta/core/widgets/match_contribution_icons.dart';
import 'package:flutter/material.dart';

/// Patron de l'Étoile du match : utilise EXACTEMENT la couronne du terrain.
///
/// Sa largeur et sa hauteur de police sont définies par [PhotoCrown], le
/// composant posé sur les vrais hommes du match en composition. L'éditeur
/// ajoute au-dessus du carré photo le débord correspondant à
/// [-PhotoCrown.topOffset] : rien n'est coupé par le cadre de recadrage.
///
/// Cette prévisualisation n'intercepte pas les gestes et n'est jamais
/// enregistrée dans la photo.
class PortraitAlignmentGuide extends StatelessWidget {
  const PortraitAlignmentGuide({
    super.key,
    required this.photoSize,
  });

  final double photoSize;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Semantics(
          label: 'Couronne Homme du match, à la même place que sur le terrain',
          image: true,
          child: Center(
            heightFactor: 1,
            child: PhotoCrown(
              key: const ValueKey('portrait-crown-guide'),
              photoSize: photoSize,
            ),
          ),
        ),
      );
}

/// Le damier montre la transparence réelle sans la remplacer par du blanc.
class TransparentPhotoBackground extends StatelessWidget {
  const TransparentPhotoBackground({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _CheckerboardPainter());
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF343B44));
    final paint = Paint()..color = const Color(0xFF424A54);
    const cells = 16;
    final w = size.width / cells;
    final h = size.height / cells;
    for (var y = 0; y < cells; y++) {
      for (var x = y.isEven ? 0 : 1; x < cells; x += 2) {
        canvas.drawRect(Rect.fromLTWH(x * w, y * h, w, h), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) => false;
}
