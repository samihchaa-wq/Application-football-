import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _methodBlock(String source, String startMarker, String endMarker) {
  final start = source.indexOf(startMarker);
  final end = source.indexOf(endMarker, start);
  expect(start, isNonNegative, reason: 'Méthode attendue introuvable.');
  expect(end, greaterThan(start),
      reason: 'Fin de méthode attendue introuvable.');
  return source.substring(start, end);
}

void main() {
  // Empêche le retour à deux écritures serveur successives pour un même match.
  test('un match entre nous est sauvegardé avec une seule RPC', () {
    final repositorySource = File(
      'lib/features/matches/data/match_edit_schedule_repository.dart',
    ).readAsStringSync();
    final repositoryBlock = _methodBlock(
      repositorySource,
      'Future<void> updateInternalMatch({',
      'String _formatTime(',
    );

    expect(repositoryBlock, contains("'update_internal_match_v3'"));
    expect(repositoryBlock, contains("'p_address': address"));

    final formSource = File(
      'lib/features/matches/presentation/match_form_page.dart',
    ).readAsStringSync();
    expect(formSource, contains('repository.updateInternalMatch('));
    expect(formSource, isNot(contains('setMatchAddress(')));
  });
}
