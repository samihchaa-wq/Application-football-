import 'package:as_grinta/core/club/club_rules.dart';
import 'package:as_grinta/core/utils/match_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(ClubRules.reset);

  test('les valeurs par défaut sont celles du club d’origine', () {
    expect(ClubRules.featuresOpenDays, 6);
    expect(ClubRules.featuresOpenHour, 12);
    expect(ClubRules.predictionCloseBeforeKickoff, const Duration(minutes: 15));
  });

  test('les horaires d’un match suivent les règles du club', () {
    final kickoff = DateTime.utc(2026, 12, 20, 15);
    expect(
      matchPredictionClosesAt(kickoff),
      DateTime.utc(2026, 12, 20, 14, 45),
    );
    expect(matchLiveOpensAt(kickoff), DateTime.utc(2026, 12, 20, 14, 45));
    // J-6 à 12 h (heure de Paris, hiver = UTC+1).
    expect(matchFeaturesOpenAt(kickoff), DateTime.utc(2026, 12, 14, 11));

    ClubRules.set({
      ClubRules.featuresOpenDaysKey: 3,
      ClubRules.featuresOpenHourKey: 18,
      ClubRules.predictionCloseMinutesKey: 60,
    });

    expect(matchPredictionClosesAt(kickoff), DateTime.utc(2026, 12, 20, 14));
    expect(matchLiveOpensAt(kickoff), DateTime.utc(2026, 12, 20, 14));
    expect(matchFeaturesOpenAt(kickoff), DateTime.utc(2026, 12, 17, 17));
  });

  test('un changement incrémente la révision, une valeur identique non', () {
    final before = ClubRules.revision.value;
    ClubRules.set({ClubRules.featuresOpenDaysKey: 6});
    expect(ClubRules.revision.value, before);
    ClubRules.set({ClubRules.featuresOpenDaysKey: 5});
    expect(ClubRules.revision.value, before + 1);
  });

  test('mode live désactivé : le live ne s’ouvre jamais', () {
    final kickoff = DateTime.utc(2026, 12, 20, 15);
    final during = DateTime.utc(2026, 12, 20, 15, 30);
    expect(isMatchLiveTooEarly(kickoff, now: during), isFalse);

    ClubRules.setLiveEnabled(false);
    expect(isMatchLiveTooEarly(kickoff, now: during), isTrue);

    ClubRules.reset();
    expect(isMatchLiveTooEarly(kickoff, now: during), isFalse);
  });
}
