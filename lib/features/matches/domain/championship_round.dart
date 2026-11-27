/// Journée de championnat.
///
/// Le numéro vient du calendrier de la ligue : le club ne joue pas forcément
/// toutes les journées d'une saison, donc il ne peut pas être déduit du rang
/// du match. L'application propose la journée suivante puis laisse
/// l'administrateur la corriger.
const int maxChampionshipRound = 60;

/// Journée proposée pour une nouvelle rencontre de championnat : une de plus
/// que la plus haute journée déjà enregistrée sur la saison.
int suggestedChampionshipRound(Iterable<int?> roundsOfSeason) {
  var highest = 0;
  for (final round in roundsOfSeason) {
    if (round != null && round > highest) highest = round;
  }
  final suggestion = highest + 1;
  return suggestion > maxChampionshipRound ? maxChampionshipRound : suggestion;
}

/// Autres rencontres de la saison qui portent déjà cette journée.
///
/// Deux rencontres peuvent légitimement partager un numéro quand la saison
/// enchaîne deux phases, donc c'est un avertissement et non une erreur.
bool championshipRoundIsAlreadyUsed({
  required int round,
  required Iterable<int?> roundsOfSeason,
}) {
  return roundsOfSeason.any((value) => value == round);
}

/// Journée proposée à la création d'un match : celle qui suit la journée de
/// la rencontre de championnat la plus récente (par date) de la saison.
///
/// Partir de la plus haute journée enregistrée proposait « J23 » quand une
/// seule rencontre ancienne portait un numéro élevé, alors que la dernière
/// journée prévue au calendrier était la J8. La date suit l'ordre dans lequel
/// l'administrateur saisit les journées ; à date égale, la plus haute gagne.
int suggestedChampionshipRoundAfterLatest(
  Iterable<({DateTime kickoffAt, int? round})> matchesOfSeason,
) {
  ({DateTime kickoffAt, int round})? latest;
  for (final match in matchesOfSeason) {
    final round = match.round;
    if (round == null) continue;
    final current = latest;
    if (current == null ||
        match.kickoffAt.isAfter(current.kickoffAt) ||
        (match.kickoffAt.isAtSameMomentAs(current.kickoffAt) &&
            round > current.round)) {
      latest = (kickoffAt: match.kickoffAt, round: round);
    }
  }
  final suggestion = (latest?.round ?? 0) + 1;
  return suggestion > maxChampionshipRound ? maxChampionshipRound : suggestion;
}
