import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/features/auth/data/auth_repository.dart';
import 'package:petit_filet/features/auth/domain/auth_profile.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
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

void main() {
  Future<void> open(
    WidgetTester tester, {
    double width = 390,
    Future<PlatformSnapshot> Function()? fetch,
    _Controller? controller,
    double textScale = 1,
    PlatformRepository? repository,
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
          if (repository != null)
            platformRepositoryProvider.overrideWithValue(repository),
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
      await tester.enterText(find.byType(TextField), 'Beta');
      await tester.pump();
      expect(find.text('Équipe Alpha'), findsNothing);
      await tester.tap(find.text('Actives'));
      await tester.pump();
      expect(
        find.text('Aucune équipe ne correspond à cette recherche.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Toutes'));
      await tester.pump();
      await tester.tap(find.text('Équipe Beta'));
      await tester.pumpAndSettle();
      expect(find.text('Fiche équipe'), findsOneWidget);
      expect(find.text('Suspendue'), findsOneWidget);
      expect(find.text('Fin de période enregistrée'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('the operator records a payment after confirming', (
    tester,
  ) async {
    final calls = <(String, Map<String, dynamic>)>[];
    final repository = PlatformRepository(
      (name) async => throw StateError('unused'),
      (name, params) async {
        calls.add((name, params));
        return {'current_period_end': '2027-11-18T10:00:00Z'};
      },
    );
    await open(tester, width: 1280, repository: repository);
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Équipe Beta'));
    await tester.pumpAndSettle();

    final button = find.byKey(const Key('platform-record-payment'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);

    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noter le paiement'));
    await tester.pumpAndSettle();
    expect(calls.single.$1, 'platform_record_payment');
    expect(calls.single.$2, {'p_club_id': 'b'});
    expect(
      find.text('Paiement noté : abonnement actif jusqu’au 18/11/2027.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('platform-extend-trial')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a failed action shows a neutral message, never the error', (
    tester,
  ) async {
    final repository = PlatformRepository(
      (name) async => throw StateError('unused'),
      (name, params) async => throw StateError('secret detail'),
    );
    await open(tester, width: 1280, repository: repository);
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Équipe Beta'));
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('platform-extend-trial'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prolonger'));
    await tester.pumpAndSettle();
    expect(
      find.text('L’opération n’a pas abouti. Réessaie dans un instant.'),
      findsOneWidget,
    );
    expect(find.textContaining('secret detail'), findsNothing);
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
    expect(find.text('Répertoire des équipes'), findsOneWidget);
    await tester.tap(find.byKey(const Key('platform-home-button')));
    await tester.pumpAndSettle();
    expect(find.text('À examiner'), findsOneWidget);
    expect(find.text('Répertoire des équipes'), findsNothing);
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
