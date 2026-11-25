import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/features/notifications/data/notification_inbox_repository.dart';
import 'package:petit_filet/features/preferences/data/push_subscriptions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Cloche de l'en-tête, à côté du trophée : ouvre l'historique des
/// notifications. Un petit chiffre indique combien n'ont pas été lues.
class NotificationInboxButton extends ConsumerWidget {
  const NotificationInboxButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;
    // Le bandeau d'avertissement ne s'affiche que sur le Calendrier : ailleurs,
    // un point sur la cloche dit que cet appareil ne reçoit pas les
    // notifications.
    final deviceAlert = ref.watch(pushDeviceAlertProvider).valueOrNull;
    final deviceIsSilent =
        deviceAlert != null && deviceAlert != PushDeviceAlert.none;
    final label = unread > 0
        ? 'Notifications, $unread non ${unread > 1 ? 'lues' : 'lue'}'
        : deviceIsSilent
            ? 'Notifications, désactivées sur cet appareil'
            : 'Notifications';

    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      child: IconButton(
        key: const ValueKey('notification-inbox-button'),
        tooltip: 'Notifications',
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        style: IconButton.styleFrom(
          foregroundColor: AppTheme.primaryBright,
          backgroundColor: AppTheme.primaryBright.withValues(alpha: .08),
          side: BorderSide(
            color: AppTheme.primaryBright.withValues(alpha: .18),
          ),
        ),
        icon: SizedBox(
          width: 30,
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 26,
                color: AppTheme.primaryBright,
              ),
              if (unread > 0)
                Positioned(
                  top: -6,
                  right: -7,
                  child: _UnreadPill(count: unread),
                )
              else if (deviceIsSilent)
                const Positioned(
                  top: -3,
                  right: -3,
                  child: _SilentDeviceDot(),
                ),
            ],
          ),
        ),
        onPressed: () => context.push('/notifications'),
      ),
    );
  }
}

/// Point d'avertissement : cet appareil ne recevra pas les notifications.
class _SilentDeviceDot extends StatelessWidget {
  const _SilentDeviceDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('notification-device-silent-dot'),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: AppTheme.warning,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.background, width: 2),
      ),
    );
  }
}

class _UnreadPill extends StatelessWidget {
  const _UnreadPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('notification-unread-pill'),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Texte sombre sur rouge : le blanc y serait trop peu lisible.
        color: AppTheme.error,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.background, width: 2),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        // La pastille garde sa taille quel que soit le réglage de texte.
        textScaler: TextScaler.noScaling,
        style: const TextStyle(
          color: AppTheme.background,
          fontSize: 11,
          height: 1.1,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
