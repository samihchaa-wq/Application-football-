import 'package:petit_filet/features/notifications/data/notification_inbox_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Types de notification annoncés par chaque onglet de la fiche d'un match.
/// Arriver sur l'onglet, par la notification ou par un autre chemin, les
/// marque lues.
List<String> notificationKindsForMatchSection(String section) =>
    switch (section) {
      'info' => const [
          'match_rescheduled_time',
          'match_address_changed',
          'match_jersey_changed',
          'match_meeting_changed',
          'match_location_changed',
        ],
      'composition' => const ['composition_published'],
      'effectif' => const ['convocation_promoted', 'convocation_demoted'],
      'live' => const [
          'live_kickoff',
          'live_goal_us',
          'live_goal_them',
          'live_full_time',
        ],
      'prediction' => const ['prediction_j5'],
      _ => const [],
    };

/// Marque lues les notifications que cet écran annonce dès qu'il est affiché
/// (et de nouveau si les types ou le match changent). Le chiffre de la cloche
/// et la pastille de l'icône se recalculent ensuite. Ne montre rien : l'écran
/// s'affiche tel quel, et un échec réseau est ignoré (la prochaine visite
/// réessaiera).
class NotificationSeenMarker extends ConsumerStatefulWidget {
  const NotificationSeenMarker({
    super.key,
    required this.kinds,
    required this.child,
    this.matchId,
  });

  final List<String> kinds;
  final String? matchId;
  final Widget child;

  @override
  ConsumerState<NotificationSeenMarker> createState() =>
      _NotificationSeenMarkerState();
}

class _NotificationSeenMarkerState
    extends ConsumerState<NotificationSeenMarker> {
  @override
  void initState() {
    super.initState();
    _mark();
  }

  @override
  void didUpdateWidget(NotificationSeenMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId != widget.matchId ||
        oldWidget.kinds.join(',') != widget.kinds.join(',')) {
      _mark();
    }
  }

  void _mark() {
    if (widget.kinds.isEmpty) return;
    final kinds = widget.kinds;
    final matchId = widget.matchId;
    Future<void>(() async {
      try {
        if (!mounted) return;
        final marked = await ref
            .read(notificationInboxRepositoryProvider)
            .markReadFor(kinds, matchId: matchId);
        if (marked > 0 && mounted) {
          ref.invalidate(unreadNotificationCountProvider);
        }
      } catch (_) {
        // Au mieux : la notification restera non lue jusqu'à la prochaine
        // ouverture de l'historique.
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
