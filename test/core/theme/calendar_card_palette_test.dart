import 'package:petit_filet/core/theme/calendar_card_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('championnat bleu foncé et amical bleu clair sont distincts', () {
    expect(CalendarCardPalette.championshipSurface, const Color(0xFF0C234D));
    expect(CalendarCardPalette.championshipBorder, const Color(0xFF2459C6));
    expect(CalendarCardPalette.friendlyBorder, const Color(0xFF6CCBFF));
    expect(CalendarCardPalette.friendlySurface,
        isNot(CalendarCardPalette.championshipSurface));
  });

  test('entre nous violet foncé, événement or et annulation rouge', () {
    expect(CalendarCardPalette.internalBorder, const Color(0xFF7435B5));
    expect(CalendarCardPalette.eventBorder, const Color(0xFFE8BF4A));
    expect(CalendarCardPalette.cancelledBorder, const Color(0xFFEB4056));
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
}
