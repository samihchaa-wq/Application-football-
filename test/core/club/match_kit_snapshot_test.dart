import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/club/match_kit_snapshot.dart';
import 'package:as_grinta/features/matches/domain/jersey_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(ClubKits.reset);
  tearDown(ClubKits.reset);

  test('le snapshot retient couleurs et gardien après modification du club',
      () {
    final kits = [
      for (final kit in ClubKits.defaultsFor())
        kit.slot == JerseyOption.france
            ? kit.copyWith(
                body: const Color(0xFFAA0000),
                goalkeeperBody: const Color(0xFF001122),
                goalkeeperTrim: const Color(0xFFFFFF00),
                pattern: KitPattern.stripes,
                goalkeeperPattern: KitPattern.hoops,
                dressPlayers: true,
              )
            : kit,
    ];
    final row = <String, dynamic>{
      'match_id': 'match-1',
      'club_id': 'club-A',
      'jersey_id': 'france',
      'kit': kits[0].toJson(),
      'kits': [for (final kit in kits) kit.toJson()],
      'captured_at': '2026-11-01T10:00:00Z',
      'team1_kit': kits[0].toJson(),
      'team2_kit': kits[1].toJson(),
    };
    final snapshot = MatchKitSnapshot.fromJson(row)!;

    // Le club change ses tenues après le match.
    ClubKits.setFromJson([
      for (final kit in ClubKits.defaultsFor())
        kit.copyWith(body: const Color(0xFF22AA22)).toJson(),
    ]);

    expect(snapshot.kit.body, const Color(0xFFAA0000));
    expect(snapshot.kit.goalkeeperBody, const Color(0xFF001122));
    expect(snapshot.kit.goalkeeperTrim, const Color(0xFFFFFF00));
    expect(snapshot.kit.pattern, KitPattern.stripes);
    expect(snapshot.kit.goalkeeperPattern, KitPattern.hoops);
    expect(snapshot.kit.dressPlayers, isTrue);
    expect(snapshot.team1Kit!.slot, JerseyOption.france);
    expect(snapshot.team2Kit!.slot, JerseyOption.orange);
    expect(snapshot.allKits.length, 3);
  });

  test('le snapshot historique refuse données incomplètes et valeurs inconnues',
      () {
    final valid = <String, dynamic>{
      'match_id': 'match-2',
      'club_id': 'club-A',
      'jersey_id': 'blue',
      'kit': ClubKits.of(JerseyOption.blue).toJson(),
      'kits': [for (final kit in ClubKits.all) kit.toJson()],
      'captured_at': '2026-11-01T10:00:00Z',
    };
    expect(MatchKitSnapshot.fromJson(valid)?.kit.slot, JerseyOption.blue);
    expect(
      MatchKitSnapshot.fromJson({...valid, 'jersey_id': 'inconnu'}),
      isNull,
    );
    expect(MatchKitSnapshot.fromJson({...valid, 'kits': const []}), isNull);
    expect(MatchKitSnapshot.fromJson({...valid, 'captured_at': null}), isNull);
  });
}
