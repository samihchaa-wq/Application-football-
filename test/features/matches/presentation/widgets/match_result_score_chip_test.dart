import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/features/matches/presentation/widgets/match_result_score_chip.dart';

/// Cinq confrontations côte à côte sur un petit téléphone : la date de chaque
/// case doit rester entière (elle s'affichait « 18/10/2 »).
void main() {
  testWidgets(
      'la date d’une confrontation n’est pas coupée en 5 cases étroites',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                for (var i = 0; i < 5; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  const Expanded(
                    child: MatchResultScoreChip(
                      scoreOwn: 3,
                      scoreOpponent: 1,
                      subtitle: '18/10/26',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    for (final element in find.text('18/10/26').evaluate()) {
      final paragraph = element.renderObject! as RenderParagraph;
      expect(paragraph.didExceedMaxLines, isFalse);
    }
    expect(tester.takeException(), isNull);
  });
}
