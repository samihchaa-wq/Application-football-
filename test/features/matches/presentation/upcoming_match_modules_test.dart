import 'package:petit_filet/features/auth/data/auth_repository.dart';
import 'package:petit_filet/features/auth/domain/auth_profile.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/feature_flags/presentation/feature_flags_controller.dart';
import 'package:petit_filet/features/matches/data/match_details_repository.dart';
import 'package:petit_filet/features/matches/presentation/match_details_page.dart';
import 'package:petit_filet/features/sports_management/data/match_availability_board_repository.dart';
import 'package:petit_filet/features/sports_management/data/match_composition_repository.dart';
import 'package:petit_filet/features/sports_management/data/match_sport_report_repository.dart';
import 'package:petit_filet/features/sports_management/domain/match_availability_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

const _matchId = 'upcoming-1';

MatchDetailsData _upcoming({Duration untilKickoff = const Duration(days: 3)}) =>
    MatchDetailsData(
      matchId: _matchId,
      opponentId: 'opp',
      opponentName: 'FC Test',
      isInternal: false,
      kickoffAt: DateTime.now().add(untilKickoff),
      status: 'a_venir',
      resultValidatedAt: null,
      location: 'domicile',
      address: null,
      matchType: 'championnat',
      championshipRound: 3,
      scoreOwn: null,
      scoreOpponent: null,
      oddsWin: null,
      oddsDraw: null,
      oddsLoss: null,
      predictionParticipantCount: 0,
      headToHead: const [],
      playerStats: const [],
      startingLineup: const [],
      predictions: const [],
    );

MatchAvailabilityBoard _board({
  required String convocationState,
  required bool compositionPublished,
}) =>
    MatchAvailabilityBoard(
      matchId: _matchId,
      kickoffAt: DateTime.now().add(const Duration(days: 3)),
      opensAt: DateTime.now().subtract(const Duration(days: 1)),
      state: 'open',
      compositionPublished: compositionPublished,
      squadSizeLimit: 14,
      convocationState: convocationState,
      players: const [],
    );

Future<void> _pump(
  WidgetTester tester, {
  required bool isAdmin,
  MatchAvailabilityBoard? board,
  bool sportsEnabled = true,
  bool? routing = true,
  Duration untilKickoff = const Duration(days: 3),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchDetailsProvider(_matchId).overrideWith(
          (ref) async => _upcoming(untilKickoff: untilKickoff),
        ),
        sportsManagementEnabledProvider.overrideWithValue(sportsEnabled),
        sportsManagementRoutingStateProvider.overrideWithValue(routing),
        isAdminViewProvider.overrideWithValue(isAdmin),
        matchAvailabilityBoardProvider(_matchId).overrideWith(
          (ref) async => board,
        ),
        authControllerProvider.overrideWith(
          (ref) => AuthController(_FakeAuthRepository()),
        ),
        publishedMatchCompositionProvider(_matchId).overrideWith(
          (ref) async => null,
        ),
        matchGoalActionsProvider(_matchId).overrideWith((ref) async => []),
      ],
      child: const MaterialApp(home: MatchDetailsPage(matchId: _matchId)),
    ),
  );
  if (routing == null) {
    await tester.pump(const Duration(milliseconds: 100));
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets(
      'réglages du club pas encore lus : pas de « Gestion sportive indisponible »',
      (tester) async {
    await _pump(tester, isAdmin: false, sportsEnabled: false, routing: null);

    expect(find.text('Gestion sportive indisponible.'), findsNothing);
  });

  testWidgets('gestion sportive réellement coupée : message affiché',
      (tester) async {
    await _pump(tester, isAdmin: false, sportsEnabled: false, routing: false);

    expect(find.text('Gestion sportive indisponible.'), findsOneWidget);
  });

  group('match à venir, vue joueur', () {
    testWidgets('rien de publié : aucune carte menant à une page vide',
        (tester) async {
      await _pump(
        tester,
        isAdmin: false,
        board: _board(convocationState: 'draft', compositionPublished: false),
      );

      expect(find.text('Effectif'), findsNothing);
      expect(find.text('Composition'), findsNothing);
    });

    testWidgets('effectif publié : seule la carte Effectif apparaît',
        (tester) async {
      await _pump(
        tester,
        isAdmin: false,
        board: _board(
          convocationState: 'published',
          compositionPublished: false,
        ),
      );

      expect(find.text('Effectif'), findsOneWidget);
      expect(find.text('Composition'), findsNothing);
    });

    testWidgets('effectif et composition publiés : les deux cartes',
        (tester) async {
      await _pump(
        tester,
        isAdmin: false,
        board:
            _board(convocationState: 'published', compositionPublished: true),
      );

      expect(find.text('Effectif'), findsOneWidget);
      expect(find.text('Composition'), findsOneWidget);
    });
  });

  testWidgets('l’administrateur garde ses deux cartes pour préparer le match',
      (tester) async {
    await _pump(
      tester,
      isAdmin: true,
      board: _board(convocationState: 'draft', compositionPublished: false),
    );

    expect(find.text('Effectif'), findsOneWidget);
    expect(find.text('Composition'), findsOneWidget);
  });

  group('accès au direct depuis la fiche', () {
    final board =
        _board(convocationState: 'published', compositionPublished: true);

    testWidgets('pas de carte « Suivre le direct » plusieurs jours avant',
        (tester) async {
      await _pump(tester, isAdmin: false, board: board);
      expect(find.text('Suivre le direct'), findsNothing);
    });

    testWidgets('à 10 min du coup d’envoi, le joueur peut suivre le direct',
        (tester) async {
      await _pump(
        tester,
        isAdmin: false,
        board: board,
        untilKickoff: const Duration(minutes: 10),
      );
      expect(find.text('Suivre le direct'), findsOneWidget);
    });

    testWidgets('pendant le match, la carte reste là', (tester) async {
      await _pump(
        tester,
        isAdmin: true,
        board: board,
        untilKickoff: const Duration(minutes: -30),
      );
      expect(find.text('Suivre le direct'), findsOneWidget);
      expect(find.text('Effectif'), findsOneWidget);
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  bool get currentUserHasNoClub => false;

  @override
  Future<bool> isPlatformOperator() async => false;

  @override
  Stream<supabase.AuthState> get authStateChanges => const Stream.empty();

  @override
  bool get hasSession => false;

  @override
  Future<AuthProfile?> fetchProfile({bool retryAfterSignIn = false}) async =>
      null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
