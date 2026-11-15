import 'package:as_grinta/features/matches/presentation/widgets/calendar_actions_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sur petit écran, les actions sont groupées et activables',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var created = 0;
    var subscribed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 304,
              child: CalendarActionsBar(
                onCreate: () => created++,
                onExport: () => subscribed++,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Nouvel événement'), findsOneWidget);
    expect(find.byTooltip('S’abonner au calendrier'), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-new-event-action')),
        findsOneWidget);
    await tester.tap(find.text('Nouvel événement'));
    await tester.pump();
    expect(created, 1);
    expect(subscribed, 0);

    await tester.tap(find.byTooltip('S’abonner au calendrier'));
    await tester.pump();
    expect(subscribed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un membre ne voit que l’abonnement', (tester) async {
    var subscribed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: CalendarActionsBar(
              onCreate: null,
              onExport: () => subscribed++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Nouvel événement'), findsNothing);
    expect(find.text('S’abonner au calendrier'), findsOneWidget);
    await tester.tap(find.text('S’abonner au calendrier'));
    expect(subscribed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('aucune action si la création et l’abonnement sont indisponibles',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalendarActionsBar(onCreate: null, onExport: null),
        ),
      ),
    );
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });
}
