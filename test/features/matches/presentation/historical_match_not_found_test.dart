import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/matches/data/calendar_history_repository.dart';
import 'package:petit_filet/features/matches/data/historical_match_detail_repository.dart';
import 'package:petit_filet/features/matches/presentation/historical_match_detail_page.dart';

/// Audit point 24 : une archive introuvable ne propose pas « Supprimer ».
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<HistoricalMatchResult> archives,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAdminViewProvider.overrideWithValue(true),
          allHistoricalMatchesProvider.overrideWith(
            (ref) => Stream.value(archives),
          ),
          historicalMatchDetailProvider('h-1').overrideWith((ref) async {
            return null;
          }),
        ],
        child: const MaterialApp(
          home: HistoricalMatchDetailPage(matchId: 'h-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('archive introuvable : message seul, pas de bouton Supprimer',
      (tester) async {
    await pump(tester, archives: const []);

    expect(find.text('Match introuvable dans les archives.'), findsOneWidget);
    expect(find.byKey(const Key('historical-match-delete')), findsNothing);
  });

  testWidgets('archive présente : l’administrateur garde Supprimer',
      (tester) async {
    await pump(
      tester,
      archives: [
        HistoricalMatchResult(
          id: 'h-1',
          date: DateTime(2020, 5, 3),
          opponentName: 'FC Ancien',
          ownScore: 2,
          opponentScore: 1,
          isHome: true,
        ),
      ],
    );

    expect(find.text('Match introuvable dans les archives.'), findsNothing);
    expect(find.byKey(const Key('historical-match-delete')), findsOneWidget);
  });
}
