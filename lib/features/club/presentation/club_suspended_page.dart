import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/widgets/pf_app_bar.dart';
import 'package:petit_filet/core/widgets/support_contact.dart';
import 'package:petit_filet/features/admin/presentation/card_payment_button.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/club/data/club_subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Affiché à la place de l'appli quand l'éditeur a suspendu le club (par
/// exemple abonnement non réglé). Les données du club ne sont pas effacées.
class ClubSuspendedPage extends ConsumerWidget {
  const ClubSuspendedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAdmin = ref.watch(isRealAdminProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PfAppBar(title: const Text('Accès suspendu')),
      body: SafeArea(
        child: Center(
          // Défilable : avec le bouton de paiement, la page dépasse la
          // hauteur d'un petit téléphone.
          child: SingleChildScrollView(
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
                    const SizedBox(height: 20),
                    if (isAdmin) ...[
                      // Le paiement rouvre le club tout de suite.
                      const CardPaymentButton(),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        key: const Key('club-suspended-refresh'),
                        onPressed: () => ref.invalidate(myClubAccessProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('J’ai payé : actualiser'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      isAdmin
                          ? 'Tu préfères un virement ou un chèque ? Écris-nous : '
                              'l’accès revient dès le paiement noté.'
                          : 'Administrateur du club : écris-nous pour régler '
                              'l’abonnement, l’accès revient dès le paiement '
                              'noté.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const SupportContact(
                      subject: 'Club suspendu : régler l’abonnement',
                      center: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
