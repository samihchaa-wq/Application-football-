import 'package:as_grinta/features/sports_management/domain/composition_simulation.dart';
import 'package:as_grinta/features/sports_management/domain/football_formation.dart';
import 'package:as_grinta/features/sports_management/domain/player_position_history.dart';
import 'package:as_grinta/features/sports_management/domain/player_position_profiles.dart';
import 'package:flutter_test/flutter_test.dart';

// Reprise de la logique de régression « simulation de saison » d'AS Grinta,
// avec uniquement des profils synthétiques et deux clubs indépendants.
// Ne jamais importer l'effectif, les identifiants ou les matchs réels du club.
SimulationCandidate candidate(
  String club,
  String suffix,
  String slot, {
  bool benchedLastTime = false,
  bool goalkeeper = false,
}) {
  return SimulationCandidate(
    participantId: '$club-$suffix',
    displayName: 'Joueur $suffix',
    benchCount: benchedLastTime ? 3 : 0,
    benchedLastTime: benchedLastTime,
    isGoalkeeper: goalkeeper,
    profile: PlayerPositionProfile(
      displayName: 'Joueur $suffix',
      appearances: 5,
      totalWeight: 5,
      samples: [PlayerPositionSample(slot, 5)],
    ),
  );
}

List<SimulationCandidate> clubSquad(String club) {
  final slots = formationForCode('4-2-1-3').slots;
  return [
    for (var i = 0; i < slots.length; i++)
      candidate(
        club,
        '$i',
        slots[i].label,
        goalkeeper: slots[i].label == 'GB',
      ),
    candidate(club, 'rotation', 'MDG', benchedLastTime: true),
  ];
}

void main() {
  test('Petit Filet utilise aussi les compositions antérieures à 2026', () {
    expect(kPlayerPositionProfiles, isEmpty);
    expect(
      kLivePositionHistoryStart.isBefore(DateTime.utc(2010)),
      isTrue,
    );

    final clubAHistory = mergePlayerPositionProfiles(
      archive: const {},
      history: [
        PlayedPosition(
          playerId: 'club-a-joueur-1',
          position: matchSheetSlotPositions['MOC']!,
          kickoffAt: DateTime.utc(2018, 9, 12),
        ),
      ],
    );
    final clubBHistory = mergePlayerPositionProfiles(
      archive: const {},
      history: [
        PlayedPosition(
          playerId: 'club-b-joueur-1',
          position: matchSheetSlotPositions['DCG']!,
          kickoffAt: DateTime.utc(2019, 9, 12),
        ),
      ],
    );

    expect(clubAHistory.keys, unorderedEquals(['club-a-joueur-1']));
    expect(clubBHistory.keys, unorderedEquals(['club-b-joueur-1']));
    expect(clubAHistory['club-a-joueur-1']!.mainSlotLabel, 'MOC');
    expect(clubBHistory['club-b-joueur-1']!.mainSlotLabel, 'DCG');
  });

  test('les simulations de deux clubs restent indépendantes et stables', () {
    final slots = formationForCode('4-2-1-3').slots;
    final aCandidates = clubSquad('club-a');
    final bCandidates = clubSquad('club-b');

    final a = simulateComposition(
      slots: slots,
      candidates: aCandidates,
    );
    final b = simulateComposition(
      slots: slots,
      candidates: bCandidates,
    );
    final aAgain = simulateComposition(
      slots: slots,
      candidates: aCandidates.reversed.toList(),
    );

    expect(a.emptySlots, isEmpty);
    expect(b.emptySlots, isEmpty);
    expect(a.stretchedPlacements, isEmpty);
    expect(b.stretchedPlacements, isEmpty);
    expect(a.placements, hasLength(11));
    expect(b.placements, hasLength(11));
    expect(a.bench, hasLength(1));
    expect(b.bench, hasLength(1));
    expect(
      a.placements.map((entry) => entry.candidate.participantId),
      everyElement(startsWith('club-a-')),
    );
    expect(
      b.placements.map((entry) => entry.candidate.participantId),
      everyElement(startsWith('club-b-')),
    );
    expect(
      a.placements.map((entry) => entry.candidate.participantId).toList(),
      aAgain.placements.map((entry) => entry.candidate.participantId).toList(),
    );
    expect(
      a.promotedFromBench.map((entry) => entry.candidate.participantId),
      contains('club-a-rotation'),
    );
    expect(
      b.promotedFromBench.map((entry) => entry.candidate.participantId),
      contains('club-b-rotation'),
    );
    expect(
      a.placements
          .where((entry) => entry.slot.label == 'GB')
          .single
          .candidate
          .isGoalkeeper,
      isTrue,
    );
    expect(
      b.placements
          .where((entry) => entry.slot.label == 'GB')
          .single
          .candidate
          .isGoalkeeper,
      isTrue,
    );
  });

  test('aucun joueur de champ n’est placé gardien par défaut', () {
    final slots = formationForCode('4-2-1-3').slots;
    final withoutGoalkeeper =
        clubSquad('club-c').where((entry) => !entry.isGoalkeeper).toList();
    final result = simulateComposition(
      slots: slots,
      candidates: withoutGoalkeeper,
    );

    expect(result.emptySlots.map((slot) => slot.label), contains('GB'));
    expect(
      result.placements.any((entry) => entry.slot.label == 'GB'),
      isFalse,
    );
  });
}
