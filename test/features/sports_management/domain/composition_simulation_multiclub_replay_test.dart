import 'package:as_grinta/features/sports_management/domain/composition_simulation.dart';
import 'package:as_grinta/features/sports_management/domain/football_formation.dart';
import 'package:as_grinta/features/sports_management/domain/player_position_history.dart';
import 'package:as_grinta/features/sports_management/domain/player_position_profiles.dart';
import 'package:flutter_test/flutter_test.dart';

// Adaptation du rejeu de saison d'AS Grinta : les cas métier sont conservés,
// mais les noms, identifiants et résultats réels sont remplacés par des
// effectifs entièrement fictifs. Aucun historique de club n'est embarqué.

Map<String, String> _syntheticSquad(String club) => {
      '$club-gardien': 'GB',
      '$club-lateral-g': 'DG',
      '$club-central-g': 'DCG',
      '$club-central-d': 'DCD',
      '$club-lateral-d': 'DD',
      '$club-milieu-g': 'MDG',
      '$club-milieu-d': 'MDD',
      '$club-meneur': 'MOC',
      '$club-ailier-g': 'AG',
      '$club-avant-centre': 'BU',
      '$club-ailier-d': 'AD',
      '$club-reserve-moc': 'MOC',
    };

List<SimulationCandidate> _convocation(String club) {
  final squad = _syntheticSquad(club);
  // Deux compositions fictives déjà jouées alimentent les profils de postes.
  // Le réserviste a déjà joué en MOC mais vient de commencer sur le banc.
  final profiles = mergePlayerPositionProfiles(
    archive: const <String, PlayerPositionProfile>{},
    history: [
      for (final date in [DateTime.utc(2026, 9, 7), DateTime.utc(2026, 9, 21)])
        for (final entry in squad.entries)
          PlayedPosition(
            playerId: entry.key,
            position: matchSheetSlotPositions[entry.value]!,
            kickoffAt: date,
          ),
    ],
  );
  return [
    for (final entry in squad.entries)
      SimulationCandidate(
        participantId: entry.key,
        // Deux clubs peuvent avoir des noms affichés identiques.
        displayName: entry.key.substring(club.length + 1),
        benchCount: entry.key == '$club-reserve-moc' ? 1 : 0,
        profile: profiles[entry.key],
        isGoalkeeper: entry.value == 'GB',
        benchedLastTime: entry.key == '$club-reserve-moc',
      ),
  ];
}

SimulatedComposition _simulate(List<SimulationCandidate> squad) =>
    simulateComposition(
      slots: formationForCode('4-2-1-3').slots,
      candidates: squad,
    );

String? _starterAt(SimulatedComposition composition, String slot) {
  for (final placement in composition.placements) {
    if (placement.slot.label == slot) {
      return placement.candidate.participantId;
    }
  }
  return null;
}

List<String> _selected(SimulatedComposition composition) =>
    composition.placements
        .map((placement) =>
            '${placement.slot.label}:${placement.candidate.participantId}')
        .toList();

void main() {
  test('rejeu fictif : onze crédible et ancien remplaçant promu', () {
    final composition = _simulate(_convocation('alpha'));

    expect(composition.emptySlots, isEmpty);
    expect(composition.placements, hasLength(11));
    expect(composition.bench, hasLength(1));
    expect(composition.stretchedPlacements, isEmpty);
    expect(_starterAt(composition, 'GB'), 'alpha-gardien');
    expect(_starterAt(composition, 'MOC'), 'alpha-reserve-moc');
    expect(
      composition.promotedFromBench
          .map((placement) => placement.candidate.participantId),
      contains('alpha-reserve-moc'),
    );

    // Un défenseur de métier ne prend pas le poste d'un milieu.
    for (final placement in composition.placements) {
      if (placement.candidate.participantId.contains('central-') ||
          placement.candidate.participantId.contains('lateral-')) {
        expect(
          {'MDG', 'MDD', 'MOC'},
          isNot(contains(placement.slot.label)),
        );
      }
    }
  });

  test('rejeu fictif : la sélection ignore l’ordre des convoqués', () {
    final squad = _convocation('alpha');
    final ordered = _simulate(squad);
    final reversed = _simulate(squad.reversed.toList());

    expect(_selected(reversed), _selected(ordered));
    expect(
      reversed.bench.map((player) => player.participantId),
      ordered.bench.map((player) => player.participantId),
    );
  });

  test('rejeu fictif : deux clubs aux mêmes noms restent indépendants', () {
    final alpha = _simulate(_convocation('alpha'));
    final bravo = _simulate(_convocation('bravo'));

    expect(_starterAt(alpha, 'GB'), 'alpha-gardien');
    expect(_starterAt(bravo, 'GB'), 'bravo-gardien');
    expect(_starterAt(alpha, 'MOC'), 'alpha-reserve-moc');
    expect(_starterAt(bravo, 'MOC'), 'bravo-reserve-moc');
    expect(
      alpha.placements.every(
        (placement) => placement.candidate.participantId.startsWith('alpha-'),
      ),
      isTrue,
    );
    expect(
      bravo.placements.every(
        (placement) => placement.candidate.participantId.startsWith('bravo-'),
      ),
      isTrue,
    );
  });
}
