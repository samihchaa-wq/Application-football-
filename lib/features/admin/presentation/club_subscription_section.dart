import 'package:as_grinta/features/club/data/club_subscription.dart';
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
          'Pour continuer après l’essai, contacte-nous pour activer '
              'l’abonnement du club.',
        ClubSubscriptionState.toPay =>
          'Ton club garde l’accès pour l’instant. Contacte-nous pour activer '
              'l’abonnement.',
        ClubSubscriptionState.pastDue =>
          'Le dernier paiement n’a pas abouti. Contacte-nous pour le '
              'régulariser.',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final advice = _advice;
    final players = subscription.billablePlayers;
    final price = formatEuros(subscription.pricePerPlayerCents);
    final base = subscription.basePriceCents;

    return Card(
      key: const Key('club-subscription-card'),
      margin: EdgeInsets.zero,
      color: subscription.state.needsAttention
          ? theme.colorScheme.errorContainer
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_headline, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              '$players joueur${players > 1 ? 's' : ''} dans l’effectif de la '
              'saison × $price par an'
              '${base > 0 ? ' + forfait de ${formatEuros(base)}' : ''}',
            ),
            const SizedBox(height: 4),
            Text(
              'Total annuel : ${formatEuros(subscription.yearlyAmountCents)}',
              key: const Key('club-subscription-total'),
              style: theme.textTheme.titleMedium,
            ),
            if (advice != null) ...[
              const SizedBox(height: 8),
              Text(advice),
            ],
          ],
        ),
      ),
    );
  }
}
