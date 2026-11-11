import 'package:flutter/foundation.dart';

/// Règles du club qui pilotent les horaires d'un match (ouverture des
/// pronostics, fermeture, mode live…). Les valeurs par défaut sont celles
/// de la version d'origine ; le club les modifie dans ses réglages et le
/// serveur reste la référence. Même mécanisme que [ClubIdentity] : tenues
/// ici pour ne pas les faire descendre dans chaque écran.
abstract final class ClubRules {
  static const String featuresOpenDaysKey = 'features_open_days';
  static const String featuresOpenHourKey = 'features_open_hour';
  static const String predictionCloseMinutesKey = 'prediction_close_minutes';

  static const Map<String, int> defaults = {
    featuresOpenDaysKey: 6,
    featuresOpenHourKey: 12,
    predictionCloseMinutesKey: 15,
  };

  static final ValueNotifier<int> _revision = ValueNotifier<int>(0);
  static Map<String, int> _values = Map.of(defaults);

  /// Change à chaque mise à jour : les écrans qui l'écoutent se redessinent.
  static ValueListenable<int> get revision => _revision;

  static int _get(String key) => _values[key] ?? defaults[key]!;

  static int get featuresOpenDays => _get(featuresOpenDaysKey);
  static int get featuresOpenHour => _get(featuresOpenHourKey);
  static Duration get predictionCloseBeforeKickoff =>
      Duration(minutes: _get(predictionCloseMinutesKey));

  /// Remplace les valeurs connues ; les clés absentes reprennent leur défaut.
  static void set(Map<String, int> values) {
    final next = {
      for (final entry in defaults.entries)
        entry.key: values[entry.key] ?? entry.value,
    };
    if (mapEquals(next, _values)) return;
    _values = next;
    _revision.value += 1;
  }

  static void reset() => set(const {});
}
