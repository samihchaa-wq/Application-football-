import 'dart:async';

import 'package:as_grinta/core/widgets/sticky_header_table.dart';
import 'package:as_grinta/features/sports_management/data/sport_waitlist_repository.dart';
import 'package:as_grinta/features/sports_management/domain/availability_reminder_models.dart';
import 'package:as_grinta/features/sports_management/domain/sport_waitlist_models.dart';
import 'package:as_grinta/features/sports_management/presentation/admin_waitlist_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('waitlist uses the sticky statistics table layout', (
    tester,
  ) async {
    final repository = _FakeSportWaitlistRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sportWaitlistRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AdminWaitlistPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StickyHeaderTableCard), findsOneWidget);
    expect(find.text('Joueurs'), findsOneWidget);
    expect(find.text('Saison\nprécédente'), findsOneWidget);
    expect(find.text('Tour cette\nsaison'), findsOneWidget);
    expect(find.text('Prénoms'), findsNothing);
    expect(find.text('#'), findsNothing);
    expect(find.text('Tours'), findsNothing);
    expect(find.text('Actions'), findsNothing);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing);

    final table = tester.widget<StickyHeaderTableCard>(
      find.byType(StickyHeaderTableCard),
    );
    expect(table.rows, hasLength(2));
  });

  testWidgets('players cannot be dragged to another place in the list', (
    tester,
  ) async {
    final repository = _FakeSportWaitlistRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sportWaitlistRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AdminWaitlistPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('waitlist-drag-alice')), findsNothing);
    expect(find.byType(LongPressDraggable<SportWaitlistEntry>), findsNothing);
    expect(find.byType(DragTarget<SportWaitlistEntry>), findsNothing);
  });

  testWidgets(
    'waitlist has no save, recalculate or refresh button: pull to refresh',
    (tester) async {
      final repository = _FakeSportWaitlistRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sportWaitlistRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: AdminWaitlistPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recalculer'), findsNothing);
      expect(find.text('Enregistrer l’ordre'), findsNothing);
      expect(find.byTooltip('Actualiser'), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.text('Saison 2026-2027'), findsNothing);
      expect(find.textContaining('L’application commence'), findsNothing);

      final table = tester.widget<StickyHeaderTableCard>(
        find.byType(StickyHeaderTableCard),
      );
      expect(table.onRefresh, isNotNull);
    },
  );

  testWidgets(
    'tapping + next to a player adjusts and persists their waitlist count',
    (tester) async {
      final repository = _FakeSportWaitlistRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sportWaitlistRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: AdminWaitlistPage()),
        ),
      );
      await tester.pumpAndSettle();

      Text countText() => tester.widget<Text>(
            find.byKey(const ValueKey('waitlist-count-bruno')),
          );

      expect(countText().data, '1');

      await tester.tap(find.byKey(const ValueKey('waitlist-increment-bruno')));
      await tester.pumpAndSettle();

      expect(repository.lastManualCountSeasonPlayerId, 'bruno');
      expect(repository.lastDelta, 1);
      expect(countText().data, '2');
    },
  );

  testWidgets('a successful adjustment immediately adopts server order', (
    tester,
  ) async {
    final repository = _FakeSportWaitlistRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sportWaitlistRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AdminWaitlistPage()),
      ),
    );
    await tester.pumpAndSettle();
    double rowY(String id) =>
        tester.getTopLeft(find.byKey(ValueKey('waitlist-row-$id'))).dy;
    expect(rowY('alice'), lessThan(rowY('bruno')));
    await tester.tap(find.byKey(const ValueKey('waitlist-increment-bruno')));
    await tester.pumpAndSettle();
    expect(rowY('bruno'), lessThan(rowY('alice')));
    expect(repository.lastDelta, 1);
    expect(repository.lastManualCount, isNull);
  });

  testWidgets('a lost acknowledgement retries the same gesture exactly once', (
    tester,
  ) async {
    final repository = _FakeSportWaitlistRepository()
      ..loseFirstAcknowledgement = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sportWaitlistRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AdminWaitlistPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('waitlist-increment-bruno')));
    await tester.pumpAndSettle();
    expect(find.textContaining('pas encore confirmée'), findsOneWidget);
    final plus = tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(const ValueKey('waitlist-increment-alice')),
        matching: find.byType(IconButton),
      ),
    );
    expect(plus.onPressed, isNull);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(repository.requestIds, hasLength(2));
    expect(repository.requestIds.toSet(), hasLength(1));
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('waitlist-count-bruno')))
          .data,
      '2',
    );
    expect(find.textContaining('pas encore confirmée'), findsNothing);
  });

  testWidgets('two taps while saving submit only one adjustment', (
    tester,
  ) async {
    final repository = _FakeSportWaitlistRepository()
      ..adjustmentCompleter = Completer<SportWaitlist>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sportWaitlistRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AdminWaitlistPage()),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('waitlist-increment-bruno'));
    await tester.tap(button);
    await tester.tap(button);
    expect(repository.requestIds, hasLength(1));
    repository.adjustmentCompleter!.complete(repository._waitlist);
    await tester.pumpAndSettle();
  });

  testWidgets('an explicit refusal keeps counts and permits a fresh gesture', (
    tester,
  ) async {
    final repository = _FakeSportWaitlistRepository()..rejectAdjustment = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sportWaitlistRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AdminWaitlistPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('waitlist-increment-bruno')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('waitlist-count-bruno')))
          .data,
      '1',
    );
    expect(find.textContaining('pas encore confirmée'), findsNothing);
    repository.rejectAdjustment = false;
    await tester.tap(find.byKey(const ValueKey('waitlist-increment-bruno')));
    await tester.pumpAndSettle();
    expect(repository.requestIds.toSet(), hasLength(2));
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('waitlist-count-bruno')))
          .data,
      '2',
    );
  });

  testWidgets('a refusal after a lost response keeps the original gesture',
      (tester) async {
    final repository = _FakeSportWaitlistRepository()
      ..loseFirstAcknowledgement = true;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sportWaitlistRepositoryProvider.overrideWithValue(repository)
      ],
      child: const MaterialApp(home: AdminWaitlistPage()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('waitlist-increment-bruno')));
    await tester.pumpAndSettle();
    repository.rejectAdjustment = true;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('reste à confirmer'), findsOneWidget);
    repository.rejectAdjustment = false;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(repository.requestIds, hasLength(3));
    expect(repository.requestIds.toSet(), hasLength(1));
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('waitlist-count-bruno')))
            .data,
        '2');
  });

  testWidgets('read-only members have no count adjustment controls', (
    tester,
  ) async {
    final repository = _FakeSportWaitlistRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sportWaitlistRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AdminWaitlistPage(editable: false)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('waitlist-increment-bruno')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('waitlist-decrement-bruno')),
      findsNothing,
    );
    expect(repository.requestIds, isEmpty);
  });
}

