import 'package:petit_filet/features/billing/data/invoice_repository.dart';
import 'package:petit_filet/features/billing/domain/invoice.dart';
import 'package:petit_filet/features/billing/presentation/invoice_download.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Factures dans la console de l'éditeur : coordonnées imprimées, factures en
/// attente à émettre, liste complète et export du livre des recettes.
class PlatformInvoicesSection extends ConsumerWidget {
  const PlatformInvoicesSection({
    super.key,
    this.save = shareFile,
    this.showSeller = true,
  });

  final FileSaver save;

  /// Les coordonnées de l'éditeur sont dans Réglages ; la Caisse les masque.
  final bool showSeller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(platformInvoicesProvider);
    return Column(
      key: const Key('platform-invoices'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSeller) ...[
          const PlatformSellerCard(),
          const SizedBox(height: 16),
        ],
        invoices.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => ListTile(
            leading: const Icon(Icons.cloud_off_outlined),
            title: const Text('Factures indisponibles'),
            trailing: IconButton(
              tooltip: 'Réessayer',
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(platformInvoicesProvider),
            ),
          ),
          data: (list) => _InvoiceList(invoices: list, save: save),
        ),
      ],
    );
  }
}

void _refresh(WidgetRef ref) {
  ref.invalidate(platformInvoicesProvider);
  ref.invalidate(platformInvoiceSettingsProvider);
}

/// Coordonnées de l'éditeur imprimées sur les factures (dont le SIRET).
class PlatformSellerCard extends ConsumerWidget {
  const PlatformSellerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(platformInvoiceSettingsProvider);
    final value = settings.valueOrNull;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tes coordonnées sur les factures',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            if (settings.isLoading && value == null)
              const LinearProgressIndicator()
            else if (value == null)
              const Text('Coordonnées indisponibles. Réessaie dans un instant.')
            else ...[
              Text(
                value.ready
                    ? '${value.sellerName} · SIRET ${value.siret}'
                    : 'Incomplètes : les factures restent en attente (aperçu '
                        'en brouillon seulement) tant que le nom, l’adresse, '
                        'le SIRET et l’e-mail ne sont pas tous saisis.',
                key: const Key('platform-invoice-settings-status'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('platform-invoice-settings-edit'),
                onPressed: () async {
                  final saved = await showDialog<bool>(
                    context: context,
                    builder: (_) => _SellerDialog(
                      initial: value,
                      repository: ref.read(invoiceRepositoryProvider),
                    ),
                  );
                  if (saved == true) _refresh(ref);
                },
                child: const Text('Modifier'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InvoiceList extends ConsumerWidget {
  const _InvoiceList({required this.invoices, required this.save});

  final List<Invoice> invoices;
  final FileSaver save;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = invoices.where((invoice) => !invoice.isIssued).toList();
    final issued = invoices.where((invoice) => invoice.isIssued).toList();
    final issuable = pending.any((invoice) => invoice.blocker == null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pending.isNotEmpty)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'En attente (${pending.length})',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text(
                      'Sans numéro tant qu’elles ne sont pas émises. Écarte '
                      'celles qui ne correspondent pas à un vrai paiement '
                      '(club de démonstration, test).',
                    ),
                  ),
                  for (final invoice in pending)
                    _PendingTile(invoice: invoice, save: save),
                  if (issuable)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton(
                          key: const Key('platform-invoices-issue'),
                          onPressed: () => _issue(context, ref),
                          child: const Text('Émettre les factures prêtes'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (pending.isNotEmpty) const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text('Factures émises (${issued.length})',
                          style: const TextStyle(fontSize: 18)),
                      OutlinedButton.icon(
                        key: const Key('platform-invoices-export'),
                        onPressed: issued.isEmpty
                            ? null
                            : () => _export(context, issued),
                        icon: const Icon(Icons.table_view_outlined),
                        label: const Text('Livre des recettes (tableur)'),
                      ),
                    ],
                  ),
                ),
                if (issued.isEmpty)
                  const ListTile(title: Text('Aucune facture émise.'))
                else
                  for (final invoice in issued)
                    ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(
                        '${invoice.number} · '
                        '${formatInvoiceAmount(invoice.amountCents)}',
                      ),
                      subtitle: Text(
                        '${invoice.buyerName ?? ''} · émise le '
                        '${formatInvoiceDay(invoice.issuedOn)}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Télécharger la facture',
                        icon: const Icon(Icons.download_outlined),
                        onPressed: () => _pdf(context, invoice, save),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _issue(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await ref.read(invoiceRepositoryProvider).issuePending();
      messenger.showSnackBar(
        SnackBar(content: Text('$count facture(s) émise(s).')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Les factures n’ont pas été émises.')),
      );
    }
    _refresh(ref);
  }

  Future<void> _export(BuildContext context, List<Invoice> issued) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await downloadInvoicesCsv(issued, save: save);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('L’export n’a pas pu être préparé.')),
      );
    }
  }
}

Future<void> _pdf(BuildContext context, Invoice invoice, FileSaver save) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await downloadInvoicePdf(invoice, save: save);
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('La facture n’a pas pu être préparée.')),
    );
  }
}

