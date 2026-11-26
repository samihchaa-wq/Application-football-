import 'package:petit_filet/features/notifications/data/notification_inbox_repository.dart';
import 'package:petit_filet/features/notifications/presentation/notification_seen_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Inbox implements NotificationInboxRepository {
  final List<(List<String>, String?)> marked = [];

  @override
  Future<List<NotificationHistoryEntry>> fetchHistory() async => const [];
  @override
  Future<int> unreadCount() async => 0;
  @override
  Future<int> markAllRead() async => 0;
  @override
  Future<void> delete(int id) async {}
  @override
  Future<int> deleteAll() async => 0;
  @override
  Future<int> markReadFor(List<String> kinds, {String? matchId}) async {
    marked.add((kinds, matchId));
    return 1;
  }
}

void main() {
  test('chaque onglet de la fiche annonce ses propres types', () {
    expect(
      notificationKindsForMatchSection('info'),
      containsAll([
        'match_rescheduled_time',
        'match_address_changed',
        'match_jersey_changed',
        'match_meeting_changed',
        'match_location_changed',
      ]),
    );
    expect(
      notificationKindsForMatchSection('composition'),
      ['composition_published'],
    );
    expect(
      notificationKindsForMatchSection('effectif'),
      ['convocation_promoted', 'convocation_demoted'],
    );
    expect(notificationKindsForMatchSection('prediction'), ['prediction_j5']);
    expect(notificationKindsForMatchSection('inconnu'), isEmpty);
  });

  testWidgets('arriver sur l’écran marque ses notifications lues', (
    tester,
  ) async {
    final inbox = _Inbox();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationInboxRepositoryProvider.overrideWithValue(inbox)
        ],
        child: const MaterialApp(
          home: NotificationSeenMarker(
            matchId: 'm1',
            kinds: ['composition_published'],
            child: Text('écran'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('écran'), findsOneWidget);
    expect(inbox.marked, hasLength(1));
    expect(inbox.marked.single.$1, ['composition_published']);
    expect(inbox.marked.single.$2, 'm1');
  });

  testWidgets('sans type, rien n’est demandé au serveur', (tester) async {
    final inbox = _Inbox();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationInboxRepositoryProvider.overrideWithValue(inbox)
        ],
        child: const MaterialApp(
          home: NotificationSeenMarker(kinds: [], child: Text('écran')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(inbox.marked, isEmpty);
  });
}
