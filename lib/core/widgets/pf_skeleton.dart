import 'package:flutter/material.dart';

/// Ancien composant d'aperçu de chargement.
///
/// Conservé uniquement pour compatibilité avec les appels existants. Aucun
/// squelette ni animation n'est rendu : après le démarrage de l'application,
/// aucun loader visuel ne doit apparaître.
class PfSkeleton extends StatelessWidget {
  const PfSkeleton({super.key, required this.child});

  const PfSkeleton.list({
    super.key,
    int itemCount = 4,
    double itemHeight = 96,
    double spacing = 12,
  }) : child = const SizedBox.shrink();

  const PfSkeleton.rows({super.key, int itemCount = 6})
      : child = const SizedBox.shrink();

  final Widget child;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
