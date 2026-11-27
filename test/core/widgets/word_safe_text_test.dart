import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/core/widgets/word_safe_text.dart';

void main() {
  testWidgets('un mot trop long rapetisse au lieu d’être coupé', (
    tester,
  ) async {
    const style = TextStyle(fontSize: 12);
    final scale = WordSafeText.scaleFor(
      text: 'Compétiteur',
      style: style,
      maxWidth: 40,
      textScaler: TextScaler.noScaling,
      textDirection: TextDirection.ltr,
    );
    expect(scale, lessThan(1));
    expect(scale, greaterThanOrEqualTo(0.7));
  });

  testWidgets('un texte qui tient garde sa taille', (tester) async {
    final scale = WordSafeText.scaleFor(
      text: 'Fidèle',
      style: const TextStyle(fontSize: 12),
      maxWidth: 200,
      textScaler: TextScaler.noScaling,
      textDirection: TextDirection.ltr,
    );
    expect(scale, 1);
  });

  testWidgets('aucun mot n’est coupé sur deux lignes à 320 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 110,
              child: WordSafeText(
                'Compétiteur',
                maxLines: 2,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('Compétiteur'));
    final painter = TextPainter(
      text: TextSpan(text: 'Compétiteur', style: text.style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 110);
    expect(painter.computeLineMetrics(), hasLength(1));
    painter.dispose();
  });
}
