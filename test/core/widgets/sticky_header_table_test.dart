import 'package:petit_filet/core/widgets/sticky_header_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'la colonne figée reste en place quand les colonnes de stats défilent',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: StickyHeaderTableCard(
                pinnedHeader: const Text('Joueur'),
                scrollableHeader: const Row(
                  children: [
                    Expanded(child: Text('COL_A')),
                    Expanded(child: Text('COL_B')),
                    Expanded(child: Text('COL_C')),
                    Expanded(child: Text('COL_D')),
                  ],
                ),
                rows: [
                  StickyTableRow(
                    pinned: const Text('Alice'),
                    scrollable: const Row(
                      children: [
                        Expanded(child: Text('1')),
                        Expanded(child: Text('2')),
                        Expanded(child: Text('3')),
                        Expanded(child: Text('4')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final beforeName = tester.getTopLeft(find.text('Alice'));
      final beforeHeaderA = tester.getTopLeft(find.text('COL_A'));

      await tester.drag(find.text('1'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      final afterName = tester.getTopLeft(find.text('Alice'));
      final afterHeaderA = tester.getTopLeft(find.text('COL_A'));

      expect(afterName, beforeName);
      expect(afterHeaderA.dx, lessThan(beforeHeaderA.dx));
    },
  );

  Widget table({required double width, required double minWidth}) =>
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: 300,
            child: StickyHeaderTableCard(
              minWidth: minWidth,
              pinnedHeader: const Text('Joueur'),
              scrollableHeader: const Row(
                children: [
                  Expanded(child: Text('A')),
                  Expanded(child: Text('B'))
                ],
              ),
              rows: [
                StickyTableRow(
                  pinned: const Text('Alice'),
                  scrollable: const Row(
                    children: [
                      Expanded(child: Text('1')),
                      Expanded(child: Text('2'))
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  double hintOpacity(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(find.byKey(const ValueKey('table-scroll-hint')))
      .opacity;

  testWidgets(
      'un tableau plus large que l’écran montre l’indice de défilement '
      'jusqu’au bout de la dernière colonne', (tester) async {
    await tester.pumpWidget(table(width: 360, minWidth: 700));
    await tester.pumpAndSettle();
    expect(hintOpacity(tester), 1);

    await tester.drag(find.text('1'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(hintOpacity(tester), 0);
  });

  testWidgets('un tableau qui tient en largeur n’affiche aucun indice',
      (tester) async {
    await tester.pumpWidget(table(width: 600, minWidth: 300));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('table-scroll-hint')), findsNothing);
  });
}
