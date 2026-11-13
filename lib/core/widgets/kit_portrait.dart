import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/widgets/kit_pattern_paint.dart';
import 'package:flutter/material.dart';

/// Habille le portrait sans retoucher ni stocker une nouvelle photo. Le visage
/// reste celui de l'image source. Le même repère carré est utilisé au recadrage,
/// sur le terrain et dans la présentation animée.
class KitPortrait extends StatelessWidget {
  const KitPortrait({
    super.key,
    required this.kit,
    required this.child,
    this.isGoalkeeper = false,
  });

  final ClubKit kit;
  final bool isGoalkeeper;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(clipper: const _HeadClipper(), child: child),
          Positioned.fill(
            child: IgnorePointer(
              child: Semantics(
                label: '${isGoalkeeper ? 'Gardien' : 'Joueur'} — ${kit.label}',
                image: true,
                child: CustomPaint(
                  key: ValueKey(
                    'portrait-jersey-${isGoalkeeper ? 'goalkeeper' : 'field'}',
                  ),
                  painter: PortraitJerseyPainter(
                    body: isGoalkeeper ? kit.goalkeeperBody : kit.body,
                    trim: isGoalkeeper ? kit.goalkeeperTrim : kit.trim,
                    pattern: isGoalkeeper ? kit.goalkeeperPattern : kit.pattern,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

class _HeadClipper extends CustomClipper<Path> {
  const _HeadClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    // La photo reste visible dans le col : menton et cou ne sont jamais
    // remplacés par un dessin de maillot.
    return Path()
      ..lineTo(w, 0)
      ..lineTo(w, h * .635)
      ..lineTo(w * .608, h * .635)
      ..lineTo(w * .608, h * .658)
      ..cubicTo(w * .588, h * .695, w * .553, h * .715, w * .5, h * .715)
      ..cubicTo(w * .447, h * .715, w * .412, h * .695, w * .392, h * .658)
      ..lineTo(w * .392, h * .635)
      ..lineTo(0, h * .635)
      ..close();
  }

  @override
  bool shouldReclip(_HeadClipper oldClipper) => false;
}

/// Repères communs à l'aperçu et aux compositions : visage entre 13 et 55 %,
/// base du cou vers 63 %, col près de 71 %. La silhouette conserve le haut
/// du buste et des manches réalistes sans recouvrir le visage.
class PortraitJerseyPainter extends CustomPainter {
  const PortraitJerseyPainter({
    required this.body,
    required this.trim,
    required this.pattern,
  });

  final Color body;
  final Color trim;
  final KitPattern pattern;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width, size.height);

    // Portrait serré, comme une photo officielle de joueur : seules les
    // épaules et le haut de poitrine sont visibles. Les manches, bras et
    // poignets sont volontairement hors cadre, sur tous les formats.
    final shirt = Path()
      ..moveTo(.392, .635)
      ..cubicTo(.334, .641, .276, .659, .218, .686)
      ..cubicTo(.115, .712, .025, .758, -.035, .795)
      ..lineTo(-.035, 1.02)
      ..lineTo(1.035, 1.02)
      ..lineTo(1.035, .795)
      ..cubicTo(.975, .758, .885, .712, .782, .686)
      ..cubicTo(.724, .659, .666, .641, .608, .635)
      ..lineTo(.608, .658)
      ..cubicTo(.588, .695, .553, .715, .5, .715)
      ..cubicTo(.447, .715, .412, .695, .392, .658)
      ..close();

    canvas.save();
    canvas.clipPath(shirt);
    canvas.drawPath(shirt, Paint()..color = body);
    paintKitPattern(
      canvas,
      const Rect.fromLTWH(.12, .635, .76, .365),
      pattern,
      trim,
    );

    // Trois bandes fines sur le DESSUS des épaules, comme le modèle validé.
    // Elles suivent la pente des épaules, jamais les manches ou les bras.
    for (var i = 0; i < 3; i++) {
      final offset = i * .016;
      final stripe = Path()
        ..moveTo(.392 - offset * .5, .648 + offset)
        ..cubicTo(.325 - offset, .657 + offset, .263 - offset,
            .674 + offset, .208 - offset, .697 + offset)
        ..cubicTo(.12 - offset, .72 + offset, .05 - offset,
            .754 + offset, -.035, .807 + offset);
      final stripePaint = Paint()
        ..color = trim
        ..style = PaintingStyle.stroke
        ..strokeWidth = .009
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(stripe, stripePaint);
      canvas.save();
      canvas.translate(1, 0);
      canvas.scale(-1, 1);
      canvas.drawPath(stripe, stripePaint);
      canvas.restore();
    }

    // Modelé textile non destructif : volume de poitrine, ombre aux
    // emmanchures et micro-plis très discrets. Le motif reste visible dessous.
    final shading = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -.32),
        radius: .88,
        colors: [
          Color(0x17FFFFFF),
          Color(0x00000000),
          Color(0x36000000),
        ],
        stops: [0, .57, 1],
      ).createShader(const Rect.fromLTWH(0, .60, 1, .58));
    canvas.drawRect(const Rect.fromLTWH(0, .63, 1, .37), shading);

    final foldPaint = Paint()
      ..color = const Color(0x24000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .011
      ..strokeCap = StrokeCap.round;
    for (final mirror in [false, true]) {
      canvas.save();
      if (mirror) {
        canvas.translate(1, 0);
        canvas.scale(-1, 1);
      }
      canvas.drawPath(
        Path()
          ..moveTo(.20, .755)
          ..cubicTo(.27, .79, .31, .825, .33, .91),
        foldPaint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(.28, .77)
          ..cubicTo(.34, .805, .355, .84, .36, .875),
        Paint()
          ..color = const Color(0x15FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .008,
      );
      canvas.restore();
    }

    // Grain de tissu discret, indépendant de la couleur choisie par le club.
    final weave = Paint()
      ..color = const Color(0x0BFFFFFF)
      ..strokeWidth = .0013;
    for (var y = .74; y < 1; y += .009) {
      canvas.drawLine(Offset(0, y), Offset(1, y), weave);
    }
    canvas.restore();

    // Col en trois couches, légèrement en relief, et non un trait plat.
    final collar = Path()
      ..moveTo(.392, .658)
      ..cubicTo(.414, .695, .449, .724, .5, .724)
      ..cubicTo(.551, .724, .586, .695, .608, .658);
    canvas.drawPath(
      collar,
      Paint()
        ..color = const Color(0x88000000)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = .039,
    );
    canvas.drawPath(
      collar,
      Paint()
        ..color = trim
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = .026,
    );
    canvas.drawPath(
      collar,
      Paint()
        ..color = const Color(0x55FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = .004,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PortraitJerseyPainter oldDelegate) =>
      oldDelegate.body != body ||
      oldDelegate.trim != trim ||
      oldDelegate.pattern != pattern;
}
