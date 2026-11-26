import 'package:flutter/material.dart';
import 'package:petit_filet/core/theme/app_theme.dart';

/// Bouton d'en-tête avec son nom écrit juste dessous.
class PfLabeledButton extends StatelessWidget {
  const PfLabeledButton({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        child,
        ExcludeSemantics(
          child: Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  height: 1.1,
                  color: AppTheme.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}
