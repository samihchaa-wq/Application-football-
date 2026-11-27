import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/core/club/club_rules.dart';
import 'package:petit_filet/features/match_live/presentation/match_live_tab.dart';

/// « Piloter le Live » reste grisé tant que le Live n'est pas ouvert (coup
/// d'envoi moins le délai de fermeture des pronostics, 15 min par défaut),
/// avec l'heure d'ouverture affichée.
void main() {
  setUp(ClubRules.reset);
  tearDown(ClubRules.reset);

  // Coup d'envoi le 30/11/2026 à 20:00, heure de Paris (19:00 UTC).
  final kickoff = DateTime.utc(2026, 11, 30, 19);

  Future<int> pump(WidgetTester tester, DateTime now) async {
    var claims = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PilotPlaceAvailable(
            kickoffAt: kickoff,
            now: () => now,
            onClaim: () async => claims += 1,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('live-pilot-button')));
    await tester.pump();
    return claims;
  }

  FilledButton button(WidgetTester tester) => tester.widget<FilledButton>(
        find.byKey(const ValueKey('live-pilot-button')),
      );

  testWidgets('4 jours avant : bouton grisé, heure d’ouverture affichée', (
    tester,
  ) async {
    final claims =
        await pump(tester, kickoff.subtract(const Duration(days: 4)));

    expect(button(tester).onPressed, isNull);
    expect(claims, 0);
    expect(find.text('Le Live n’est pas encore ouvert'), findsOneWidget);
    expect(find.text('Le Live ouvre le 30/11 à 19:45.'), findsOneWidget);
  });

  testWidgets('le jour même, avant l’ouverture : seulement l’heure', (
    tester,
  ) async {
    final claims =
        await pump(tester, kickoff.subtract(const Duration(minutes: 30)));

    expect(button(tester).onPressed, isNull);
    expect(claims, 0);
    expect(find.text('Le Live ouvre à 19:45.'), findsOneWidget);
  });

  testWidgets('à l’ouverture : le bouton est actif et demande la place', (
    tester,
  ) async {
    final claims =
        await pump(tester, kickoff.subtract(const Duration(minutes: 15)));

    expect(button(tester).onPressed, isNotNull);
    expect(claims, 1);
    expect(find.text('Personne ne pilote le Live'), findsOneWidget);
    expect(find.byKey(const ValueKey('live-pilot-opens-at')), findsNothing);
  });

  testWidgets('le délai suit le réglage du club', (tester) async {
    ClubRules.set({ClubRules.predictionCloseMinutesKey: 60});
    final claims =
        await pump(tester, kickoff.subtract(const Duration(minutes: 30)));

    expect(button(tester).onPressed, isNotNull);
    expect(claims, 1);
  });
}
