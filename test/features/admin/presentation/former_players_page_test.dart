import 'package:petit_filet/features/admin/data/former_players_repository.dart';
import 'package:petit_filet/features/admin/presentation/former_players_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page « Anciens joueurs » : choisir un joueur, raccourcir ou remplacer son
/// nom, puis la liste est rechargée.
void main() {
  late _FakeFormerPlayers repository;

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          formerPlayersRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: FormerPlayersPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => repository = _FakeFormerPlayers());

  testWidgets('liste les anciens joueurs et filtre par nom', (tester) async {
    await pumpPage(tester);
    expect(find.text('Yves Dujardin'), findsOneWidget);
    expect(find.text('Paul Martin'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('former-players-search')),
      'yves',
    );
    await tester.pump();
    expect(find.text('Yves Dujardin'), findsOneWidget);
    expect(find.text('Paul Martin'), findsNothing);
  });

  testWidgets('raccourcir le nom l’envoie au serveur et recharge la liste', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Yves Dujardin'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('former-player-shorten')));
    await tester.pumpAndSettle();

    expect(repository.renamed, [('p-yves', FormerPlayerRename.shorten)]);
    expect(find.text('Nom remplacé par « Yves D. ».'), findsOneWidget);
    expect(find.text('Yves D.'), findsOneWidget);
  });

  testWidgets('annuler ne change rien', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Paul Martin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(repository.renamed, isEmpty);
  });
}

class _FakeFormerPlayers implements FormerPlayersRepository {
  final names = {'p-yves': 'Yves Dujardin', 'p-paul': 'Paul Martin'};
  final renamed = <(String, FormerPlayerRename)>[];

  @override
  Future<List<FormerPlayer>> list() async => [
        for (final entry in names.entries)
          FormerPlayer(id: entry.key, displayName: entry.value),
      ];

  @override
  Future<String> rename(String playerId, FormerPlayerRename mode) async {
    renamed.add((playerId, mode));
    final first = names[playerId]!.split(' ').first;
    final newName = mode == FormerPlayerRename.shorten
        ? '$first ${names[playerId]!.split(' ').last[0]}.'
        : 'Ancien joueur';
    names[playerId] = newName;
    return newName;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
