import 'package:flutter/material.dart';

/// Patron discret de couronne : seul repère conservé avec le maillot réel.
/// Aucun trait horizontal/vertical, ellipse du visage ni étiquette.
/// Le calque n'intercepte aucun geste et n'est jamais inclus dans l'export.
class PortraitAlignmentGuide extends StatelessWidget {
  const PortraitAlignmentGuide({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Semantics(
          label: 'Emplacement de la couronne Homme du match',
          image: true,
          child: const CustomPaint(
            key: ValueKey('portrait-crown-guide'),
            painter: CrownPlacementPainter(),
          ),
        ),
      );
}

/// Silhouette d'une couronne ouverte centrée juste au-dessus de la tête.
/// Ses proportions sont indépendantes du téléphone et du zoom photo.
class CrownPlacementPainter extends CustomPainter {
  const CrownPlacementPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width, size.height);

    // Cinq pointes délicates, un bord légèrement courbé, sans remplissage :
    // le front, les cheveux et le damier restent visibles à travers.
    final outline = Path()
      ..moveTo(.334, .152)
      ..lineTo(.275, .062)
      ..lineTo(.405, .098)
      ..lineTo(.5, .016)
      ..lineTo(.595, .098)
      ..lineTo(.725, .062)
      ..lineTo(.666, .152)
      ..quadraticBezierTo(.5, .164, .334, .152);
    final paint = Paint()
      ..color = const Color(0xE6FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .005
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(outline, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CrownPlacementPainter oldDelegate) => false;
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
