import 'dart:convert';

import 'package:petit_filet/features/matches/domain/history_import_batch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cutoff = DateTime(2025, 6, 30);

  Map<String, dynamic> match({
    String date = '2024-10-20',
    String opponent = 'Exemple FC',
    int scored = 3,
    int conceded = 1,
  }) =>
      {
        'date': date,
        'opponent': opponent,
        'score_for': scored,
        'score_against': conceded,
        'is_home': true,
        'match_type': 'championnat',
      };

  String document(List<Map<String, dynamic>> matches) => jsonEncode({
        'format': 'petit-filet-historique',
        'version': 1,
        'matches': matches,
      });

  test('350 matchs valides sont acceptés sans changement de score', () {
    final rows = List.generate(
      350,
      (i) => match(
        date: DateTime(2023, 1, 1)
            .add(Duration(days: i))
            .toIso8601String()
            .substring(0, 10),
      ),
    );
    final batch = HistoryImportBatch.parse(document(rows), cutoff);
    expect(batch.count, 350);
    expect(batch.matches.last['score_for'], 3);
  });

  test('accepte les champs domicile/type absents sans les inventer', () {
    final row = match()..remove('is_home');
    final withoutHome = HistoryImportBatch.parse(document([row]), cutoff);
    expect(withoutHome.matches.single.containsKey('is_home'), false);
    row['is_home'] = true;
    row.remove('match_type');
    final withoutType = HistoryImportBatch.parse(document([row]), cutoff);
    expect(withoutType.matches.single.containsKey('match_type'), false);
  });

  test('accepte un match dans une saison déjà suivie', () {
    final batch = HistoryImportBatch.parse(
      document([match(date: '2025-07-01')]),
      DateTime(2026, 11, 17),
    );
    expect(batch.count, 1);
  });

  test('refuse les dates normalisées incorrectes', () {
    expect(
      () => HistoryImportBatch.parse(
        document([match(date: '2024-02-30')]),
        cutoff,
      ),
      throwsFormatException,
    );
  });

  test('refuse un fichier contradictoire et les buts excédentaires', () {
    expect(
      () => HistoryImportBatch.parse(
        document([match(scored: 1), match(scored: 2)]),
        cutoff,
      ),
      throwsFormatException,
    );
    final row = match(scored: 1);
    row['scorers'] = [
      {'name': 'Alex Martin', 'goals': 2}
    ];
    expect(
      () => HistoryImportBatch.parse(document([row]), cutoff),
      throwsFormatException,
    );
  });

  test('filtre les ID de joueur injectés dans un export IA', () {
    final row = match();
    row['present'] = [
      {'name': 'Alex Martin', 'player_id': 'id-falsifie'},
    ];
    final batch = HistoryImportBatch.parse(document([row]), cutoff);
    expect((batch.matches.single['present'] as List).single, {
      'name': 'Alex Martin',
    });
  });

  test('rejet d’un format inconnu ou fichier vide', () {
    expect(
      () => HistoryImportBatch.parse('{"version":2}', cutoff),
      throwsFormatException,
    );
    expect(
      () => HistoryImportBatch.parse(document([]), cutoff),
      throwsFormatException,
    );
  });
}
