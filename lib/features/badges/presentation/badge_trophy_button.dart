import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/widgets/pf_labeled_button.dart';
import 'package:petit_filet/features/badges/data/badge_inbox_repository.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BadgeTrophyButton extends ConsumerWidget {
  const BadgeTrophyButton({this.showLabel = false, super.key});

  /// Écrit « Badges » sous l'icône.
  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Le club peut avoir désactivé les badges : le bouton disparaît alors.
    if (!ref.watch(clubModuleEnabledProvider(ClubModule.badges))) {
      return const SizedBox.shrink();
    }
    final hasUnseen = ref.watch(hasUnseenBadgeProvider).valueOrNull ?? false;

    Future<void> open() async {
      try {
        await ref.read(badgeInboxRepositoryProvider).markSeen();
        ref.invalidate(hasUnseenBadgeProvider);
      } catch (_) {
        // L'armoire reste accessible même si l'acquittement échoue.
      }
      if (context.mounted) context.push('/armoire');
    }

    final iconWidget = SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 26,
            color: AppTheme.reward,
          ),
          const ExcludeSemantics(
            child: Opacity(opacity: 0, child: Text('🏆')),
          ),
          if (hasUnseen)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                key: const ValueKey('badge-unseen-indicator'),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.background, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: .28),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    final button = IconButton(
      tooltip: 'Armoire à badges',
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      style: IconButton.styleFrom(
        foregroundColor: AppTheme.reward,
        backgroundColor: AppTheme.reward.withValues(alpha: .08),
        side: BorderSide(color: AppTheme.reward.withValues(alpha: .18)),
      ),
      icon: iconWidget,
      onPressed: open,
    );
    return showLabel
        ? PfLabeledButton(
            label: 'Badges',
            color: AppTheme.reward,
            icon: iconWidget,
            onTap: open,
          )
        : button;
  }
}
