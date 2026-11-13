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
  static const String correctionWindowHoursKey = 'correction_window_hours';
  static const String waitlistModeKey = 'waitlist_mode';
  static const String predictionPointsExactKey = 'prediction_points_exact';
  static const String predictionPointsGoalDifferenceKey =
      'prediction_points_goal_difference';
  static const String predictionPointsOneScoreKey =
      'prediction_points_one_score';
  static const String predictionPointsWinnerKey = 'prediction_points_winner';
  static const String oddsModeKey = 'odds_mode';
  static const String livePilotModeKey = 'live_pilot_mode';
  static const String motmSelfVoteKey = 'motm_self_vote';
  static const String wrappedMusicKey = 'wrapped_music';

  /// Unité des règles enregistrées en dixièmes de multiplicateur (20 = × 2).
  static const String multiplierUnit = '×';

  /// Unité des règles oui/non (1 = oui, 0 = non) : un interrupteur.
  static const String boolUnit = 'bool';

  /// Unité des règles à choix : une liste déroulante.
  static const String modeUnit = 'mode';

  /// Libellés des choix des règles à choix (index = valeur enregistrée).
  /// La liste d'attente a son propre menu, plus détaillé ([WaitlistMode]).
  static const Map<String, List<String>> modeLabels = {
    oddsModeKey: ['Calculées automatiquement', 'Sans cotes (barème seul)'],
    livePilotModeKey: ['Coach seulement', 'Coach et administrateurs'],
  };

  /// Pas des boutons +/− : 1 par défaut, plus grand pour les longues durées.
  static int stepFor(String key) => switch (key) {
        'odds_form_memory_days' => 30,
        'odds_h2h_memory_days' => 90,
        'match_duration_minutes' => 5,
        _ => 1,
      };

  static const Map<String, int> defaults = {
    featuresOpenDaysKey: 6,
    featuresOpenHourKey: 12,
    predictionCloseMinutesKey: 15,
    correctionWindowHoursKey: 24,
    waitlistModeKey: 0,
    predictionPointsExactKey: 20,
    predictionPointsGoalDifferenceKey: 15,
    predictionPointsOneScoreKey: 15,
    predictionPointsWinnerKey: 10,
    oddsModeKey: 0,
    livePilotModeKey: 0,
    motmSelfVoteKey: 0,
    wrappedMusicKey: 1,
  };

  static bool _liveEnabled = true;

  /// Faux quand l'administrateur a désactivé le mode live du club.
  static bool get liveEnabled => _liveEnabled;

  static void setLiveEnabled(bool value) {
    if (value == _liveEnabled) return;
    _liveEnabled = value;
    _revision.value += 1;
  }

  static final ValueNotifier<int> _revision = ValueNotifier<int>(0);
  static Map<String, int> _values = Map.of(defaults);

  /// Change à chaque mise à jour : les écrans qui l'écoutent se redessinent.
  static ValueListenable<int> get revision => _revision;

  static int _get(String key) => _values[key] ?? defaults[key]!;

  static int get featuresOpenDays => _get(featuresOpenDaysKey);
  static int get featuresOpenHour => _get(featuresOpenHourKey);
  static Duration get predictionCloseBeforeKickoff =>
      Duration(minutes: _get(predictionCloseMinutesKey));

  /// Délai pendant lequel un résultat validé peut encore être corrigé.
  static Duration get correctionWindow =>
      Duration(hours: _get(correctionWindowHoursKey));

  /// Qui passe en premier quand il y a trop de disponibles.
  static WaitlistMode get waitlistMode =>
      WaitlistMode.fromValue(_get(waitlistModeKey));

  /// Barème des pronostics : multiplicateurs de la cote choisis par le club.
  static double get predictionExactMultiplier =>
      _get(predictionPointsExactKey) / 10;
  static double get predictionGoalDifferenceMultiplier =>
      _get(predictionPointsGoalDifferenceKey) / 10;
  static double get predictionOneScoreMultiplier =>
      _get(predictionPointsOneScoreKey) / 10;
  static double get predictionWinnerMultiplier =>
      _get(predictionPointsWinnerKey) / 10;

  /// Vrai quand le club joue sans cotes : chaque issue vaut 1, seul le
  /// barème compte. Les cotes ne sont alors pas affichées.
  static bool get oddsDisabled => _get(oddsModeKey) == 1;

  /// Vrai quand les administrateurs peuvent aussi piloter le direct.
  static bool get adminsCanPilotLive => _get(livePilotModeKey) == 1;

  /// Vrai quand un joueur peut voter pour lui-même à l'Étoile du match.
  static bool get motmSelfVoteAllowed => _get(motmSelfVoteKey) == 1;

  /// Faux quand le club a coupé la musique du bilan de saison.
  static bool get wrappedMusicEnabled => _get(wrappedMusicKey) == 1;

  /// « × 1,5 » pour une règle enregistrée en dixièmes (15).
  static String formatMultiplier(int tenths) {
    final whole = tenths ~/ 10;
    final decimal = tenths % 10;
    return '× $whole,$decimal';
  }

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

  static void reset() {
    set(const {});
    setLiveEnabled(true);
  }
}

/// Les trois façons de départager les disponibles quand il y a trop de monde.
/// La valeur numérique est celle enregistrée par le serveur.
enum WaitlistMode {
  /// Ceux qui sont le moins venus la saison passée attendent les premiers,
  /// puis chacun son tour (règle d'origine).
  lastSeasonAttendance(
    0,
    'Par présence l’an dernier',
    'Les +1 acquis cette saison sont prioritaires, puis les présences '
        'de la saison précédente départagent les joueurs.',
  ),

  /// Premier à se dire disponible, premier convoqué.
  arrivalOrder(
    1,
    'Ordre d’arrivée',
    'Les +1 acquis cette saison sont prioritaires, puis les joueurs '
        'qui se sont déclarés présents en premier.',
  ),

  /// Tout le monde est convoqué ; l'admin met lui-même en attente.
  adminChoice(
    2,
    'Par choix',
    'Tous les disponibles sont convoqués : l’admin décide qui attend, '
        'avec les crédits +1 visibles pour le guider.',
  );

  const WaitlistMode(this.value, this.label, this.description);

  final int value;
  final String label;
  final String description;

  static WaitlistMode fromValue(int value) => WaitlistMode.values.firstWhere(
        (mode) => mode.value == value,
        orElse: () => WaitlistMode.lastSeasonAttendance,
      );
}
