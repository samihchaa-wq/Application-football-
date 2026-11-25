import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/unavailability/data/player_unavailability_repository.dart';
import 'package:petit_filet/features/unavailability/domain/player_unavailability.dart';
import 'package:petit_filet/features/unavailability/presentation/unavailability_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements PlayerUnavailabilityRepository {
  _FakeRepository({this.mine = const [], this.club = const [], this.fail});

  List<PlayerUnavailability> mine;
  final List<PlayerUnavailability> club;
  final Object? fail;
  final cancelled = <String>[];

  @override
  Future<List<PlayerUnavailability>> fetchMine() async {
    if (fail != null) throw fail!;
    return mine;
  }

  @override
  Future<List<PlayerUnavailability>> fetchAll() async => club;

  @override
  Future<void> cancel(String id) async {
    cancelled.add(id);
    mine = mine.where((period) => period.id != id).toList();
  }

  @override
  Future<void> save({
    String? id,
    required DateTime startsOn,
    required DateTime endsOn,
    required String reason,
  }) async {}
}

PlayerUnavailability _period(
  String id, {
  bool past = false,
  bool current = false,
  String? name,
}) =>
    PlayerUnavailability(
      id: id,
      startsOn: DateTime(2026, 12, 1),
      endsOn: DateTime(2026, 12, 10),
      reason: 'Vacances $id',
      createdAt: DateTime(2026, 11, 1),
      isPast: past,
      isCurrent: current,
      profileId: name == null ? null : 'p-$id',
      displayName: name,
    );

Future<void> _pump(
  WidgetTester tester,
  _FakeRepository repository, {
  bool admin = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playerUnavailabilityRepositoryProvider.overrideWithValue(repository),
        isAdminViewProvider.overrideWithValue(admin),
      ],
      child: const MaterialApp(home: UnavailabilityPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sans période : message vide et bouton pour déclarer', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository());
    expect(find.text('Aucune indisponibilité'), findsOneWidget);
    expect(find.text('Déclarer une indisponibilité'), findsOneWidget);
    // Un joueur ne voit pas l'onglet de l'équipe.
    expect(find.text('Équipe'), findsNothing);
  });

  testWidgets('erreur de chargement : message lisible, pas de plantage', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository(fail: Exception('réseau coupé')));
    expect(find.text('Aucune indisponibilité'), findsNothing);
    expect(find.text('Déclarer une indisponibilité'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une période passée ne peut plus être modifiée ni annulée', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository(mine: [_period('a', past: true)]));
    expect(find.text('Vacances a'), findsOneWidget);
    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Annuler'), findsNothing);
  });

  testWidgets('annuler demande confirmation ; « Garder » ne supprime rien', (
    tester,
  ) async {
    final repository = _FakeRepository(mine: [_period('b')]);
    await _pump(tester, repository);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Annuler cette indisponibilité\u00A0?'), findsOneWidget);
    await tester.tap(find.text('Garder'));
    await tester.pumpAndSettle();
    expect(repository.cancelled, isEmpty);
    expect(find.text('Vacances b'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler la période'));
    await tester.pumpAndSettle();
    expect(repository.cancelled, ['b']);
    expect(find.text('Indisponibilité annulée.'), findsOneWidget);
    expect(find.text('Aucune indisponibilité'), findsOneWidget);
  });

  testWidgets('un admin voit aussi les périodes de toute l’équipe', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeRepository(club: [_period('c', name: 'Hugo Lefèvre')]),
      admin: true,
    );
    expect(find.text('Équipe'), findsOneWidget);
    await tester.tap(find.text('Équipe'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hugo Lefèvre'), findsWidgets);
    expect(find.textContaining('Vacances c'), findsWidgets);
  });
}
