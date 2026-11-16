import 'package:as_grinta/features/platform/data/platform_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'non-operator rejection never requests another global endpoint',
    () async {
      final calls = <String>[];
      final repository = PlatformRepository((name) async {
        calls.add(name);
        throw const PostgrestException(message: 'denied', code: '42501');
      });
      await expectLater(
        repository.fetch(),
        throwsA(isA<PlatformAccessDenied>()),
      );
      expect(calls, ['platform_list_clubs']);
    },
  );

  test('revocation between teams and health discards all data', () async {
    final repository = PlatformRepository((name) async {
      if (name == 'platform_list_clubs') {
        return [
          {'id': 'a', 'name': 'Private team'},
        ];
      }
      throw const PostgrestException(message: 'revoked', code: '42501');
    });
    await expectLater(repository.fetch(), throwsA(isA<PlatformAccessDenied>()));
  });

  test(
    'unavailable health is missing, never zero or globally healthy',
    () async {
      final repository = PlatformRepository((name) async {
        if (name == 'platform_list_clubs') {
          return [
            {'id': 'a', 'name': 'Team'},
          ];
        }
        throw const PostgrestException(message: 'source down', code: '42P01');
      });
      final snapshot = await repository.fetch();
      expect(snapshot.teams.single.name, 'Team');
      expect(snapshot.health, isNull);
    },
  );

  test('malformed teams fail closed and duplicate IDs are rejected', () async {
    for (final rows in [
      null,
      {},
      [null],
      [
        {'name': 'Missing ID'},
      ],
      [
        {'id': 'a', 'name': 'A'},
        {'id': 'a', 'name': 'A again'},
      ],
    ]) {
      final repository = PlatformRepository((_) async => rows);
      await expectLater(repository.fetch(), throwsFormatException);
    }
  });

  test('only the two existing read-only RPCs are used', () async {
    final calls = <String>[];
    final repository = PlatformRepository((name) async {
      calls.add(name);
      return name == 'platform_list_clubs'
          ? []
          : {'checked_at': '2026-11-16T12:00:00Z', 'failed_jobs_last_hour': 0};
    });
    final snapshot = await repository.fetch();
    expect(calls, ['platform_list_clubs', 'platform_health']);
    expect(snapshot.teams, isEmpty);
    expect(snapshot.health!.failedJobs, 0);
    expect(snapshot.health!.failedPush, isNull);
  });
}
