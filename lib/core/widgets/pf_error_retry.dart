import 'package:flutter/material.dart';
import 'package:petit_filet/core/widgets/pf_empty_state.dart';

/// Erreur de chargement avec bouton « Réessayer ».
///
/// À utiliser quand une lecture échoue : sans issue, la personne ne peut
/// qu'attendre ou quitter l'écran. [onRetry] relance la lecture.
class PfErrorRetry extends StatelessWidget {
  const PfErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Chargement impossible',
    this.compact = false,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return PfEmptyState(
      icon: Icons.error_outlined,
      title: title,
      message: message,
      compact: compact,
      tone: PfEmptyTone.alert,
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_outlined),
        label: const Text('Réessayer'),
      ),
    );
  }
}
