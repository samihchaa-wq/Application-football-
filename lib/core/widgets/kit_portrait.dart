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
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height * .62)
    ..lineTo(size.width * .61, size.height * .62)
    ..lineTo(size.width * .61, size.height * .67)
    ..quadraticBezierTo(
      size.width * .5,
      size.height * .74,
      size.width * .39,
      size.height * .67,
    )
    ..lineTo(size.width * .39, size.height * .62)
    ..lineTo(0, size.height * .62)
    ..close();

  @override
  bool shouldReclip(_HeadClipper oldClipper) => false;
}

/// Coordonnées partagées avec l'ovale/couronne du patron : front à 13 %, menton
/// à 55 %, col à 62 %. Ne recouvre jamais le visage placé dans l'ovale.
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
    final shirt = Path()
      ..moveTo(.39, .62)
      ..cubicTo(.20, .65, .06, .73, 0, .84)
      ..lineTo(0, 1)
      ..lineTo(1, 1)
      ..lineTo(1, .84)
      ..cubicTo(.94, .73, .80, .65, .61, .62)
      ..lineTo(.61, .67)
      ..quadraticBezierTo(.50, .74, .39, .67)
      ..close();
    canvas.save();
    canvas.clipPath(shirt);
    canvas.drawPath(shirt, Paint()..color = body);
    paintKitPattern(
      canvas,
      const Rect.fromLTWH(.12, .62, .76, .38),
      pattern,
      trim,
    );
    // Manches, coutures et col donnent du relief sans remplacer les couleurs.
    final cuffs = Path()
      ..moveTo(0, .85)
      ..lineTo(.17, .80)
      ..lineTo(.20, .86)
      ..lineTo(0, .93)
      ..close()
      ..moveTo(1, .85)
      ..lineTo(.83, .80)
      ..lineTo(.80, .86)
      ..lineTo(1, .93)
      ..close();
    canvas.drawPath(cuffs, Paint()..color = trim);
    canvas.drawRect(
      const Rect.fromLTWH(0, .62, 1, .38),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x22000000), Color(0x00FFFFFF), Color(0x33000000)],
        ).createShader(const Rect.fromLTWH(0, .62, 1, .38)),
    );
    canvas.restore();
    canvas.drawPath(
      Path()
        ..moveTo(.39, .62)
        ..lineTo(.39, .67)
        ..quadraticBezierTo(.50, .74, .61, .67)
        ..lineTo(.61, .62),
      Paint()
        ..color = trim
        ..style = PaintingStyle.stroke
        ..strokeWidth = .035,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PortraitJerseyPainter oldDelegate) =>
      oldDelegate.body != body ||
      oldDelegate.trim != trim ||
      oldDelegate.pattern != pattern;
}
