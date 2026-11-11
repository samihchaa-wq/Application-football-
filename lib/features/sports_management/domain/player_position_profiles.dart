// Postes de référence des joueurs.
//
// Chaque titularisation est projetée sur le poste le plus proche de la feuille
// de match, puis les saisons sont pondérées par récence (demi-vie 2 saisons).
//
// Dans la version multi-clubs, aucun archive embarqué : le socle est vide et
// les postes se construisent uniquement à partir des compositions réellement
// alignées dans l'application, pour le club concerné.

library;

/// Saison de référence de la pondération.
///
/// Les poids de ce fichier y sont ancrés : l'historique lu en base est
/// pondéré avec la même formule et le même ancrage, pour que les deux
/// sources s'additionnent sans se déformer.
const int kPositionProfilesReferenceSeason = 2025;

/// Nombre de saisons au bout duquel une titularisation ne pèse plus que
/// la moitié.
const double kPositionProfilesHalfLifeSeasons = 2.0;

/// Dernière composition couverte par l'archive.
///
/// Tout ce qui précède cette date est déjà compté ici : reprendre ces
/// matchs depuis la base les compterait deux fois.
final DateTime kPositionProfilesCoverageEnd = DateTime.utc(2026, 5, 21);

/// Un poste occupé par un joueur, et le poids de ses passages à ce poste.
class PlayerPositionSample {
  const PlayerPositionSample(this.slotLabel, this.weight);

  /// Étiquette du poste, telle que `matchSheetSlots` la nomme.
  final String slotLabel;

  /// Somme pondérée de ses titularisations à ce poste. La valeur est
  /// absolue, pas un pourcentage : c'est ce qui permet d'y ajouter les
  /// matchs joués depuis.
  final double weight;
}

/// Postes de référence d'un joueur, du plus fréquent au moins fréquent.
class PlayerPositionProfile {
  const PlayerPositionProfile({
    required this.displayName,
    required this.appearances,
    required this.samples,
    required this.totalWeight,
  });

  /// Nom du joueur dans l'archive du club, à titre indicatif. Vide pour
  /// un joueur connu uniquement par les matchs joués dans l'app.
  final String displayName;

  /// Nombre de titularisations relevées, toutes saisons confondues.
  final int appearances;

  /// Postes occupés, triés par poids décroissant. Jamais vide.
  final List<PlayerPositionSample> samples;

  /// Somme des poids de toutes ses titularisations, y compris les
  /// postes trop rares pour figurer dans [samples]. C'est le
  /// dénominateur des parts : sans lui, tronquer la queue de
  /// distribution gonflerait artificiellement le poste principal.
  final double totalWeight;

  /// Part du temps de jeu passée à un poste, entre 0 et 1.
  double shareOf(String slotLabel) {
    if (totalWeight <= 0) return 0;
    for (final sample in samples) {
      if (sample.slotLabel == slotLabel) {
        return sample.weight / totalWeight;
      }
    }
    return 0;
  }

  /// Le poste où le joueur a le plus joué.
  String get mainSlotLabel => samples.first.slotLabel;

  /// Son second poste, s'il en a réellement un.
  String? get secondarySlotLabel =>
      samples.length > 1 ? samples[1].slotLabel : null;

  /// Vrai quand aucun poste ne domine : le joueur est un couteau
  /// suisse, que les matchs entre nous rangent dans « Autre » plutôt
  /// que sous une ligne qui n'en est pas une.
  bool get isVersatile => shareOf(mainSlotLabel) < 0.3;
}

/// Profils indexés par identité canonique (`players.id`).
///
/// L'identité canonique traverse les saisons et les changements de nom,
/// contrairement à `season_players.id` ou au nom affiché.
///
/// Elle ne survit pas à une fusion d'identités : `merge_player_identities`
/// déplace l'historique sur l'identité gagnante puis supprime la perdante.
/// Les clés relevées ici se périment donc à chaque fusion, et un joueur dont
/// la clé a disparu retombe silencieusement dans « Autre ». Après toute
/// fusion, revérifier `tool/player_identity_map.json` contre
/// `public.player_aliases` et régénérer ce fichier.
const Map<String, PlayerPositionProfile> kPlayerPositionProfiles =
    <String, PlayerPositionProfile>{};
