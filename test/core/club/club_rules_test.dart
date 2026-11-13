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

  test('les nouveaux réglages valent le comportement d’origine par défaut', () {
    expect(ClubRules.oddsDisabled, isFalse);
    expect(ClubRules.adminsCanPilotLive, isFalse);
    expect(ClubRules.motmSelfVoteAllowed, isFalse);
    expect(ClubRules.wrappedMusicEnabled, isTrue);

    ClubRules.set({
      ClubRules.oddsModeKey: 1,
      ClubRules.livePilotModeKey: 1,
      ClubRules.motmSelfVoteKey: 1,
      ClubRules.wrappedMusicKey: 0,
    });
    expect(ClubRules.oddsDisabled, isTrue);
    expect(ClubRules.adminsCanPilotLive, isTrue);
    expect(ClubRules.motmSelfVoteAllowed, isTrue);
    expect(ClubRules.wrappedMusicEnabled, isFalse);
  });

  test('pas des boutons +/− : 1 sauf pour les longues durées', () {
    expect(ClubRules.stepFor(ClubRules.predictionCloseMinutesKey), 1);
    expect(ClubRules.stepFor('odds_form_memory_days'), 30);
    expect(ClubRules.stepFor('odds_h2h_memory_days'), 90);
    expect(ClubRules.stepFor('match_duration_minutes'), 5);
  });

  test('le délai de correction du résultat suit la règle du club', () {
    expect(ClubRules.correctionWindow, const Duration(hours: 24));
    ClubRules.set({ClubRules.correctionWindowHoursKey: 72});
    expect(ClubRules.correctionWindow, const Duration(hours: 72));
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

  test('le mode de liste d’attente suit le réglage du club', () {
    expect(ClubRules.waitlistMode, WaitlistMode.lastSeasonAttendance);
    ClubRules.set({ClubRules.waitlistModeKey: 1});
    expect(ClubRules.waitlistMode, WaitlistMode.arrivalOrder);
    ClubRules.set({ClubRules.waitlistModeKey: 2});
    expect(ClubRules.waitlistMode, WaitlistMode.adminChoice);
    // Une valeur inconnue retombe sur la règle d'origine.
    ClubRules.set({ClubRules.waitlistModeKey: 9});
    expect(ClubRules.waitlistMode, WaitlistMode.lastSeasonAttendance);
  });
}
