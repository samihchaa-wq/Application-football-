import 'package:flutter/material.dart';

/// Icônes des faits de match d'un joueur, partagées par la composition d'un
/// match terminé et la fiche joueur : ⚽ pour un but, un crampon pour une
/// passe décisive, 👑 pour l'Homme du match.

/// Ballon d'un but, ajusté dans un carré de côté [size] : un emoji dessiné à
/// une taille de police donnée déborde de cette taille, et le ballon
/// paraissait plus gros que le crampon voisin à taille égale.
class GoalIcon extends StatelessWidget {
  const GoalIcon({super.key, this.size = 13});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: FittedBox(
        // Sans hauteur de ligne forcée, la boîte du texte englobe tout le
        // dessin de l'emoji : rien ne dépasse du carré.
        child: Text('⚽', style: TextStyle(fontSize: size)),
      ),
    );
  }
}

/// Couronne de l'Homme du match.
class ManOfTheMatchIcon extends StatelessWidget {
  const ManOfTheMatchIcon({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Text('👑', style: TextStyle(fontSize: size, height: 1));
  }
}

/// Couronne de l'Homme du match posée sur la photo d'un joueur du terrain :
/// elle commence au-dessus de la photo et descend sur la tête.
///
/// Sa taille et sa place suivent le côté de la photo ([photoSize]) : l'éditeur
/// de photo la montre ainsi exactement où elle tombera sur le terrain, à
/// l'échelle de son aperçu.
class PhotoCrown extends StatelessWidget {
  const PhotoCrown({super.key, this.photoSize = pitchPhotoSize});

  /// Côté de la photo d'un joueur sur le terrain.
  static const double pitchPhotoSize = 52;

  final double photoSize;

  /// Écart entre le haut de la couronne et le haut d'une photo de côté
  /// [photoSize] : négatif, la couronne dépasse au-dessus de la photo.
  static double topOffset(double photoSize) => -16 * photoSize / pitchPhotoSize;

  @override
  Widget build(BuildContext context) {
    // Style pris dans le thème plutôt qu'hérité de l'écran : la hauteur de
    // ligne décale l'emoji, et l'éditeur doit le placer comme le terrain.
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return Text(
      '👑',
      // Insensible au réglage de taille du texte, comme la photo : sinon la
      // couronne grandit et descend sur le visage chez qui agrandit le texte.
      // 22, c'est 20 agrandi des 10 % que l'application ajoute à tout le
      // texte (voir app.dart) : la couronne garde la taille qu'elle avait.
      textScaler: TextScaler.noScaling,
      style: base.copyWith(fontSize: 22 * photoSize / pitchPhotoSize),
    );
  }
}

/// Crampon d'une passe décisive, dans son cercle, en blanc sur un disque
/// noir : sur fond transparent, le trait blanc se perdait dans les bandes
/// claires du terrain et sur les photos des joueurs.
///
/// [size] est le côté du carré, le même que celui de [GoalIcon] : à taille
/// égale, ballon et crampon ont la même taille à l'écran.
class AssistBootIcon extends StatelessWidget {
  const AssistBootIcon({super.key, this.size = 13});

  final double size;

  @override
  Widget build(BuildContext context) {
    // Dessiné en vectoriel : net à toutes les tailles, sans image à charger.
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _BootPainter()),
    );
  }
}

class _BootPainter extends CustomPainter {
  const _BootPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, size.width / 2, Paint()..color = Colors.black);
    canvas.drawCircle(
      c,
      size.width / 2 - 3 * s,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * s,
    );
    final white = Paint()..color = Colors.white;
    // Chaussure : tige, pointe et semelle.
    final boot = Path()
      ..moveTo(26 * s, 34 * s)
      ..lineTo(40 * s, 34 * s)
      ..cubicTo(44 * s, 44 * s, 56 * s, 48 * s, 66 * s, 52 * s)
      ..cubicTo(76 * s, 55 * s, 80 * s, 60 * s, 80 * s, 65 * s)
      ..lineTo(80 * s, 68 * s)
      ..lineTo(26 * s, 68 * s)
      ..close();
    canvas.drawPath(boot, white);
    // Crampons sous la semelle.
    for (final x in [32.0, 46.0, 60.0, 72.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH((x - 3) * s, 68 * s, 6 * s, 8 * s),
          Radius.circular(2 * s),
        ),
        white,
      );
    }
    // Lacets.
    final lace = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round;
    for (final x in [44.0, 52.0, 60.0]) {
      canvas.drawLine(Offset(x * s, (x - 6) * s + 4 * s),
          Offset((x + 4) * s, (x - 6) * s + 10 * s), lace);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
