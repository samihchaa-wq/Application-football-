import 'package:as_grinta/core/club/club_kits.dart';

/// Les trois emplacements de maillot d'un club. La valeur stockée en base
/// (`jersey_note` d'un match, maillots d'une composition « entre nous ») est
/// l'identifiant de l'emplacement.
///
/// Les identifiants historiques sont gardés tels quels pour rester compatibles
/// avec les données existantes ; ils ne sont jamais affichés. Le nom et les
/// couleurs de chaque maillot sont réglés par le club ([ClubKits]).
enum JerseyOption {
  france('france'),
  orange('orange'),
  blue('blue');

  const JerseyOption(this.id);

  final String id;

  /// Le maillot du club à cet emplacement (nom, couleurs).
  ClubKit get kit => ClubKits.of(this);

  /// Nom du maillot choisi par le club.
  String get label => kit.label;

  static JerseyOption? fromId(String? id) {
    if (id == null) return null;
    for (final option in values) {
      if (option.id == id) return option;
    }
    return null;
  }
}
