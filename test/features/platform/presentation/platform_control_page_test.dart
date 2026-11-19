import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/features/auth/data/auth_repository.dart';
import 'package:petit_filet/features/auth/domain/auth_profile.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/platform/data/platform_billing_repository.dart';
import 'package:petit_filet/features/platform/data/platform_repository.dart';
import 'package:petit_filet/features/platform/domain/platform_snapshot.dart';
import 'package:petit_filet/features/platform/presentation/platform_control_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

final _snapshot = PlatformSnapshot(
  fetchedAt: DateTime.utc(2026, 11, 16),
  teams: const [
    PlatformTeam(id: 'a', name: 'Équipe Alpha', status: 'active', members: 12),
    PlatformTeam(
      id: 'b',
      name: 'Équipe Beta',
      status: 'suspended',
      members: 10,
    ),
  ],
);

final _now = DateTime.now().toUtc();

final _rich = PlatformSnapshot(
  fetchedAt: _now,
  teams: [
    PlatformTeam(
      id: 'trial',
      name: 'FC Essai',
      status: 'active',
      subscriptionStatus: 'trialing',
      createdAt: _now.subtract(const Duration(days: 25)),
      trialEndsAt: _now.add(const Duration(days: 5)),
      nextDueAt: _now.add(const Duration(days: 5)),
      members: 22,
      players: 18,
      visitsPerDay: 6.5,
      visits30d: 160,
      people7d: 15,
      lastVisitOn: _now,
      referralsTotal: 0,
      referralsPaid: 0,
      referredBy: 'AS Abonnée',
      basePriceCents: 7900,
      discountPercent: 5,
      amountDueCents: 7505,
    ),
    PlatformTeam(
      id: 'paid',
      name: 'AS Abonnée',
      status: 'active',
      subscriptionStatus: 'active',
      createdAt: _now.subtract(const Duration(days: 400)),
      currentPeriodEnd: _now.add(const Duration(days: 200)),
      nextDueAt: _now.add(const Duration(days: 200)),
      members: 30,
      players: 25,
      visitsPerDay: 2.1,
      people7d: 9,
      lastVisitOn: _now.subtract(const Duration(days: 20)),
      referralsTotal: 3,
      referralsPaid: 2,
      basePriceCents: 7900,
      discountPercent: 10,
      amountDueCents: 7110,
      paidCents: 7900,
    ),
  ],
  totals: const PlatformTotals(
    clubs: 2,
    trialing: 1,
    paying: 1,
    suspended: 0,
    new30d: 1,
    trialsEnding7d: 1,
    due30d: 1,
    due30dCents: 7505,
    expected12mCents: 14615,
    members: 52,
    players: 43,
    visitsToday: 12,
    people7d: 24,
    collectedTotalCents: 7900,
    collectedYearCents: 7900,
    toDelete90d: 0,
  ),
  dailyVisits: [
    for (var i = 29; i >= 0; i--)
      PlatformDailyVisits(_now.subtract(Duration(days: i)), i % 7),
  ],
);

