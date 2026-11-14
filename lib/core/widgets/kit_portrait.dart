import 'dart:ui' as ui;

import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/widgets/kit_pattern_paint.dart';
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
  });

  final ClubKit kit;
  final bool isGoalkeeper;
  final Widget child;

  /// Une seule texture, décodée une fois pour toutes les fiches, les joueurs
  /// de l'effectif et les compositions. Aucun appel réseau ni traitement du
  /// visage. Le maillot vectoriel reste disponible si l'asset tarde.
  static final Future<ui.Image?> _fabricMaterial = _loadFabricMaterial();

  static Future<ui.Image?> _loadFabricMaterial() async {
    try {
      final data =
          await rootBundle.load('assets/composition/jersey_fabric_luma.png');
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
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
              child: Semantics(
                label: '${isGoalkeeper ? 'Gardien' : 'Joueur'} — ${kit.label}',
                image: true,
                child: FutureBuilder<ui.Image?>(
                  future: _fabricMaterial,
                  builder: (context, snapshot) => CustomPaint(
                    key: ValueKey(
                      'portrait-jersey-${isGoalkeeper ? 'goalkeeper' : 'field'}',
                    ),
                    painter: PortraitJerseyPainter(
                      body: isGoalkeeper ? kit.goalkeeperBody : kit.body,
                      trim: isGoalkeeper ? kit.goalkeeperTrim : kit.trim,
                      pattern: isGoalkeeper ? kit.goalkeeperPattern : kit.pattern,
                      material: snapshot.data,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

/// Patron partagé par la découpe photo et le tissu. Le bord intérieur du
/// col et la découpe du cou ont EXACTEMENT le même tracé pour éviter les
/// décalages et les vêtements d'origine apparents.
abstract final class _PortraitGeometry {
  static const neckLeft = .336;
  static const neckRight = .664;

  /// Ouverture arrondie et large : 33 % du portrait entre les deux attaches.
  /// La photo reste visible jusqu'au bord intérieur, sans fausse peau.
  static Path headClip(Size size) {
    final w = size.width;
    final h = size.height;
    // L'ancien tracé quittait le bord par une grande ligne HORIZONTALE
    // à 61,3 % et coupait net la mâchoire des joueurs au visage large.
    // Cette silhouette organique se resserre derrière la mâchoire, puis
    // rejoint exactement l'ouverture intérieure du col. Aucun angle droit.
    return Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * .485)
      ..cubicTo(w * .925, h * .520, w * .845, h * .570, w * .777, h * .625)
      ..cubicTo(w * .738, h * .662, w * .704, h * .683,
          w * neckRight, h * .655)
      ..cubicTo(w * .637, h * .711, w * .585, h * .744, w * .5, h * .748)
      ..cubicTo(w * .415, h * .744, w * .363, h * .711, w * neckLeft, h * .655)
      ..cubicTo(w * .296, h * .683, w * .262, h * .662, w * .223, h * .625)
      ..cubicTo(w * .155, h * .570, w * .075, h * .520, 0, h * .485)
      ..close();
  }

  /// Silhouette de buste : épaules arrondies, trapèzes et manches hors champ.
  /// Contrairement à l'ancien patron, le dessus n'est pas un triangle plat.
  static Path shirt() => Path()
    ..moveTo(neckLeft, .640)
    ..cubicTo(.284, .644, .241, .655, .196, .675)
    ..cubicTo(.111, .706, .039, .746, -.025, .788)
    ..lineTo(-.025, 1.03)
    ..lineTo(1.025, 1.03)
    ..lineTo(1.025, .788)
    ..cubicTo(.961, .746, .889, .706, .804, .675)
    ..cubicTo(.759, .655, .716, .644, neckRight, .640)
    ..lineTo(neckRight, .655)
    ..cubicTo(.637, .711, .585, .744, .5, .748)
    ..cubicTo(.415, .744, .363, .711, neckLeft, .655)
    ..close();

  /// Bande souple de col côtelé, réellement plus ouverte que l'ancien
  /// anneau épais en demi-cercle. La partie intérieure suit headClip.
  static Path collar() => Path()
    ..moveTo(.316, .642)
    ..cubicTo(.343, .728, .410, .776, .5, .777)
    ..cubicTo(.590, .776, .657, .728, .684, .642)
    ..lineTo(neckRight, .655)
    ..cubicTo(.637, .711, .585, .744, .5, .748)
    ..cubicTo(.415, .744, .363, .711, neckLeft, .655)
    ..close();

  static Path innerCollar() => Path()
    ..moveTo(neckLeft, .655)
    ..cubicTo(.363, .711, .415, .744, .5, .748)
    ..cubicTo(.585, .744, .637, .711, neckRight, .655);
}

class _HeadClipper extends CustomClipper<Path> {
  const _HeadClipper();

  @override
  Path getClip(Size size) => _PortraitGeometry.headClip(size);

  @override
  bool shouldReclip(_HeadClipper oldClipper) => false;
}

/// Habillage procédural à la taille du portrait. Le rendu Info reste le
/// pictogramme KitJersey ; ici la lumière, les plis et les coutures
/// sont peints sur un buste aux épaules arrondies. Le visage est toujours
/// la photographie réelle, sans transformation de ses pixels.
class PortraitJerseyPainter extends CustomPainter {
  const PortraitJerseyPainter({
    required this.body,
    required this.trim,
    required this.pattern,
    this.material,
  });

  final Color body;
  final Color trim;
  final KitPattern pattern;
  final ui.Image? material;

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width, size.height);

    final shirt = _PortraitGeometry.shirt();
    canvas.save();
    canvas.clipPath(shirt);

    // Teinte de base plus photographique : le centre capte la lumière,
    // les flancs, l'emmanchure et les manches tombent dans l'ombre.
    canvas.drawPath(
      shirt,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0, .18, .44, .62, .82, 1],
          colors: [
            _mix(body, Colors.black, .24),
            _mix(body, Colors.black, .10),
            _mix(body, Colors.white, .055),
            _mix(body, Colors.white, .025),
            _mix(body, Colors.black, .13),
            _mix(body, Colors.black, .29),
          ],
        ).createShader(const Rect.fromLTWH(0, .625, 1, .4)),
    );

    paintKitPattern(
      canvas,
      const Rect.fromLTWH(0, .64, 1, .38),
      pattern,
      trim,
    );

    // Le modelé doit éclairer aussi les motifs : une bande imprimée est
    // sur le même textile, elle ne flotte pas par-dessus sa matière.
    canvas.drawRect(
      const Rect.fromLTWH(0, .64, 1, .38),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0, .18, .47, .73, 1],
          colors: [
            Color(0x40000000),
            Color(0x07000000),
            Color(0x14FFFFFF),
            Color(0x0C000000),
            Color(0x46000000),
          ],
        ).createShader(const Rect.fromLTWH(0, .64, 1, .38)),
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, .64, 1, .38),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, .27, .68, 1],
          colors: [
            Color(0x10FFFFFF),
            Color(0x06FFFFFF),
            Color(0x00000000),
            Color(0x22000000),
          ],
        ).createShader(const Rect.fromLTWH(0, .64, 1, .38)),
    );

    // Matière tricotée : carte de luminance 256px réutilisée pour tous les
    // portraits. Le mode multiply garde les véritables couleurs et motifs
    // du club, mais leur applique les mêmes micro-ombres et le relief.
    // Les composants du maillot (dont le col) restent parfaitement nets.
    if (material != null) {
      canvas.drawImageRect(
        material!,
        Rect.fromLTWH(
          0,
          0,
          material!.width.toDouble(),
          material!.height.toDouble(),
        ),
        const Rect.fromLTWH(0, 0, 1, 1),
        Paint()
          ..blendMode = BlendMode.multiply
          ..colorFilter = const ColorFilter.mode(
            Color(0xAFFFFFFF),
            BlendMode.modulate,
          )
          ..filterQuality = FilterQuality.medium,
      );
    }

    // Pli de tissu près de l'emmanchure : une ombre fondue plutôt qu'une
    // ligne épaisse qui dessinerait un torse de bande dessinée.
    for (final reflected in [false, true]) {
      canvas.save();
      if (reflected) {
        canvas.translate(1, 0);
        canvas.scale(-1, 1);
      }
      final armShadow = Path()
        ..moveTo(.153, .71)
        ..cubicTo(.218, .762, .252, .813, .278, .941)
        ..cubicTo(.242, .835, .197, .771, .137, .731)
        ..close();
      canvas.drawPath(
        armShadow,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x00000000),
              Color(0x36000000),
              Color(0x00000000),
            ],
          ).createShader(const Rect.fromLTWH(.13, .69, .18, .29)),
      );

      final underArm = Path()
        ..moveTo(.015, .789)
        ..cubicTo(.078, .764, .109, .753, .145, .738)
        ..cubicTo(.134, .779, .127, .824, .107, .865)
        ..cubicTo(.079, .829, .051, .807, .015, .789)
        ..close();
      canvas.drawPath(
        underArm,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.5, -.3),
            radius: 1,
            colors: [Color(0x36000000), Color(0x00000000)],
          ).createShader(const Rect.fromLTWH(.005, .73, .18, .16)),
      );

      final lightFold = Path()
        ..moveTo(.264, .81)
        ..cubicTo(.328, .842, .354, .897, .356, 1.04)
        ..cubicTo(.338, .908, .316, .862, .256, .825)
        ..close();
      canvas.drawPath(
        lightFold,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0x00FFFFFF),
              Color(0x17FFFFFF),
              Color(0x00FFFFFF),
            ],
          ).createShader(const Rect.fromLTWH(.25, .8, .12, .22)),
      );
      canvas.restore();
    }

    // L'asset de tricot remplace l'ancien quadrillage de traits plats.
    // Garder une microtrame légère uniquement en cas de chargement impossible
    // garantit un maillot lisible même sans asset.
    if (material == null) {
      final yarn = Paint()
        ..color = const Color(0x0BFFFFFF)
        ..strokeWidth = .00065;
      for (var y = .705; y < 1.01; y += .008) {
        canvas.drawLine(Offset(0, y), Offset(1, y), yarn);
      }
    }

    // Volume textile central : les zones d'ombre sont fondues au lieu de
    // traits dessinés au feutre. Les replis suivent la pente des épaules.
    for (final reflected in [false, true]) {
      canvas.save();
      if (reflected) {
        canvas.translate(1, 0);
        canvas.scale(-1, 1);
      }
      final clavicle = Path()
        ..moveTo(.30, .686)
        ..cubicTo(.278, .725, .301, .755, .336, .784);
      canvas.drawPath(
        clavicle,
        Paint()
          ..color = const Color(0x27000000)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = .018
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .009),
      );
      canvas.drawPath(
        clavicle.shift(const Offset(.020, -.004)),
        Paint()
          ..color = const Color(0x1BFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .009
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .007),
      );
      final chestDrape = Path()
        ..moveTo(.379, .809)
        ..cubicTo(.341, .861, .336, .915, .354, 1.02);
      canvas.drawPath(
        chestDrape,
        Paint()
          ..color = const Color(0x17000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .023
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .015),
      );
      canvas.restore();
    }
    canvas.restore();

    // Coutures textiles fondues sur l'épaule, sans bandes fluo permanentes.
    // Le motif du club assure les éventuelles rayures visibles.
    for (final reflected in [false, true]) {
      canvas.save();
      if (reflected) {
        canvas.translate(1, 0);
        canvas.scale(-1, 1);
      }
      final shoulder = Path()
        ..moveTo(.326, .653)
        ..cubicTo(.282, .664, .224, .682, .174, .71)
        ..cubicTo(.106, .745, .063, .774, .012, .808);
      canvas.drawPath(
        shoulder,
        Paint()
          ..color = const Color(0x27000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .003,
      );
      canvas.drawPath(
        shoulder.shift(const Offset(0, -.003)),
        Paint()
          ..color = const Color(0x18FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .0014,
      );
      canvas.restore();
    }

    // D'abord l'ombre d'insertion sous le bord du col. Elle donne du
    // volume au tissu sans poser de halo autour de la peau.
    final collarBand = _PortraitGeometry.collar();
    canvas.drawPath(
      collarBand,
      Paint()
        ..color = const Color(0x28000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .007,
    );
    canvas.drawPath(
      collarBand,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, .43, 1],
          colors: [
            _mix(trim, Colors.black, .18),
            _mix(trim, Colors.white, .05),
            _mix(trim, Colors.black, .22),
          ],
        ).createShader(const Rect.fromLTWH(.315, .64, .37, .14)),
    );

    // Relief côtelé très discret : chaque maille reprend exactement la
    // couleur du col. Le patron parait cousu plutôt que posé en anneau plat.
    canvas.save();
    canvas.clipPath(collarBand);
    final collarRib = Paint()
      ..color = const Color(0x27000000)
      ..strokeWidth = .0016;
    final collarGlint = Paint()
      ..color = const Color(0x23FFFFFF)
      ..strokeWidth = .0011;
    for (var x = .317; x < .683; x += .009) {
      canvas.drawLine(
        Offset(x, .638),
        Offset(x + .014, .788),
        collarRib,
      );
      canvas.drawLine(
        Offset(x + .002, .638),
        Offset(x + .016, .788),
        collarGlint,
      );
    }
    canvas.restore();

    // Ombre courte à la naissance du cou et lumière sur la bordure haute
    // du col : aucune couleur n'est déposée sur les pixels du visage.
    canvas.drawPath(
      _PortraitGeometry.innerCollar(),
      Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .006
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .005),
    );
    // Joint intérieur très fin : le col touche visuellement le cou,
    // l'image réelle n'est jamais retouchée, recolorée ou repeinte.
    canvas.drawPath(
      _PortraitGeometry.innerCollar(),
      Paint()
        ..color = const Color(0x49000000)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = .0035,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PortraitJerseyPainter oldDelegate) =>
      oldDelegate.body != body ||
      oldDelegate.trim != trim ||
      oldDelegate.pattern != pattern ||
      oldDelegate.material != material;
}
