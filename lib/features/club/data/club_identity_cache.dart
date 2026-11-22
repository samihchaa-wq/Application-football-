import 'dart:convert';

import 'package:petit_filet/core/club/club_identity.dart';
import 'package:petit_filet/core/club/club_kits.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dernier habillage de club (nom, couleurs, logo) gardé sur l'appareil.
///
/// Sans cette copie, l'application se dessinait d'abord aux couleurs par
/// défaut avec le libellé « Mon club », puis se redessinait en entier
/// plusieurs fois à l'arrivée du club (boutons de la mauvaise couleur,
/// saccade d'environ une demi-seconde au lancement). La copie est liée au
/// compte : un autre compte ne la lit jamais, et la réponse du serveur la
/// remplace dès qu'elle arrive.
abstract final class ClubIdentityCache {
  static const _keyPrefix = 'club_identity_v1_';

  /// Compte dont l'habillage a été restauré au lancement, tant que le serveur
  /// n'a pas confirmé.
  static String? restoredUserId;

  /// Relit la copie du compte [userId] et l'applique avant le premier rendu.
  static Future<void> restore(String? userId) async {
    if (userId == null || userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyPrefix$userId');
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw);
      if (data is! Map) return;
      final name = data['name'];
      final shortName = data['short'];
      if (name is! String || shortName is! String) return;
      final primary = AppTheme.parseHex(data['primary'] as String?);
      final secondary = AppTheme.parseHex(data['secondary'] as String?);
      ClubIdentity.set(name: name, shortName: shortName);
      AppTheme.applyClubColors(primary: primary, secondary: secondary);
      ClubKits.setClubColors(primary: primary, secondary: secondary);
      final logo = data['logo'];
      ClubIdentity.setLogoUrl(logo is String ? logo : null);
      restoredUserId = userId;
    } catch (_) {
      // Copie illisible : l'application démarre comme avant.
    }
  }

  static Future<void> save(
    String? userId, {
    required String name,
    required String shortName,
    String? primaryHex,
    String? secondaryHex,
    String? logoUrl,
  }) async {
    if (userId == null || userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_keyPrefix$userId',
        jsonEncode({
          'name': name,
          'short': shortName,
          'primary': primaryHex,
          'secondary': secondaryHex,
          'logo': logoUrl,
        }),
      );
    } catch (_) {}
  }
}
