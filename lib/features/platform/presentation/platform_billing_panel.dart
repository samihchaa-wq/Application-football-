import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/features/club/data/club_subscription.dart';
import 'package:petit_filet/features/platform/data/platform_billing_repository.dart';
import 'package:petit_filet/features/platform/data/platform_repository.dart';
import 'package:petit_filet/features/platform/domain/platform_billing.dart';
import 'package:petit_filet/features/platform/domain/platform_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Facturation d'une équipe : échéance, suspension prévue, paiements reçus et
/// saisie d'un paiement hors ligne (virement, chèque, espèces).
class PlatformBillingPanel extends ConsumerWidget {
  const PlatformBillingPanel({super.key, required this.team});

  final PlatformTeam team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billing = ref.watch(platformBillingProvider(team.id));
    return Card(
      key: const Key('platform-billing-panel'),
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
            ...billing.when(
              loading: () => const [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
              ],
              error: (_, __) => [
                ListTile(
                  leading: const Icon(Icons.cloud_off_outlined),
                  title: const Text('Paiements indisponibles'),
                  subtitle: const Text('Réessaie dans un instant.'),
                  trailing: IconButton(
                    tooltip: 'Réessayer',
                    icon: const Icon(Icons.refresh),
                    onPressed: () =>
                        ref.invalidate(platformBillingProvider(team.id)),
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
    PlatformBilling billing,
  ) {
    final autoSuspended = billing.autoSuspendedAt != null;
    return [
      if (autoSuspended && team.status == 'suspended')
        ListTile(
          leading:
              const Icon(Icons.pause_circle_outline, color: AppTheme.warning),
          title: const Text('Suspendue automatiquement pour impayé'),
          subtitle: Text(
            'Depuis le ${platformDay(billing.autoSuspendedAt)}. '
            'Noter un paiement rouvre l’accès aussitôt.',
          ),
        )
      else if (team.status == 'suspended')
        const ListTile(
          leading: Icon(Icons.pause_circle_outline),
          title: Text('Suspendue à la main'),
          subtitle: Text(
            'Un paiement prolonge l’abonnement mais ne rouvre pas l’accès.',
          ),
        )
      else if (billing.suspensionOn != null)
        ListTile(
          leading: const Icon(Icons.event_outlined),
          title: Text(
            'Suspension prévue le ${platformDay(billing.suspensionOn)}',
          ),
          subtitle: const Text(
            'Si aucun paiement n’est noté d’ici là (15 jours après '
            'l’échéance).',
          ),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const Key('platform-record-payment'),
            onPressed: () => _record(context, ref, billing),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Noter un paiement reçu'),
          ),
        ),
      ),
      if (billing.payments.isEmpty)
        const ListTile(title: Text('Aucun paiement noté pour cette équipe.'))
      else
        ...billing.payments.map(
          (payment) => ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(
              '${formatEuros(payment.amountCents)} · ${payment.methodLabel}',
            ),
            subtitle: Text(
              'Reçu le ${platformDay(payment.receivedOn)} · payé jusqu’au '
              '${platformDay(payment.periodEnd)}'
              '${payment.note == null ? '' : '\n${payment.note}'}',
            ),
          ),
        ),
    ];
  }

  Future<void> _record(
    BuildContext context,
    WidgetRef ref,
    PlatformBilling billing,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<RecordedPayment>(
      context: context,
      builder: (_) => _RecordPaymentDialog(
        team: team,
        defaultAmountCents: billing.basePriceCents ?? 7900,
        repository: ref.read(platformBillingRepositoryProvider),
      ),
    );
    if (result == null) return;
    ref.invalidate(platformBillingProvider(team.id));
    ref.invalidate(platformSnapshotProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Paiement noté. Abonnement payé jusqu’au '
          '${platformDay(result.periodEnd)}.'
          '${result.reopened ? ' L’équipe a retrouvé l’accès.' : ''}',
        ),
      ),
    );
  }
}

class _RecordPaymentDialog extends StatefulWidget {
  const _RecordPaymentDialog({
    required this.team,
    required this.defaultAmountCents,
    required this.repository,
  });

  final PlatformTeam team;
  final int defaultAmountCents;
  final PlatformBillingRepository repository;

  @override
  State<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<_RecordPaymentDialog> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.defaultAmountCents % 100 == 0
        ? '${widget.defaultAmountCents ~/ 100}'
        : '${widget.defaultAmountCents ~/ 100},'
            '${(widget.defaultAmountCents % 100).toString().padLeft(2, '0')}',
  );
  final _note = TextEditingController();
  String _method = 'virement';
  DateTime _receivedOn = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedOn,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) setState(() => _receivedOn = picked);
  }

  Future<void> _save() async {
    final cents = parseEurosToCents(_amount.text);
    if (cents == null) {
      setState(() => _error = 'Montant illisible. Exemple : 79 ou 79,50.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await widget.repository.recordPayment(
        clubId: widget.team.id,
        amountCents: cents,
        method: _method,
        receivedOn: _receivedOn,
        note: _note.text,
      );
      if (mounted) Navigator.of(context).pop(result);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Le paiement n’a pas été enregistré. Réessaie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Paiement reçu · ${widget.team.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('platform-payment-amount'),
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Montant reçu',
                suffixText: '€',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Moyen'),
              items: [
                for (final entry in platformPaymentMethods.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) => setState(() => _method = value ?? _method),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text('Reçu le ${platformDay(_receivedOn)}'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Note (facultatif)',
                hintText: 'Numéro de chèque, référence du virement…',
              ),
            ),
            const Text(
              'Le paiement ouvre une année d’abonnement, à partir de la fin '
              'de l’essai ou de l’année en cours si elle n’est pas finie.',
              style: TextStyle(fontSize: 12, color: AppTheme.textFaint),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('platform-payment-save'),
          onPressed: _saving ? null : _save,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

/// Jour à la française, dans le fuseau de l'appareil.
String platformDay(DateTime? date) {
  if (date == null) return 'date inconnue';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}
