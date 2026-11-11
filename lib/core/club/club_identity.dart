import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Nom du club affiché dans toute l'application.
///
/// Les écrans écrivent le nom du club à de très nombreux endroits (scores,
/// feuilles de match, calendrier…). Plutôt que de faire descendre ce nom dans
/// chaque écran, il est tenu ici et renseigné une fois le club du compte
/// connecté chargé. Avant cela, et hors connexion, un libellé neutre est
/// utilisé.
abstract final class ClubIdentity {
  static const String defaultName = 'Mon club';
  static const String defaultShortName = 'CLUB';

  /// Nom de l'application elle-même, quand aucun club n'est en jeu (écran de
  /// connexion, titre de l'onglet…). Provisoire tant que le nom du produit
  /// n'est pas choisi.
  static const String appName = 'Club';

  static final ValueNotifier<int> _revision = ValueNotifier<int>(0);
  static String _name = defaultName;
  static String _shortName = defaultShortName;
  static String? _logoUrl;

  /// Écusson neutre livré avec l'application.
  static const String defaultCrestAsset = 'assets/images/club_crest.webp';

  /// Adresse du logo envoyé par le club, ou null (écusson neutre).
  static String? get logoUrl => _logoUrl;

  /// Écusson à afficher : le logo du club s'il en a un, sinon l'écusson neutre.
  static ImageProvider get crestImage {
    final url = _logoUrl;
    return url == null
        ? const AssetImage(defaultCrestAsset)
        : NetworkImage(url) as ImageProvider;
  }

  static void setLogoUrl(String? url) {
    final next = (url == null || url.trim().isEmpty) ? null : url.trim();
    if (next == _logoUrl) return;
    _logoUrl = next;
    _revision.value += 1;
  }

  /// Change à chaque mise à jour du nom : les écrans qui l'écoutent se
  /// redessinent.
  static ValueListenable<int> get revision => _revision;

  static String get name => _name;
  static String get shortName => _shortName;

  static void set({required String name, required String shortName}) {
    final nextName = name.trim().isEmpty ? defaultName : name.trim();
    final nextShort =
        shortName.trim().isEmpty ? defaultShortName : shortName.trim();
    if (nextName == _name && nextShort == _shortName) return;
    _name = nextName;
    _shortName = nextShort;
    _revision.value += 1;
  }

  static void reset() {
    set(name: defaultName, shortName: defaultShortName);
    setLogoUrl(null);
  }
}
