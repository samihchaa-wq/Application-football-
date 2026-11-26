import 'package:flutter/material.dart';
import 'package:petit_filet/core/theme/app_theme.dart';

/// Bouton d'en-tête avec son nom écrit à sa droite (le nom est aussi cliquable).
class PfLabeledButton extends StatelessWidget {
  const PfLabeledButton({
    required this.label,
    required this.child,
    required this.onTap,
    super.key,
  });

  final VoidCallback onTap;

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.only(left: 2, right: 3),
              child: Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
