import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/widgets/kit_portrait.dart';
import 'package:as_grinta/features/matches/domain/jersey_option.dart';
import 'package:as_grinta/features/sports_management/presentation/widgets/composition_kit_scope.dart';
import 'package:as_grinta/features/sports_management/presentation/widgets/composition_pitch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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

  test('le col est plus large et laisse le vrai cou visible', () async {
    final recorder = ui.PictureRecorder();
    const PortraitJerseyPainter(
      body: Colors.red,
      trim: Colors.yellow,
      pattern: KitPattern.plain,
    ).paint(Canvas(recorder), const Size(180, 180));
    final picture = recorder.endRecording();
    final raster = await picture.toImage(180, 180);
    final bytes = (await raster.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!
        .buffer
        .asUint8List();

    int channel(int x, int y, int component) =>
        bytes[(y * 180 + x) * 4 + component];

    // Au-dessus du col, seule la photo réelle du cou doit être visible.
    // L'ancien anneau étroit peignait déjà cette zone en jaune.
    expect(channel(90, 132, 3), 0);
    expect(channel(90, 141, 3), 255);
    // Épaule : de la matière rouge ombrée, pas trois grosses bandes jaunes
    // systématiquement collées sur chaque maillot uni.
    expect(channel(30, 141, 3), 255);
    expect(channel(30, 141, 0), greaterThan(channel(30, 141, 1) + 40));

    raster.dispose();
    picture.dispose();
  });

  testWidgets('texture tricotée réelle du maillot, sans toucher au visage',
      (tester) async {
    final bytes =
        await rootBundle.load('assets/composition/jersey_fabric_luma.png');
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    final frame = await codec.getNextFrame();
    final material = frame.image;
    codec.dispose();
    expect(material.width, 256);
    expect(material.height, 256);

    Future<ui.Image> painted(ui.Image? texture) async {
      final recorder = ui.PictureRecorder();
      PortraitJerseyPainter(
        body: const Color(0xFFE33A29),
        trim: Colors.amber,
        pattern: KitPattern.plain,
        material: texture,
      ).paint(Canvas(recorder), const Size(300, 300));
      final picture = recorder.endRecording();
      final result = await picture.toImage(300, 300);
      picture.dispose();
      return result;
    }

    final before = await painted(null);
    final after = await painted(material);
    final without = (await before.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!
        .buffer
        .asUint8List();
    final withTexture = (await after.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!
        .buffer
        .asUint8List();

    int channel(Uint8List data, int x, int y, int component) =>
        data[(y * 300 + x) * 4 + component];

    // Une vraie différence de matière apparaît sur la poitrine.
    expect(
      channel(without, 150, 260, 0),
      isNot(channel(withTexture, 150, 260, 0)),
    );
    // Aucune matière ne passe au-dessus du maillot et du col.
    expect(channel(withTexture, 150, 130, 3), 0);
    expect(channel(withTexture, 150, 260, 3), 255);

    before.dispose();
    after.dispose();
    material.dispose();
  });

  testWidgets('la photo est découpée en courbe et non au cutter sous la joue',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox.square(
          dimension: 180,
          child: KitPortrait(
            kit: ClubKits.of(JerseyOption.france),
            child: const ColoredBox(color: Colors.blue),
          ),
        ),
      ),
    ));

    final clip = tester.widget<ClipPath>(find.byType(ClipPath));
    final mask = clip.clipper!.getClip(const Size(180, 180));
    // Ancien masque : ligne horizontale dès 61,3 %, un rectangle
    // apparaissait au niveau de la mâchoire lorsque le visage était large.
    expect(mask.contains(const Offset(55, 115)), isTrue);
    expect(mask.contains(const Offset(20, 135)), isFalse);
    expect(mask.contains(const Offset(90, 125)), isTrue);
    expect(mask.contains(const Offset(90, 145)), isFalse);
  });

  testWidgets('le patron découpe la photo exactement au bord intérieur du col',
      (tester) async {
    final kit = ClubKits.of(JerseyOption.france);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox.square(
          dimension: 180,
          child: KitPortrait(
            kit: kit,
            child: const ColoredBox(color: Colors.blue),
          ),
        ),
      ),
    ));
    final clip = tester.widget<ClipPath>(find.byType(ClipPath));
    final path = clip.clipper!.getClip(const Size(180, 180));
    expect(path.contains(const Offset(90, 132)), isTrue);
    expect(path.contains(const Offset(90, 141)), isFalse);
    expect(path.contains(const Offset(12, 138)), isFalse);
    expect(find.byKey(const ValueKey('portrait-jersey-field')), findsOneWidget);
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

  testWidgets('même les petits portraits affichent le maillot du match',
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
    expect(dressed, isA<KitPortrait>());
    expect((dressed as KitPortrait).kit, kit);
  });

  testWidgets('profil, effectif et fiche utilisent la tenue par défaut du club',
      (tester) async {
    final defaultKit = ClubKits.enabled.first;
    // Le réglage historique n'est plus un prérequis : tous les portraits
    // disposant d'une photo utilisent la tenue du club, à toute taille.
    expect(defaultKit.dressPlayers, isFalse);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            PlayerAvatar(
              photoUrl: 'https://example.test/profil.png',
              name: 'Profil',
              size: 82,
            ),
            PlayerAvatar(
              photoUrl: 'https://example.test/effectif.png',
              name: 'Effectif',
              size: 30,
            ),
            PlayerAvatar(
              photoUrl: 'https://example.test/fiche.png',
              name: 'Fiche',
              size: 96,
            ),
            PlayerAvatar(
              photoUrl: 'https://example.test/gardien.png',
              name: 'Gardien',
              size: 36,
              isGoalkeeper: true,
            ),
          ],
        ),
      ),
    ));
    final avatars = find.byType(PlayerAvatar);
    expect(avatars, findsNWidgets(4));
    for (var i = 0; i < 4; i++) {
      final avatar = avatars.at(i);
      final image = tester.widget<Image>(
        find.descendant(of: avatar, matching: find.byType(Image)),
      );
      final context = tester.element(avatar);
      expect(
        image.frameBuilder!(context, const SizedBox(), null, false),
        isNot(isA<KitPortrait>()),
      );
      final ready = image.frameBuilder!(
        context,
        const SizedBox(),
        0,
        false,
      );
      expect(ready, isA<KitPortrait>());
      final portrait = ready as KitPortrait;
      expect(portrait.kit, defaultKit);
      expect(portrait.isGoalkeeper, i == 3);
    }
  });

  testWidgets('le portrait suit les changements de tenue du club',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PlayerAvatar(
          photoUrl: 'https://example.test/joueur.png',
          name: 'Alex',
          size: 56,
        ),
      ),
    ));
    KitPortrait dressedPortrait() {
      final avatar = find.byType(PlayerAvatar);
      final image = tester.widget<Image>(find.byType(Image));
      return image.frameBuilder!(
        tester.element(avatar),
        const SizedBox(),
        0,
        false,
      ) as KitPortrait;
    }

    expect(dressedPortrait().kit.body, ClubKits.enabled.first.body);
    final changed = [
      for (final kit in ClubKits.all)
        if (kit.slot == JerseyOption.france)
          kit.copyWith(body: const Color(0xFFBB22CC), dressPlayers: false)
        else
          kit,
    ];
    ClubKits.setFromJson([for (final kit in changed) kit.toJson()]);
    await tester.pump();
    expect(dressedPortrait().kit.body, const Color(0xFFBB22CC));
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
