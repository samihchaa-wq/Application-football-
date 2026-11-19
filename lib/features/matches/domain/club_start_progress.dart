/// Avancement d'un nouveau club dans ses premiers pas.
///
/// Un administrateur qui venait de créer son club arrivait sur « Aucun
/// match » sans savoir quoi faire, et le formulaire de match refusait
/// d'enregistrer tant qu'aucune saison n'était ouverte. Les quatre étapes
/// sont donc présentées dans l'ordre où elles fonctionnent.
class ClubStartProgress {
  const ClubStartProgress({
    required this.hasLogo,
    required this.hasOpenSeason,
    required this.hasMatches,
    required this.activeMembers,
  });

  /// Le club a déposé son logo (les couleurs ont toujours une valeur).
  final bool hasLogo;
  final bool hasOpenSeason;
  final bool hasMatches;

  /// Comptes validés du club, administrateur compris.
  final int activeMembers;

  bool get identityDone => hasLogo;
  bool get seasonDone => hasOpenSeason;
  bool get matchDone => hasMatches;
  bool get playersDone => activeMembers > 1;

  int get doneCount => [identityDone, seasonDone, matchDone, playersDone]
      .where((done) => done)
      .length;

  /// Le guide disparaît dès que le club joue avec des joueurs inscrits : le
  /// logo n'est pas indispensable pour être lancé.
  bool get complete => seasonDone && matchDone && playersDone;
}
