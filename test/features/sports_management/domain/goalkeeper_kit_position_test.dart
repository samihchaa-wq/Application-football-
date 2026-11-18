import 'package:petit_filet/features/sports_management/domain/match_composition.dart';
import 'package:petit_filet/features/sports_management/domain/internal_match_composition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MatchCompositionEntry entry(bool goalkeeper, String? slot, String zone) =>
      MatchCompositionEntry.fromJson({
        'participant_id': 'p',
        'season_player_id': 's',
        'is_goalkeeper': goalkeeper,
        'zone': zone,
        'slot_label': slot
      });
  test('le poste du match prime sur le poste habituel', () {
    expect(entry(false, 'GB', 'field').wearsGoalkeeperKit, isTrue);
    expect(entry(true, 'DC', 'field').wearsGoalkeeperKit, isFalse);
    expect(entry(true, null, 'bench').wearsGoalkeeperKit, isTrue);
    expect(entry(false, null, 'bench').wearsGoalkeeperKit, isFalse);
  });
  test('la place du gardien prime sur un ancien libellé de poste', () {
    MatchCompositionEntry positioned(double x, double y, String slot) =>
        MatchCompositionEntry.fromJson({
          'participant_id': 'p',
          'season_player_id': 's',
          'is_goalkeeper': false,
          'zone': 'field',
          'slot_label': slot,
          'x': x,
          'y': y,
        });
    expect(positioned(.5, .89, 'DC').wearsGoalkeeperKit, isTrue);
    expect(positioned(.12, .67, 'GB').wearsGoalkeeperKit, isFalse);
  });

  test('même règle pour les deux équipes des matchs entre nous', () {
    for (final team in [1, 2]) {
      final player = InternalCompositionEntry(
          participantId: 'p',
          displayName: 'Alex',
          isGuest: false,
          isGoalkeeper: false,
          teamNo: team,
          zone: 'field',
          slotLabel: 'GB');
      expect(player.wearsGoalkeeperKit, isTrue);
      expect(player.copyWith(slotLabel: 'DC').wearsGoalkeeperKit, isFalse);
    }
  });
}
