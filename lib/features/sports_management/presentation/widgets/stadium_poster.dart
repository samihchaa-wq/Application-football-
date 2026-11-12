import 'package:flutter/widgets.dart';

/// Saturation laissée au stade quand il ne peut pas être repeint aux couleurs
/// du club : assez basse pour effacer le bleu et le jaune d'origine, assez
/// haute pour garder une pelouse verte.
const double kNeutralStadiumSaturation = 0.25;

/// L'image fixe du stade, atténuée : elle ne montre pas les couleurs du club
/// d'origine. La version repeinte aux couleurs du club se dessine par-dessus
/// dès que possible.
class NeutralStadiumPoster extends StatelessWidget {
  const NeutralStadiumPoster({super.key, required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_saturation(kNeutralStadiumSaturation)),
      child: Image.asset(asset, fit: BoxFit.cover, gaplessPlayback: true),
    );
  }
}

/// Matrice de saturation (même formule que le filtre CSS `saturate`).
List<double> _saturation(double s) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  return [
    r + (1 - r) * s, g - g * s, b - b * s, 0, 0, //
    r - r * s, g + (1 - g) * s, b - b * s, 0, 0, //
    r - r * s, g - g * s, b + (1 - b) * s, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}
