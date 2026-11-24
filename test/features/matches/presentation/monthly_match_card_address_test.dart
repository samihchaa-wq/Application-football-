import 'package:petit_filet/features/matches/domain/match_model.dart';
import 'package:petit_filet/features/matches/presentation/calendar_matches_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MatchModel upcomingMatch({
    required String matchType,
    String? address,
    Duration untilKickoff = const Duration(days: 20),
    String? liveState,
  }) =>
      MatchModel(
        id: 'match',
        seasonId: 'season',
        opponentId: matchType == 'entre_nous' ? '' : 'opponent',
        kickoffAt: DateTime.now().add(untilKickoff),
        liveState: liveState,
        isHome: true,
        plannedDurationMinutes: 90,
        status: 'a_venir',
        ownScore: null,
        opponentScore: null,
        opponentName: matchType == 'entre_nous' ? null : 'FC Booster',
        matchType: matchType,
        address: address,
      );

  Future<void> pumpCard(WidgetTester tester, MatchModel match) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MonthlyMatchCard(match: match, adminActions: null),
          ),
        ),
      ),
    );
  }

  testWidgets('un match à venir affiche son adresse dans la vue Par mois', (
    tester,
  ) async {
    const address = 'INP - 223 Rue des Arts - 31670 - Labège';
    await pumpCard(
      tester,
      upcomingMatch(matchType: 'amical', address: address),
    );

    expect(find.byIcon(Icons.place_outlined), findsNothing);
    expect(find.text(address), findsOneWidget);
  });

  testWidgets('un match entre nous à venir affiche aussi son adresse', (
    tester,
  ) async {
    const address = 'INP - 223 Rue des Arts - 31670 - Labège';
    await pumpCard(
      tester,
      upcomingMatch(matchType: 'entre_nous', address: address),
    );

    expect(find.text('Match entre nous'), findsOneWidget);
    expect(find.text(address), findsOneWidget);
  });

  testWidgets('sans adresse renseignée, aucune ligne de lieu n’est ajoutée', (
    tester,
  ) async {
    await pumpCard(tester, upcomingMatch(matchType: 'amical'));

    expect(find.byIcon(Icons.place_outlined), findsNothing);
  });

  testWidgets('pendant le direct, la carte du calendrier dit « En direct »', (
    tester,
  ) async {
    await pumpCard(
      tester,
      upcomingMatch(
        matchType: 'amical',
        untilKickoff: const Duration(minutes: -20),
        liveState: 'running',
      ),
    );

    expect(find.text('En direct'), findsOneWidget);
  });

  testWidgets('un direct oublié depuis des heures passe « À valider »', (
    tester,
  ) async {
    await pumpCard(
      tester,
      upcomingMatch(
        matchType: 'amical',
        untilKickoff: const Duration(hours: -6),
        liveState: 'running',
      ),
    );

    expect(find.text('À valider'), findsOneWidget);
    expect(find.text('En direct'), findsNothing);
  });
}
