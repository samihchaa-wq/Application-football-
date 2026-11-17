import 'package:as_grinta/features/matches/presentation/widgets/calendar_actions_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('le calendrier affiche seulement Nouvel événement aux admins', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var created = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 304,
              child: CalendarActionsBar(onCreate: () => created++),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Nouvel événement'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar-new-event-action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendar-subscribe-action')),
      findsNothing,
    );
    expect(find.byTooltip('S’abonner au calendrier'), findsNothing);
    await tester.tap(find.text('Nouvel événement'));
    await tester.pump();
    expect(created, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un joueur ne voit aucun bouton dans le calendrier', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalendarActionsBar(onCreate: null),
        ),
      ),
    );

    expect(find.text('Nouvel événement'), findsNothing);
    expect(
      find.byKey(const ValueKey('calendar-subscribe-action')),
      findsNothing,
    );
    expect(find.byType(FilledButton), findsNothing);
  });
}
