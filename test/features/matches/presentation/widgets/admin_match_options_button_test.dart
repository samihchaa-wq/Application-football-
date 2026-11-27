import 'package:petit_filet/features/matches/domain/match_model.dart';
import 'package:petit_filet/features/matches/presentation/widgets/admin_match_options_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match({required DateTime kickoffAt, required String status}) =>
    MatchModel(
      id: 'match-id',
      seasonId: 'season-id',
      opponentId: 'opponent-id',
      kickoffAt: kickoffAt,
      isHome: true,
      plannedDurationMinutes: 90,
      status: status,
      ownScore: 6,
      opponentScore: 0,
      opponentName: 'FC Booster',
    );

Future<void> _pump(WidgetTester tester, MatchModel match) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: AdminMatchOptionsButton(match: match)),
      ),
    ),
  );
}

void main() {
  testWidgets(
      'un match validé depuis plus de 24 h n’a plus de crayon : '
      'aucune option ne reste possible', (tester) async {
    await _pump(
      tester,
      _match(
        kickoffAt: DateTime.now().subtract(const Duration(days: 2)),
        status: 'termine',
      ),
    );

    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });

  testWidgets('un match à venir garde son crayon et ses options', (
    tester,
  ) async {
    await _pump(
      tester,
      _match(
        kickoffAt: DateTime.now().add(const Duration(days: 5)),
        status: 'a_venir',
      ),
    );

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
  });

  testWidgets(
      'supprimer un match joué demande de taper SUPPRIMER avant d’activer '
      'le bouton', (tester) async {
    await _pump(
      tester,
      _match(
        kickoffAt: DateTime.now().subtract(const Duration(hours: 5)),
        status: 'a_venir',
      ),
    );

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer définitivement…'), findsOneWidget);
    await tester.tap(find.text('Supprimer définitivement…'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer ce match joué\u00A0?'), findsOneWidget);
    FilledButton deleteButton() => tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Supprimer'),
        );
    expect(deleteButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'suppr');
    await tester.pump();
    expect(deleteButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'supprimer');
    await tester.pump();
    expect(deleteButton().onPressed, isNotNull);

    // Annuler ferme sans rien supprimer.
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.byType(StrongDeleteMatchDialog), findsNothing);
  });

  testWidgets('supprimer un match à venir garde la confirmation simple', (
    tester,
  ) async {
    await _pump(
      tester,
      _match(
        kickoffAt: DateTime.now().add(const Duration(days: 5)),
        status: 'a_venir',
      ),
    );

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer ce match\u00A0?'), findsOneWidget);
    expect(find.byType(StrongDeleteMatchDialog), findsNothing);
  });

  test('un match annulé n’est pas un match joué', () {
    expect(
      isPlayedMatch(
        _match(
          kickoffAt: DateTime.now().subtract(const Duration(days: 1)),
          status: 'annule',
        ),
      ),
      isFalse,
    );
  });
}
