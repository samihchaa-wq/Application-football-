import 'package:as_grinta/features/matches/domain/history_match_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alice = HistoryPlayer(
    playerId: 'p-alice',
    name: 'Alice Gardienne',
    displayName: 'Alice',
    isGoalkeeper: true,
  );
  const bruno = HistoryPlayer(
    playerId: 'p-bruno',
    name: 'Bruno Buteur',
    displayName: 'Bruno',
  );
  final ancien = HistoryPlayer.former('  Vieux   Joueur ');
  final lastAllowed = DateTime(2026, 6, 30);

  test('seuls l’adversaire et la date sont exigés', () {
    const empty = HistoryMatchDraft();
    expect(empty.missingRequirement(lastAllowed), contains('adversaire'));
    expect(
      empty.copyWith(opponent: 'FC Test').missingRequirement(lastAllowed),
      contains('date'),
    );
    expect(
      empty
          .copyWith(opponent: 'FC Test', date: DateTime(2026, 7, 1))
          .missingRequirement(lastAllowed),
      contains('30 juin 2026'),
    );
    expect(
      empty
          .copyWith(opponent: 'FC Test', date: DateTime(2026, 6, 30))
          .missingRequirement(lastAllowed),
      isNull,
    );
  });

  test('un ancien joueur garde un nom propre, sans fiche', () {
    expect(ancien.name, 'Vieux Joueur');
    expect(ancien.playerId, isNull);
    expect(ancien.toJson(), {'name': 'Vieux Joueur'});
  });

  test('les buts ne dépassent jamais le score', () {
    var draft = const HistoryMatchDraft()
        .setScoreFor(2)
        .togglePresent(bruno)
        .togglePresent(alice);
    draft = draft.setGoals(bruno, 3);
    expect(draft.goals[bruno.key], 2);
    draft = draft.setGoals(alice, 1);
    expect(draft.goals[alice.key], isNull, reason: 'plus de but disponible');

    // Baisser le score retire les buts en trop.
    draft = draft.setScoreFor(1);
    expect(draft.assignedGoals, 1);
  });

  test('retirer un présent efface ses buts, son titre et son poste', () {
    var draft = const HistoryMatchDraft()
        .setScoreFor(1)
        .togglePresent(bruno)
        .setGoals(bruno, 1)
        .copyWith(manOfTheMatch: bruno, formation: '4-4-2 à plat')
        .placeStarter(slotLabel: 'BU', xPct: 50, yPct: 14, player: bruno);
    draft = draft.togglePresent(bruno);
    expect(draft.present, isEmpty);
    expect(draft.goals, isEmpty);
    expect(draft.manOfTheMatch, isNull);
    expect(draft.starters, isEmpty);
  });

  test('un joueur ne peut occuper qu’un poste', () {
    final draft = const HistoryMatchDraft()
        .togglePresent(bruno)
        .placeStarter(slotLabel: 'BUG', xPct: 37, yPct: 14, player: bruno)
        .placeStarter(slotLabel: 'BUD', xPct: 63, yPct: 14, player: bruno);
    expect(draft.starters.map((s) => s.slotLabel), ['BUD']);
  });

  test('sans composition, les présents partent en effectif simple', () {
    final payload = const HistoryMatchDraft()
        .copyWith(
          opponent: ' FC Test ',
          date: DateTime(2025, 3, 9),
          scoreFor: 2,
          scoreAgainst: 1,
        )
        .togglePresent(alice)
        .togglePresent(bruno)
        .togglePresent(ancien)
        .setGoals(bruno, 2)
        .copyWith(manOfTheMatch: bruno)
        .toPayload();

    expect(payload['opponent'], 'FC Test');
    expect(payload['date'], '2025-03-09');
    expect(payload['match_type'], 'championnat');
    expect(payload['starters'], isEmpty);
    expect(payload['bench'], isEmpty);
    expect(payload['present'], [
      {'name': 'Alice Gardienne', 'player_id': 'p-alice'},
      {'name': 'Bruno Buteur', 'player_id': 'p-bruno'},
      {'name': 'Vieux Joueur'},
    ]);
    expect(payload['scorers'], [
      {'name': 'Bruno Buteur', 'player_id': 'p-bruno', 'goals': 2},
    ]);
    expect(payload['motm'], [
      {'name': 'Bruno Buteur', 'player_id': 'p-bruno'},
    ]);
    expect(payload.containsKey('formation'), isFalse);
  });

  test('avec une composition, les présents non placés vont sur le banc', () {
    final payload = const HistoryMatchDraft()
        .copyWith(
          opponent: 'FC Test',
          date: DateTime(2025, 3, 9),
          formation: '4-4-2 à plat',
          isFriendly: true,
        )
        .togglePresent(alice)
        .togglePresent(bruno)
        .placeStarter(slotLabel: 'GB', xPct: 50, yPct: 89, player: alice)
        .toPayload();

    expect(payload['formation'], '4-4-2 à plat');
    expect(payload['match_type'], 'amical');
    expect(payload['starters'], [
      {
        'name': 'Alice Gardienne',
        'player_id': 'p-alice',
        'position_code': 'GB',
        'is_gk': true,
        'x_pct': 50.0,
        'y_pct': 89.0,
      },
    ]);
    expect(payload['bench'], [
      {'name': 'Bruno Buteur', 'player_id': 'p-bruno'},
    ]);
    expect(payload['present'], isEmpty);
  });

  test('la saisie rapide garde l’effectif et avance d’une semaine', () {
    final draft = const HistoryMatchDraft()
        .copyWith(
          opponent: 'FC Test',
          date: DateTime(2025, 3, 9),
          scoreFor: 3,
          isFriendly: true,
        )
        .togglePresent(bruno)
        .setGoals(bruno, 1);

    final next = draft.nextQuickEntry(lastAllowed);
    expect(next.opponent, isEmpty);
    expect(next.date, DateTime(2025, 3, 16));
    expect(next.present, [bruno]);
    expect(next.scoreFor, 0);
    expect(next.goals, isEmpty);
    expect(next.isFriendly, isTrue);

    // Jamais au-delà du dernier jour autorisé.
    final atEnd = draft.copyWith(date: DateTime(2026, 6, 28));
    expect(atEnd.nextQuickEntry(lastAllowed).date, DateTime(2026, 6, 28));
  });

  test('le contexte du serveur liste effectif et anciens joueurs', () {
    final context = HistoryEntryContext.fromJson({
      'last_allowed_date': '2026-06-30',
      'players': [
        {
          'player_id': 'p-alice',
          'name': 'Alice Gardienne',
          'display_name': 'Alice',
          'is_goalkeeper': true,
          'in_current_roster': true,
        },
      ],
      'former_players': ['Vieux Joueur'],
      'opponents': ['FC Test'],
    });
    expect(context.lastAllowedDate, DateTime(2026, 6, 30));
    expect(
        context.players.map((p) => p.displayName), ['Alice', 'Vieux Joueur']);
    expect(context.players.first.isGoalkeeper, isTrue);
    expect(context.opponents, ['FC Test']);
  });
}
