import 'package:petit_filet/features/billing/data/invoice_repository.dart';
import 'package:petit_filet/features/billing/domain/invoice.dart';
import 'package:petit_filet/features/billing/presentation/invoice_download.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Factures du club, téléchargeables par ses administrateurs.
class ClubInvoicesList extends ConsumerWidget {
  const ClubInvoicesList({super.key, this.save = shareFile});

  final FileSaver save;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final invoices = ref.watch(clubInvoicesProvider);
    return Column(
      key: const Key('club-invoices'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Factures', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        invoices.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) =>
              const Text('Impossible de charger les factures pour le moment.'),
          data: (list) => list.isEmpty
              ? const Text(
                  'Aucune facture pour l’instant. Une facture est créée à '
                  'chaque paiement de l’abonnement.',
                )
              : Column(
                  children: [
                    for (final invoice in list)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(
                          '${invoice.number} · '
                          '${formatInvoiceAmount(invoice.amountCents)}',
                        ),
                        subtitle: Text(
                          'Du ${formatInvoiceDay(invoice.periodStart)} au '
                          '${formatInvoiceDay(invoice.periodEnd)}',
                        ),
                        trailing: IconButton(
                          key: ValueKey('club-invoice-download-${invoice.id}'),
                          tooltip: 'Télécharger la facture',
                          icon: const Icon(Icons.download_outlined),
                          onPressed: () => _download(context, invoice),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _download(BuildContext context, Invoice invoice) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await downloadInvoicePdf(invoice, save: save);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('La facture n’a pas pu être préparée.')),
      );
    }
  }
}
