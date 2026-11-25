import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Icônes des faits de match d'un joueur, partagées par la composition d'un
/// match terminé et la fiche joueur : ⚽ pour un but, un crampon pour une
/// passe décisive, 👑 pour l'Homme du match.

/// Ballon d'un but, dessiné comme le crampon (blanc sur disque noir) : même
/// taille, même style, et lisible sur le vert du terrain. L'emoji ⚽ restait
/// invisible sur certains téléphones.
class GoalIcon extends StatelessWidget {
  const GoalIcon({super.key, this.size = 13});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _BallPainter()),
    );
  }
}

class _BallPainter extends CustomPainter {
  const _BallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, r, Paint()..color = Colors.black);
    final white = Paint()..color = Colors.white;
    final ringR = r * 0.86;
    canvas.drawCircle(
      c,
      ringR,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.1,
    );
    // Pentagone central, relié au bord par cinq traits.
    final pent = Path();
    final dark = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, ringR - r * 0.05, white);
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final p = c + Offset(math.cos(a), math.sin(a)) * r * 0.32;
      i == 0 ? pent.moveTo(p.dx, p.dy) : pent.lineTo(p.dx, p.dy);
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.32,
        c + Offset(math.cos(a), math.sin(a)) * ringR,
        dark,
      );
    }
    pent.close();
    canvas.drawPath(pent, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
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

/// Crampon dans son cercle : le contour de l'ancienne image, repris en
/// vectoriel (cercle, chaussure, lacets et crampons en un seul tracé).
class _BootPainter extends CustomPainter {
  const _BootPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width / 2,
      Paint()..color = Colors.black,
    );
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(47.14 * s, 0.51 * s)
      ..lineTo(40.62 * s, 1.26 * s)
      ..lineTo(36.98 * s, 2.08 * s)
      ..lineTo(31.77 * s, 3.80 * s)
      ..lineTo(28.12 * s, 5.43 * s)
      ..lineTo(23.70 * s, 7.90 * s)
      ..lineTo(20.05 * s, 10.42 * s)
      ..lineTo(16.15 * s, 13.72 * s)
      ..lineTo(11.65 * s, 18.49 * s)
      ..lineTo(8.33 * s, 22.99 * s)
      ..lineTo(5.80 * s, 27.34 * s)
      ..lineTo(4.17 * s, 30.86 * s)
      ..lineTo(2.52 * s, 35.42 * s)
      ..lineTo(1.56 * s, 39.07 * s)
      ..lineTo(0.85 * s, 42.97 * s)
      ..lineTo(0.49 * s, 48.70 * s)
      ..lineTo(0.66 * s, 54.69 * s)
      ..lineTo(0.95 * s, 57.55 * s)
      ..lineTo(1.65 * s, 61.20 * s)
      ..lineTo(2.50 * s, 64.32 * s)
      ..lineTo(4.17 * s, 68.95 * s)
      ..lineTo(5.76 * s, 72.40 * s)
      ..lineTo(8.32 * s, 76.82 * s)
      ..lineTo(11.46 * s, 81.12 * s)
      ..lineTo(14.14 * s, 84.11 * s)
      ..lineTo(17.99 * s, 87.76 * s)
      ..lineTo(22.40 * s, 91.09 * s)
      ..lineTo(26.56 * s, 93.59 * s)
      ..lineTo(29.69 * s, 95.14 * s)
      ..lineTo(34.11 * s, 96.85 * s)
      ..lineTo(36.72 * s, 97.68 * s)
      ..lineTo(41.44 * s, 98.70 * s)
      ..lineTo(47.14 * s, 99.31 * s)
      ..lineTo(52.60 * s, 99.31 * s)
      ..lineTo(58.59 * s, 98.66 * s)
      ..lineTo(62.76 * s, 97.75 * s)
      ..lineTo(67.77 * s, 96.09 * s)
      ..lineTo(71.61 * s, 94.38 * s)
      ..lineTo(76.08 * s, 91.93 * s)
      ..lineTo(80.73 * s, 88.60 * s)
      ..lineTo(84.64 * s, 85.11 * s)
      ..lineTo(88.17 * s, 81.25 * s)
      ..lineTo(91.41 * s, 76.82 * s)
      ..lineTo(93.98 * s, 72.40 * s)
      ..lineTo(95.57 * s, 68.96 * s)
      ..lineTo(97.26 * s, 64.32 * s)
      ..lineTo(98.14 * s, 60.94 * s)
      ..lineTo(98.98 * s, 55.99 * s)
      ..lineTo(99.23 * s, 51.56 * s)
      ..lineTo(99.09 * s, 45.31 * s)
      ..lineTo(98.78 * s, 42.19 * s)
      ..lineTo(97.22 * s, 35.42 * s)
      ..lineTo(95.57 * s, 30.87 * s)
      ..lineTo(94.01 * s, 27.48 * s)
      ..lineTo(91.41 * s, 22.99 * s)
      ..lineTo(88.93 * s, 19.53 * s)
      ..lineTo(85.54 * s, 15.62 * s)
      ..lineTo(81.66 * s, 11.98 * s)
      ..lineTo(77.34 * s, 8.73 * s)
      ..lineTo(73.18 * s, 6.23 * s)
      ..lineTo(70.05 * s, 4.68 * s)
      ..lineTo(65.62 * s, 2.97 * s)
      ..lineTo(62.76 * s, 2.08 * s)
      ..lineTo(57.61 * s, 1.04 * s)
      ..lineTo(52.08 * s, 0.46 * s)
      ..close()
      ..moveTo(46.88 * s, 5.47 * s)
      ..lineTo(41.41 * s, 6.18 * s)
      ..lineTo(37.50 * s, 7.12 * s)
      ..lineTo(32.81 * s, 8.76 * s)
      ..lineTo(29.22 * s, 10.42 * s)
      ..lineTo(25.00 * s, 12.94 * s)
      ..lineTo(21.61 * s, 15.49 * s)
      ..lineTo(18.23 * s, 18.57 * s)
      ..lineTo(15.72 * s, 21.35 * s)
      ..lineTo(13.33 * s, 24.48 * s)
      ..lineTo(10.89 * s, 28.39 * s)
      ..lineTo(9.20 * s, 31.77 * s)
      ..lineTo(7.41 * s, 36.46 * s)
      ..lineTo(6.65 * s, 39.06 * s)
      ..lineTo(5.75 * s, 43.75 * s)
      ..lineTo(5.47 * s, 47.92 * s)
      ..lineTo(5.61 * s, 54.43 * s)
      ..lineTo(5.80 * s, 56.51 * s)
      ..lineTo(6.75 * s, 61.20 * s)
      ..lineTo(8.27 * s, 65.89 * s)
      ..lineTo(9.90 * s, 69.57 * s)
      ..lineTo(11.58 * s, 72.66 * s)
      ..lineTo(14.06 * s, 76.37 * s)
      ..lineTo(18.23 * s, 81.23 * s)
      ..lineTo(20.75 * s, 83.59 * s)
      ..lineTo(23.96 * s, 86.13 * s)
      ..lineTo(27.86 * s, 88.64 * s)
      ..lineTo(30.99 * s, 90.28 * s)
      ..lineTo(34.95 * s, 91.93 * s)
      ..lineTo(40.62 * s, 93.49 * s)
      ..lineTo(44.79 * s, 94.14 * s)
      ..lineTo(47.92 * s, 94.41 * s)
      ..lineTo(52.86 * s, 94.37 * s)
      ..lineTo(58.59 * s, 93.60 * s)
      ..lineTo(62.24 * s, 92.73 * s)
      ..lineTo(67.19 * s, 90.98 * s)
      ..lineTo(70.57 * s, 89.37 * s)
      ..lineTo(74.74 * s, 86.86 * s)
      ..lineTo(77.86 * s, 84.53 * s)
      ..lineTo(80.68 * s, 82.03 * s)
      ..lineTo(83.85 * s, 78.64 * s)
      ..lineTo(87.24 * s, 74.14 * s)
      ..lineTo(88.89 * s, 71.35 * s)
      ..lineTo(90.58 * s, 67.97 * s)
      ..lineTo(92.28 * s, 63.54 * s)
      ..lineTo(93.10 * s, 60.68 * s)
      ..lineTo(94.06 * s, 55.47 * s)
      ..lineTo(94.28 * s, 50.78 * s)
      ..lineTo(94.13 * s, 45.31 * s)
      ..lineTo(93.03 * s, 38.80 * s)
      ..lineTo(91.43 * s, 33.85 * s)
      ..lineTo(89.83 * s, 30.21 * s)
      ..lineTo(87.24 * s, 25.67 * s)
      ..lineTo(85.68 * s, 23.44 * s)
      ..lineTo(83.12 * s, 20.31 * s)
      ..lineTo(78.91 * s, 16.15 * s)
      ..lineTo(75.78 * s, 13.70 * s)
      ..lineTo(73.21 * s, 11.98 * s)
      ..lineTo(70.53 * s, 10.42 * s)
      ..lineTo(64.84 * s, 7.92 * s)
      ..lineTo(59.11 * s, 6.34 * s)
      ..lineTo(54.43 * s, 5.60 * s)
      ..lineTo(51.56 * s, 5.40 * s)
      ..close()
      ..moveTo(28.39 * s, 21.83 * s)
      ..lineTo(27.60 * s, 22.14 * s)
      ..lineTo(25.52 * s, 23.80 * s)
      ..lineTo(24.96 * s, 24.48 * s)
      ..lineTo(24.88 * s, 25.26 * s)
      ..lineTo(25.74 * s, 27.34 * s)
      ..lineTo(27.34 * s, 29.89 * s)
      ..lineTo(28.81 * s, 31.51 * s)
      ..lineTo(30.49 * s, 32.81 * s)
      ..lineTo(31.20 * s, 33.85 * s)
      ..lineTo(29.17 * s, 33.19 * s)
      ..lineTo(26.60 * s, 31.51 * s)
      ..lineTo(24.00 * s, 28.91 * s)
      ..lineTo(22.55 * s, 27.08 * s)
      ..lineTo(21.61 * s, 27.45 * s)
      ..lineTo(19.79 * s, 29.32 * s)
      ..lineTo(19.62 * s, 30.21 * s)
      ..lineTo(19.98 * s, 30.73 * s)
      ..lineTo(23.18 * s, 32.75 * s)
      ..lineTo(26.29 * s, 35.16 * s)
      ..lineTo(28.81 * s, 37.50 * s)
      ..lineTo(32.01 * s, 41.15 * s)
      ..lineTo(35.17 * s, 46.09 * s)
      ..lineTo(36.93 * s, 50.00 * s)
      ..lineTo(38.57 * s, 55.21 * s)
      ..lineTo(39.58 * s, 56.37 * s)
      ..lineTo(45.83 * s, 59.90 * s)
      ..lineTo(46.44 * s, 60.42 * s)
      ..lineTo(57.81 * s, 66.21 * s)
      ..lineTo(63.80 * s, 68.75 * s)
      ..lineTo(67.45 * s, 69.95 * s)
      ..lineTo(68.23 * s, 70.37 * s)
      ..lineTo(73.96 * s, 72.00 * s)
      ..lineTo(81.25 * s, 73.75 * s)
      ..lineTo(83.07 * s, 73.88 * s)
      ..lineTo(83.92 * s, 73.18 * s)
      ..lineTo(84.71 * s, 71.09 * s)
      ..lineTo(84.71 * s, 69.79 * s)
      ..lineTo(84.15 * s, 67.71 * s)
      ..lineTo(83.07 * s, 65.73 * s)
      ..lineTo(81.51 * s, 63.89 * s)
      ..lineTo(69.01 * s, 50.93 * s)
      ..lineTo(68.43 * s, 51.04 * s)
      ..lineTo(67.71 * s, 52.96 * s)
      ..lineTo(67.19 * s, 53.16 * s)
      ..lineTo(66.93 * s, 52.95 * s)
      ..lineTo(66.78 * s, 52.34 * s)
      ..lineTo(66.87 * s, 48.96 * s)
      ..lineTo(66.45 * s, 47.92 * s)
      ..lineTo(65.62 * s, 46.88 * s)
      ..lineTo(65.10 * s, 46.87 * s)
      ..lineTo(64.74 * s, 47.14 * s)
      ..lineTo(64.06 * s, 49.39 * s)
      ..lineTo(63.54 * s, 49.62 * s)
      ..lineTo(63.14 * s, 49.48 * s)
      ..lineTo(62.96 * s, 48.70 * s)
      ..lineTo(63.82 * s, 45.05 * s)
      ..lineTo(63.40 * s, 44.01 * s)
      ..lineTo(62.50 * s, 42.67 * s)
      ..lineTo(61.98 * s, 42.56 * s)
      ..lineTo(61.72 * s, 42.79 * s)
      ..lineTo(60.16 * s, 45.65 * s)
      ..lineTo(59.64 * s, 45.78 * s)
      ..lineTo(59.38 * s, 45.62 * s)
      ..lineTo(59.25 * s, 45.31 * s)
      ..lineTo(59.40 * s, 44.53 * s)
      ..lineTo(60.84 * s, 41.67 * s)
      ..lineTo(60.89 * s, 41.15 * s)
      ..lineTo(60.68 * s, 40.80 * s)
      ..lineTo(59.90 * s, 40.60 * s)
      ..lineTo(57.29 * s, 41.07 * s)
      ..lineTo(55.99 * s, 41.51 * s)
      ..lineTo(55.43 * s, 41.41 * s)
      ..lineTo(55.29 * s, 40.62 * s)
      ..lineTo(55.73 * s, 40.13 * s)
      ..lineTo(58.07 * s, 39.68 * s)
      ..lineTo(59.52 * s, 39.06 * s)
      ..lineTo(59.67 * s, 38.54 * s)
      ..lineTo(59.11 * s, 37.67 * s)
      ..lineTo(58.07 * s, 37.28 * s)
      ..lineTo(52.60 * s, 37.44 * s)
      ..lineTo(51.93 * s, 37.24 * s)
      ..lineTo(51.83 * s, 36.72 * s)
      ..lineTo(52.34 * s, 36.11 * s)
      ..lineTo(57.29 * s, 35.86 * s)
      ..lineTo(57.81 * s, 35.42 * s)
      ..lineTo(57.60 * s, 34.64 * s)
      ..lineTo(54.25 * s, 28.12 * s)
      ..lineTo(53.39 * s, 27.04 * s)
      ..lineTo(52.40 * s, 27.08 * s)
      ..lineTo(49.58 * s, 28.65 * s)
      ..lineTo(48.77 * s, 29.43 * s)
      ..lineTo(47.89 * s, 31.25 * s)
      ..lineTo(47.40 * s, 31.69 * s)
      ..lineTo(41.15 * s, 32.55 * s)
      ..lineTo(38.02 * s, 32.55 * s)
      ..lineTo(35.94 * s, 32.32 * s)
      ..lineTo(33.19 * s, 31.51 * s)
      ..lineTo(31.77 * s, 30.57 * s)
      ..lineTo(30.73 * s, 29.39 * s)
      ..lineTo(30.05 * s, 27.86 * s)
      ..lineTo(29.83 * s, 26.82 * s)
      ..lineTo(29.98 * s, 23.96 * s)
      ..lineTo(29.83 * s, 22.92 * s)
      ..lineTo(29.43 * s, 22.08 * s)
      ..close()
      ..moveTo(18.49 * s, 31.23 * s)
      ..lineTo(17.61 * s, 32.03 * s)
      ..lineTo(16.66 * s, 33.59 * s)
      ..lineTo(15.08 * s, 37.50 * s)
      ..lineTo(14.53 * s, 40.89 * s)
      ..lineTo(14.90 * s, 42.19 * s)
      ..lineTo(19.71 * s, 44.27 * s)
      ..lineTo(22.92 * s, 45.93 * s)
      ..lineTo(34.38 * s, 53.03 * s)
      ..lineTo(36.46 * s, 54.27 * s)
      ..lineTo(36.81 * s, 54.17 * s)
      ..lineTo(36.95 * s, 53.39 * s)
      ..lineTo(36.41 * s, 52.34 * s)
      ..lineTo(35.94 * s, 50.53 * s)
      ..lineTo(34.43 * s, 46.88 * s)
      ..lineTo(31.91 * s, 42.71 * s)
      ..lineTo(29.43 * s, 39.58 * s)
      ..lineTo(26.02 * s, 36.20 * s)
      ..lineTo(22.73 * s, 33.59 * s)
      ..lineTo(20.31 * s, 32.01 * s)
      ..close()
      ..moveTo(14.84 * s, 43.67 * s)
      ..lineTo(14.57 * s, 44.27 * s)
      ..lineTo(14.77 * s, 45.57 * s)
      ..lineTo(16.29 * s, 48.18 * s)
      ..lineTo(16.01 * s, 51.04 * s)
      ..lineTo(16.93 * s, 52.19 * s)
      ..lineTo(17.71 * s, 52.47 * s)
      ..lineTo(18.49 * s, 52.46 * s)
      ..lineTo(19.27 * s, 52.09 * s)
      ..lineTo(20.83 * s, 50.71 * s)
      ..lineTo(22.14 * s, 50.84 * s)
      ..lineTo(25.26 * s, 52.46 * s)
      ..lineTo(25.94 * s, 53.12 * s)
      ..lineTo(26.28 * s, 53.91 * s)
      ..lineTo(26.25 * s, 55.99 * s)
      ..lineTo(26.56 * s, 56.61 * s)
      ..lineTo(27.34 * s, 57.19 * s)
      ..lineTo(28.65 * s, 57.35 * s)
      ..lineTo(29.30 * s, 57.03 * s)
      ..lineTo(30.73 * s, 55.68 * s)
      ..lineTo(32.03 * s, 55.75 * s)
      ..lineTo(50.78 * s, 65.70 * s)
      ..lineTo(52.28 * s, 66.67 * s)
      ..lineTo(52.83 * s, 67.71 * s)
      ..lineTo(52.70 * s, 69.53 * s)
      ..lineTo(53.12 * s, 70.25 * s)
      ..lineTo(53.65 * s, 70.61 * s)
      ..lineTo(54.95 * s, 71.00 * s)
      ..lineTo(57.03 * s, 69.62 * s)
      ..lineTo(57.81 * s, 69.46 * s)
      ..lineTo(58.85 * s, 69.73 * s)
      ..lineTo(62.76 * s, 71.55 * s)
      ..lineTo(63.32 * s, 72.40 * s)
      ..lineTo(63.54 * s, 74.48 * s)
      ..lineTo(64.32 * s, 75.05 * s)
      ..lineTo(65.10 * s, 75.34 * s)
      ..lineTo(65.89 * s, 75.27 * s)
      ..lineTo(67.97 * s, 73.52 * s)
      ..lineTo(68.75 * s, 73.47 * s)
      ..lineTo(72.14 * s, 74.42 * s)
      ..lineTo(73.18 * s, 74.95 * s)
      ..lineTo(73.41 * s, 75.52 * s)
      ..lineTo(73.47 * s, 76.82 * s)
      ..lineTo(73.77 * s, 77.34 * s)
      ..lineTo(74.74 * s, 77.94 * s)
      ..lineTo(76.04 * s, 77.91 * s)
      ..lineTo(77.86 * s, 76.21 * s)
      ..lineTo(78.65 * s, 75.87 * s)
      ..lineTo(80.99 * s, 75.49 * s)
      ..lineTo(81.35 * s, 75.26 * s)
      ..lineTo(81.25 * s, 74.96 * s)
      ..lineTo(67.71 * s, 71.27 * s)
      ..lineTo(63.02 * s, 69.60 * s)
      ..lineTo(55.47 * s, 66.30 * s)
      ..lineTo(50.61 * s, 63.80 * s)
      ..lineTo(45.83 * s, 60.90 * s)
      ..lineTo(44.79 * s, 60.45 * s)
      ..lineTo(22.40 * s, 46.85 * s)
      ..lineTo(17.45 * s, 44.40 * s)
      ..lineTo(16.02 * s, 44.01 * s)
      ..lineTo(15.36 * s, 43.55 * s)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
