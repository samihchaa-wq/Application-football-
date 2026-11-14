import 'dart:typed_data';

import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/storage/avatar_image.dart';
import 'package:as_grinta/core/widgets/kit_portrait.dart';
import 'package:as_grinta/core/widgets/match_contribution_icons.dart';
import 'package:as_grinta/core/widgets/photo_crop_preview.dart';
import 'package:as_grinta/core/widgets/portrait_alignment_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _photo(int width, int height) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgb(
        x,
        y,
        (x * 7 + y * 3) % 256,
        (x * 3 + y * 11) % 256,
        (x * 13 + y * 5) % 256,
      );
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 92));
}

Uint8List _cutout(int side) {
  final image = img.Image(width: side, height: side, numChannels: 4);
  final center = side / 2;
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      final inside = (x - center) * (x - center) + (y - center) * (y - center) <
          (side / 3) * (side / 3);
      image.setPixelRgba(x, y, 200, 40, 40, inside ? 255 : 0);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

Future<Uint8List?> _crop(
  WidgetTester tester,
  Uint8List source, {
  Future<void> Function()? beforeExport,
}) async {
  Uint8List? exported;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            exported = await cropProfilePhoto(context, source);
          },
          child: const Text('recadrer'),
        ),
      ),
    ),
  );

  await tester.tap(find.text('recadrer'));
  await tester.pumpAndSettle();
  // Le décodage et l'encodage sont de vraies opérations asynchrones : elles
  // ne se terminent pas sur l'horloge simulée des tests.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pumpAndSettle();
  await beforeExport?.call();

  await tester.runAsync(() async {
    await tester.tap(find.text('Utiliser cette photo'));
    for (var i = 0; i < 40 && exported == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  });
  await tester.pumpAndSettle();
  return exported;
}

