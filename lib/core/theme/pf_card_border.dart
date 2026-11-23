import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Contour et fond travaillés des cartes « Nuit » : un dégradé de lumière
/// qui part du coin haut-gauche, un liseré lumineux en haut, et un très
/// discret tracé de terrain (rond central et ligne médiane) dans le coin bas
/// droit. Tout est peint derrière le contenu : rien ne bouge dans la mise en
/// page.
class PfCardBorder extends ShapeBorder {
  const PfCardBorder({
    required this.radius,
    required this.borderColor,
    this.borderWidth = 1,
  });

  final double radius;
  final Color borderColor;
  final double borderWidth;

  RRect _rrect(Rect rect) =>
      RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect.deflate(borderWidth)));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (rect.isEmpty) return;
    final rrect = _rrect(rect);
    canvas.save();
    canvas.clipRRect(rrect);

    // Lumière diagonale.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .075),
            Colors.white.withValues(alpha: .0),
            Colors.black.withValues(alpha: .10),
          ],
          stops: const [0, .5, 1],
        ).createShader(rect),
    );

    // Tracé de terrain, en bas à droite.
    final motif = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: .055);
    final r = math.min(rect.height * .55, 74.0);
    final c = Offset(rect.right - r * .55, rect.bottom - r * .35);
    canvas.drawCircle(c, r, motif);
    canvas.drawLine(
      Offset(c.dx - r * 1.6, c.dy + r * 1.2),
      Offset(c.dx + r * 1.6, c.dy - r * 1.2),
      motif,
    );
    canvas.drawCircle(c, 2.2, motif..style = PaintingStyle.fill);

    // Liseré lumineux en haut.
    canvas.drawLine(
      Offset(rect.left + radius, rect.top + .5),
      Offset(rect.right - radius, rect.top + .5),
      Paint()
        ..strokeWidth = 1
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: .26),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
    canvas.restore();

    // Contour.
    if (borderWidth > 0) {
      canvas.drawRRect(
        rrect.deflate(borderWidth / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..color = borderColor,
      );
    }
  }

  @override
  ShapeBorder scale(double t) => PfCardBorder(
        radius: radius * t,
        borderColor: borderColor,
        borderWidth: borderWidth * t,
      );
}
