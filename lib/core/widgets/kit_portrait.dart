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

    // Épaules en pente, emmanchures et manches courtes. Les anciennes courbes
    // jusqu'aux bords formaient un demi-cercle, pas un haut de maillot.
    final shirt = Path()
      ..moveTo(.392, .635)
      ..cubicTo(.334, .641, .276, .659, .218, .686)
      ..cubicTo(.113, .711, .03, .761, -.018, .82)
      ..lineTo(-.045, 1.02)
      ..lineTo(1.045, 1.02)
      ..lineTo(1.018, .82)
      ..cubicTo(.97, .761, .887, .711, .782, .686)
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

    // Les bandes de finition sont placées sur les manches, et non au milieu
    // d'une forme ovale. Le haut des bras reste majoritairement couleur corps.
    final leftCuff = Path()
      ..moveTo(-.014, .852)
      ..cubicTo(.045, .825, .11, .819, .173, .844)
      ..lineTo(.161, .883)
      ..cubicTo(.10, .859, .044, .865, -.019, .9)
      ..close();
    final cuffPaint = Paint()..color = trim;
    canvas.drawPath(leftCuff, cuffPaint);
    canvas.save();
    canvas.translate(1, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(leftCuff, cuffPaint);
    canvas.restore();

    // Une couture fine sépare chaque manche du corps, symétriquement.
    final sleeveSeam = Path()
      ..moveTo(.22, .686)
      ..cubicTo(.245, .747, .258, .79, .253, .845);
    final seamPaint = Paint()
      ..color = const Color(0x50000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .009
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(sleeveSeam, seamPaint);
    canvas.save();
    canvas.translate(1, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(sleeveSeam, seamPaint);
    canvas.restore();

    canvas.drawRect(
      const Rect.fromLTWH(0, .63, 1, .37),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0x19000000),
            Color(0x08FFFFFF),
            Color(0x00000000),
            Color(0x08FFFFFF),
            Color(0x19000000),
          ],
        ).createShader(const Rect.fromLTWH(0, .63, 1, .37)),
    );
    canvas.restore();

    // Col rond ajusté : liseré fin, posé contre le cou photographié.
    final collar = Path()
      ..moveTo(.392, .658)
      ..cubicTo(.414, .695, .449, .724, .5, .724)
      ..cubicTo(.551, .724, .586, .695, .608, .658);
    canvas.drawPath(
      collar,
      Paint()
        ..color = const Color(0x64000000)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = .027,
    );
    canvas.drawPath(
      collar,
      Paint()
        ..color = trim
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = .017,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PortraitJerseyPainter oldDelegate) =>
      oldDelegate.body != body ||
      oldDelegate.trim != trim ||
      oldDelegate.pattern != pattern;
}
