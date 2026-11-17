import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Création d'un événement depuis le Calendrier, réservée aux administrateurs.
/// L'abonnement personnel aux matchs se trouve dans Paramètres.
class CalendarActionsBar extends StatelessWidget {
  const CalendarActionsBar({super.key, required this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    if (onCreate == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
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
    );
  }
}
