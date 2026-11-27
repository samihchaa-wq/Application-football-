import 'package:flutter/material.dart' hide LicensePage;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/features/license/data/license_repository.dart';
import 'package:petit_filet/features/license/domain/license_models.dart';
import 'package:petit_filet/features/license/presentation/license_page.dart';
import 'package:petit_filet/features/players/data/roster_repository.dart';

RosterPlayer _player(String id, String firstName, {bool active = true}) =>
    RosterPlayer(
      id: id,
      firstName: firstName,
      lastName: 'Test',
      isGoalkeeper: false,
      isCoach: false,
      isActive: active,
      linkedProfileId: null,
      linkedProfileName: null,
      linkedProfileUsername: null,
    );

/// Faux dépôt en mémoire : les cases cochées modifient l'état relu ensuite.
class _MemoryLicenseRepository implements LicenseRepository {
  final expenses = <LicenseExpense>[
    const LicenseExpense(id: 'e1', label: 'Survêtement'),
  ];
  final licensePaid = <String>{'p1'};
  final expensePaid = <String, Set<String>>{
    'e1': {'p1'},
  };
  final calls = <String>[];
  Object? failure;

  final expenseSeasons = <String>[];

  @override
  Future<List<LicenseExpense>> fetchExpenses(String seasonId) async {
    expenseSeasons.add(seasonId);
    return List.of(expenses);
  }

  @override
  Future<SeasonLicenses> fetchSeason(String seasonId) async => SeasonLicenses(
        licensePaid: Set.of(licensePaid),
        expensePaid: {
          for (final entry in expensePaid.entries)
            entry.key: Set.of(entry.value),
        },
      );

  @override
  Future<void> setLicensePaid(String playerId, bool paid) async {
    calls.add('licence $playerId $paid');
    final error = failure;
    if (error != null) throw error;
    paid ? licensePaid.add(playerId) : licensePaid.remove(playerId);
  }

  @override
  Future<void> setExpensePaid(
    String expenseId,
    String playerId,
    bool paid,
  ) async {
    calls.add('dépense $expenseId $playerId $paid');
    final set = expensePaid.putIfAbsent(expenseId, () => <String>{});
    paid ? set.add(playerId) : set.remove(playerId);
  }

  @override
  Future<void> addExpense(String seasonId, String label) async {
    calls.add('ajout $seasonId $label');
    expenses.add(LicenseExpense(id: 'e${expenses.length + 1}', label: label));
  }

  @override
  Future<void> renameExpense(String id, String label) async =>
      calls.add('renommage $id $label');

  @override
  Future<void> deleteExpense(String id) async => calls.add('suppression $id');
}

Future<_MemoryLicenseRepository> _pump(
  WidgetTester tester, {
  String? seasonId = 'season-1',
}) async {
  final repository = _MemoryLicenseRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        openSeasonIdProvider.overrideWith((ref) async => seasonId),
        rosterProvider('season-1').overrideWith(
          (ref) async => [
            _player('p2', 'Zoé'),
            _player('p1', 'Adam'),
            _player('p3', 'Parti', active: false),
          ],
        ),
        licenseRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: LicensePage()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('résume les paiements des joueurs actifs seulement',
      (tester) async {
    final repository = await _pump(tester);

    expect(find.text('Licences payées : 1 / 2'), findsOneWidget);
    expect(find.text('Survêtement : 1 / 2'), findsOneWidget);
    expect(repository.expenseSeasons.toSet(), {'season-1'},
        reason: 'les dépenses lues sont celles de la saison ouverte');
    expect(find.text('Adam Test'), findsOneWidget);
    expect(find.text('Zoé Test'), findsOneWidget);
    expect(find.text('Parti Test'), findsNothing);
    // Ordre alphabétique.
    expect(
      tester.getTopLeft(find.text('Adam Test')).dy,
      lessThan(tester.getTopLeft(find.text('Zoé Test')).dy),
    );
  });

  testWidgets('« Impayés seulement » masque les joueurs à jour',
      (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Impayés seulement'));
    await tester.pumpAndSettle();

    expect(find.text('Adam Test'), findsNothing);
    expect(find.text('Zoé Test'), findsOneWidget);
  });

  testWidgets('cocher la licence l’enregistre et met le résumé à jour',
      (tester) async {
    final repository = await _pump(tester);

    final zoeLicence = find.descendant(
      of: find.byKey(const ValueKey('p2')),
      matching: find.widgetWithText(CheckboxListTile, 'Licence'),
    );
    await tester.tap(zoeLicence);
    await tester.pumpAndSettle();

    expect(repository.calls, ['licence p2 true']);
    expect(find.text('Licences payées : 2 / 2'), findsOneWidget);
  });

  testWidgets('cocher une dépense l’enregistre pour ce joueur', (tester) async {
    final repository = await _pump(tester);

    final zoeExpense = find.descendant(
      of: find.byKey(const ValueKey('p2')),
      matching: find.widgetWithText(CheckboxListTile, 'Survêtement'),
    );
    await tester.tap(zoeExpense);
    await tester.pumpAndSettle();

    expect(repository.calls, ['dépense e1 p2 true']);
    expect(find.text('Survêtement : 2 / 2'), findsOneWidget);
  });

  testWidgets('un refus du serveur est signalé', (tester) async {
    final repository = await _pump(tester);
    repository.failure = StateError('refus');

    await tester.tap(find.descendant(
      of: find.byKey(const ValueKey('p2')),
      matching: find.widgetWithText(CheckboxListTile, 'Licence'),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Enregistrement impossible.'), findsOneWidget);
    expect(find.text('Licences payées : 1 / 2'), findsOneWidget);
  });

  testWidgets('ajouter une dépense demande son nom', (tester) async {
    final repository = await _pump(tester);

    await tester.tap(find.text('Ajouter une dépense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Maillot');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(repository.calls, ['ajout season-1 Maillot']);
    expect(find.text('Maillot : 0 / 2'), findsOneWidget);
  });

  testWidgets('un nom trop court n’est pas envoyé', (tester) async {
    final repository = await _pump(tester);

    await tester.tap(find.text('Ajouter une dépense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'M');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(repository.calls, isEmpty);
    expect(find.text('Nouvelle dépense'), findsOneWidget);
  });

  testWidgets('sans saison ouverte, rien n’est chargé', (tester) async {
    final repository = await _pump(tester, seasonId: null);

    expect(find.text('Aucune saison ouverte.'), findsOneWidget);
    expect(repository.calls, isEmpty);
  });
}
