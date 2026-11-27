import 'dart:async';

import 'package:petit_filet/features/auth/data/auth_repository.dart';
import 'package:petit_filet/features/auth/domain/auth_profile.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/feature_flags/domain/feature_flags.dart';
import 'package:petit_filet/features/feature_flags/presentation/feature_flags_controller.dart';
import 'package:petit_filet/features/matches/data/matches_repository.dart';
import 'package:petit_filet/features/matches/domain/match_model.dart';
import 'package:petit_filet/features/matches/presentation/calendar_entry_form_page.dart';
import 'package:petit_filet/features/matches/presentation/matches_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Formulaire « Ajouter au calendrier » (point 13 de l'audit du 26/11) :
/// les valeurs proposées par défaut ne doivent pas piéger l'administrateur.
void main() {
  testWidgets(
      'un match proposé pour demain dit que les disponibilités s’ouvrent '
      'tout de suite', (tester) async {
    await _openForm(tester);

    // Demain 21 h : le J-6 à 12 h est derrière nous.
    expect(find.textContaining('c’est déjà passé'), findsOneWidget);
    expect(find.textContaining('touche « Choisir »'), findsOneWidget);
  });

  testWidgets('le stade de l’adversaire disparaît pour un match entre nous',
      (tester) async {
    await _openForm(tester);
    expect(find.text('Stade de l’adversaire'), findsOneWidget);

    final internal = find.text('Match entre nous');
    await tester.ensureVisible(internal);
    await tester.tap(internal);
    await tester.pumpAndSettle();

    expect(find.text('Stade de l’adversaire'), findsNothing);
  });

  testWidgets(
      'la journée proposée suit la dernière journée prévue, pas la plus haute',
      (tester) async {
    final now = DateTime.now();
    await _openForm(
      tester,
      matches: [
        // Ancienne rencontre de la saison saisie avec un numéro élevé.
        _match('m-old',
            round: 22, kickoff: now.subtract(const Duration(days: 60))),
        _match('m-7', round: 7, kickoff: now.subtract(const Duration(days: 7))),
        _match('m-8', round: 8, kickoff: now.add(const Duration(days: 7))),
        // Autre saison : ignorée.
        _match(
          'm-other',
          round: 30,
          kickoff: now.add(const Duration(days: 20)),
          seasonId: 's0',
        ),
      ],
    );

    expect(find.text('Journée de championnat J9'), findsOneWidget);
    expect(find.textContaining('J23'), findsNothing);
  });
}

MatchModel _match(
  String id, {
  required int round,
  required DateTime kickoff,
  String seasonId = 's1',
}) {
  return MatchModel(
    id: id,
    seasonId: seasonId,
    opponentId: 'o1',
    kickoffAt: kickoff,
    isHome: true,
    plannedDurationMinutes: 90,
    status: 'a_venir',
    ownScore: null,
    opponentScore: null,
    matchType: 'championnat',
    championshipRound: round,
    oddsWin: 2,
    oddsDraw: 3,
    oddsLoss: 4,
    opponentName: 'FC Test',
  );
}

Future<void> _openForm(
  WidgetTester tester, {
  List<MatchModel> matches = const [],
}) async {
  // Seule assertion tolérée (comme dans match_form_page_test) : la case
  // « Garder cette adresse » est posée sur un fond coloré, ce que Flutter
  // signale en mode test. Toute autre erreur fait échouer le test.
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains(
          'ListTile background color or ink splashes may be invisible',
        )) {
      return;
    }
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
  await tester.binding.setSurfaceSize(const Size(900, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => _SignedInController()),
        matchesRepositoryProvider.overrideWithValue(_FakeMatchesRepository()),
        matchesControllerProvider.overrideWith(
          (ref) => _StaticMatchesController(ref, matches),
        ),
        featureFlagsControllerProvider.overrideWith(_PendingFlags.new),
        sportsManagementEnabledProvider.overrideWithValue(false),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('Calendrier')),
      ),
    ),
  );
  unawaited(
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const CalendarEntryFormPage()),
    ),
  );
  await tester.pumpAndSettle();
}

class _StaticMatchesController extends MatchesController {
  _StaticMatchesController(Ref ref, List<MatchModel> matches)
      : super(_FakeMatchesRepository(), ref) {
    state = MatchesState(
      isLoading: false,
      matches: matches,
      seasons: const [
        {'id': 's1', 'name': '2026-2027', 'status': 'open'},
        {'id': 's0', 'name': '2025-2026', 'status': 'closed'},
      ],
      opponents: const [
        {'id': 'o1', 'name': 'FC Test', 'address': ''},
      ],
      selectedSeasonId: 's1',
    );
  }

  @override
  Future<void> load({
    String? seasonId,
    bool allSeasons = false,
    bool forceRefresh = false,
  }) async {}
}

class _FakeMatchesRepository implements MatchesRepository {
  @override
  Future<String?> fetchClubHomeAddress() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PendingFlags extends FeatureFlagsController {
  @override
  Future<FeatureFlagsSnapshot> build() =>
      Completer<FeatureFlagsSnapshot>().future;
}

class _SignedInController extends AuthController {
  _SignedInController() : super(_FakeAuthRepository()) {
    state = const AuthState(
      isLoading: false,
      isAuthenticated: true,
      hasSession: true,
      profile: AuthProfile(
        id: 'profile-1',
        firstName: 'Samih',
        lastName: 'Test',
        role: AuthRole.admin,
        isGoalkeeper: false,
        isActive: true,
        mustChangePassword: false,
      ),
    );
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  bool get currentUserHasNoClub => false;

  @override
  Future<bool> isPlatformOperator() async => false;

  final _events = StreamController<supabase.AuthState>.broadcast();

  @override
  Stream<supabase.AuthState> get authStateChanges => _events.stream;

  @override
  bool get hasSession => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