class _PendingTile extends ConsumerWidget {
  const _PendingTile({required this.invoice, required this.save});

  final Invoice invoice;
  final FileSaver save;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      key: ValueKey('platform-pending-invoice-${invoice.id}'),
      leading: const Icon(Icons.hourglass_empty_outlined),
      title: Text(
        '${invoice.buyerName ?? 'Club'} · '
        '${formatInvoiceAmount(invoice.amountCents)}',
      ),
      subtitle: Text(
        'Payé le ${formatInvoiceDay(invoice.receivedOn)} · '
        '${invoice.blocker?.label ?? 'Prête à émettre'}',
      ),
      trailing: Wrap(
        children: [
          if (invoice.blocker == InvoiceBlocker.buyerAddress &&
              invoice.clubId != null)
            IconButton(
              key: ValueKey('platform-invoice-buyer-${invoice.id}'),
              tooltip: 'Saisir l’adresse du club',
              icon: const Icon(Icons.edit_location_alt_outlined),
              onPressed: () async {
                final saved = await showDialog<bool>(
                  context: context,
                  builder: (_) => _BuyerDialog(
                    invoice: invoice,
                    repository: ref.read(invoiceRepositoryProvider),
                  ),
                );
                if (saved == true) _refresh(ref);
              },
            ),
          IconButton(
            tooltip: 'Aperçu en brouillon',
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () => _pdf(context, invoice, save),
          ),
          IconButton(
            key: ValueKey('platform-invoice-discard-${invoice.id}'),
            tooltip: 'Écarter',
            icon: const Icon(Icons.delete_outlined),
            onPressed: () => _discard(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _discard(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Écarter cette facture\u00A0?'),
        content: const Text(
          'Le paiement reste noté, mais aucune facture ne sera émise pour lui. '
          'À réserver aux paiements de test ou du club de démonstration.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const Key('platform-invoice-discard-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Écarter'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(invoiceRepositoryProvider).discardPending(invoice.id);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('La facture n’a pas été écartée.')),
      );
    }
    _refresh(ref);
  }
}

class _SellerDialog extends StatefulWidget {
  const _SellerDialog({required this.initial, required this.repository});

  final InvoiceSettings initial;
  final InvoiceRepository repository;

  @override
  State<_SellerDialog> createState() => _SellerDialogState();
}

class _SellerDialogState extends State<_SellerDialog> {
  late final _name = TextEditingController(text: widget.initial.sellerName);
  late final _address =
      TextEditingController(text: widget.initial.sellerAddress);
  late final _siret = TextEditingController(text: widget.initial.siret);
  late final _email = TextEditingController(text: widget.initial.contactEmail);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _address, _siret, _email]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final siret = _siret.text.replaceAll(RegExp(r'\s'), '');
    if (siret.isNotEmpty && !RegExp(r'^\d{14}$').hasMatch(siret)) {
      setState(() => _error = 'Le SIRET compte 14 chiffres.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveSettings(
        sellerName: _name.text,
        sellerAddress: _address.text,
        siret: siret,
        contactEmail: _email.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Les coordonnées n’ont pas été enregistrées. Réessaie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tes coordonnées'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('platform-invoice-seller-name'),
              controller: _name,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Nom',
                helperText: 'Tel qu’inscrit, suivi de « EI ». '
                    'Exemple : Prénom NOM EI – Petit Filet',
                helperMaxLines: 4,
              ),
            ),
            TextField(
              key: const Key('platform-invoice-seller-address'),
              controller: _address,
              maxLength: 300,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(labelText: 'Adresse'),
            ),
            TextField(
              key: const Key('platform-invoice-seller-siret'),
              controller: _siret,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'SIRET (14 chiffres)',
                helperText: 'Laisse vide tant que tu ne l’as pas reçu.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('platform-invoice-seller-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail de contact'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('platform-invoice-seller-save'),
          onPressed: _saving ? null : _save,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _BuyerDialog extends StatefulWidget {
  const _BuyerDialog({required this.invoice, required this.repository});

  final Invoice invoice;
  final InvoiceRepository repository;

  @override
  State<_BuyerDialog> createState() => _BuyerDialogState();
}

class _BuyerDialogState extends State<_BuyerDialog> {
  late final _name = TextEditingController(text: widget.invoice.buyerName);
  late final _address =
      TextEditingController(text: widget.invoice.buyerAddress);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_address.text.trim().length < 5) {
      setState(() => _error = 'Saisis l’adresse complète du club.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.setClubBillingDetails(
        clubId: widget.invoice.clubId!,
        name: _name.text,
        address: _address.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Les coordonnées n’ont pas été enregistrées. Réessaie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Coordonnées du club'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Imprimées sur cette facture et sur les suivantes de ce club.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('platform-invoice-buyer-name'),
              controller: _name,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Nom du client',
                helperText: 'Nom officiel de l’association, si différent.',
              ),
            ),
            TextField(
              key: const Key('platform-invoice-buyer-address'),
              controller: _address,
              maxLength: 300,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(labelText: 'Adresse'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('platform-invoice-buyer-save'),
          onPressed: _saving ? null : _save,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
