import 'package:petit_filet/features/matches/domain/convocation_launch.dart';
import 'package:petit_filet/features/matches/presentation/widgets/convocation_launch_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Point 13 de l'audit : une ouverture automatique déjà passée ne doit pas
/// être affichée comme une date à venir.
void main() {
  final now = DateTime(2026, 11, 25, 10);

  Future<void> pump(WidgetTester tester, DateTime kickoffAt) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConvocationLaunchPicker(
            kickoffAt: kickoffAt,
            mode: ConvocationLaunchMode.automatic,
            customAt: null,
            now: now,
            onModeChanged: (_) {},
            onCustomAtChanged: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('match dans 3 jours : ouverture immédiate annoncée',
      (tester) async {
    await pump(tester, DateTime(2026, 11, 28, 21));

    expect(
      find.textContaining('22/11/2026 à 12:00, c’est déjà passé'),
      findsOneWidget,
    );
    expect(
      find.textContaining('les disponibilités s’ouvrent tout de suite'),
      findsOneWidget,
    );
  });

  testWidgets('match dans 10 jours : date d’ouverture à venir', (tester) async {
    await pump(tester, DateTime(2026, 12, 5, 21));

    expect(find.text('Ouverture le 29/11/2026 à 12:00'), findsOneWidget);
    expect(find.textContaining('déjà passé'), findsNothing);
  });
}
