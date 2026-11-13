import 'package:flutter/foundation.dart';

/// Un joueur proposé dans le formulaire d'ajout d'un match passé : un membre
/// de l'effectif (il a une fiche, [playerId]) ou un ancien joueur saisi à la
/// main (sans fiche).
@immutable
class HistoryPlayer {
  const HistoryPlayer({
    required this.name,
    required this.displayName,
    this.playerId,
    this.isGoalkeeper = false,
    this.photoUrl,
    this.inCurrentRoster = false,
  });

  factory HistoryPlayer.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString().trim();
    final display = (json['display_name'] ?? '').toString().trim();
    final photo = (json['photo_url'] ?? '').toString().trim();
    return HistoryPlayer(
      playerId: json['player_id']?.toString(),
      name: name,
      displayName: display.isEmpty ? name : display,
      isGoalkeeper: json['is_goalkeeper'] == true,
      photoUrl: photo.isEmpty ? null : photo,
      inCurrentRoster: json['in_current_roster'] == true,
    );
  }

  /// Ancien joueur sans fiche, connu seulement par son nom.
  factory HistoryPlayer.former(String name) {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    return HistoryPlayer(name: clean, displayName: clean);
  }

  /// Nom complet envoyé au serveur : il relie le joueur à ses statistiques.
  final String name;

  /// Appellation affichée (surnom ou prénom).
  final String displayName;
  final String? playerId;
  final bool isGoalkeeper;
  final String? photoUrl;
  final bool inCurrentRoster;

  /// Clé stable : la fiche quand elle existe, sinon le nom.
  String get key => playerId ?? 'nom:${name.toLowerCase()}';

  Map<String, dynamic> toJson() => {
        'name': name,
        if (playerId != null) 'player_id': playerId,
      };

  @override
  bool operator ==(Object other) => other is HistoryPlayer && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// Ce que le serveur fournit au formulaire.
@immutable
class HistoryEntryContext {
  const HistoryEntryContext({
    required this.lastAllowedDate,
    required this.players,
    required this.opponents,
  });

  factory HistoryEntryContext.fromJson(Map<String, dynamic> json) {
    final players = <HistoryPlayer>[
      for (final raw in (json['players'] as List? ?? const []))
        if (raw is Map) HistoryPlayer.fromJson(Map<String, dynamic>.from(raw)),
      for (final raw in (json['former_players'] as List? ?? const []))
        if (raw is String && raw.trim().isNotEmpty) HistoryPlayer.former(raw),
    ];
    return HistoryEntryContext(
      lastAllowedDate:
          DateTime.tryParse('${json['last_allowed_date']}') ?? DateTime.now(),
      players: players,
      opponents: [
        for (final raw in (json['opponents'] as List? ?? const []))
          if (raw is String) raw,
      ],
    );
  }

  /// Dernier jour qu'on peut saisir : la veille de la première saison
  /// suivie dans l'application.
  final DateTime lastAllowedDate;
  final List<HistoryPlayer> players;
  final List<String> opponents;
}

/// Un titulaire placé sur un poste du terrain.
@immutable
class HistoryStarter {
  const HistoryStarter({
    required this.player,
    required this.slotLabel,
    required this.xPct,
    required this.yPct,
  });

  final HistoryPlayer player;
  final String slotLabel;
  final double xPct;
  final double yPct;

  bool get isGoalkeeper => slotLabel == 'GB';
}

/// Le match passé en cours de saisie. Seuls l'adversaire, la date et le
/// score sont obligatoires ; tout le reste est facultatif.
@immutable
class HistoryMatchDraft {
  const HistoryMatchDraft({
    this.opponent = '',
    this.date,
    this.isHome = true,
    this.address = '',
    this.isFriendly = false,
    this.scoreFor = 0,
    this.scoreAgainst = 0,
    this.present = const [],
    this.goals = const {},
    this.manOfTheMatch,
    this.formation,
    this.starters = const [],
  });

  final String opponent;
  final DateTime? date;
  final bool isHome;
  final String address;
  final bool isFriendly;
  final int scoreFor;
  final int scoreAgainst;

  /// Les joueurs présents (l'effectif du match).
  final List<HistoryPlayer> present;

  /// Buts par joueur, clé [HistoryPlayer.key].
  final Map<String, int> goals;
  final HistoryPlayer? manOfTheMatch;
  final String? formation;
  final List<HistoryStarter> starters;

  int get assignedGoals => goals.values.fold(0, (sum, value) => sum + value);

  HistoryMatchDraft copyWith({
    String? opponent,
    DateTime? date,
    bool? isHome,
    String? address,
    bool? isFriendly,
    int? scoreFor,
    int? scoreAgainst,
    List<HistoryPlayer>? present,
    Map<String, int>? goals,
    HistoryPlayer? manOfTheMatch,
    bool clearManOfTheMatch = false,
    String? formation,
    bool clearFormation = false,
    List<HistoryStarter>? starters,
  }) {
    return HistoryMatchDraft(
      opponent: opponent ?? this.opponent,
      date: date ?? this.date,
      isHome: isHome ?? this.isHome,
      address: address ?? this.address,
      isFriendly: isFriendly ?? this.isFriendly,
      scoreFor: scoreFor ?? this.scoreFor,
      scoreAgainst: scoreAgainst ?? this.scoreAgainst,
      present: present ?? this.present,
      goals: goals ?? this.goals,
      manOfTheMatch:
          clearManOfTheMatch ? null : (manOfTheMatch ?? this.manOfTheMatch),
      formation: clearFormation ? null : (formation ?? this.formation),
      starters: starters ?? this.starters,
    );
  }

