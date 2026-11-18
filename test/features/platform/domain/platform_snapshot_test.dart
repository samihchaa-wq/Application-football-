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

  test('club list: filters, sorts, missing values last', () {
    final now = DateTime.utc(2026, 11, 18);
    final teams = [
      PlatformTeam(
        id: 'trial',
        name: 'B Essai',
        status: 'active',
        subscriptionStatus: 'trialing',
        nextDueAt: now.add(const Duration(days: 4)),
        players: 10,
        visitsPerDay: 3,
        amountDueCents: 7505,
        createdAt: now.subtract(const Duration(days: 26)),
      ),
      PlatformTeam(
        id: 'paid',
        name: 'A Abonné',
        status: 'active',
        subscriptionStatus: 'active',
        nextDueAt: now.add(const Duration(days: 300)),
        players: 20,
        visitsPerDay: 1,
        amountDueCents: 7900,
        createdAt: now.subtract(const Duration(days: 65)),
      ),
      const PlatformTeam(
        id: 'off',
        name: 'C Suspendu',
        status: 'suspended',
        subscriptionStatus: 'active',
      ),
    ];
    List<String> ids({
      PlatformClubFilter filter = PlatformClubFilter.all,
      PlatformClubSort sort = PlatformClubSort.nextDue,
      String query = '',
    }) =>
        selectPlatformClubs(
          teams,
          now: now,
          filter: filter,
          sort: sort,
          query: query,
        ).map((team) => team.id).toList();

    expect(ids(), ['trial', 'paid', 'off']);
    expect(ids(sort: PlatformClubSort.squad), ['paid', 'trial', 'off']);
    expect(ids(sort: PlatformClubSort.visits), ['trial', 'paid', 'off']);
    expect(ids(sort: PlatformClubSort.seniority), ['paid', 'trial', 'off']);
    expect(ids(sort: PlatformClubSort.amountDue), ['paid', 'trial', 'off']);
    expect(ids(sort: PlatformClubSort.name), ['paid', 'trial', 'off']);
    expect(ids(filter: PlatformClubFilter.trial), ['trial']);
    expect(ids(filter: PlatformClubFilter.paying), ['paid']);
    expect(ids(filter: PlatformClubFilter.dueSoon), ['trial']);
    expect(ids(filter: PlatformClubFilter.suspended), ['off']);
    expect(ids(query: ' essai '), ['trial']);
  });

  test('seniority and due date read naturally', () {
    final now = DateTime.utc(2026, 11, 18, 12);
    expect(formatSeniority(null, now), 'Non renseigné');
    expect(formatSeniority(now.subtract(const Duration(hours: 3)), now),
        'Aujourd’hui');
    expect(
        formatSeniority(now.subtract(const Duration(days: 12)), now), '12 j');
    expect(
        formatSeniority(now.subtract(const Duration(days: 95)), now), '3 mois');
    expect(
        formatSeniority(now.subtract(const Duration(days: 366)), now), '1 an');
    expect(formatSeniority(now.subtract(const Duration(days: 800)), now),
        '2 ans et 2 mois');
    expect(formatDueIn(null), 'Aucune');
    expect(formatDueIn(0), 'aujourd’hui');
    expect(formatDueIn(9), 'dans 9 j');
    expect(formatDueIn(-2), 'dépassée de 2 j');
    final team = PlatformTeam(
      id: 'a',
      name: 'A',
      status: 'active',
      nextDueAt: now.add(const Duration(days: 10, hours: 1)),
    );
    expect(team.daysUntilDue(now), 11);
  });
}
