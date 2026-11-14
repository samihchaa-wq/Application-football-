import 'dart:typed_data';

import 'package:as_grinta/core/widgets/photo_crop_preview.dart';
import 'package:as_grinta/features/sports_management/domain/match_composition.dart';
import 'package:as_grinta/features/sports_management/presentation/widgets/composition_pitch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

const _motm = MatchCompositionEntry(
  participantId: 'p1',
  seasonPlayerId: 's1',
  displayName: 'Alban',
  isGoalkeeper: false,
  zone: MatchCompositionZone.field,
  sortOrder: 0,
  availabilityStatus: 'available',
  convocationStatus: 'not_applicable',
  selectionStatus: 'selected',
  isMotm: true,
);

/// Place de la couronne par rapport à la photo, en fractions de son côté.
typedef _CrownPlacement = ({double top, double width, double centerShift});

_CrownPlacement _placement(Rect crown, Rect photo) => (
      top: (crown.top - photo.top) / photo.width,
      width: crown.width / photo.width,
      centerShift: (crown.center.dx - photo.center.dx) / photo.width,
    );

Future<_CrownPlacement> _pitchCrown(
  WidgetTester tester, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const Scaffold(
        body: Center(child: CompositionPlayerTile(entry: _motm)),
      ),
    ),
  );
  return _placement(
    tester.getRect(find.text('👑')),
    tester.getRect(find.byType(PlayerAvatar)),
  );
}

Uint8List _photo() {
  final image = img.Image(width: 400, height: 400);
  img.fill(image, color: img.ColorRgb8(90, 90, 90));
  return Uint8List.fromList(img.encodeJpg(image));
}

void main() {
  testWidgets(
    'la couronne du terrain ne grandit pas avec la taille du texte',
    (tester) async {
      final normal = await _pitchCrown(tester, textScale: 1.1);
      final large = await _pitchCrown(tester, textScale: 1.6);

      expect(large, normal);
    },
  );

  testWidgets(
    'le patron et le terrain partagent la couronne, la taille et la position',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => cropProfilePhoto(context, _photo()),
              child: const Text('recadrer'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('recadrer'));
      await tester.pumpAndSettle();
      // Le décodage de l'image s'effectue hors de l'horloge simulée.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('👑'), findsOneWidget);
      final editor = _placement(
        tester.getRect(find.text('👑')),
        tester.getRect(find.byKey(const ValueKey('portrait-crop-frame'))),
      );

      final pitch = await _pitchCrown(tester);
      // Même emoji et mêmes proportions. Les fractions de pixels du
      // layout peuvent légèrement différer entre 58 px et 300 px.
      expect(editor.top, closeTo(pitch.top, .03));
      expect(editor.width, closeTo(pitch.width, .03));
      expect(editor.centerShift, closeTo(pitch.centerShift, .03));
    },
  );
}