class _FakeSportWaitlistRepository implements SportWaitlistRepository {
  String? lastManualCountSeasonPlayerId;
  int? lastManualCount;
  int? lastDelta;
  bool loseFirstAcknowledgement = false;
  bool rejectAdjustment = false;
  Completer<SportWaitlist>? adjustmentCompleter;
  final List<String> requestIds = [];
  final Set<String> _processedRequests = {};
  SportWaitlist? _currentWaitlist;

  SportWaitlist get _waitlist =>
      _currentWaitlist ??
      const SportWaitlist(
        seasonId: 'season',
        seasonName: '2026-2027',
        entries: [
          SportWaitlistEntry(
            seasonPlayerId: 'alice',
            firstName: 'Alice',
            lastName: 'Grinta',
            position: 1,
            previousSeasonAttendanceCount: 2,
            previousSeasonMatchCount: 10,
            currentSeasonWaitlistCount: 3,
            source: 'previous_season_attendance',
          ),
          SportWaitlistEntry(
            seasonPlayerId: 'bruno',
            firstName: 'Bruno',
            lastName: 'Grinta',
            position: 2,
            previousSeasonAttendanceCount: 4,
            previousSeasonMatchCount: 10,
            currentSeasonWaitlistCount: 1,
            source: 'previous_season_attendance',
          ),
        ],
      );

  @override
  Future<SportWaitlist> fetchWaitlist({String? seasonId}) async => _waitlist;

  @override
  Future<SportWaitlist> fetchWaitlistReadOnly({String? seasonId}) async =>
      _waitlist;

  @override
  Future<void> setWaitlistManualCount({
    required String seasonPlayerId,
    required int count,
  }) async {
    lastManualCountSeasonPlayerId = seasonPlayerId;
    lastManualCount = count;
  }

  @override
  Future<SportWaitlist> adjustWaitlistManualCount({
    required String seasonPlayerId,
    required int delta,
    required String requestId,
  }) async {
    lastManualCountSeasonPlayerId = seasonPlayerId;
    lastDelta = delta;
    requestIds.add(requestId);
    if (rejectAdjustment) {
      throw const PostgrestException(
        message: 'Refus du serveur',
        code: '42501',
      );
    }
    if (adjustmentCompleter != null) return adjustmentCompleter!.future;
    if (_processedRequests.add(requestId)) {
      final current = _waitlist;
      final entries = [
        for (final entry in current.entries)
          if (entry.seasonPlayerId == seasonPlayerId)
            entry.copyWith(
              currentSeasonWaitlistCount:
                  entry.currentSeasonWaitlistCount + delta,
            )
          else
            entry,
      ]..sort(
          (a, b) => a.currentSeasonWaitlistCount.compareTo(
            b.currentSeasonWaitlistCount,
          ),
        );
      _currentWaitlist = SportWaitlist(
        seasonId: current.seasonId,
        seasonName: current.seasonName,
        entries: entries,
      );
    }
    if (loseFirstAcknowledgement && requestIds.length == 1) {
      throw TimeoutException('Accusé perdu après écriture');
    }
    return _waitlist;
  }

  @override
  Future<List<AdminSportMatch>> fetchUpcomingMatches() async => const [];

  @override
  Future<MatchConvocations> fetchMatchConvocations(String matchId) {
    throw UnimplementedError();
  }

  @override
  Future<AvailabilityReminderSummary> fetchReminderSummary(String matchId) {
    throw UnimplementedError();
  }

  @override
  Future<AvailabilityReminderResult> sendAvailabilityReminder({
    required String matchId,
    String? seasonPlayerId,
    String? reason,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<MatchConvocations> publishEffectif({
    required String matchId,
    required int squadSizeLimit,
    required Map<String, ConvocationStatus> decisions,
    Set<String> changedPlayerIds = const {},
    String? reason,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> overrideAvailability({
    required String matchId,
    required String seasonPlayerId,
    required String status,
    String? reason,
  }) {
    throw UnimplementedError();
  }
}
