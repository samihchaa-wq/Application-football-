import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:petit_filet/features/club/data/club_subscription.dart';
import 'package:petit_filet/features/platform/data/platform_billing_repository.dart';
import 'package:petit_filet/features/platform/domain/platform_cash.dart';
import 'package:petit_filet/features/platform/presentation/platform_billing_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Haut de « À faire » : alertes de paiement, paiements par carte reçus,
/// factures et avoirs en attente, confirmations Stripe en échec.
class PlatformAlertsPanel extends ConsumerWidget {
  const PlatformAlertsPanel({
    super.key,
    this.onOpenCash,
    this.onOpenSettings,
    this.onOpenClub,
  });

  final VoidCallback? onOpenCash;
  final VoidCallback? onOpenSettings;
  final void Function(String clubId)? onOpenClub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(platformAlertsProvider);
    return Card(
      key: const Key('platform-alerts'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Paiements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
              ),
            ),
            ...alerts.when(
              loading: () => const [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
              ],
              error: (_, __) => [
                ListTile(
                  leading: const Icon(Icons.cloud_off_outlined),
                  title: const Text('Suivi des paiements indisponible'),
                  trailing: IconButton(
                    tooltip: 'Réessayer',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => ref.invalidate(platformAlertsProvider),
                  ),
                ),
              ],
              data: (value) => _content(context, ref, value),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    WidgetRef ref,
    PlatformAlerts value,
  ) {
    final stripe = value.stripe;
    final nothing = value.alerts.isEmpty &&
        value.cardPayments7d.isEmpty &&
        value.pendingInvoices == 0 &&
        value.pendingCreditNotes == 0 &&
        stripe.failures7d == 0;
    return [
      for (final alert in value.alerts)
        ListTile(
          key: ValueKey('platform-alert-${alert.id}'),
          leading: const Icon(Icons.report_outlined, color: AppTheme.error),
          title: Text(
            '${alert.title}'
            '${alert.clubName == null ? '' : ' · ${alert.clubName}'}',
          ),
          subtitle: Text(
            '${alert.message}'
            '${alert.amountCents == null ? '' : ' Montant : ${formatEuros(alert.amountCents!)}.'}'
            '\nÀ traiter dans le tableau de bord Stripe, puis marque-la comme traitée.',
          ),
          isThreeLine: true,
          trailing: TextButton(
            key: ValueKey('platform-alert-resolve-${alert.id}'),
            onPressed: () => _resolve(context, ref, alert),
            child: const Text('Traitée'),
          ),
        ),
      if (stripe.failures7d > 0)
        ListTile(
          key: const Key('platform-stripe-failures'),
          leading:
              const Icon(Icons.sync_problem_outlined, color: AppTheme.warning),
          title: Text(
            '${stripe.failures7d} confirmation(s) Stripe en échec cette semaine',
          ),
          subtitle: Text(
            stripe.lastFailureError ?? 'Voir Réglages › Stripe.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenSettings,
        ),
      if (value.cardPayments7d.isNotEmpty) ...[
        ListTile(
          leading:
              const Icon(Icons.credit_card_outlined, color: AppTheme.success),
          title: Text(
            '${value.cardPayments7d.length} paiement(s) par carte cette semaine',
          ),
          subtitle: Text(
            '${formatEuros(value.cardPayments7d.fold(0, (sum, payment) => sum + payment.amountCents))} '
            'encaissés automatiquement',
          ),
        ),
        for (final payment in value.cardPayments7d.take(5))
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 72, right: 16),
            title: Text(payment.clubName),
            subtitle: Text('Le ${platformDay(payment.createdAt)}'),
            trailing: Text(formatEuros(payment.amountCents)),
            onTap: payment.clubId == null || onOpenClub == null
                ? null
                : () => onOpenClub!(payment.clubId!),
          ),
      ],
      if (value.pendingInvoices > 0 || value.pendingCreditNotes > 0)
        ListTile(
          key: const Key('platform-pending-documents'),
          leading: const Icon(Icons.pending_actions_outlined,
              color: AppTheme.warning),
          title: Text(
            [
              if (value.pendingInvoices > 0)
                '${value.pendingInvoices} facture(s) en attente',
              if (value.pendingCreditNotes > 0)
                '${value.pendingCreditNotes} avoir(s) en attente',
            ].join(' · '),
          ),
          subtitle: const Text(
            'Il manque ton SIRET ou l’adresse d’un club : voir Caisse.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenCash,
        ),
      if (nothing)
        const ListTile(
          leading: Icon(Icons.check_circle_outlined, color: AppTheme.success),
          title: Text('Rien à traiter côté paiements'),
          subtitle: Text('Aucune alerte, aucun document en attente.'),
        ),
    ];
  }

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    PlatformAlert alert,
  ) async {
    // Une alerte marquée traitée disparaît de la liste : on confirme.
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Marquer cette alerte comme traitée ?'),
            content: const Text(
              'Elle disparaîtra de la liste. À faire une fois le problème '
              'réglé dans le tableau de bord Stripe.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                key: const Key('platform-alert-resolve-confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Traitée'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(platformBillingRepositoryProvider).resolveAlert(alert.id);
      ref.invalidate(platformAlertsProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Alerte marquée comme traitée.')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(humanizeError(error))));
    }
  }
}
