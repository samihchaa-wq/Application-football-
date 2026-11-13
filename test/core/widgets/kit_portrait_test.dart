import 'dart:ui' as ui;

import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/widgets/kit_portrait.dart';
import 'package:as_grinta/features/matches/domain/jersey_option.dart';
import 'package:as_grinta/features/sports_management/presentation/widgets/composition_kit_scope.dart';
import 'package:as_grinta/features/sports_management/presentation/widgets/composition_pitch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(ClubKits.reset);
  tearDown(ClubKits.reset);

  test('tous les modèles laissent le visage et la couronne intacts', () async {
    for (final pattern in KitPattern.values) {
      final recorder = ui.PictureRecorder();
      PortraitJerseyPainter(
              body: Colors.red, trim: Colors.white, pattern: pattern)
          .paint(Canvas(recorder), const Size(180, 180));
      final picture = recorder.endRecording();
      final image = await picture.toImage(180, 180);
      final bytes = (await image.toByteData())!.buffer.asUint8List();
      for (var y = 0; y < 100; y++) {
        for (var x = 0; x < 180; x++) {
          expect(bytes[(y * 180 + x) * 4 + 3], 0);
        }
      }
      // Le bas du buste est opaque : le maillot remplace réellement la tenue.
      expect(bytes[(165 * 180 + 90) * 4 + 3], 255);
      image.dispose();
      picture.dispose();
    }
  });

  testWidgets('joueur et gardien portent leur modèle sur toute la vignette',
      (tester) async {
    final kit = ClubKits.of(JerseyOption.orange).copyWith(
      dressPlayers: true,
      pattern: KitPattern.sash,
      goalkeeperPattern: KitPattern.hoops,
    );
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CompositionKitScope(
      kit: kit,
      child: const Column(children: [
        PlayerAvatar(photoUrl: null, name: 'Alex', size: 58),
        PlayerAvatar(
            photoUrl: null, name: 'Camille', size: 58, isGoalkeeper: true),
      ]),
    ))));
    final painters = tester
        .widgetList<CustomPaint>(find.descendant(
          of: find.byType(KitPortrait),
          matching: find.byType(CustomPaint),
        ))
        .map((widget) => widget.painter)
        .whereType<PortraitJerseyPainter>()
        .toList();
    expect(painters.map((painter) => painter.body),
        [kit.body, kit.goalkeeperBody]);
    expect(painters.map((painter) => painter.pattern),
        [KitPattern.sash, KitPattern.hoops]);
    expect(find.byIcon(Icons.checkroom), findsNothing);
  });

  testWidgets('option désactivée : le portrait garde son affichage existant',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CompositionKitScope(
      kit: ClubKits.of(JerseyOption.france),
      child: const PlayerAvatar(photoUrl: null, name: 'Alex', size: 58),
    ))));
    expect(find.byType(KitPortrait), findsNothing);
    expect(find.byIcon(Icons.checkroom), findsOneWidget);
  });
}
