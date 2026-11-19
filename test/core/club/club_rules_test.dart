import 'package:petit_filet/core/club/club_rules.dart';
import 'package:petit_filet/core/utils/match_window.dart';
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

  test('pas des boutons +/− : 1 sauf pour les durées et le barème', () {
    expect(ClubRules.stepFor(ClubRules.featuresOpenDaysKey), 1);
    expect(ClubRules.stepFor(ClubRules.predictionCloseMinutesKey), 5);
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

  test('les +1 restent comptés indépendamment de leur priorité', () {
    expect(ClubRules.waitlistPriorityEnabled, isTrue);
    ClubRules.set({ClubRules.waitlistPriorityEnabledKey: 0});
    expect(ClubRules.waitlistPriorityEnabled, isFalse);
    ClubRules.set({ClubRules.waitlistPriorityEnabledKey: 1});
    expect(ClubRules.waitlistPriorityEnabled, isTrue);
    ClubRules.reset();
    expect(ClubRules.waitlistPriorityEnabled, isTrue);
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

  test('les boutons +/− avancent par pas ronds sans sortir des bornes', () {
    int step(String key, int value, bool up, int min, int max) =>
        ClubRules.stepValue(key, value, up: up, min: min, max: max);

    // Fermeture des pronostics : par 5 minutes.
    expect(step('prediction_close_minutes', 15, true, 0, 240), 20);
    expect(step('prediction_close_minutes', 15, false, 0, 240), 10);
    // Une valeur non ronde se recale sur le multiple voisin.
    expect(step('prediction_close_minutes', 17, true, 0, 240), 20);
    expect(step('prediction_close_minutes', 17, false, 0, 240), 15);
    expect(step('prediction_close_minutes', 240, true, 0, 240), 240);
    expect(step('prediction_close_minutes', 0, false, 0, 240), 0);
    // Délai de correction : par 6 heures, sans descendre sous 1 h.
    expect(step('correction_window_hours', 24, true, 1, 168), 30);
    expect(step('correction_window_hours', 6, false, 1, 168), 1);
    expect(step('correction_window_hours', 1, true, 1, 168), 6);
    // Barème : par × 0,5.
    expect(step('prediction_points_exact', 20, true, 0, 50), 25);
    // Les petites valeurs gardent un pas de 1.
    expect(step('features_open_days', 6, true, 1, 21), 7);
  });
}
