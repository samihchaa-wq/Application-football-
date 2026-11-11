import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:as_grinta/core/widgets/grinta_app_bar.dart';
import 'package:flutter/material.dart';

/// Affiché à la place de l'appli quand l'éditeur a suspendu le club (par
/// exemple abonnement non réglé). Les données du club ne sont pas effacées.
class ClubSuspendedPage extends StatelessWidget {
  const ClubSuspendedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: GrintaAppBar(title: const Text('Accès suspendu')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pause_circle_outline, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'L’accès de ton club est suspendu',
                    key: const Key('club-suspended-title'),
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Les données du club sont conservées. L’accès reviendra '
                    'dès que l’administrateur de ton club aura régularisé '
                    'l’abonnement.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
