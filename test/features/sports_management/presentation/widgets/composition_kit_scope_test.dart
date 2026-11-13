import 'dart:async';
import 'package:as_grinta/core/club/match_kit_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/features/matches/domain/jersey_option.dart';
import 'package:as_grinta/features/sports_management/presentation/widgets/composition_kit_scope.dart';
import 'package:as_grinta/features/sports_management/presentation/widgets/composition_pitch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(ClubKits.reset);
  tearDown(ClubKits.reset);

  testWidgets('attendre l historique avant de montrer la tenue courante',
      (tester) async {
    final history = Completer<MatchKitSnapshot?>();
    final oldKit = ClubKits.of(JerseyOption.orange).copyWith(
      dressPlayers: true,
      body: const Color(0xFFAA0000),
      pattern: KitPattern.sash,
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        matchKitSnapshotProvider('ancien-match')
            .overrideWith((ref) => history.future)
      ],
      child: const MaterialApp(
          home: Scaffold(
              body: MatchCompositionKitScope(
        matchId: 'ancien-match',
        child: PlayerAvatar(photoUrl: null, name: 'Alex', size: 58),
      ))),
    ));
    expect(find.byKey(const ValueKey('composition-kit-field')), findsNothing);
    expect(find.byKey(const ValueKey('portrait-jersey-field')), findsNothing);
    history.complete(MatchKitSnapshot(
      matchId: 'ancien-match',
      clubId: 'club-a',
      jerseyId: JerseyOption.orange,
      kit: oldKit,
      allKits: [oldKit],
      capturedAt: DateTime.utc(2026, 10, 1),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('portrait-jersey-field')), findsNothing);
  });

  testWidgets('composition: les maillots joueur et gardien sont distincts', (
    tester,
  ) async {
    final kit = ClubKits.of(JerseyOption.france).copyWith(
      body: const Color(0xFFAA0000),
      trim: const Color(0xFFFFFFFF),
      goalkeeperBody: const Color(0xFF123456),
      goalkeeperTrim: const Color(0xFFFFCC00),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompositionKitScope(
            kit: kit,
            child: const Column(
              children: [
                PlayerAvatar(photoUrl: null, name: 'Alex', size: 58),
                PlayerAvatar(
                  photoUrl: null,
                  name: 'Camille',
                  isGoalkeeper: true,
                  size: 58,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.checkroom), findsNothing);
    expect(find.byKey(const ValueKey('composition-kit-field')), findsNothing);
    expect(find.byKey(const ValueKey('composition-kit-goalkeeper')), findsNothing);
    expect(find.byType(PlayerAvatar), findsNWidgets(2));
  });

  testWidgets('deux équipes partagent le terrain, pas leurs couleurs', (
    tester,
  ) async {
    final home = ClubKits.of(JerseyOption.france)
        .copyWith(trim: const Color(0xFFAA0000));
    final away = ClubKits.of(JerseyOption.orange)
        .copyWith(trim: const Color(0xFF00BB00));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              CompositionKitScope(
                kit: home,
                child: const PlayerAvatar(
                  photoUrl: null,
                  name: 'Alex',
                  size: 58,
                ),
              ),
              CompositionKitScope(
                kit: away,
                child: const PlayerAvatar(
                  photoUrl: null,
                  name: 'Camille',
                  size: 58,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('composition-kit-field')), findsNothing);
    expect(find.byIcon(Icons.checkroom), findsNothing);
    expect(find.byType(PlayerAvatar), findsNWidgets(2));
  });

  testWidgets('les photos hors composition ne reçoivent pas le maillot', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlayerAvatar(photoUrl: null, name: 'Alex', size: 58),
        ),
      ),
    );
    expect(find.byIcon(Icons.checkroom), findsNothing);
    expect(find.byKey(const ValueKey('composition-kit-field')), findsNothing);
  });
}
