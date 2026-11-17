import 'package:as_grinta/features/badges/presentation/badge_image_editor.dart';
import 'package:as_grinta/features/badges/presentation/badge_premium_skins.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ajout d’image mystère : l’orange est remplacé par le violet',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showBadgeImageCropDialog(
                context,
                badgeColor: const Color(0xFFF97316),
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Choisir une image'), findsOneWidget);
    final colors = tester
        .widgetList<Container>(find.byType(Container))
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .map((decoration) => decoration.gradient)
        .whereType<LinearGradient>()
        .map((gradient) => gradient.colors)
        .toList();

    expect(
      colors.any((palette) =>
          palette.contains(badgePremiumDark(BadgePremiumSkin.violet)) &&
          palette.contains(badgePremiumAccent(BadgePremiumSkin.violet))),
      isTrue,
    );
    expect(
      colors.any((palette) => palette.contains(const Color(0xFFF97316))),
      isFalse,
    );
  });
}
