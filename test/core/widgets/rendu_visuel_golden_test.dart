import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/core/club/club_kits.dart';
import 'package:petit_filet/core/widgets/kit_portrait.dart';
import 'package:petit_filet/features/matches/domain/jersey_option.dart';
import 'package:petit_filet/features/matches/presentation/widgets/kit_jersey.dart';

/// Images de référence du rendu des maillots et des portraits.
/// Régénérer : flutter test --update-goldens test/core/widgets/rendu_visuel_golden_test.dart
const _kit = ClubKit(
  slot: JerseyOption.france,
  label: 'Domicile',
  body: Color(0xFF1E4FA3),
  trim: Color(0xFFFFFFFF),
  enabled: true,
);

Widget _planche({required bool gardien}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final p in KitPattern.values)
                SizedBox(
                  width: 70,
                  child: KitJersey(
                    kit: _kit.copyWith(pattern: p, goalkeeperPattern: p),
                    isGoalkeeper: gardien,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

Widget _portraits() => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey.shade300,
        body: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in KitPattern.values)
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: PortraitJerseyPainter(
                    body: const Color(0xFFC62828),
                    trim: Colors.white,
                    pattern: p,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

void main() {
  for (final (nom, taille) in [
    ('petit', const Size(360, 640)),
    ('grand', const Size(1024, 768)),
  ]) {
    testWidgets('maillots joueurs $nom écran', (tester) async {
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_planche(gardien: false));
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('maillots_joueurs_$nom.png'));
    });
    testWidgets('maillots gardiens $nom écran', (tester) async {
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_planche(gardien: true));
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('maillots_gardiens_$nom.png'));
    });
    testWidgets('portraits $nom écran', (tester) async {
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_portraits());
      await expectLater(
          find.byType(MaterialApp), matchesGoldenFile('portraits_$nom.png'));
    });
  }
}