void main() {
  Future<void> open(
    WidgetTester tester, {
    double width = 390,
    Future<PlatformSnapshot> Function()? fetch,
    _Controller? controller,
    double textScale = 1,
    PlatformBillingRepository? billing,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => controller ?? _Controller(),
          ),
          platformSnapshotProvider.overrideWith(
            (ref) => (fetch ?? () async => _snapshot)(),
          ),
          platformBillingRepositoryProvider.overrideWithValue(
            billing ?? _FakeBilling().repository,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const PlatformControlPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [390.0, 1280.0]) {
    testWidgets('responsive console at $width pixels with missing metrics', (
      tester,
    ) async {
      await open(tester, width: width);
      expect(find.text('Poste de contrôle'), findsOneWidget);
      expect(find.text('Non mesuré'), findsWidgets);
      expect(find.text('Lecture seule'), findsOneWidget);
      expect(
        width < 1000 ? find.byType(NavigationBar) : find.byType(NavigationRail),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'search, status filter and team detail work without switching identity',
    (tester) async {
      await open(tester);
      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Équipe Alpha'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('platform-club-search')),
        'Beta',
      );
      await tester.pump();
      expect(find.text('Équipe Alpha'), findsNothing);
      await tester.tap(find.byKey(const Key('platform-filter-paying')));
      await tester.pump();
      expect(
        find.text('Aucun club ne correspond à cette recherche.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('platform-filter-all')));
      await tester.pump();
      await tester.tap(find.text('Équipe Beta'));
      await tester.pumpAndSettle();
      expect(find.text('Fiche club'), findsOneWidget);
      expect(find.text('Suspendue'), findsOneWidget);
      expect(find.text('Fin de l’année payée'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('the operator records an offline payment from a team page', (
    tester,
  ) async {
    final billing = _FakeBilling();
    await open(tester, width: 1280, billing: billing.repository);
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Équipe Beta'));
    await tester.pumpAndSettle();
    expect(find.text('Lecture seule'), findsNothing);
    expect(find.text('Suspendue automatiquement pour impayé'), findsOneWidget);
    expect(find.text('Aucun paiement noté pour cette équipe.'), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const Key('platform-record-payment')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('platform-record-payment')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('platform-payment-amount')))
          .controller!
          .text,
      '79',
    );
    await tester.enterText(
      find.byKey(const Key('platform-payment-amount')),
      'abc',
    );
    await tester.tap(find.byKey(const Key('platform-payment-save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Montant illisible'), findsOneWidget);
    expect(billing.recorded, isEmpty);

    await tester.enterText(
      find.byKey(const Key('platform-payment-amount')),
      '79,00',
    );
    await tester.tap(find.byKey(const Key('platform-payment-save')));
    await tester.pumpAndSettle();
    expect(billing.recorded.single['p_club_id'], 'b');
    expect(billing.recorded.single['p_amount_cents'], 7900);
    expect(billing.recorded.single['p_method'], 'virement');
    expect(find.textContaining('L’équipe a retrouvé l’accès.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('refresh after revocation removes previously visible team data', (
    tester,
  ) async {
    var revoked = false;
    await open(
      tester,
      fetch: () async {
        if (revoked) throw const PlatformAccessDenied();
        return _snapshot;
      },
    );
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Équipe Alpha'), findsOneWidget);
    revoked = true;
    await tester.tap(find.byTooltip('Actualiser les données'));
    await tester.pumpAndSettle();
    expect(find.text('Accès gestionnaire requis'), findsOneWidget);
    expect(find.text('Équipe Alpha'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('network failure never displays raw errors or sample metrics', (
    tester,
  ) async {
    await open(tester, fetch: () async => throw StateError('private detail'));
    expect(find.text('Données indisponibles'), findsOneWidget);
    expect(find.textContaining('private detail'), findsNothing);
    expect(find.text('Équipe Alpha'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('large text remains usable on a narrow phone', (tester) async {
    await open(tester, width: 360, textScale: 1.5);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'operator home returns to overview without requiring a team calendar',
      (tester) async {
    await open(tester);
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('platform-club-search')), findsOneWidget);
    await tester.tap(find.byKey(const Key('platform-home-button')));
    await tester.pumpAndSettle();
    expect(find.text('À traiter'), findsOneWidget);
    expect(find.byKey(const Key('platform-club-search')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('signing out hides a loaded privileged snapshot immediately',
      (tester) async {
    final controller = _Controller();
    await open(tester, controller: controller);
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Équipe Alpha'), findsOneWidget);
    controller.signedOutForTest();
    await tester.pump();
    expect(find.text('Équipe Alpha'), findsNothing);
    expect(find.text('Vérification de l’accès…'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('background hides private data and resume rechecks access',
      (tester) async {
    var revoked = false;
    await open(tester, fetch: () async {
      if (revoked) throw const PlatformAccessDenied();
      return _snapshot;
    });
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Équipe Alpha'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('Équipe Alpha'), findsNothing);
    revoked = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Accès gestionnaire requis'), findsOneWidget);
    expect(find.text('Équipe Alpha'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dashboard shows money, clubs, visits and what to handle',
      (tester) async {
    await open(tester, width: 1280, fetch: () async => _rich);
    expect(find.text('Encaissé cette année'), findsOneWidget);
    expect(find.text('Prévu sur 12 mois'), findsOneWidget);
    expect(
        find.textContaining('1 en mois gratuit · 1 abonnés'), findsOneWidget);
    expect(find.text('Visites des 30 derniers jours'), findsOneWidget);
    expect(find.textContaining('par jour en moyenne'), findsOneWidget);
    expect(find.byKey(const Key('platform-todo-trials')), findsOneWidget);
    expect(find.byKey(const ValueKey('platform-due-trial')), findsOneWidget);
    expect(find.byKey(const Key('platform-todo-quiet')), findsOneWidget,
        reason: 'AS Abonnée has not visited for 20 days');
    expect(find.text('Les clubs les plus actifs'), findsOneWidget);

    // A to-do opens the matching filtered club list.
    await tester.ensureVisible(find.byKey(const Key('platform-todo-trials')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('platform-todo-trials')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('platform-team-trial')), findsOneWidget);
    expect(find.byKey(const ValueKey('platform-team-paid')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('club list shows every column at $width pixels',
        (tester) async {
      await open(tester, width: width, fetch: () async => _rich);
      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('platform-team-trial'));
      expect(row, findsOneWidget);
      String rowText() => tester
          .widgetList<Text>(
              find.descendant(of: row, matching: find.byType(Text)))
          .map((text) => text.data ?? '')
          .join(' | ');
      expect(rowText(), contains('18 joueurs'));
      expect(rowText(), contains('6,5'));
      expect(rowText(), contains('25 j'));
      expect(rowText(), contains('dans 5 j'));
      expect(rowText(), contains('75,05'));
      expect(rowText(), contains('Mois gratuit'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('sorting by visits puts the most active club first',
      (tester) async {
    await open(tester, width: 1280, fetch: () async => _rich);
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    double top(String id) =>
        tester.getTopLeft(find.byKey(ValueKey('platform-team-$id'))).dy;
    expect(top('trial'), lessThan(top('paid')),
        reason: 'nearest due date first');
    await tester.tap(find.byKey(const Key('platform-club-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trier : Effectif').last);
    await tester.pumpAndSettle();
    expect(top('paid'), lessThan(top('trial')), reason: '25 players before 18');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('club page details referral, amount due and seniority',
      (tester) async {
    await open(tester, width: 1280, fetch: () async => _rich);
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('platform-team-paid')));
    await tester.pumpAndSettle();
    expect(find.text('Fiche club'), findsOneWidget);
    expect(find.textContaining('parrainage −10 %'), findsOneWidget);
    expect(find.text('3 · 2 payé(s)'), findsOneWidget);
    expect(find.textContaining('1 an et 1 mois'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _Controller extends AuthController {
  _Controller() : super(_Repository()) {
    state = const AuthState(
      isLoading: false,
      hasSession: true,
      needsClub: true,
    );
  }

  void signedOutForTest() => state = const AuthState(isLoading: false);
}

class _Repository implements AuthRepository {
  @override
  bool get hasSession => true;
  @override
  bool get currentUserHasNoClub => true;
  @override
  Stream<supabase.AuthState> get authStateChanges => const Stream.empty();
  @override
  Future<AuthProfile?> fetchProfile({bool retryAfterSignIn = false}) async =>
      null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBilling {
  final recorded = <Map<String, dynamic>>[];

  late final repository = PlatformBillingRepository((name, params) async {
    if (name == 'platform_club_billing') {
      return {
        'base_price_cents': 7900,
        'suspension_on': '2026-11-01T00:00:00Z',
        'auto_suspended_at': recorded.isEmpty ? '2026-11-02T04:23:00Z' : null,
        'payments': [
          for (final payment in recorded)
            {
              'amount_cents': payment['p_amount_cents'],
              'method': payment['p_method'],
              'received_on': payment['p_received_on'],
              'period_end': '2027-11-18T10:00:00Z',
            },
        ],
      };
    }
    if (name == 'platform_record_offline_payment') {
      recorded.add(params);
      return {'period_end': '2027-11-18T10:00:00Z', 'reopened': true};
    }
    throw StateError('unexpected $name');
  });
}
