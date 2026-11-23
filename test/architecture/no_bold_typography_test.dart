import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _themed = [
  'core/theme/app_theme.dart',
  'core/widgets/calendar_scoreline.dart',
  'core/widgets/pf_status_banner.dart',
  'predictions/presentation/merged_matches_view.dart',
];

void main() {
  test('application typography contains no bold font weights', () {
    final boldWeight = RegExp(r'FontWeight\.(?:bold|w[5-9]00)');
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // L'habillage « Pelouse » porte ses graisses (titres Lora, boutons).
      if (_themed.any(entity.path.endsWith)) continue;

      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (boldWeight.hasMatch(line)) {
          offenders.add(
            '${entity.path}:${index + 1}: ${line.trim()}',
          );
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Le texte de l’application doit rester en graisse normale (w400), hors habillage central.\n'
          '${offenders.join('\n')}',
    );
  });
}
