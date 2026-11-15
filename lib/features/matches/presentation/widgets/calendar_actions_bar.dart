import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Actions du calendrier réunies dans un même bandeau, sans icônes isolées.
/// La création est réservée aux admins par le parent ; l'abonnement reste
/// accessible à tous les membres lorsque la saison courante existe.
class CalendarActionsBar extends StatelessWidget {
  const CalendarActionsBar({
    super.key,
    required this.onCreate,
    required this.onExport,
  });

  final VoidCallback? onCreate;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    if (onCreate == null && onExport == null) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outline.withValues(alpha: .42),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            if (onCreate != null)
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('calendar-new-event-action'),
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'Nouvel événement',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (onCreate != null && onExport != null) const SizedBox(width: 8),
            if (onExport != null)
              if (onCreate != null)
                IconButton.outlined(
                  key: const ValueKey('calendar-subscribe-action'),
                  onPressed: onExport,
                  tooltip: 'S’abonner au calendrier',
                  icon: const Icon(Icons.calendar_month_outlined),
                  iconSize: 22,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(
                      color: AppTheme.outline.withValues(alpha: .65),
                    ),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('calendar-subscribe-action'),
                    onPressed: onExport,
                    icon: const Icon(Icons.calendar_month_outlined, size: 20),
                    label: const Text('S’abonner au calendrier'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
