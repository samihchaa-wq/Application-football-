/// Catégories qui peuvent être affichées dans le bilan de saison.
/// Un masque de bits permet un réglage par club, sans modifier les statistiques.
enum WrappedStatOption {
  matches(1, 'Matchs joués', 'Participations pendant la saison'),
  results(2, 'Victoires, nuls, défaites', 'Bilan collectif pendant tes matchs'),
  winRate(4, 'Pourcentage de victoires', 'Taux de victoire et classement'),
  goals(8, 'Buts', 'Nombre de buts marqués'),
  motm(16, 'Homme du match', 'Récompenses de l’équipe'),
  cleanSheets(32, 'Matchs sans encaisser', 'Rencontres avec zéro but encaissé'),
  position(64, 'Postes et polyvalence', 'Postes occupés et diversité'),
  responsiveness(128, 'Réactivité', 'Temps de réponse aux disponibilités'),
  badges(256, 'Badges', 'Badges obtenus pendant la saison');

  const WrappedStatOption(this.bit, this.label, this.description);

  final int bit;
  final String label;
  final String description;

  static const int allMask = 511;

  bool enabledIn(int mask) => (mask & bit) != 0;
}
