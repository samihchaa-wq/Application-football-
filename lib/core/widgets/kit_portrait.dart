import 'dart:ui' as ui;

import 'package:petit_filet/core/club/club_kits.dart';
import 'package:petit_filet/core/widgets/kit_pattern_paint.dart';
import 'package:petit_filet/core/widgets/kit_portrait_silhouette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Habille le portrait sans retoucher ni stocker une nouvelle photo. Le visage
/// reste celui de l'image source. Le même repère carré est utilisé au recadrage,
/// sur le terrain et dans la présentation animée.
class KitPortrait extends StatelessWidget {
  const KitPortrait({
    super.key,
    required this.kit,
    required this.child,
    this.isGoalkeeper = false,
    this.isCoach = false,
  });

  final ClubKit kit;
  final bool isGoalkeeper;

  /// Le coach ne porte pas le maillot du club : il est habillé d'un costume.
  final bool isCoach;
  final Widget child;

  /// Le maillot validé : une carte de lumière (plis, mailles, coutures) et
  /// un masque du col. Les couleurs du club sont appliquées par-dessus, donc
  /// la forme et le tissu restent identiques quelle que soit la tenue.
  /// Décodées une seule fois pour tous les portraits.
  static final Future<_PortraitJerseyImages?> _images = _loadImages();

  static Future<ui.Image> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  /// Costume du coach : même emplacement et même silhouette que le maillot,
  /// fabriqué par tool/gen_portrait_suit.py à partir des plis du maillot.
  static final Future<ui.Image?> _suit = _loadSuit();

  static Future<ui.Image?> _loadSuit() async {
    try {
      return await _decode('assets/composition/portrait_suit.png');
    } catch (_) {
      return null; // repli : costume dessiné en aplat
    }
  }

