import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:petit_filet/features/billing/presentation/platform_invoices_section.dart';
import 'package:petit_filet/features/club/data/club_subscription.dart';
import 'package:petit_filet/features/platform/data/platform_billing_repository.dart';
import 'package:petit_filet/features/platform/domain/platform_billing.dart';
import 'package:petit_filet/features/platform/domain/platform_cash.dart';
import 'package:petit_filet/features/platform/presentation/platform_billing_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Réglages du Gestionnaire : offre commerciale, coordonnées sur les
/// factures, état de Stripe. La supervision technique suit (page).
class PlatformSettingsSection extends StatelessWidget {
  const PlatformSettingsSection({super.key, this.supervision});

  /// Bloc de supervision technique, fourni par la page.
  final Widget? supervision;

  @override
  Widget build(BuildContext context) => Column(
        key: const Key('platform-settings'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _OfferCard(),
          const SizedBox(height: 16),
          const PlatformSellerCard(),
          const SizedBox(height: 16),
          const _StripeCard(),
          if (supervision != null) ...[
            const SizedBox(height: 24),
            supervision!,
          ],
        ],
      );
}

class _OfferCard extends ConsumerWidget {
  const _OfferCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(platformBillingSettingsProvider);
    return Card(
      key: const Key('platform-offer'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: settings.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cloud_off_outlined),
            title: const Text('Offre indisponible'),
            trailing: IconButton(
              tooltip: 'Réessayer',
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(platformBillingSettingsProvider),
            ),
          ),
          data: (value) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Offre', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                'Tarif des nouveaux clubs : ${formatEuros(value.basePriceCents)} '
                'par an\nParrainage : −${value.referralRatePercent} % par '
                'filleul payé, jusqu’à −${value.referralCapPercent} %\n'
                'Essai gratuit : ${value.trialDays} jours',
                key: const Key('platform-offer-summary'),
              ),
              if (!value.matchesPublishedTerms) ...[
                const SizedBox(height: 8),
                const Text(
                  'Différent des conditions d’abonnement publiées (79 €, '
                  '−5 % jusqu’à −100 %, 30 jours) : mets-les à jour avant '
                  'de proposer cette offre.',
                  key: Key('platform-offer-terms-warning'),
                  style: TextStyle(color: AppTheme.warning),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Les clubs existants gardent leur tarif (modifiable dans leur '
                'fiche). Le parrainage s’applique à tous.',
                style: TextStyle(fontSize: 12, color: AppTheme.textFaint),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('platform-offer-edit'),
                onPressed: () async {
                  final saved = await showDialog<bool>(
                    context: context,
                    builder: (_) => _OfferDialog(
                      initial: value,
                      repository: ref.read(platformBillingRepositoryProvider),
                    ),
                  );
                  if (saved == true) {
                    ref.invalidate(platformBillingSettingsProvider);
                  }
                },
                child: const Text('Modifier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferDialog extends StatefulWidget {
  const _OfferDialog({required this.initial, required this.repository});

  final PlatformBillingSettings initial;
  final PlatformBillingRepository repository;

  @override
  State<_OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends State<_OfferDialog> {
  late final _price =
      TextEditingController(text: centsToInput(widget.initial.basePriceCents));
  late final _rate =
      TextEditingController(text: '${widget.initial.referralRatePercent}');
  late final _cap =
      TextEditingController(text: '${widget.initial.referralCapPercent}');
  late final _trial =
      TextEditingController(text: '${widget.initial.trialDays}');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_price, _rate, _cap, _trial]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final price = parseEurosToCents(_price.text);
    final rate = int.tryParse(_rate.text.trim());
    final cap = int.tryParse(_cap.text.trim());
    final trial = int.tryParse(_trial.text.trim());
    if (price == null ||
        rate == null ||
        cap == null ||
        trial == null ||
        rate < 1 ||
        cap > 100 ||
        rate > cap ||
        trial < 0 ||
        trial > 365) {
      setState(() => _error = 'Valeurs invalides : parrainage entre 1 et '
          '100 %, plafond au moins égal, essai de 0 à 365 jours.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveSettings(
        basePriceCents: price,
        referralRatePercent: rate,
        referralCapPercent: cap,
        trialDays: trial,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = humanizeError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Offre'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('platform-offer-price'),
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Tarif annuel des nouveaux clubs',
                    suffixText: '€',
                  ),
                ),
                TextField(
                  key: const Key('platform-offer-rate'),
                  controller: _rate,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Réduction par filleul payé',
                    suffixText: '%',
                  ),
                ),
                TextField(
                  key: const Key('platform-offer-cap'),
                  controller: _cap,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Réduction maximale',
                    suffixText: '%',
                  ),
                ),
                TextField(
                  key: const Key('platform-offer-trial'),
                  controller: _trial,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Durée de l’essai gratuit',
                    suffixText: 'jours',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pense à mettre à jour les conditions d’abonnement si tu '
                  'changes l’offre.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textFaint),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const Key('platform-offer-save'),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
          ),
        ],
      );
}

class _StripeCard extends ConsumerWidget {
  const _StripeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(platformAlertsProvider);
    final stripe = alerts.valueOrNull?.stripe;
    return Card(
      key: const Key('platform-stripe'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stripe (paiement par carte)',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            if (alerts.isLoading && stripe == null)
              const LinearProgressIndicator()
            else if (stripe == null)
              const Text('État indisponible. Réessaie dans un instant.')
            else ...[
              Text(
                stripe.lastEventAt == null
                    ? 'Aucune confirmation reçue de Stripe pour l’instant.'
                    : 'Dernière confirmation le ${platformDay(stripe.lastEventAt)} '
                        '· mode ${stripe.lastLivemode == true ? 'réel' : 'test'}\n'
                        '${stripe.events7d} confirmation(s) cette semaine, '
                        '${stripe.failures7d} en échec',
                key: const Key('platform-stripe-status'),
              ),
              if (stripe.lastFailureError != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Dernier échec (${stripe.lastFailureType}) : '
                  '${stripe.lastFailureError}',
                  style: const TextStyle(color: AppTheme.warning),
                ),
              ],
            ],
            const SizedBox(height: 8),
            const Text(
              'Stripe prévient aussi par e-mail en cas de contestation ou '
              'd’échec de livraison. Clés et point de terminaison : voir '
              'docs/STRIPE.md.',
              style: TextStyle(fontSize: 12, color: AppTheme.textFaint),
            ),
          ],
        ),
      ),
    );
  }
}
