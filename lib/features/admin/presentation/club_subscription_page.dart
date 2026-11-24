import 'dart:async';

import 'package:petit_filet/core/widgets/pf_app_bar.dart';
import 'package:petit_filet/features/admin/presentation/club_subscription_section.dart';
import 'package:petit_filet/features/billing/data/invoice_repository.dart';
import 'package:petit_filet/features/billing/presentation/club_invoices_list.dart';
import 'package:petit_filet/features/club/data/club_subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Retour de la page de paiement Stripe (`?paiement=merci` ou `annule`).
enum PaymentReturn { none, paid, canceled }

PaymentReturn paymentReturnFrom(String? value) => switch (value) {
      'merci' => PaymentReturn.paid,
      'annule' => PaymentReturn.canceled,
      _ => PaymentReturn.none,
    };

/// Abonnement du club, ouvert depuis Paramètres : essai ou forfait, paiement
/// par carte, espace photos, parrainage et factures. Réservé aux
/// administrateurs (route `/admin/...`).
class ClubSubscriptionPage extends ConsumerStatefulWidget {
  const ClubSubscriptionPage({
    super.key,
    this.paymentReturn = PaymentReturn.none,
  });

  final PaymentReturn paymentReturn;

  @override
  ConsumerState<ClubSubscriptionPage> createState() =>
      _ClubSubscriptionPageState();
}

class _ClubSubscriptionPageState extends ConsumerState<ClubSubscriptionPage> {
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    // La confirmation de Stripe arrive au serveur quelques secondes après le
    // retour : on relit l'abonnement un peu plus tard.
    if (widget.paymentReturn == PaymentReturn.paid) {
      _refresh = Timer(const Duration(seconds: 4), _reload);
    }
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    ref.invalidate(clubSubscriptionProvider);
    ref.invalidate(clubReferralsProvider);
    ref.invalidate(clubInvoicesProvider);
    ref.invalidate(myClubAccessProvider);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final banner = switch (widget.paymentReturn) {
      PaymentReturn.paid =>
        'Merci ! Paiement reçu par Stripe. L’abonnement se met à jour dans '
            'quelques instants.',
      PaymentReturn.canceled => 'Paiement annulé : rien n’a été débité.',
      PaymentReturn.none => null,
    };
    return Scaffold(
      appBar: PfAppBar(title: const Text('Abonnement')),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          key: const Key('club-subscription-page'),
          padding: const EdgeInsets.all(16),
          children: [
            if (banner != null) ...[
              Card(
                key: const Key('club-payment-return'),
                margin: EdgeInsets.zero,
                color: scheme.secondaryContainer,
                child: ListTile(
                  leading: Icon(
                    widget.paymentReturn == PaymentReturn.paid
                        ? Icons.check_circle_outlined
                        : Icons.info_outlined,
                    color: scheme.onSecondaryContainer,
                  ),
                  title: Text(
                    banner,
                    style: TextStyle(color: scheme.onSecondaryContainer),
                  ),
                  trailing: widget.paymentReturn == PaymentReturn.paid
                      ? IconButton(
                          tooltip: 'Actualiser',
                          icon: const Icon(Icons.refresh_outlined),
                          color: scheme.onSecondaryContainer,
                          onPressed: _reload,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const ClubSubscriptionSection(),
            const SizedBox(height: 20),
            const ClubInvoicesList(),
          ],
        ),
      ),
    );
  }
}
