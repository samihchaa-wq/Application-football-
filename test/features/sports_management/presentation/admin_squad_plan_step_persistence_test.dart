import 'dart:async';

import 'package:petit_filet/core/sync/shared_data_sync.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/features/matches/presentation/widgets/upcoming_match_fixture_header.dart';
import 'package:petit_filet/features/predictions/presentation/widgets/inline_match_prediction_card.dart';
import 'package:petit_filet/features/sports_management/data/match_composition_repository.dart';
import 'package:petit_filet/features/sports_management/data/sport_waitlist_repository.dart';
import 'package:petit_filet/features/sports_management/domain/availability_reminder_models.dart';
import 'package:petit_filet/features/sports_management/domain/match_composition.dart';
import 'package:petit_filet/features/sports_management/domain/player_position_history.dart';
import 'package:petit_filet/features/sports_management/domain/sport_waitlist_models.dart';
import 'package:petit_filet/features/sports_management/presentation/admin_squad_plan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _matchId = 'match-step-persistence';

void main() {
  // Régression : à T-15 les pronostics ferment, donc showPredictionStep passe
  // de vrai à faux tout seul. Cette bascule était prise pour une demande de
  // navigation et renvoyait l'admin sur l'onglet d'arrivée (Info), en plein
  // Tableau Blanc, au premier rafraîchissement suivant.
  testWidgets(
    'la fermeture des pronostics ne renvoie pas sur l’onglet d’arrivée',
    (tester) async {
      await _pump(tester, showPredictionStep: true);
      expect(find.text('Prono'), findsOneWidget);

      await tester.tap(find.text('Effectif'));
      await _settle(tester);
      expect(find.textContaining('Convoqués ('), findsOneWidget);

      // Même page, même section demandée : seules les pronostics viennent de
      // fermer.
      await _pump(tester, showPredictionStep: false);
      expect(find.text('Prono'), findsNothing);
      expect(
        find.textContaining('Convoqués ('),
        findsOneWidget,
        reason: 'l’onglet choisi à la main doit survivre à la fermeture des '
            'pronostics',
      );
    },
  );

  testWidgets('l’onglet Prono affiché cède la place quand il disparaît', (
    tester,
  ) async {
    await _pump(tester, showPredictionStep: true);
    await tester.tap(find.text('Prono'));
    await _settle(tester);
    expect(find.byType(InlineMatchPredictionCard), findsOneWidget);

    // Là, en revanche, l'onglet consulté n'existe plus : la page doit revenir
    // d'elle-même sur la section demandée à l'ouverture.
    await _pump(tester, showPredictionStep: false);
    expect(find.text('Prono'), findsNothing);
    expect(find.byType(InlineMatchPredictionCard), findsNothing);
  });

  // Un joueur répond « Absent » pendant que le coach prépare l'effectif :
  // l'écran ouvert doit relire les réponses, sans qu'il faille le rouvrir.
  testWidgets('un signal sportif recharge l’effectif ouvert', (tester) async {
    final signals = StreamController<SharedDataChangeSignal?>.broadcast();
    addTearDown(signals.close);
    final repository = _FakeSportWaitlistRepository(_convocations());
    SharedDataChangeSignal signal(int sports) => SharedDataChangeSignal(
          revision: sports,
          profileRevision: 1,
          sportsRevision: sports,
          updatedAt: DateTime.utc(2026, 11, 24),
        );

    await _pump(
      tester,
      showPredictionStep: false,
      repository: repository,
      signals: signals.stream,
    );
    signals.add(signal(1));
    await _settle(tester);
    final loadsBefore = repository.convocationLoads;

    signals.add(signal(2));
    await _settle(tester);
    expect(repository.convocationLoads, loadsBefore + 1);

    // Même révision : rien ne change, aucun rechargement inutile.
    signals.add(signal(2));
    await _settle(tester);
    expect(repository.convocationLoads, loadsBefore + 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required bool showPredictionStep,
  _FakeSportWaitlistRepository? repository,
  Stream<SharedDataChangeSignal?>? signals,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sportWaitlistRepositoryProvider.overrideWithValue(
          repository ?? _FakeSportWaitlistRepository(_convocations()),
        ),
        if (signals != null)
          sharedDataSignalProvider.overrideWith((ref) => signals),
        matchCompositionRepositoryProvider.overrideWithValue(
          _FakeMatchCompositionRepository(),
        ),
        upcomingMatchFixtureProvider(_matchId).overrideWith(
          (ref) async => const UpcomingMatchFixtureData(
            status: 'a_venir',
            location: 'domicile',
            opponentName: 'Olympique Test',
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        home: AdminSquadPlanPage(
          initialMatchId: _matchId,
          initialStep: 'info',
          showPredictionStep: showPredictionStep,
        ),
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var index = 0; index < 12; index += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

MatchConvocations _convocations() {
  final players = [
    _player(id: 'p1', seasonPlayerId: 'sp1', name: 'Alex', isGoalkeeper: true),
    _player(id: 'p2', seasonPlayerId: 'sp2', name: 'Bruno'),
    _player(id: 'p3', seasonPlayerId: 'sp3', name: 'Clara'),
  ];

  return MatchConvocations(
    matchId: _matchId,
    opponentName: 'Olympique Test',
    kickoffAt: DateTime.now().add(const Duration(days: 2)),
    seasonId: 'season-step',
    squadSizeLimit: 14,
    publishedSquadSizeLimit: 14,
    convocationState: 'published',
    convocationVersion: 2,
    hasUnpublishedChanges: false,
    lateWithdrawalCutoffAt: null,
    availableCount: players.length,
    convokedCount: players.length,
    notConvokedCount: 0,
    players: players,
  );
}

ConvocationPlayer _player({
  required String id,
  required String seasonPlayerId,
  required String name,
  bool isGoalkeeper = false,
}) {
  return ConvocationPlayer(
    participantId: id,
    seasonPlayerId: seasonPlayerId,
    firstName: name,
    lastName: 'Grinta',
    availabilityStatus: 'available',
    convocationStatus: ConvocationStatus.convoked,
    publishedConvocationStatus: ConvocationStatus.convoked,
    manualOverride: true,
    waitlistPosition: null,
    recommendedNotConvoked: false,
    turnShouldConsume: false,
    turnState: WaitlistTurnState.waived,
    promotedAfterWithdrawalAt: null,
    isGoalkeeper: isGoalkeeper,
  );
}

class _FakeSportWaitlistRepository implements SportWaitlistRepository {
  _FakeSportWaitlistRepository(this.convocations);

  final MatchConvocations convocations;

  @override
  Future<List<AdminSportMatch>> fetchUpcomingMatches() async => [
        AdminSportMatch(
          id: _matchId,
          opponentName: 'Olympique Test',
          kickoffAt: convocations.kickoffAt,
        ),
      ];

  int convocationLoads = 0;

  @override
  Future<MatchConvocations> fetchMatchConvocations(String matchId) async {
    convocationLoads += 1;
    return convocations;
  }

  @override
  Future<AvailabilityReminderSummary> fetchReminderSummary(
    String matchId,
  ) async {
    return const AvailabilityReminderSummary(
      matchId: _matchId,
      availabilityState: 'open',
      noResponseCount: 0,
      openSentCount: 1,
      j3SentCount: 0,
      j1SentCount: 0,
      canRemind: true,
      players: [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMatchCompositionRepository implements MatchCompositionRepository {
  @override
  Future<MatchComposition?> fetchAdminComposition(String matchId) async => null;

  @override
  Future<Set<String>> fetchGoalkeeperSeasonPlayerIds(
    List<String> seasonPlayerIds,
  ) async =>
      {'sp1'};

  @override
  Future<Map<String, String>> fetchCanonicalPlayerIds(
    List<String> seasonPlayerIds,
  ) async =>
      const {};

  @override
  Future<List<PlayedPosition>> fetchPlayerPositionHistory(
    DateTime since,
  ) async =>
      const [];

  @override
  Future<FinishedBenchHistory> fetchFinishedBenchHistory(
    String matchId,
  ) async =>
      FinishedBenchHistory.empty;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
