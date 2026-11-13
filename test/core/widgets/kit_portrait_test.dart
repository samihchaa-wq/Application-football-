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

  test('les épaules descendent naturellement, le col laisse le cou visible',
      () async {
    final recorder = ui.PictureRecorder();
    const PortraitJerseyPainter(
      body: Colors.red,
      trim: Colors.yellow,
      pattern: KitPattern.plain,
    ).paint(Canvas(recorder), const Size(180, 180));
    final picture = recorder.endRecording();
    final image = await picture.toImage(180, 180);
    final pixels = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!
        .buffer
        .asUint8List();

    int opacityAt(int x, int y) => pixels[(y * 180 + x) * 4 + 3];

    // La manche commence sur une épaule inclinée et ne forme plus un disque.
    expect(opacityAt(12, 125), 0);
    expect(opacityAt(12, 157), 255);
    // Le centre reste ouvert pour le cou photographié, pas pour un faux col.
    expect(opacityAt(90, 119), 0);
    expect(opacityAt(90, 143), 255);

    image.dispose();
    picture.dispose();
  });

  testWidgets('aucun maillot n’est superposé aux avatars joueur et gardien',
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
    expect(find.byType(KitPortrait), findsNothing);
    expect(find.byIcon(Icons.checkroom), findsNothing);
    expect(find.byType(PlayerAvatar), findsNWidgets(2));
  });

  testWidgets(
    'le maillot du match habille les photos de composition et de vidéo',
    (tester) async {
      final kit = ClubKits.of(JerseyOption.orange).copyWith(
        dressPlayers: true,
        body: Colors.red,
        goalkeeperBody: Colors.green,
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CompositionKitScope(
            kit: kit,
            child: const Column(
              children: [
                PlayerAvatar(
                  photoUrl: 'https://example.test/joueur.png',
                  name: 'Alex',
                  size: 58,
                ),
                PlayerAvatar(
                  photoUrl: 'https://example.test/gardien.png',
                  name: 'Camille',
                  size: 58,
                  isGoalkeeper: true,
                ),
              ],
            ),
          ),
        ),
      ));
      // Ne pas confondre « URL chargée » et « photo décodée » : le
      // frameBuilder n'habille rien avant le premier frame réussi.
      final avatars = find.byType(PlayerAvatar);
      final images = [
        for (var i = 0; i < 2; i++)
          tester.widget<Image>(
            find.descendant(
              of: avatars.at(i),
              matching: find.byType(Image),
            ),
          ),
      ];
      for (var i = 0; i < images.length; i++) {
        final image = images[i];
        expect(image.frameBuilder, isNotNull);
        final context = tester.element(avatars.at(i));
        final placeholder =
            image.frameBuilder!(context, const SizedBox(), null, false);
        expect(placeholder, isNot(isA<KitPortrait>()));
        final dressed =
            image.frameBuilder!(context, const SizedBox(), 0, false);
        expect(dressed, isA<KitPortrait>());
        final portrait = dressed as KitPortrait;
        expect(portrait.kit, kit);
        expect(portrait.isGoalkeeper, i == 1);
      }
    },
  );

  testWidgets('les petits avatars restent neutres même en composition',
      (tester) async {
    final kit = ClubKits.of(JerseyOption.france).copyWith(dressPlayers: true);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CompositionKitScope(
          kit: kit,
          child: const PlayerAvatar(
            photoUrl: 'https://example.test/joueur.png',
            name: 'Alex',
            size: 24,
          ),
        ),
      ),
    ));
    final image = tester.widget<Image>(find.byType(Image));
    final dressed = image.frameBuilder!(
      tester.element(find.byType(PlayerAvatar)),
      const SizedBox(),
      0,
      false,
    );
    expect(dressed, isNot(isA<KitPortrait>()));
  });

  testWidgets('la fiche joueur peut fournir sa tenue sans scope de match',
      (tester) async {
    final kit = ClubKits.of(JerseyOption.france).copyWith(dressPlayers: true);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PlayerAvatar(
          photoUrl: 'https://example.test/joueur.png',
          name: 'Alex',
          size: 112,
          kit: kit,
        ),
      ),
    ));
    final image = tester.widget<Image>(find.byType(Image));
    final dressed = image.frameBuilder!(
      tester.element(find.byType(PlayerAvatar)),
      const SizedBox(),
      0,
      false,
    );
    expect(dressed, isA<KitPortrait>());
  });

  testWidgets('sans habillage, aucune icône maillot n’est ajoutée',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CompositionKitScope(
      kit: ClubKits.of(JerseyOption.france),
      child: const PlayerAvatar(photoUrl: null, name: 'Alex', size: 58),
    ))));
    expect(find.byType(KitPortrait), findsNothing);
    expect(find.byIcon(Icons.checkroom), findsNothing);
  });
}
