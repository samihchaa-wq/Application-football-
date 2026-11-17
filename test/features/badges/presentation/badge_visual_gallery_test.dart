import 'dart:io';
import 'dart:ui' as ui;

import 'package:as_grinta/features/badges/presentation/badge_descriptor.dart';
import 'package:as_grinta/features/badges/presentation/badge_emblem_body.dart';
import 'package:as_grinta/features/badges/presentation/badge_premium_skins.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Galerie de recette des 14 fonds procéduraux, sur un dessin local fictif.
/// Elle ne certifie pas le rendu des JPEG opaques de Storage.
void main() {
  testWidgets('galerie PNG des quatorze fonds premium', (tester) async {
    const variants = <(String, String)>[
      ('GRIS', '#7A858D'),
      ('BRONZE', '#CD7F32'),
      ('ARGENT', '#C0C0C0'),
      ('OR', '#D4AF37'),
      ('BLEU CLAIR', '#4FA9E8'),
      ('BLEU', '#1E3A8A'),
      ('BLEU FONCÉ', '#7C3AED'),
      ('NOIR', '#1C1C24'),
      ('ORANGE', '#F1706E'),
      ('RUBIS', '#E23B36'),
      ('GRENAT', '#9E1B1B'),
      ('DIAMANT', '#B9F2FF'),
      ('ÉMERAUDE', '#F2811D'),
      ('VIOLET', '#F97316'),
    ];
    final boundaryKey = GlobalKey();

    tester.view.physicalSize = const Size(1024, 1160);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF080E18),
        body: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: 985,
              height: 1120,
              child: ColoredBox(
                color: const Color(0xFF101826),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Wrap(
                    spacing: 19,
                    runSpacing: 13,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final (name, hex) in variants)
                        SizedBox(
                          width: 216,
                          height: 258,
                          child: Column(
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 7),
                              BadgeEmblemBody(
                                size: 124,
                                base: Color(int.parse('FF${hex.substring(1)}',
                                    radix: 16)),
                                skin: badgePremiumSkinFor(hex),
                                descriptor:
                                    const BadgeDescriptor('MATCHS', 'SAISON'),
                                value: '25',
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.white,
                                  size: 65,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(BadgeEmblemBody), findsNWidgets(14));

    // La conversion PNG utilise le thread raster : exécution asynchrone
    // réelle, et non l'horloge factice des tests widget.
    final imageBytes = await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(boundaryKey),
      );
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return bytes;
    });
    expect(imageBytes, isNotNull);
    final file = File('badge-previews/quatorze_fonds_premium.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(imageBytes!.buffer.asUint8List());
  });
}
