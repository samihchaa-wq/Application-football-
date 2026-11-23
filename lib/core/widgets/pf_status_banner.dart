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
          AppTheme.primaryBright,
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
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 16,
          vertical: compact ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            accent.withValues(alpha: .08),
            AppTheme.surface,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: accent.withValues(alpha: .24)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 32 : 36,
              height: compact ? 32 : 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: compact ? 18 : 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title case final value? when value.trim().isNotEmpty) ...[
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
                    const SizedBox(height: 6),
                    Align(alignment: Alignment.centerRight, child: action!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
