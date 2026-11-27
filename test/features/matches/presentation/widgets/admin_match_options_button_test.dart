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
      'lecteur d’écran : chaque ligne du menu Options du match a son nom',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      _match(
        kickoffAt: DateTime.now().add(const Duration(days: 5)),
        status: 'a_venir',
      ),
    );
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    // Avant : la ligne de menu n'avait ni nom ni action (conflit avec le
    // ListTile placé dedans).
    expect(
      tester.getSemantics(find.text('Modifier')),
      matchesSemantics(
        label: 'Modifier',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Supprimer')),
      matchesSemantics(
        label: 'Supprimer',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });
}
