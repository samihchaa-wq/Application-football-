import 'dart:convert';
import 'dart:typed_data';

import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:petit_filet/features/billing/domain/invoice.dart';
import 'package:petit_filet/features/billing/presentation/invoice_download.dart';
import 'package:petit_filet/features/billing/presentation/platform_invoices_section.dart';
import 'package:petit_filet/features/club/data/club_subscription.dart';
import 'package:petit_filet/features/platform/data/platform_billing_repository.dart';
import 'package:petit_filet/features/platform/domain/platform_billing.dart';
import 'package:petit_filet/features/platform/domain/platform_cash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Caisse du Gestionnaire : registre des encaissements, remboursements et
/// périodes offertes d'un mois ou d'une année, totaux, export, factures et
/// avoirs.
class PlatformCashSection extends ConsumerStatefulWidget {
  const PlatformCashSection({
    super.key,
    this.save = shareFile,
    this.onOpenClub,
    this.now,
  });

  final FileSaver save;

  /// Ouvre la fiche d'un club depuis une ligne du registre.
  final void Function(String clubId)? onOpenClub;

  /// Date de référence (tests).
  final DateTime? now;

  @override
  ConsumerState<PlatformCashSection> createState() =>
      _PlatformCashSectionState();
}

class _PlatformCashSectionState extends ConsumerState<PlatformCashSection> {
  late LedgerPeriod _period =
      LedgerPeriod.current(widget.now ?? DateTime.now());

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(platformLedgerProvider(_period));
    return Column(
      key: const Key('platform-cash'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _periodBar(),
        const SizedBox(height: 16),
        ledger.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: const Text('Caisse indisponible'),
              subtitle: const Text('Réessaie dans un instant.'),
              trailing: IconButton(
                tooltip: 'Réessayer',
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    ref.invalidate(platformLedgerProvider(_period)),
              ),
            ),
          ),
          data: (value) => _ledger(value),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('Factures'),
        PlatformInvoicesSection(save: widget.save, showSeller: false),
        const SizedBox(height: 24),
        const _SectionLabel('Avoirs'),
        _CreditNotes(save: widget.save),
      ],
    );
  }

  Widget _periodBar() => Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(
            key: const Key('platform-cash-previous'),
            tooltip: 'Période précédente',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _period = _period.previous),
          ),
          Text(
            _period.label,
            key: const Key('platform-cash-period'),
            style: const TextStyle(fontSize: 20),
          ),
          IconButton(
            key: const Key('platform-cash-next'),
            tooltip: 'Période suivante',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _period = _period.next),
          ),
          const SizedBox(width: 8),
          SegmentedButton<bool>(
            key: const Key('platform-cash-scope'),
            segments: const [
              ButtonSegment(value: false, label: Text('Mois')),
              ButtonSegment(value: true, label: Text('Année')),
            ],
            selected: {_period.month == null},
            onSelectionChanged: (value) => setState(() {
              final now = widget.now ?? DateTime.now();
              _period = value.first
                  ? _period.asYear
                  : _period.asMonth(
                      _period.year == now.year ? now.month : 12,
                    );
            }),
          ),
        ],
      );

  Widget _ledger(PlatformLedger ledger) {
    final totals = ledger.totals;
    final methods = totals.byMethod.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Metrics([
          (
            'Encaissé',
            formatEuros(totals.collectedCents),
            '${totals.payments} paiement(s)'
          ),
          (
            'Remboursé',
            formatEuros(totals.refundedCents),
            '${totals.refunds} remboursement(s)'
          ),
          (
            'Frais Stripe',
            formatEuros(totals.feesCents),
            'Prélevés sur les cartes'
          ),
          ('Net', formatEuros(totals.netCents), 'Encaissé − remboursé − frais'),
        ]),
        if (methods.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final method in methods)
                Chip(
                  label: Text(
                    '${platformPaymentMethodLabels[method.key] ?? 'Autre'} : '
                    '${formatEuros(method.value)}',
                  ),
                ),
              if (totals.gifts > 0)
                Chip(
                  avatar: const Icon(Icons.card_giftcard_outlined, size: 16),
                  label: Text('${totals.gifts} période(s) offerte(s)'),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
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
                      Text('Registre · ${_period.label}',
                          style: const TextStyle(fontSize: 18)),
                      OutlinedButton.icon(
                        key: const Key('platform-cash-export'),
                        onPressed: ledger.entries.isEmpty
                            ? null
                            : () => _export(ledger),
                        icon: const Icon(Icons.table_view_outlined),
                        label: const Text('Exporter (tableur)'),
                      ),
                    ],
                  ),
                ),
                if (ledger.entries.isEmpty)
                  const ListTile(
                    title: Text('Aucun mouvement sur cette période.'),
                  )
                else
                  for (final entry in ledger.entries) _entryTile(entry),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _entryTile(PlatformLedgerEntry entry) {
    final (icon, color) = switch (entry.kind) {
      LedgerKind.payment => entry.method == 'carte'
          ? (Icons.credit_card, AppTheme.success)
          : (Icons.payments_outlined, AppTheme.success),
      LedgerKind.refund => (Icons.undo, AppTheme.warning),
      LedgerKind.gift => (Icons.card_giftcard_outlined, AppTheme.textFaint),
    };
    final details = [
      formatInvoiceDay(entry.day),
      if (entry.kind == LedgerKind.gift)
        entry.periodLabel ?? 'Période offerte'
      else
        entry.methodLabel,
      if (entry.reference != null) entry.reference!,
      if (entry.feeCents > 0) 'frais ${formatEuros(entry.feeCents)}',
      if (entry.refundedCents > 0)
        'dont ${formatEuros(entry.refundedCents)} remboursés',
      if (entry.kind == LedgerKind.payment)
        entry.documentNumber == null
            ? 'facture en attente'
            : 'facture ${entry.documentNumber}',
      if (entry.kind == LedgerKind.refund)
        entry.documentNumber == null
            ? 'avoir en attente'
            : 'avoir ${entry.documentNumber}',
    ];
    return ListTile(
      key: ValueKey('platform-ledger-${entry.id}'),
      leading: Icon(icon, color: color),
      title: Text(entry.clubName),
      subtitle: Text(
        [
          details.join(' · '),
          if (entry.label != null && entry.label!.isNotEmpty) entry.label!,
        ].join('\n'),
      ),
      isThreeLine: entry.label != null && entry.label!.isNotEmpty,
      trailing: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(
            entry.kind == LedgerKind.gift
                ? 'offert'
                : '${entry.amountCents < 0 ? '−' : ''}'
                    '${formatEuros(entry.amountCents.abs())}',
            style: TextStyle(
              color: entry.amountCents < 0 ? AppTheme.warning : null,
            ),
          ),
          if (entry.receiptUrl != null)
            IconButton(
              tooltip: 'Reçu Stripe',
              icon: const Icon(Icons.receipt_outlined, size: 20),
              onPressed: () => launchUrl(Uri.parse(entry.receiptUrl!)),
            ),
        ],
      ),
      onTap: entry.clubId == null || widget.onOpenClub == null
          ? null
          : () => widget.onOpenClub!(entry.clubId!),
    );
  }

  Future<void> _export(PlatformLedger ledger) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(ledgerToCsv(ledger)));
      await widget.save(bytes, '${_period.fileStem}.csv', 'text/csv');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L’export n’a pas pu être préparé.')),
      );
    }
  }
}

