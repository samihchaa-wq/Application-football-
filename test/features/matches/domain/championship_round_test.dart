import 'package:petit_filet/features/matches/domain/championship_round.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('suggestedChampionshipRound', () {
    test('propose J1 sur une saison sans championnat', () {
      expect(suggestedChampionshipRound(const <int?>[]), 1);
    });

    test('propose une journée de plus que la plus haute enregistrée', () {
      expect(suggestedChampionshipRound(const [1, 2, 3]), 4);
    });

    test('ignore les rencontres sans journée', () {
      expect(suggestedChampionshipRound(const [1, null, 5, null]), 6);
    });

    test('suit les trous du calendrier de la ligue', () {
      // Saison 2025-2026 : 19 rencontres jusqu'à la J26, sept journées non
      // jouées. La suggestion part de la plus haute, pas du nombre de matchs.
      const rounds = [
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, //
        12, 13, 14, 16, 17, 20, 22, 23, 26,
      ];
      expect(suggestedChampionshipRound(rounds), 27);
    });

    test('ne dépasse jamais la borne haute', () {
      expect(
        suggestedChampionshipRound(const [maxChampionshipRound]),
        maxChampionshipRound,
      );
    });
  });

  group('championshipRoundIsAlreadyUsed', () {
    test('signale une journée déjà portée par une autre rencontre', () {
      expect(
        championshipRoundIsAlreadyUsed(
          round: 3,
          roundsOfSeason: const [1, 2, 3],
        ),
        isTrue,
      );
    });

    test('ne signale rien sur une journée libre', () {
      expect(
        championshipRoundIsAlreadyUsed(
          round: 4,
          roundsOfSeason: const [1, 2, 3, null],
        ),
        isFalse,
      );
    });
  });

  group('suggestedChampionshipRoundAfterLatest', () {
    test('suit la rencontre la plus récente, pas le plus haut numéro', () {
      expect(
        suggestedChampionshipRoundAfterLatest([
          (kickoffAt: DateTime(2026, 9, 1), round: 22),
          (kickoffAt: DateTime(2026, 11, 20), round: 7),
          (kickoffAt: DateTime(2026, 11, 28), round: 8),
        ]),
        9,
      );
    });

    test('ignore les rencontres sans numéro et démarre à J1', () {
      expect(suggestedChampionshipRoundAfterLatest(const []), 1);
      expect(
        suggestedChampionshipRoundAfterLatest([
          (kickoffAt: DateTime(2026, 11, 28), round: null),
          (kickoffAt: DateTime(2026, 11, 20), round: 4),
        ]),
        5,
      );
    });

    test('à date égale, garde la plus haute journée', () {
      final day = DateTime(2026, 11, 28, 21);
      expect(
        suggestedChampionshipRoundAfterLatest([
          (kickoffAt: day, round: 3),
          (kickoffAt: day, round: 5),
        ]),
        6,
      );
    });

    test('ne dépasse pas la journée maximale', () {
      expect(
        suggestedChampionshipRoundAfterLatest([
          (kickoffAt: DateTime(2026, 11, 28), round: maxChampionshipRound),
        ]),
        maxChampionshipRound,
      );
    });
  });
}
