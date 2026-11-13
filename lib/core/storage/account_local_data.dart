import 'package:shared_preferences/shared_preferences.dart';

/// Copies locales des données d'un compte (calendrier, historique, événements
/// du club), gardées pour un affichage immédiat au démarrage.
///
/// Elles appartiennent au compte connecté : à la déconnexion, elles sont
/// effacées pour qu'une autre personne qui utilise le même appareil, ou un
/// compte d'un autre club, ne puisse pas les retrouver dans le navigateur.
class AccountLocalData {
  const AccountLocalData._();

  /// Débuts de clés effacés à la déconnexion.
  static const List<String> keyPrefixes = [
    'calendar_matches_v',
    'calendar_history_all_v',
    'club_events_v',
  ];

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().toList()) {
        if (keyPrefixes.any(key.startsWith)) await prefs.remove(key);
      }
    } catch (_) {
      // Au mieux : la déconnexion ne doit jamais échouer pour un cache.
    }
  }
}
