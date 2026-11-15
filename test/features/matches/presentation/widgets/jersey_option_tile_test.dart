import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/features/matches/domain/jersey_option.dart';
import 'package:as_grinta/features/matches/presentation/widgets/jersey_option_tile.dart';
import 'package:as_grinta/features/matches/presentation/widgets/kit_jersey.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    ClubKits.reset();
    ClubKits.setFromJson([
      {
        'slot': 'france',
        'label': 'Rouge A',
        'body': '#2255CC',
        'trim': '#FFFF00',
        'goalkeeper_body': '#138450',
        'goalkeeper_trim': '#FFFFFF',
        'enabled': true,
      },
      {
        'slot': 'orange',
        'label': 'Ext A',
        'body': '#FFFFFF',
        'trim': '#CC2020',
        'goalkeeper_body': '#F0A100',
        'goalkeeper_trim': '#FFFFFF',
        'enabled': true,
      },
    ]);
  });
  tearDown(ClubKits.reset);

  Future<void> showPicker(
    WidgetTester tester, {
    required JerseyOption? selected,
    ValueChanged<JerseyOption?>? onChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: JerseyOptionPicker(
                selected: selected,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('un seul maillot joueur par tenue, aucun maillot gardien', (
    tester,
  ) async {
    await showPicker(tester, selected: JerseyOption.orange, onChanged: (_) {});

    expect(find.byType(JerseyOptionTile), findsNWidgets(2));
    expect(find.byType(KitJersey), findsNWidgets(2));
    expect(
      tester.widgetList<KitJersey>(find.byType(KitJersey))
          .every((jersey) => !jersey.isGoalkeeper),
      isTrue,
    );
    expect(find.text('Rouge A'), findsOneWidget);
    expect(find.text('Ext A'), findsOneWidget);
  });

  testWidgets('la coche est sur le maillot joueur sélectionné', (tester) async {
    await showPicker(tester, selected: JerseyOption.orange, onChanged: (_) {});

    final selectedTile = find.ancestor(
      of: find.byIcon(Icons.check_circle_rounded),
      matching: find.byType(JerseyOptionTile),
    );
    expect(selectedTile, findsOneWidget);
    expect(
      tester.widget<JerseyOptionTile>(selectedTile).option,
      JerseyOption.orange,
    );

    final jersey = find.descendant(
      of: selectedTile,
      matching: find.byType(KitJersey),
    );
    final checkRect = tester.getRect(find.byIcon(Icons.check_circle_rounded));
    expect(tester.getRect(jersey).contains(checkRect.center), isTrue);
  });

  testWidgets('la sélection et la désélection restent inchangées', (
    tester,
  ) async {
    JerseyOption? chosen;
    await showPicker(
      tester,
      selected: JerseyOption.orange,
      onChanged: (value) => chosen = value,
    );

    await tester.tap(find.text('Rouge A'));
    expect(chosen, JerseyOption.france);

    await tester.tap(find.text('Ext A'));
    expect(chosen, isNull);
  });
}
