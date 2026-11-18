import 'package:petit_filet/features/platform/domain/platform_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing and malformed metrics never become zero', () {
    for (final value in [null, -1, '0', 1.5, double.nan]) {
      expect(measuredCount(value), isNull);
    }
    expect(measuredCount(0), 0);
    final team = PlatformTeam.fromJson({'id': 'a', 'name': 'Équipe A'});
    expect(team.members, isNull);
    expect(team.statusLabel, 'État inconnu');
    final snapshot = PlatformSnapshot(
      teams: [team],
      fetchedAt: DateTime.utc(2026),
    );
    expect(snapshot.activeMemberCount, isNull);
  });

  test('the server trial status is shown as a trial', () {
    final team = PlatformTeam.fromJson({
      'id': 'a',
      'name': 'Équipe A',
      'subscription_status': 'trialing',
    });
    expect(team.subscriptionLabel, 'Essai');
  });

  test('aggregates actual profiles, never players or historical price', () {
    final team = PlatformTeam.fromJson({
      'id': 'a',
      'name': 'Équipe A',
      'status': 'active',
      'members': 12,
      'billable_players': 19,
      'yearly_amount_cents': 19000,
    });
    final snapshot = PlatformSnapshot(
      teams: [team],
      fetchedAt: DateTime.utc(2026),
    );
    expect(snapshot.activeTeams, 1);
    expect(snapshot.activeMemberCount, 12);
  });

  test(
    'renewals use active annual periods, 30-day boundaries and date order',
    () {
      final now = DateTime.utc(2026, 11, 16);
      PlatformTeam team(String id, DateTime? end, {String status = 'active'}) =>
          PlatformTeam(
            id: id,
            name: id,
            status: 'active',
            subscriptionStatus: status,
            currentPeriodEnd: end,
          );
      final snapshot = PlatformSnapshot(
        fetchedAt: now,
        teams: [
          team('last', now.add(const Duration(days: 30))),
          team('expired', now.subtract(const Duration(seconds: 1))),
          team('tomorrow', now.add(const Duration(days: 1))),
          team('now', now),
          team('outside', now.add(const Duration(days: 30, seconds: 1))),
          team('missing', null),
          team('trial', now, status: 'trial'),
        ],
      );
      expect(
        snapshot
            .renewalsBefore(now, const Duration(days: 30))
            .map((team) => team.id),
        ['now', 'tomorrow', 'last'],
      );
    },
  );

  test('search and filters combine without changing the source', () {
    final teams = [
      const PlatformTeam(id: 'b', name: 'Beta', status: 'suspended'),
      const PlatformTeam(id: 'a', name: 'Alpha', status: 'active'),
    ];
    expect(filterPlatformTeams(teams).map((team) => team.id), ['a', 'b']);
    expect(
      filterPlatformTeams(teams, query: ' ALP ', status: 'active').single.id,
      'a',
    );
    expect(
      filterPlatformTeams(teams, query: 'Beta', status: 'active'),
      isEmpty,
    );
    expect(teams.first.id, 'b');
  });

  test('health requires a real observation timestamp', () {
    expect(() => PlatformHealth.fromJson({}), throwsFormatException);
    final health = PlatformHealth.fromJson({
      'checked_at': '2026-11-16T12:00:00Z',
    });
    expect(health.failedPush, isNull);
    expect(health.checkedAt.isUtc, isTrue);
  });
}
