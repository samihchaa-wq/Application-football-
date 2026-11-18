import 'package:petit_filet/core/widgets/match_detail_header_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0, 768.0]) {
    testWidgets('action Homme du match complète et tactile à $width px',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var tapped = false;
      const label = 'Vote de l’Homme du match enregistré';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MatchDetailHeaderCard(
              homeName: 'Équipe A',
              awayName: 'Équipe B',
              ownIsHome: true,
              kickoffAt: DateTime(2026, 11, 17, 20),
              compact: true,
              motmActionLabel: label,
              onMotmTap: () => tapped = true,
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text(label));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      final target = find
          .ancestor(of: find.text(label), matching: find.byType(InkWell))
          .first;
      expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
      await tester.tap(find.text(label));
      expect(tapped, isTrue);
    });
  }
}
