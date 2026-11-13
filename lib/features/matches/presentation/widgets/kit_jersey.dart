import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/widgets/kit_pattern_paint.dart';
import 'package:flutter/material.dart';

/// Pictogramme simple et lisible pour « Info maillots », le choix du match
/// et l'administration : couleurs et motif, sans simulation de textile.
/// Le portrait habillé utilise séparément KitPortrait et son rendu naturel.
class KitJersey extends StatelessWidget {
  const KitJersey({
    required this.kit,
    this.isGoalkeeper = false,
    this.semanticLabel,
    super.key,
  });

  final ClubKit kit;
  final bool isGoalkeeper;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ??
          (isGoalkeeper
              ? 'Maillot gardien ${kit.label}'
              : 'Maillot ${kit.label}'),
      image: true,
      child: AspectRatio(
        aspectRatio: _KitJerseyPainter.width / _KitJerseyPainter.height,
        child: CustomPaint(
          painter: _KitJerseyPainter(
            body: isGoalkeeper ? kit.goalkeeperBody : kit.body,
            trim: isGoalkeeper ? kit.goalkeeperTrim : kit.trim,
            pattern: isGoalkeeper ? kit.goalkeeperPattern : kit.pattern,
          ),
        ),
      ),
    );
  }
}

class _KitJerseyPainter extends CustomPainter {
  _KitJerseyPainter({
    required this.body,
    required this.trim,
    required this.pattern,
  });

  // Repère du dessin (même proportions que les anciennes illustrations).
  static const double width = 520;
  static const double height = 600;

  final Color body;
  final Color trim;
  final KitPattern pattern;

  static Color _shade(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  static Path _shirt() => Path()
    ..moveTo(190, 28)
    ..quadraticBezierTo(260, 70, 330, 28)
    ..lineTo(430, 60)
    ..quadraticBezierTo(490, 85, 502, 200)
    ..lineTo(418, 232)
    ..lineTo(405, 152)
    ..lineTo(405, 560)
    ..quadraticBezierTo(405, 580, 385, 580)
    ..lineTo(135, 580)
    ..quadraticBezierTo(115, 580, 115, 560)
    ..lineTo(115, 152)
    ..lineTo(102, 232)
    ..lineTo(18, 200)
    ..quadraticBezierTo(30, 85, 90, 60)
    ..close();

  static Path _cuffs() => Path()
    ..moveTo(410, 190)
    ..lineTo(496, 163)
    ..lineTo(502, 200)
    ..lineTo(418, 232)
    ..close()
    ..moveTo(110, 190)
    ..lineTo(24, 163)
    ..lineTo(18, 200)
    ..lineTo(102, 232)
    ..close();

  static Path _collar() => Path()
    ..moveTo(190, 28)
    ..quadraticBezierTo(260, 70, 330, 28)
    ..quadraticBezierTo(326, 64, 260, 74)
    ..quadraticBezierTo(194, 64, 190, 28)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / width) < (size.height / height)
        ? size.width / width
        : size.height / height;
    canvas
      ..save()
      ..translate(
        (size.width - width * scale) / 2,
        (size.height - height * scale) / 2,
      )
      ..scale(scale);

    final shirt = _shirt();
    // Contour plus foncé que le maillot ; plus clair pour un maillot très
    // sombre, qui resterait sinon invisible sur le fond de l'application.
    final luminance = body.computeLuminance();
    final outline = luminance < .03
        ? _shade(body, -.28)
        : _shade(body, luminance > .5 ? .35 : .18);

    canvas
      ..drawPath(shirt, Paint()..color = body)
      ..save()
      ..clipPath(shirt);
    paintKitPattern(
      canvas,
      const Rect.fromLTWH(115, 28, 290, 552),
      pattern,
      trim,
    );
    canvas
      ..drawPath(_cuffs(), Paint()..color = trim)
      ..drawPath(_collar(), Paint()..color = trim)
      ..restore()
      ..drawPath(
        shirt,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeJoin = StrokeJoin.round
          ..color = outline,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_KitJerseyPainter oldDelegate) =>
      oldDelegate.body != body ||
      oldDelegate.trim != trim ||
      oldDelegate.pattern != pattern;
}
