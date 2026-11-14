import 'dart:typed_data';
import 'package:as_grinta/core/storage/player_photo_mode.dart';
import 'package:as_grinta/core/widgets/kit_portrait.dart';
import 'package:as_grinta/core/widgets/match_contribution_icons.dart';
import 'package:as_grinta/core/widgets/photo_crop_preview.dart';
import 'package:as_grinta/core/widgets/player_photo_mode_picker.dart';
import 'package:as_grinta/features/sports_management/domain/match_composition.dart';
import 'package:as_grinta/features/sports_management/presentation/widgets/composition_pitch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  testWidgets('Autre conserve sa photo entière et la couronne', (tester) async {
    final entry = MatchCompositionEntry.fromJson({
      'participant_id': 'p',
      'photo_url': 'https://example.test/profile/avatar_other_123.png',
      'is_motm': true,
      'zone': 'field'
    });
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CompositionPlayerTile(entry: entry))));
    final avatar = find.byType(PlayerAvatar);
    final image = tester.widget<Image>(
        find.descendant(of: avatar, matching: find.byType(Image)));
    const photo = SizedBox(key: ValueKey('unchanged-photo'));
    final rendered =
        image.frameBuilder!(tester.element(avatar), photo, 0, false);
    expect(identical(rendered, photo), isTrue);
    expect(find.byType(PhotoCrown), findsOneWidget);
    expect(find.byType(KitPortrait), findsNothing);
  });
  testWidgets('le choix propose uniquement Type joueur et Autre',
      (tester) async {
    PlayerPhotoMode? selected;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => TextButton(
                onPressed: () async {
                  selected = await choosePlayerPhotoMode(context);
                },
                child: const Text('Photo')))));
    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();
    expect(find.text('Type joueur'), findsOneWidget);
    expect(find.text('Autre'), findsOneWidget);
    await tester.tap(find.text('Autre'));
    await tester.pumpAndSettle();
    expect(selected, PlayerPhotoMode.other);
  });
  Future<void> openCrop(WidgetTester tester, PlayerPhotoMode mode,
      {required bool transparent}) async {
    final source = img.Image(width: 40, height: 40, numChannels: 4);
    img.fill(source, color: img.ColorRgba8(150, 80, 30, 255));
    if (transparent) source.setPixelRgba(0, 0, 0, 0, 0, 0);
    final bytes = Uint8List.fromList(img.encodePng(source));
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => TextButton(
                onPressed: () => cropProfilePhoto(context, bytes,
                    mode: mode,
                    requireTransparent: mode == PlayerPhotoMode.player),
                child: const Text('Photo')))));
    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
  }

  testWidgets('un fond opaque est refusé avant le recadrage joueur',
      (tester) async {
    await openCrop(tester, PlayerPhotoMode.player, transparent: false);
    expect(find.textContaining('nécessite une photo à fond transparent'),
        findsOneWidget);
    final confirm = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Utiliser cette photo'));
    expect(confirm.onPressed, isNull);
  });
  testWidgets(
      'Type joueur montre maillot et couronne pour une photo transparente',
      (tester) async {
    await openCrop(tester, PlayerPhotoMode.player, transparent: true);
    expect(find.byType(KitPortrait), findsOneWidget);
    expect(find.byType(PhotoCrown), findsOneWidget);
  });
  testWidgets('Autre ne montre que la couronne pendant le cadrage',
      (tester) async {
    await openCrop(tester, PlayerPhotoMode.other, transparent: false);
    expect(find.byType(KitPortrait), findsNothing);
    expect(find.byType(PhotoCrown), findsOneWidget);
  });
}
