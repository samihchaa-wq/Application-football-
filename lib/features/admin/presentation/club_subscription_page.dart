import 'package:petit_filet/core/widgets/pf_app_bar.dart';
import 'package:petit_filet/features/admin/presentation/club_subscription_section.dart';
import 'package:petit_filet/features/billing/presentation/club_invoices_list.dart';
import 'package:flutter/material.dart';

/// Abonnement du club, ouvert depuis Paramètres : essai ou forfait, espace
/// photos, parrainage et factures. Réservé aux administrateurs (route
/// `/admin/...`).
class ClubSubscriptionPage extends StatelessWidget {
  const ClubSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PfAppBar(title: const Text('Abonnement')),
      body: ListView(
        key: const Key('club-subscription-page'),
        padding: const EdgeInsets.all(16),
        children: const [
          ClubSubscriptionSection(),
          SizedBox(height: 20),
          ClubInvoicesList(),
        ],
      ),
    );
  }
}
