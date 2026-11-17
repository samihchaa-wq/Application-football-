import 'dart:convert';

/// Contrat JSON versionné, validé intégralement avant toute écriture.
class HistoryImportBatch {
  const HistoryImportBatch(this.matches);
  final List<Map<String, dynamic>> matches;
  int get count => matches.length;

  static HistoryImportBatch parse(String source, DateTime lastAllowedDate) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const FormatException('Le fichier JSON est illisible.');
    }
    if (decoded is! Map ||
        decoded['format'] != 'petit-filet-historique' ||
        decoded['version'] != 1 ||
        decoded['matches'] is! List) {
      throw const FormatException(
          'Format incorrect. Utilise le prompt Petit Filet v1.');
    }
    final rows = decoded['matches'] as List;
    if (rows.isEmpty || rows.length > 400) {
      throw const FormatException(
          'Le fichier doit contenir de 1 à 400 matchs.');
    }
    final out = <Map<String, dynamic>>[];
    final seen = <String, String>{};
    for (var i = 0; i < rows.length; i++) {
      final number = i + 1;
      if (rows[i] is! Map) {
        throw FormatException('Match $number : objet invalide.');
      }
      final row = Map<String, dynamic>.from(rows[i] as Map);
      final date = row['date'];
      final opponent = row['opponent'];
      final scored = row['score_for'];
      final conceded = row['score_against'];
      final home = row['is_home'];
      final kind = row['match_type'];
      if (date is! String ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
          opponent is! String ||
          opponent.trim().length < 2 ||
          opponent.trim().length > 100 ||
          scored is! int ||
          scored < 0 ||
          scored > 99 ||
          conceded is! int ||
          conceded < 0 ||
          conceded > 99 ||
          (home != null && home is! bool) ||
          (kind != null && kind != 'amical' && kind != 'championnat')) {
        throw FormatException(
            'Match $number : date, adversaire, score ou information renseignée invalide.');
      }
      final day = DateTime.tryParse(date);
      if (day == null ||
          [
                day.year.toString().padLeft(4, '0'),
                day.month.toString().padLeft(2, '0'),
                day.day.toString().padLeft(2, '0')
              ].join('-') !=
              date ||
          day.isAfter(DateTime(lastAllowedDate.year, lastAllowedDate.month,
              lastAllowedDate.day))) {
        throw FormatException('Match $number : date hors période autorisée.');
      }
      final clean = <String, dynamic>{
        'date': date,
        'opponent': opponent.trim(),
        'score_for': scored,
        'score_against': conceded,
        if (home != null) 'is_home': home,
        if (kind != null) 'match_type': kind,
      };
      for (final field in ['time', 'address', 'formation']) {
        final value = row[field];
        if (value == null) continue;
        if (value is! String) {
          throw FormatException('Match $number : $field invalide.');
        }
        if (value.trim().isNotEmpty) clean[field] = value.trim();
      }
      if (clean['address'] is String &&
          (clean['address'] as String).length > 200) {
        throw FormatException('Match $number : lieu trop long.');
      }
      if (clean['time'] is String &&
          !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$')
              .hasMatch(clean['time'] as String)) {
        throw FormatException('Match $number : heure invalide.');
      }
      var goalsTotal = 0;
      for (final field in ['present', 'starters', 'bench', 'scorers', 'motm']) {
        final entries = row[field];
        if (entries == null) continue;
        if (entries is! List || entries.length > 80) {
          throw FormatException('Match $number : liste $field invalide.');
        }
        clean[field] = <Map<String, dynamic>>[
          for (final player in entries) _checkPlayer(player, field, number),
        ];
        if (field == 'scorers') {
          for (final scorer in clean[field] as List) {
            goalsTotal += scorer['goals'] as int;
          }
        }
      }
      if (goalsTotal > scored) {
        throw FormatException('Match $number : plus de buteurs que de buts.');
      }
      final identity = '$date|${opponent.trim().toLowerCase()}';
      final signature = '$scored|$conceded|$home|$kind';
      if (seen.containsKey(identity) && seen[identity] != signature) {
        throw FormatException('Match $number : doublon contradictoire.');
      }
      seen[identity] = signature;
      out.add(clean);
    }
    return HistoryImportBatch(out);
  }

  static Map<String, dynamic> _checkPlayer(
      dynamic raw, String field, int number) {
    if (raw is! Map ||
        raw['name'] is! String ||
        (raw['name'] as String).trim().isEmpty ||
        (raw['name'] as String).trim().length > 80) {
      throw FormatException('Match $number : joueur invalide ($field).');
    }
    final out = <String, dynamic>{'name': (raw['name'] as String).trim()};
    if (field == 'scorers') {
      if (raw['goals'] is! int ||
          (raw['goals'] as int) < 1 ||
          (raw['goals'] as int) > 99) {
        throw FormatException('Match $number : nombre de buts invalide.');
      }
      out['goals'] = raw['goals'];
    }
    if (field == 'starters') {
      if (raw['position_code'] is String) {
        out['position_code'] = raw['position_code'];
      }
      if (raw['is_gk'] is bool) out['is_gk'] = raw['is_gk'];
      for (final axis in ['x_pct', 'y_pct']) {
        final value = raw[axis];
        if (value != null && (value is! num || value < 0 || value > 100)) {
          throw FormatException('Match $number : poste $axis invalide.');
        }
        if (value != null) out[axis] = value;
      }
    }
    return out;
  }
}
