import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/core/theme/app_theme.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + .05) / (lo + .05);
}

void main() {
  test('Présent et Absent choisis : texte blanc lisible (4,5:1 minimum)', () {
    expect(
      _ratio(AppTheme.availabilityInSolid, Colors.white),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _ratio(AppTheme.availabilityOutSolid, Colors.white),
      greaterThanOrEqualTo(4.5),
    );
  });
}
