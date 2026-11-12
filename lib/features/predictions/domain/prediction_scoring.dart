import 'package:as_grinta/core/club/club_rules.dart';

/// Barème des pronostics de match, identique à la vue SQL
/// v_match_prediction_points. Les multiplicateurs sont réglés par chaque club
/// ([ClubRules]) ; par défaut :
///   score exact                                   → cote × 2
///   bon vainqueur + bon écart de buts             → cote × 1,5
///   bon vainqueur + score exact d'une des équipes → cote × 1,5
///   bon vainqueur seul                            → cote × 1
///   mauvais vainqueur ou pronostic non rempli     → 0
class PredictionScoring {
  const PredictionScoring._();

  static double? points({
    required int predictedHome,
    required int predictedAway,
    required int actualHome,
    required int actualAway,
    required double? baseOdds,
    double? exactMultiplier,
    double? goalDifferenceMultiplier,
    double? oneScoreMultiplier,
    double? winnerMultiplier,
  }) {
    if (baseOdds == null) return null;

    final predictedResult = _result(predictedHome, predictedAway);
    final actualResult = _result(actualHome, actualAway);
    if (predictedResult != actualResult) return 0;

    if (predictedHome == actualHome && predictedAway == actualAway) {
      return baseOdds *
          (exactMultiplier ?? ClubRules.predictionExactMultiplier);
    }
    if (predictedHome - predictedAway == actualHome - actualAway) {
      return baseOdds *
          (goalDifferenceMultiplier ??
              ClubRules.predictionGoalDifferenceMultiplier);
    }
    if (predictedHome == actualHome || predictedAway == actualAway) {
      return baseOdds *
          (oneScoreMultiplier ?? ClubRules.predictionOneScoreMultiplier);
    }
    return baseOdds *
        (winnerMultiplier ?? ClubRules.predictionWinnerMultiplier);
  }

  static int _result(int home, int away) {
    if (home > away) return 1;
    if (home == away) return 0;
    return -1;
  }
}
