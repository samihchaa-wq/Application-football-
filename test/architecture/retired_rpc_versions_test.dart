import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Anciennes versions de fonctions serveur remplacées par une version plus
/// récente. L'appli n'en appelle plus aucune : ce contrôle empêche qu'un
/// ancien chemin revienne par erreur (copier-coller, retour arrière).
const _retired = [
  'admin_save_internal_composition_v2',
  'update_internal_match_v2',
  'admin_update_match_complete_v2',
];

void main() {
  test('aucune version retirée de fonction serveur n’est appelée', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final name in _retired) {
        if (source.contains("'$name'")) offenders.add('${file.path} → $name');
      }
    }
    expect(offenders, isEmpty);
  });
}
