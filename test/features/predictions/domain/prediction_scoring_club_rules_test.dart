import 'package:as_grinta/core/club/club_rules.dart';
import 'package:as_grinta/features/predictions/domain/prediction_scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(ClubRules.reset);

  double? score(int home, int away) => PredictionScoring.points(
        predictedHome: home,
        predictedAway: away,
        actualHome: 2,
        actualAway: 1,
        baseOdds: 2,
      );

  test('sans réglage, le barème d’origine s’applique', () {
    expect(score(2, 1), 4);
    expect(score(3, 2), 3);
    expect(score(2, 0), 3);
    expect(score(3, 0), 2);
    expect(score(0, 1), 0);
  });

  test('le barème suit les règles du club (en dixièmes)', () {
    ClubRules.set({
      ClubRules.predictionPointsExactKey: 30,
      ClubRules.predictionPointsGoalDifferenceKey: 20,
      ClubRules.predictionPointsOneScoreKey: 12,
      ClubRules.predictionPointsWinnerKey: 5,
    });
    expect(score(2, 1), 6);
    expect(score(3, 2), 4);
    expect(score(2, 0), closeTo(2.4, 1e-9));
    expect(score(3, 0), 1);
    expect(score(0, 1), 0);
  });

  test('affichage d’un multiplicateur', () {
    expect(ClubRules.formatMultiplier(20), '× 2,0');
    expect(ClubRules.formatMultiplier(15), '× 1,5');
    expect(ClubRules.formatMultiplier(0), '× 0,0');
  });
}