void main() {
  setUp(ClubKits.reset);
  tearDown(ClubKits.reset);

  testWidgets(
    'le recadrage ne montre que les patrons maillot et couronne',
    (tester) async {
      final exported = await _crop(
        tester,
        _photo(400, 400),
        beforeExport: () async {
          expect(find.text('Ajouter la photo du joueur'), findsOneWidget);
          expect(find.byType(KitPortrait), findsOneWidget);
          expect(find.byType(PortraitAlignmentGuide), findsOneWidget);
          expect(find.byKey(const ValueKey('portrait-crown-guide')),
              findsOneWidget);
          expect(find.byType(PhotoCrown), findsOneWidget);
          expect(find.text('👑'), findsOneWidget);
          expect(find.byType(InteractiveViewer), findsOneWidget);

          // Le sommet de la couronne est au-dessus du carré exactement
          // comme en composition : même widget, même topOffset par pixel.
          final photo = tester.getRect(
            find.byKey(const ValueKey('portrait-crop-frame')),
          );
          final crown = tester.getRect(
            find.byKey(const ValueKey('portrait-crown-guide')),
          );
          expect(
            crown.top - photo.top,
            closeTo(PhotoCrown.topOffset(photo.width), 1.0),
          );
          for (final label in [
            'Patron de cadrage',
            'Patron du cadrage',
            'Conseils',
            'Sommet de la tête',
            'Hauteur des yeux',
            'Base du menton',
            'Haut du maillot',
            'Correct',
            'Trop haut',
            'Décalé',
            'Aperçu final',
          ]) {
            expect(find.text(label), findsNothing, reason: label);
          }
        },
      );
      expect(exported, isNotNull);
    },
  );

  testWidgets('le patron emploie la même couronne que la composition',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: PortraitAlignmentGuide(photoSize: 300),
          ),
        ),
      ),
    );
    final icon = tester.widget<PhotoCrown>(find.byType(PhotoCrown));
    expect(icon.photoSize, 300);
    expect(find.text('👑'), findsOneWidget);
    expect(PhotoCrown.topOffset(300), closeTo(-92.3077, 0.001));
  });

  testWidgets(
    'une photo détourée garde sa transparence au lieu d’un fond blanc',
    (tester) async {
      final exported = await _crop(tester, _cutout(400));

      expect(exported, isNotNull);
      final decoded = img.decodeImage(exported!)!;
      expect(decoded.width, avatarStorageSide);
      final corner = decoded.getPixel(2, 2);
      expect(corner.a, 0);
      final middle =
          decoded.getPixel(avatarStorageSide ~/ 2, avatarStorageSide ~/ 2);
      expect(middle.a, 255);
      expect(middle.r, closeTo(200, 3));
    },
  );

  testWidgets(
    'les deux patrons laissent passer les gestes sur la photo',
    (tester) async {
      // Moitié gauche rouge, moitié droite bleue.
      final halves = img.Image(width: 400, height: 400);
      for (var y = 0; y < 400; y++) {
        for (var x = 0; x < 400; x++) {
          halves.setPixelRgb(x, y, x < 200 ? 220 : 30, 30, x < 200 ? 30 : 220);
        }
      }

      final exported = await _crop(
        tester,
        Uint8List.fromList(img.encodeJpg(halves, quality: 95)),
        beforeExport: () async {
          // La couronne déborde désormais au-dessus du carré photo :
          // sur un petit écran de test, la moitié inférieure du portrait
          // peut nécessiter un scroll. Partir d'une zone effectivement
          // visible, en haut de la photo, et non d'un point caché derrière
          // la barre fixe des boutons.
          final viewer = find.byType(InteractiveViewer);
          final rect = tester.getRect(viewer);
          final start = Offset(rect.center.dx, rect.top + rect.height * .2);
          final controller = tester
              .widget<InteractiveViewer>(viewer)
              .transformationController!;
          final initialX = controller.value.getTranslation().x;
          final gesture = await tester.startGesture(start);
          for (var i = 0; i < 12; i++) {
            await gesture.moveBy(const Offset(8, 0));
            await tester.pump(const Duration(milliseconds: 50));
          }
          await gesture.up();
          await tester.pumpAndSettle();
          expect(controller.value.getTranslation().x, greaterThan(initialX));
        },
      );

      expect(exported, isNotNull);
      final decoded = img.decodeImage(exported!)!;
      // Juste à droite du centre, la photo montrait sa moitié bleue :
      // poussée vers la droite, elle y montre désormais sa moitié rouge.
      final pixel = decoded.getPixel(
        avatarStorageSide * 95 ~/ 180,
        avatarStorageSide ~/ 2,
      );
      expect(pixel.r, greaterThan(150));
      expect(pixel.b, lessThan(100));
    },
  );

  testWidgets(
    'ni le maillot ni la couronne ne sont enregistrés dans la photo',
    (tester) async {
      ClubKits.setFromJson([
        for (final kit in ClubKits.all)
          kit.copyWith(dressPlayers: true).toJson(),
      ]);
      final solid = img.Image(width: 600, height: 600);
      img.fill(solid, color: img.ColorRgb8(40, 120, 200));
      final exported = await _crop(
        tester,
        Uint8List.fromList(img.encodeJpg(solid, quality: 95)),
        beforeExport: () async {
          expect(find.byType(InteractiveViewer), findsOneWidget);
          expect(
            find.byKey(const ValueKey('portrait-kit-preview')),
            findsNothing,
          );
          // Présente sur l'écran, jamais dans l'image exportée.
          expect(find.text('👑'), findsOneWidget);
        },
      );

      expect(exported, isNotNull);
      final decoded = img.decodeImage(exported!)!;
      var worst = 0;
      for (final pixel in decoded) {
        worst = [
          worst,
          (pixel.r - 40).abs().toInt(),
          (pixel.g - 120).abs().toInt(),
          (pixel.b - 200).abs().toInt(),
        ].reduce((a, b) => a > b ? a : b);
      }
      // Seules les approximations du JPEG séparent la photo exportée de la
      // couleur unie d'origine : aucun pointillé blanc, aucune couronne.
      expect(worst, lessThan(8));
    },
  );

  testWidgets(
    'la photo recadrée est exportée à la taille de stockage, pas plus grande',
    (tester) async {
      final exported = await _crop(tester, _photo(800, 800));

      expect(exported, isNotNull);
      // Une photo opaque reste en JPEG, plus léger qu'un PNG.
      expect(exported!.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
      final decoded = img.decodeImage(exported)!;
      expect(decoded.width, avatarStorageSide);
      expect(decoded.height, avatarStorageSide);
    },
  );
}