  /// Ajoute ou retire un joueur de l'effectif. Le retirer efface aussi ses
  /// buts, son titre d'Étoile du match et son poste.
  HistoryMatchDraft togglePresent(HistoryPlayer player) {
    if (present.contains(player)) {
      return HistoryMatchDraft(
        opponent: opponent,
        date: date,
        isHome: isHome,
        address: address,
        isFriendly: isFriendly,
        scoreFor: scoreFor,
        scoreAgainst: scoreAgainst,
        present: [...present]..remove(player),
        goals: Map.of(goals)..remove(player.key),
        manOfTheMatch: manOfTheMatch == player ? null : manOfTheMatch,
        formation: formation,
        starters: [
          for (final starter in starters)
            if (starter.player != player) starter,
        ],
      );
    }
    return copyWith(present: [...present, player]);
  }

  /// Change le nombre de buts d'un joueur (jamais au-delà du score).
  HistoryMatchDraft setGoals(HistoryPlayer player, int value) {
    final next = Map.of(goals);
    final others = assignedGoals - (goals[player.key] ?? 0);
    final clamped = value.clamp(0, (scoreFor - others).clamp(0, 99));
    if (clamped == 0) {
      next.remove(player.key);
    } else {
      next[player.key] = clamped;
    }
    return copyWith(goals: next);
  }

  /// Baisser le score retire les buts attribués en trop, en partant du
  /// dernier buteur.
  HistoryMatchDraft setScoreFor(int value) {
    final score = value.clamp(0, 99);
    final next = Map.of(goals);
    var excess = next.values.fold(0, (sum, v) => sum + v) - score;
    for (final key in next.keys.toList().reversed) {
      if (excess <= 0) break;
      final current = next[key]!;
      final removed = current < excess ? current : excess;
      excess -= removed;
      if (current - removed == 0) {
        next.remove(key);
      } else {
        next[key] = current - removed;
      }
    }
    return copyWith(scoreFor: score, goals: next);
  }

  /// Place (ou retire, avec `null`) un joueur sur un poste.
  HistoryMatchDraft placeStarter({
    required String slotLabel,
    required double xPct,
    required double yPct,
    HistoryPlayer? player,
  }) {
    final next = [
      for (final starter in starters)
        if (starter.slotLabel != slotLabel && starter.player != player) starter,
      if (player != null)
        HistoryStarter(
          player: player,
          slotLabel: slotLabel,
          xPct: xPct,
          yPct: yPct,
        ),
    ];
    return copyWith(starters: next);
  }

  /// Ce qui manque pour enregistrer, ou `null` si tout est bon.
  String? missingRequirement(DateTime lastAllowedDate) {
    if (opponent.trim().length < 2) return 'Indique le nom de l’adversaire.';
    final day = date;
    if (day == null) return 'Indique la date du match.';
    final last = _dateOnly(lastAllowedDate);
    if (_dateOnly(day).isAfter(last)) {
      return 'Choisis une date jusqu’au ${_frenchDate(last)} au plus tard.';
    }
    return null;
  }

  /// Version envoyée au serveur.
  Map<String, dynamic> toPayload() {
    final day = date!;
    final starterKeys = {for (final s in starters) s.player.key};
    final placed = starters.isNotEmpty;
    final playersByKey = {for (final player in present) player.key: player};
    return {
      'opponent': opponent.trim(),
      'date': '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}',
      'is_home': isHome,
      if (address.trim().isNotEmpty) 'address': address.trim(),
      'match_type': isFriendly ? 'amical' : 'championnat',
      'score_for': scoreFor,
      'score_against': scoreAgainst,
      if (placed && formation != null) 'formation': formation,
      'starters': [
        for (final starter in starters)
          {
            ...starter.player.toJson(),
            'position_code': starter.slotLabel,
            'is_gk': starter.isGoalkeeper,
            'x_pct': starter.xPct,
            'y_pct': starter.yPct,
          },
      ],
      // Avec une composition, les présents non placés sont sur le banc ;
      // sans composition, ils sont simplement présents.
      'bench': [
        if (placed)
          for (final player in present)
            if (!starterKeys.contains(player.key)) player.toJson(),
      ],
      'present': [
        if (!placed)
          for (final player in present) player.toJson(),
      ],
      'scorers': [
        for (final entry in goals.entries)
          if (entry.value > 0 && playersByKey[entry.key] != null)
            {...playersByKey[entry.key]!.toJson(), 'goals': entry.value},
      ],
      'motm': [
        if (manOfTheMatch != null) manOfTheMatch!.toJson(),
      ],
    };
  }

  /// Point de départ du match suivant en saisie rapide : même effectif,
  /// une semaine plus tard, le reste à remplir.
  HistoryMatchDraft nextQuickEntry(DateTime lastAllowedDate) {
    final current = date;
    DateTime? next;
    if (current != null) {
      final candidate = current.add(const Duration(days: 7));
      next = candidate.isAfter(lastAllowedDate) ? current : candidate;
    }
    return HistoryMatchDraft(
      date: next,
      isFriendly: isFriendly,
      present: present,
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _frenchDate(DateTime date) {
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
