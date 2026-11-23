import 'package:petit_filet/features/platform/data/platform_repository.dart';
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
      expect(calls, ['platform_control_overview']);
    },
  );

  test(
    'jeton expiré au retour dans l’appli : session renouvelée puis relecture, '
    'jamais « accès refusé »',
    () async {
      var refreshed = 0;
      var overviewCalls = 0;
      final repository = PlatformRepository(
        (name) async {
          if (name == 'platform_control_overview') {
            overviewCalls++;
            if (refreshed == 0) {
              throw const PostgrestException(
                message: 'JWT expired',
                code: 'PGRST301',
              );
            }
            return {
              'clubs': [
                {'id': 'a', 'name': 'Team'},
              ],
            };
          }
          throw const PostgrestException(message: 'off', code: '42P01');
        },
        refreshSession: () async => refreshed++,
      );
      final snapshot = await repository.fetch();
      expect(snapshot.teams.single.name, 'Team');
      expect(refreshed, 1);
      expect(overviewCalls, 2);
    },
  );

  test(
    'jeton déjà renouvelé par le client pendant la requête : pas de second '
    'renouvellement concurrent',
    () async {
      var token = 'old';
      var refreshed = 0;
      var calls = 0;
      final repository = PlatformRepository(
        (name) async {
          if (name == 'platform_control_overview') {
            calls++;
            if (calls == 1) {
              token = 'new'; // le client Supabase renouvelle de lui-même
              throw const PostgrestException(
                message: 'JWT expired',
                code: 'PGRST301',
              );
            }
            return {
              'clubs': [
                {'id': 'a', 'name': 'Team'},
              ],
            };
          }
          throw const PostgrestException(message: 'off', code: '42P01');
        },
        refreshSession: () async => refreshed++,
        currentAccessToken: () => token,
      );
      final snapshot = await repository.fetch();
      expect(snapshot.teams.single.name, 'Team');
      expect(refreshed, 0);
    },
  );

  test('jeton toujours refusé après renouvellement : un seul essai de plus',
      () async {
    var refreshed = 0;
    var calls = 0;
    final repository = PlatformRepository(
      (name) async {
        calls++;
        throw const PostgrestException(
            message: 'JWT expired', code: 'PGRST301');
      },
      refreshSession: () async => refreshed++,
    );
    await expectLater(repository.fetch(), throwsA(isA<PlatformAccessDenied>()));
    expect(refreshed, 1);
    expect(calls, 2);
  });

  test('refus réel (42501) : aucun renouvellement de session', () async {
    var refreshed = 0;
    final repository = PlatformRepository(
      (name) async =>
          throw const PostgrestException(message: 'denied', code: '42501'),
      refreshSession: () async => refreshed++,
    );
    await expectLater(repository.fetch(), throwsA(isA<PlatformAccessDenied>()));
    expect(refreshed, 0);
  });

  test('revocation between teams and health discards all data', () async {
    final repository = PlatformRepository((name) async {
      if (name == 'platform_control_overview') {
        return {
          'clubs': [
            {'id': 'a', 'name': 'Private team'},
          ],
        };
      }
      throw const PostgrestException(message: 'revoked', code: '42501');
    });
    await expectLater(repository.fetch(), throwsA(isA<PlatformAccessDenied>()));
  });

  test(
    'unavailable health is missing, never zero or globally healthy',
    () async {
      final repository = PlatformRepository((name) async {
        if (name == 'platform_control_overview') {
          return {
            'clubs': [
              {'id': 'a', 'name': 'Team'},
            ],
          };
        }
        throw const PostgrestException(message: 'source down', code: '42P01');
      });
      final snapshot = await repository.fetch();
      expect(snapshot.teams.single.name, 'Team');
      expect(snapshot.health, isNull);
    },
  );

  test('malformed teams fail closed and duplicate IDs are rejected', () async {
    for (final response in [
      null,
      [],
      {},
      {
        'clubs': [null],
      },
      {
        'clubs': [
          {'name': 'Missing ID'},
        ],
      },
      {
        'clubs': [
          {'id': 'a', 'name': 'A'},
          {'id': 'a', 'name': 'A again'},
        ],
      },
    ]) {
      final repository = PlatformRepository((_) async => response);
      await expectLater(repository.fetch(), throwsFormatException);
    }
  });

  test('only the two read-only RPCs are used', () async {
    final calls = <String>[];
    final repository = PlatformRepository((name) async {
      calls.add(name);
      return name == 'platform_control_overview'
          ? {'clubs': []}
          : {'checked_at': '2026-11-16T12:00:00Z', 'failed_jobs_last_hour': 0};
    });
    final snapshot = await repository.fetch();
    expect(calls, ['platform_control_overview', 'platform_health']);
    expect(snapshot.teams, isEmpty);
    expect(snapshot.health!.failedJobs, 0);
    expect(snapshot.health!.failedPush, isNull);
  });

  test('per-club figures, totals and the visit curve are read', () async {
    final repository = PlatformRepository((name) async {
      if (name == 'platform_health') {
        return {'checked_at': '2026-11-16T12:00:00Z'};
      }
      return {
        'clubs': [
          {
            'id': 'a',
            'name': 'Club A',
            'status': 'active',
            'subscription_status': 'trialing',
            'next_due_at': '2026-12-01T10:00:00Z',
            'members': 18,
            'visits_per_day': 4.5,
            'referrals_total': 3,
            'referrals_paid': 2,
            'discount_percent': 10,
            'amount_due_cents': 7110,
            'referred_by': 'Club Parrain',
          },
        ],
        'totals': {'clubs': 1, 'trialing': 1, 'collected_year_cents': 0},
        'daily_visits': [
          {'day': '2026-11-15', 'visits': 3},
          {'day': '2026-11-16', 'visits': 5},
          {'day': 'bad', 'visits': 1},
        ],
      };
    });
    final snapshot = await repository.fetch();
    final club = snapshot.teams.single;
    expect(club.visitsPerDay, 4.5);
    expect(club.referralsPaid, 2);
    expect(club.amountDueCents, 7110);
    expect(club.referredBy, 'Club Parrain');
    expect(club.isTrial, isTrue);
    expect(club.daysUntilDue(DateTime.utc(2026, 11, 21, 10)), 10);
    expect(snapshot.totals.clubs, 1);
    expect(snapshot.totals.collectedYearCents, 0);
    expect(snapshot.totals.paying, isNull);
    expect(snapshot.dailyVisits.map((point) => point.visits), [3, 5]);
  });
}
