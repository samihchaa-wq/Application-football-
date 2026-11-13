import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les 12 couleurs proposées dans « Réglages du club ».
const _palette = [
  0xFF1A4AC0, 0xFF1F6FEB, 0xFF0E9F9A, 0xFF168A52, 0xFF7CB518, 0xFFFBE80C, //
  0xFFF5A300, 0xFFE8590C, 0xFFD62828, 0xFFC2185B, 0xFF7B2CBF, 0xFFFFFFFF,
];

void main() {
  tearDown(AppTheme.resetClubColors);

  test(
      'le texte sélectionné reste lisible quelle que soit la couleur secondaire',
      () {
    for (final hex in _palette) {
      AppTheme.applyClubColors(secondary: Color(hex));
      final ratio =
          AppTheme.contrastRatio(AppTheme.accent, AppTheme.selectedSurface);
      expect(
        ratio,
        greaterThanOrEqualTo(AppTheme.minAccentContrast),
        reason: 'couleur ${hex.toRadixString(16)} : contraste $ratio',
      );
    }
  });
}
