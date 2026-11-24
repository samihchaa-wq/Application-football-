import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum PfStatusTone { info, success, warning, error }

class PfStatusBanner extends StatelessWidget {
  const PfStatusBanner({
    super.key,
    required this.message,
    this.title,
    this.tone = PfStatusTone.info,
    this.action,
    this.compact = false,
  });

  final String? title;
  final String message;
  final PfStatusTone tone;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (accent, icon) = switch (tone) {
      PfStatusTone.info => (
          AppTheme.info,
          Icons.info_outline_rounded,
        ),
      PfStatusTone.success => (
          AppTheme.success,
          Icons.check_circle_outline_rounded,
        ),
      PfStatusTone.warning => (
          AppTheme.warning,
          Icons.warning_amber_rounded,
        ),
      PfStatusTone.error => (
          theme.colorScheme.error,
          Icons.error_outline_rounded,
        ),
    };

    return Semantics(
      container: true,
      liveRegion: tone == PfStatusTone.error,
      label: [if (title != null) title!, message].join('. '),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            accent.withValues(alpha: .06),
            AppTheme.surface,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: Colors.white.withValues(alpha: .09)),
          boxShadow: AppTheme.cardShadows,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Liseré de couleur : le ton du message se lit avant le texte.
                ColoredBox(color: accent, child: const SizedBox(width: 4)),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 14,
                      vertical: compact ? 10 : 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: compact ? 20 : 22, color: accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title case final value?
                                  when value.trim().isNotEmpty) ...[
                                Text(
                                  value,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                message,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              if (action != null) ...[
                                const SizedBox(height: 2),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: action!,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