class _CreditNotes extends ConsumerWidget {
  const _CreditNotes({required this.save});

  final FileSaver save;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(platformCreditNotesProvider);
    return Card(
      key: const Key('platform-credit-notes'),
      margin: EdgeInsets.zero,
      child: notes.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        ),
        error: (_, __) => ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: const Text('Avoirs indisponibles'),
          trailing: IconButton(
            tooltip: 'Réessayer',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(platformCreditNotesProvider),
          ),
        ),
        data: (list) => list.isEmpty
            ? const ListTile(title: Text('Aucun remboursement.'))
            : Column(
                children: [
                  for (final note in list)
                    ListTile(
                      leading: const Icon(Icons.undo),
                      title: Text(
                        '${note.number ?? 'En attente'} · '
                        '${formatEuros(note.amountCents)}',
                      ),
                      subtitle: Text(
                        '${note.buyerName ?? ''} · remboursé le '
                        '${formatInvoiceDay(note.refundedOn)}'
                        '${note.invoiceNumber == null ? '' : ' · facture ${note.invoiceNumber}'}'
                        '${note.isIssued ? '' : '\nNuméroté dès que la facture du paiement est émise.'}',
                      ),
                      trailing: note.isIssued
                          ? IconButton(
                              tooltip: 'Télécharger l’avoir (PDF)',
                              icon: const Icon(Icons.download_outlined),
                              onPressed: () async {
                                try {
                                  await downloadCreditNotePdf(note, save: save);
                                } catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(humanizeError(error))),
                                  );
                                }
                              },
                            )
                          : null,
                    ),
                ],
              ),
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics(this.values);

  final List<(String, String, String)> values;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 850
              ? 4
              : constraints.maxWidth >= 500
                  ? 2
                  : 1;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final value in values)
                SizedBox(
                  width: (constraints.maxWidth - 12 * (columns - 1)) / columns,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(value.$1,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          Text(value.$2, style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(value.$3,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textFaint)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1.5,
            color: AppTheme.textFaint,
          ),
        ),
      );
}