  static Future<_PortraitJerseyImages?> _loadImages() async {
    try {
      return _PortraitJerseyImages(
        luma: await _decode('assets/composition/portrait_jersey_luma.png'),
        collar: await _decode('assets/composition/portrait_jersey_collar.png'),
      );
    } catch (_) {
      // Degradation gracieuse en mode hors ligne / moteur Flutter réduit.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(clipper: const _HeadClipper(), child: child),
          Positioned.fill(
            child: IgnorePointer(
              child: isCoach
                  ? Semantics(
                      label: 'Coach — costume',
                      image: true,
                      child: FutureBuilder<ui.Image?>(
                        future: _suit,
                        builder: (context, snapshot) => CustomPaint(
                          key: const ValueKey('portrait-suit'),
                          painter: PortraitSuitPainter(image: snapshot.data),
                        ),
                      ),
                    )
                  : Semantics(
                      label:
                          '${isGoalkeeper ? 'Gardien' : 'Joueur'} — ${kit.label}',
                      image: true,
                      child: FutureBuilder<_PortraitJerseyImages?>(
                        future: _images,
                        builder: (context, snapshot) => CustomPaint(
                          key: ValueKey(
                            'portrait-jersey-${isGoalkeeper ? 'goalkeeper' : 'field'}',
                          ),
                          painter: PortraitJerseyPainter(
                            body: isGoalkeeper ? kit.goalkeeperBody : kit.body,
                            trim: isGoalkeeper ? kit.goalkeeperTrim : kit.trim,
                            pattern: isGoalkeeper
                                ? kit.goalkeeperPattern
                                : kit.pattern,
                            luma: snapshot.data?.luma,
                            collar: snapshot.data?.collar,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      );
}

class _PortraitJerseyImages {
  const _PortraitJerseyImages({required this.luma, required this.collar});

  final ui.Image luma;
  final ui.Image collar;
}

/// Patron partagé par la découpe photo et le maillot. Le haut du maillot
/// (épaules, col) est relevé sur le modèle validé ; la photo est découpée
/// exactement sur ce tracé pour éviter les décalages et les vêtements
/// d'origine apparents.
abstract final class _PortraitGeometry {
  /// Le maillot occupe le bas du carré : l'image fournie couvre de 60 % à
  /// 100 % de la hauteur.
  static const jerseyTop = .60;

  /// Marge cachée sous le col : la photo passe juste sous son bord.
  static const _neckOverlap = .004;

  static Offset _point(int index) => Offset(
        portraitSilhouette[index * 2],
        portraitSilhouette[index * 2 + 1],
      );

  /// Ouverture du col : la photo reste visible jusqu'au bord intérieur du col
  /// (le maillot, peint au-dessus, couvre les derniers pixels).
  static Path headClip(Size size) {
    final w = size.width;
    final h = size.height;
    final right = _point(portraitNeckEnd);
    final left = _point(portraitNeckStart);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * .485)
      ..cubicTo(w * .925, h * .520, w * .845, h * .570, w * .777, h * .625)
      ..cubicTo(
          w * .738, h * .640, w * .700, h * .632, w * right.dx, h * right.dy);
    for (var i = portraitNeckEnd; i >= portraitNeckStart; i--) {
      final p = _point(i);
      path.lineTo(w * p.dx, h * (p.dy + _neckOverlap));
    }
    path
      ..lineTo(w * left.dx, h * left.dy)
      ..cubicTo(w * .300, h * .632, w * .262, h * .640, w * .223, h * .625)
      ..cubicTo(w * .155, h * .570, w * .075, h * .520, 0, h * .485)
      ..close();
    return path;
  }

  /// Silhouette complète du maillot en fraction du carré : sert quand les
  /// images ne sont pas encore chargées.
  static Path shirt() {
    final path = Path()..moveTo(0, 1.03);
    final first = _point(0);
    path.lineTo(0, first.dy);
    for (var i = 0; i < portraitSilhouette.length ~/ 2; i++) {
      final p = _point(i);
      path.lineTo(p.dx, p.dy);
    }
    final last = _point(portraitSilhouette.length ~/ 2 - 1);
    path
      ..lineTo(1, last.dy)
      ..lineTo(1, 1.03)
      ..close();
    return path;
  }

  /// Ouverture du col, de pointe à pointe.
  static Path innerCollar() {
    final path = Path();
    for (var i = portraitNeckStart; i <= portraitNeckEnd; i++) {
      final p = _point(i);
      if (i == portraitNeckStart) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path;
  }
}

class _HeadClipper extends CustomClipper<Path> {
  const _HeadClipper();

  @override
  Path getClip(Size size) => _PortraitGeometry.headClip(size);

  @override
  bool shouldReclip(_HeadClipper oldClipper) => false;
}

/// Maillot du portrait. La forme, les plis, les mailles et le col viennent du
/// modèle validé ; les couleurs et le motif sont ceux de la tenue du club.
/// Le visage est toujours la photographie réelle, sans transformation de ses
/// pixels.
class PortraitJerseyPainter extends CustomPainter {
  const PortraitJerseyPainter({
    required this.body,
    required this.trim,
    required this.pattern,
    this.luma,
    this.collar,
  });

  final Color body;
  final Color trim;
  final KitPattern pattern;

  /// Carte de lumière du maillot (gris), son canal alpha est la silhouette.
  final ui.Image? luma;

  /// Masque (alpha) de la bande du col.
  final ui.Image? collar;

  /// La carte de lumière ne sait qu'assombrir : la teinte de départ est
  /// éclaircie d'autant, pour que les zones moyennes retrouvent exactement
  /// la couleur de la tenue.
  static const _lift = 1.18;

  /// Un noir pur multiplié par la carte de lumière reste un aplat noir : plis
  /// et coutures disparaissent et le maillot paraît faux. Les tenues très
  /// sombres sont donc ramenées vers un gris anthracite avant la lumière.
  static Color visibleBody(Color c) {
    final luminance = c.computeLuminance();
    if (luminance >= .06) return c;
    final amount = ((.06 - luminance) / .06).clamp(0.0, 1.0) * .8;
    return Color.lerp(c, const Color(0xFF4B5262), amount)!;
  }

  static Color _lifted(Color c) => Color.from(
        alpha: 1,
        red: (c.r * _lift).clamp(0.0, 1.0),
        green: (c.g * _lift).clamp(0.0, 1.0),
        blue: (c.b * _lift).clamp(0.0, 1.0),
      );

  static Rect _source(ui.Image image) =>
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width, size.height);
    const area = Rect.fromLTWH(
      0,
      _PortraitGeometry.jerseyTop,
      1,
      1 - _PortraitGeometry.jerseyTop,
    );
    final luma = this.luma;
    final collar = this.collar;
    if (luma != null && collar != null) {
      canvas.saveLayer(area, Paint());
      canvas.drawRect(area, Paint()..color = _lifted(visibleBody(body)));
      paintKitPattern(
        canvas,
        const Rect.fromLTWH(0, .64, 1, .38),
        pattern,
        _lifted(trim),
      );
      // Col : la couleur secondaire de la tenue, à la place du corps.
      canvas.drawImageRect(
        collar,
        _source(collar),
        area,
        Paint()
          ..colorFilter = ColorFilter.mode(_lifted(trim), BlendMode.srcIn)
          ..filterQuality = FilterQuality.medium,
      );
      // Lumière, plis et mailles du modèle, puis découpe à sa silhouette.
      canvas.drawImageRect(
        luma,
        _source(luma),
        area,
        Paint()
          ..blendMode = BlendMode.multiply
          ..filterQuality = FilterQuality.medium,
      );
      canvas.drawImageRect(
        luma,
        _source(luma),
        area,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    } else {
      // Images pas encore chargées (ou indisponibles) : même silhouette,
      // en aplat, pour ne jamais laisser la tenue d'origine visible.
      final shirt = _PortraitGeometry.shirt();
      canvas.save();
      canvas.clipPath(shirt);
      canvas.drawPath(shirt, Paint()..color = visibleBody(body));
      paintKitPattern(
        canvas,
        const Rect.fromLTWH(0, .64, 1, .38),
        pattern,
        trim,
      );
      canvas.restore();
      canvas.drawPath(
        _PortraitGeometry.innerCollar().shift(const Offset(0, .015)),
        Paint()
          ..color = trim
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = .03,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PortraitJerseyPainter oldDelegate) =>
      oldDelegate.body != body ||
      oldDelegate.trim != trim ||
      oldDelegate.pattern != pattern ||
      oldDelegate.luma != luma ||
      oldDelegate.collar != collar;
}


/// Costume du coach : veste bleu nuit, chemise blanche, cravate. Même
/// silhouette (épaules, col) que le maillot, pour que la photo soit découpée
/// au même endroit et que le visage ne bouge pas.
class PortraitSuitPainter extends CustomPainter {
  const PortraitSuitPainter({this.image});

  /// Costume photo-réaliste (plis, laine, cravate). Sans lui, aplat dessiné.
  final ui.Image? image;

  static const _jacket = Color(0xFF1C2742);
  static const _jacketLight = Color(0xFF2E3B5E);
  static const _shirt = Color(0xFFF4F6FA);
  static const _tie = Color(0xFFB3202F);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final image = this.image;
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(
          0,
          size.height * _PortraitGeometry.jerseyTop,
          size.width,
          size.height * (1 - _PortraitGeometry.jerseyTop),
        ),
        Paint()..filterQuality = FilterQuality.medium,
      );
      return;
    }
    canvas
      ..save()
      ..scale(size.width, size.height);

    final body = _PortraitGeometry.shirt();
    final collar = _PortraitGeometry.innerCollar().getBounds();
    final left = collar.left;
    final right = collar.right;
    final top = collar.top;
    final mid = (left + right) / 2;
    final bottom = collar.bottom;
    final apexY = bottom + .17;

    // Veste, avec un léger dégradé vertical pour garder du volume.
    canvas
      ..save()
      ..clipPath(body)
      ..drawRect(
        const Rect.fromLTWH(0, _PortraitGeometry.jerseyTop, 1, .45),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_jacketLight, _jacket],
          ).createShader(
            const Rect.fromLTWH(0, _PortraitGeometry.jerseyTop, 1, .45),
          ),
      );

    // Chemise : triangle blanc entre les deux revers.
    final shirt = Path()
      ..moveTo(left - .035, top - .01)
      ..lineTo(right + .035, top - .01)
      ..lineTo(mid, apexY)
      ..close();
    canvas.drawPath(shirt, Paint()..color = _shirt);

    // Cravate : nœud puis lame.
    final knot = Path()
      ..moveTo(mid - .03, bottom - .03)
      ..lineTo(mid + .03, bottom - .03)
      ..lineTo(mid + .02, bottom + .035)
      ..lineTo(mid - .02, bottom + .035)
      ..close();
    final blade = Path()
      ..moveTo(mid - .02, bottom + .035)
      ..lineTo(mid + .02, bottom + .035)
      ..lineTo(mid + .034, apexY + .09)
      ..lineTo(mid, apexY + .13)
      ..lineTo(mid - .034, apexY + .09)
      ..close();
    canvas
      ..drawPath(blade, Paint()..color = _tie)
      ..drawPath(knot, Paint()..color = _tie);

    // Revers : deux bandes plus claires qui bordent la chemise.
    final lapelPaint = Paint()
      ..color = _jacketLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = .016
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(
        Path()
          ..moveTo(left - .035, top - .01)
          ..lineTo(mid, apexY)
          ..lineTo(mid, apexY + .2),
        lapelPaint,
      )
      ..drawPath(
        Path()
          ..moveTo(right + .035, top - .01)
          ..lineTo(mid, apexY)
          ..lineTo(mid, apexY + .2),
        lapelPaint,
      )
      ..restore();

    // Contour fin de la veste.
    canvas
      ..drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .006
          ..color = const Color(0xFF0E1526),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(PortraitSuitPainter oldDelegate) =>
      oldDelegate.image != image;
}
