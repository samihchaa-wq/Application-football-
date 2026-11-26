import 'package:petit_filet/core/theme/app_spacing.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Barre de sous-onglets uniforme utilisée dans le module Stats.
///
/// Centralise les dimensions, les espacements et la typographie afin que les
/// sous-familles de Prono, Joueur et Équipe restent parfaitement alignées.
class PfSecondaryTabs<T> extends StatelessWidget {
  const PfSecondaryTabs({
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    super.key,
  });

  // 44 px : taille minimale conseillée pour un doigt (36 px faisait rater
  // des appuis). Reste plus bas que les onglets principaux.
  static const double height = 44;

  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        2,
        AppSpacing.screenGutter,
        AppSpacing.sectionGap,
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.contentGap),
            Expanded(
                child: _Pill(
              segment: segments[i],
              isSelected: selected.contains(segments[i].value),
              onTap: () => onSelectionChanged({segments[i].value}),
            )),
          ],
        ],
      ),
    );
  }
}

/// Une bulle (forme arrondie) : même style que les boutons du reste de l'appli.
class _Pill<T> extends StatelessWidget {
  const _Pill({
    required this.segment,
    required this.isSelected,
    required this.onTap,
  });

  final ButtonSegment<T> segment;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.primaryBright : AppTheme.textPrimary;
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? AppTheme.selectedSurface : AppTheme.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: .55)
                : AppTheme.outline.withValues(alpha: .28),
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: PfSecondaryTabs.height,
            child: Center(
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: 14,
                  height: 1,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
                child: segment.label ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
