import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/features/matches/domain/club_start_progress.dart';
import 'package:petit_filet/features/matches/presentation/widgets/club_start_guide.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester,
  ClubStartProgress progress, {
  VoidCallback? onCreateMatch,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clubStartProgressProvider(progress.hasMatches)
            .overrideWith((ref) async => progress),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClubStartGuide(
              hasMatches: progress.hasMatches,
              onCreateMatch: onCreateMatch ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('un nouveau club voit les 4 étapes, la saison avant le match',
      (tester) async {
    var created = 0;
    await _pump(
      tester,
      const ClubStartProgress(
        hasLogo: false,
        hasOpenSeason: false,
        hasMatches: false,
        activeMembers: 1,
      ),
      onCreateMatch: () => created++,
    );

    expect(find.text('Bien démarrer'), findsOneWidget);
    expect(find.text('0/4'), findsOneWidget);
    expect(find.text('Possible une fois la saison créée.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('club-start-step-match')));
    await tester.pumpAndSettle();
    expect(created, 0, reason: 'pas de match sans saison ouverte');
  });

  testWidgets('avec une saison, l’étape du premier match s’ouvre',
      (tester) async {
    var created = 0;
    await _pump(
      tester,
      const ClubStartProgress(
        hasLogo: true,
        hasOpenSeason: true,
        hasMatches: false,
        activeMembers: 1,
      ),
      onCreateMatch: () => created++,
    );

    expect(find.text('2/4'), findsOneWidget);
    await tester.tap(find.byKey(const Key('club-start-step-match')));
    await tester.pumpAndSettle();
    expect(created, 1);
  });

  testWidgets('« Masquer le guide » est retenu sur l’appareil', (tester) async {
    await _pump(
      tester,
      const ClubStartProgress(
        hasLogo: false,
        hasOpenSeason: false,
        hasMatches: false,
        activeMembers: 1,
      ),
    );

    await tester.tap(find.byKey(const Key('club-start-guide-hide')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('club-start-guide')), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('pf-club-start-guide-hidden'), isTrue);
  });

  testWidgets('un club lancé ne voit plus le guide', (tester) async {
    await _pump(
      tester,
      const ClubStartProgress(
        hasLogo: false,
        hasOpenSeason: true,
        hasMatches: true,
        activeMembers: 15,
      ),
    );
    expect(find.byKey(const Key('club-start-guide')), findsNothing);
  });
}
