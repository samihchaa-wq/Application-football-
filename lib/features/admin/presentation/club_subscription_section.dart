import 'package:petit_filet/core/widgets/support_contact.dart';
import 'package:petit_filet/features/club/data/club_subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abonnement et espace de fichiers du club, dans ses réglages.
class ClubSubscriptionSection extends ConsumerWidget {
  const ClubSubscriptionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subscription = ref.watch(clubSubscriptionProvider);
    final storage = ref.watch(clubStorageUsageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Abonnement', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        subscription.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) =>
              const Text('Impossible de charger l’abonnement pour le moment.'),
          data: (value) => value == null
              ? const SizedBox.shrink()
              : _SubscriptionCard(subscription: value),
        ),
        const SizedBox(height: 20),
        Text('Espace photos', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        storage.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Espace indisponible pour le moment.'),
          data: (value) => value == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      key: const Key('club-storage-usage'),
                      value: value.ratio,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatBytes(value.usedBytes)} utilisés sur '
                      '${formatBytes(value.quotaBytes)}.',
                    ),
                    if (value.ratio >= 0.9)
                      const Text(
                        'L’espace est presque plein : les nouvelles photos '
                        'seront refusées une fois la limite atteinte.',
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription});

  final ClubSubscription subscription;

  String get _headline {
    final days = subscription.trialDaysLeft;
    return switch (subscription.state) {
      ClubSubscriptionState.trial ||
      ClubSubscriptionState.trialEnding =>
        days <= 1
            ? 'Essai gratuit : dernier jour'
            : 'Essai gratuit : encore $days jours',
      ClubSubscriptionState.toPay => 'Essai gratuit terminé',
      ClubSubscriptionState.active => 'Abonnement actif',
      ClubSubscriptionState.pastDue => 'Paiement en attente',
      ClubSubscriptionState.canceled => 'Abonnement arrêté',
    };
  }

  String? get _advice => switch (subscription.state) {
        ClubSubscriptionState.trialEnding =>
          'Pour continuer après l’essai, contacte-nous pour régler '
              'l’abonnement du club (virement ou chèque).',
        ClubSubscriptionState.toPay =>
          'Contacte-nous pour régler l’abonnement du club (virement ou '
              'chèque).',
        ClubSubscriptionState.pastDue =>
          'Un paiement reste à régulariser. Contacte-nous pour le régler.',
        ClubSubscriptionState.active when _renewalDue =>
          'L’abonnement arrive à échéance. Contacte-nous pour le renouveler.',
        _ => null,
      };

  bool get _renewalDue => subscription.renewalDueBy(DateTime.now());

  /// Rappel de la suspension automatique, seulement quand elle approche.
  String? get _suspensionWarning {
    final date = subscription.suspensionOn;
    if (date == null) return null;
    final attention = subscription.state.needsAttention || _renewalDue;
    if (!attention) return null;
    return 'Sans paiement, l’accès du club sera suspendu à partir du '
        '${_day(date)}. Les données sont conservées.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final advice = _advice;
    final warning = _suspensionWarning;
    final periodEnd = subscription.currentPeriodEnd;
    final players = subscription.billablePlayers;
    final perPlayer = subscription.pricePerPlayerCents;
    final base = subscription.basePriceCents;
    // Forfait seul (tarif standard) : le nombre de joueurs ne change rien.
    final pricing = perPlayer == 0
        ? 'Forfait club, quel que soit le nombre de joueurs'
        : '$players joueur${players > 1 ? 's' : ''} dans l’effectif de la '
            'saison × ${formatEuros(perPlayer)} par an'
            '${base > 0 ? ' + forfait de ${formatEuros(base)}' : ''}';

    final alert = subscription.state.needsAttention || _renewalDue;
    return Card(
      key: const Key('club-subscription-card'),
      margin: EdgeInsets.zero,
      color: alert ? theme.colorScheme.errorContainer : null,
      // Texte foncé sur le fond d'alerte : le texte clair par défaut y était
      // presque illisible.
      child: DefaultTextStyle.merge(
        style:
            alert ? TextStyle(color: theme.colorScheme.onErrorContainer) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _headline,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: alert ? theme.colorScheme.onErrorContainer : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(pricing),
              const SizedBox(height: 4),
              Text(
                'Total annuel : ${formatEuros(subscription.yearlyAmountCents)}',
                key: const Key('club-subscription-total'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: alert ? theme.colorScheme.onErrorContainer : null,
                ),
              ),
              if (subscription.state == ClubSubscriptionState.active &&
                  periodEnd != null) ...[
                const SizedBox(height: 4),
                Text('Payé jusqu’au ${_day(periodEnd)}'),
              ],
              if (advice != null) ...[
                const SizedBox(height: 8),
                Text(advice),
                const SizedBox(height: 4),
                const SupportContact(),
              ],
              if (warning != null) ...[
                const SizedBox(height: 8),
                Text(
                  warning,
                  key: const Key('club-subscription-suspension-warning'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _day(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}
