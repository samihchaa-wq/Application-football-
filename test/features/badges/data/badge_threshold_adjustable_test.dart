import 'package:as_grinta/features/badges/data/badge_repository.dart';
import 'package:flutter_test/flutter_test.dart';

BadgeDef _badge({
  required String metric,
  String kind = 'tier',
  bool auto = true,
  int? threshold = 10,
}) =>
    BadgeDef(
      code: '${metric}__$threshold',
      name: 'Badge',
      description: '',
      emoji: '🏅',
      imageUrl: null,
      color: '#123456',
      family: 'joueur',
      kind: kind,
      category: 'joueur_all_time',
      metric: metric,
      threshold: threshold,
      sortOrder: 1,
      auto: auto,
    );

void main() {
  test('les paliers comptés ont un seuil réglable', () {
    expect(_badge(metric: 'goals').hasAdjustableThreshold, isTrue);
    expect(
        _badge(metric: 'matches_played_season').hasAdjustableThreshold, isTrue);
  });

  test('titres, exploits d’un match et badges manuels : pas de seuil', () {
    expect(_badge(metric: 'title_top_scorer').hasAdjustableThreshold, isFalse);
    expect(_badge(metric: 'max_match_goals').hasAdjustableThreshold, isFalse);
    expect(
        _badge(metric: 'bet_against_grinta').hasAdjustableThreshold, isFalse);
    expect(
        _badge(metric: 'goals', auto: false).hasAdjustableThreshold, isFalse);
    expect(_badge(metric: 'goals', kind: 'custom').hasAdjustableThreshold,
        isFalse);
    expect(_badge(metric: 'goals', threshold: null).hasAdjustableThreshold,
        isFalse);
  });
}
