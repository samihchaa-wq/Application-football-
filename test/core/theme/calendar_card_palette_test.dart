import 'package:petit_filet/core/theme/calendar_card_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('championnat bleu foncé et amical bleu clair sont distincts', () {
    expect(CalendarCardPalette.championshipSurface, const Color(0xFF0F2557));
    expect(CalendarCardPalette.championshipBorder, const Color(0xFF5C8DFF));
    expect(CalendarCardPalette.friendlyBorder, const Color(0xFF8FD3FF));
    expect(CalendarCardPalette.friendlySurface,
        isNot(CalendarCardPalette.championshipSurface));
  });

  test('entre nous violet, événement or et annulation rouge', () {
    expect(CalendarCardPalette.internalBorder, const Color(0xFFA987FF));
    expect(CalendarCardPalette.eventBorder, const Color(0xFFF2C94C));
    expect(CalendarCardPalette.cancelledBorder, const Color(0xFFFF5A6A));
  });

  test('les identités sportives sont identiques avant et après le match', () {
    expect(CalendarCardPalette.matchBorder('championnat'),
        CalendarCardPalette.championshipBorder);
    expect(CalendarCardPalette.matchBorder('amical'),
        CalendarCardPalette.friendlyBorder);
    expect(CalendarCardPalette.matchBorder('entre_nous'),
        CalendarCardPalette.internalBorder);
    expect(CalendarCardPalette.matchBorder('inconnu', unknownAsFinished: true),
        CalendarCardPalette.finishedBorder);
  });

  test(
      'chaque couleur de carte reste lisible : texte clair sur le fond, '
      'liseré (aussi utilisé comme texte) à 4,5:1 minimum', () {
    double ratio(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + .05) / (lo + .05);
    }

    final pairs = <String, (Color, Color)>{
      'championnat': (
        CalendarCardPalette.championshipSurface,
        CalendarCardPalette.championshipBorder,
      ),
      'amical': (
        CalendarCardPalette.friendlySurface,
        CalendarCardPalette.friendlyBorder,
      ),
      'entre nous': (
        CalendarCardPalette.internalSurface,
        CalendarCardPalette.internalBorder,
      ),
      'événement': (
        CalendarCardPalette.eventSurface,
        CalendarCardPalette.eventBorder,
      ),
    };
    pairs.forEach((name, pair) {
      expect(ratio(pair.$1, Colors.white), greaterThanOrEqualTo(4.5),
          reason: 'texte blanc sur $name');
      expect(ratio(pair.$1, pair.$2), greaterThanOrEqualTo(4.5),
          reason: 'liseré sur $name');
    });
  });
}
