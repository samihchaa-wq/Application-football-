import 'package:petit_filet/core/theme/calendar_card_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('championnat bleu et amical bleu ciel sont distincts', () {
    expect(CalendarCardPalette.championshipSurface, const Color(0xFFE6EEF9));
    expect(CalendarCardPalette.championshipBorder, const Color(0xFF3866C4));
    expect(CalendarCardPalette.friendlyBorder, const Color(0xFF2F8FC4));
    expect(CalendarCardPalette.friendlySurface,
        isNot(CalendarCardPalette.championshipSurface));
  });

  test('entre nous violet, événement or et annulation rouge', () {
    expect(CalendarCardPalette.internalBorder, const Color(0xFF7A45B8));
    expect(CalendarCardPalette.eventBorder, const Color(0xFFC99A1E));
    expect(CalendarCardPalette.cancelledBorder, const Color(0xFFC93A4C));
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
