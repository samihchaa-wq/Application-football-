import 'package:as_grinta/features/matches/data/history_entry_repository.dart';
import 'package:as_grinta/features/matches/domain/history_match_draft.dart';
import 'package:as_grinta/features/matches/presentation/history_entry_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fait défiler la liste du formulaire jusqu'à [finder].
Future<void> reveal(
  WidgetTester tester,
  Finder finder, {
  bool up = false,
}) async {
  await tester.scrollUntilVisible(
    finder,
    up ? -200 : 200,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  late _FakeHistoryRepository repository;

  setUp(() => repository = _FakeHistoryRepository());

  Future<void> pumpPage(WidgetTester tester) async {
    // Écran de téléphone.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyEntryRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: HistoryEntryPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sans adversaire, rien n’est envoyé', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const Key('history-save')));
    await tester.pumpAndSettle();
    expect(repository.saved, isEmpty);
    expect(find.text('Indique le nom de l’adversaire.'), findsOneWidget);
  });

  testWidgets('saisie rapide : deux matchs à la suite, même effectif',
      (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('history-opponent')), 'FC Un');
    await tester.tap(find.byKey(const Key('history-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    // Score 1-0
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('history-score-for')),
        matching: find.byIcon(Icons.add_circle_outline),
      ),
    );
    await tester.pumpAndSettle();

    await reveal(tester, find.byKey(const ValueKey('history-present-p-bruno')));
    await tester.tap(find.byKey(const ValueKey('history-present-p-bruno')));
    await tester.pumpAndSettle();

    await reveal(
      tester,
      find.byKey(const ValueKey('history-goals-plus-p-bruno')),
    );
    await tester.tap(find.byKey(const ValueKey('history-goals-plus-p-bruno')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('history-save-next')));
    await tester.pumpAndSettle();

    expect(repository.saved, hasLength(1));
    final first = repository.saved.single.toPayload();
    expect(first['opponent'], 'FC Un');
    expect(first['date'], '2026-06-30');
    expect(first['score_for'], 1);
    expect(first['scorers'], [
      {'name': 'Bruno Buteur', 'player_id': 'p-bruno', 'goals': 1},
    ]);

    // Le formulaire est prêt pour le suivant : adversaire vide, effectif gardé.
    await reveal(tester, find.byKey(const Key('history-saved-count')),
        up: true);
    final opponentField = tester.widget<TextField>(
      find.byKey(const Key('history-opponent')),
    );
    expect(opponentField.controller!.text, isEmpty);
    expect(find.byKey(const Key('history-saved-count')), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('history-opponent')), 'FC Deux');
    await tester.tap(find.byKey(const Key('history-save')));
    await tester.pumpAndSettle();

    expect(repository.saved, hasLength(2));
    final second = repository.saved.last.toPayload();
    expect(second['opponent'], 'FC Deux');
    // Une semaine après ne dépasse pas la date limite : même jour gardé.
    expect(second['date'], '2026-06-30');
    expect(second['present'], [
      {'name': 'Bruno Buteur', 'player_id': 'p-bruno'},
    ]);
    expect(second['scorers'], isEmpty);
  });
}

class _FakeHistoryRepository implements HistoryEntryRepository {
  final List<HistoryMatchDraft> saved = [];

  @override
  Future<HistoryEntryContext> fetchContext() async => HistoryEntryContext(
        lastAllowedDate: DateTime(2026, 6, 30),
        players: const [
          HistoryPlayer(
            playerId: 'p-alice',
            name: 'Alice Gardienne',
            displayName: 'Alice',
            isGoalkeeper: true,
          ),
          HistoryPlayer(
            playerId: 'p-bruno',
            name: 'Bruno Buteur',
            displayName: 'Bruno',
          ),
        ],
        opponents: const ['FC Un'],
      );

  @override
  Future<String> addMatch(HistoryMatchDraft draft) async {
    saved.add(draft);
    return 'match-${saved.length}';
  }

  @override
  Future<bool> deleteMatch(String matchId) async => true;
}
