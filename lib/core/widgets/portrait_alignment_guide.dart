import 'package:flutter/material.dart';

/// Guides d'alignement de la photo du joueur. Purement visuels : ne sont
/// jamais incrustés dans le fichier exporté.
class PortraitAlignmentGuide extends StatelessWidget {
  const PortraitAlignmentGuide({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth;
            return Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _AlignmentPainter()),
                for (final entry in <(String, double)>[
                  ('Sommet de la tête', .19),
                  ('Hauteur des yeux', .35),
                  ('Base du menton', .57),
                  ('Haut du maillot', .72),
                ])
                  Positioned(
                    left: 5,
                    top: side * entry.$2 - 11,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xE60A1420),
                        border: Border.all(color: Colors.white70),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        child: Text(
                          entry.$1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
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

class _AlignmentPainter extends CustomPainter {
  const _AlignmentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final dash = Paint()
      ..color = const Color(0xAAFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    void dashed(Offset a, Offset b) {
      final line = b - a;
      final length = line.distance;
      final direction = line / length;
      for (double d = 0; d < length; d += 11) {
        canvas.drawLine(a + direction * d,
            a + direction * (d + 5).clamp(0, length).toDouble(), dash);
      }
    }

    for (final level in [.19, .35, .57, .72]) {
      dashed(Offset(0, size.height * level),
          Offset(size.width, size.height * level));
    }
    dashed(Offset(size.width * .5, 0), Offset(size.width * .5, size.height));

    final face = Path()
      ..moveTo(.31 * size.width, .34 * size.height)
      ..cubicTo(.27 * size.width, .20 * size.height, .36 * size.width,
          .12 * size.height, .5 * size.width, .12 * size.height)
      ..cubicTo(.64 * size.width, .12 * size.height, .73 * size.width,
          .20 * size.height, .69 * size.width, .34 * size.height)
      ..cubicTo(.76 * size.width, .32 * size.height, .75 * size.width,
          .43 * size.height, .69 * size.width, .44 * size.height)
      ..cubicTo(.67 * size.width, .51 * size.height, .59 * size.width,
          .57 * size.height, .5 * size.width, .57 * size.height)
      ..cubicTo(.41 * size.width, .57 * size.height, .33 * size.width,
          .51 * size.height, .31 * size.width, .44 * size.height)
      ..cubicTo(.25 * size.width, .43 * size.height, .24 * size.width,
          .32 * size.height, .31 * size.width, .34 * size.height)
      ..close();
    canvas.drawPath(face, white);

    final corner = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final w = size.width;
    final h = size.height;
    for (final (origin, dx, dy) in <(Offset, double, double)>[
      (const Offset(8, 8), 1, 1),
      (Offset(w - 8, 8), -1, 1),
      (Offset(8, h - 8), 1, -1),
      (Offset(w - 8, h - 8), -1, -1),
    ]) {
      canvas.drawLine(origin, origin.translate(dx * 20, 0), corner);
      canvas.drawLine(origin, origin.translate(0, dy * 20), corner);
    }
  }

  @override
  bool shouldRepaint(covariant _AlignmentPainter oldDelegate) => false;
}
