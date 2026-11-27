import 'package:petit_filet/core/utils/club_time.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:petit_filet/features/club/data/club_subscription.dart';
import 'package:petit_filet/features/platform/data/platform_billing_repository.dart';
import 'package:petit_filet/features/platform/data/platform_repository.dart';
import 'package:petit_filet/features/platform/domain/platform_billing.dart';
import 'package:petit_filet/features/platform/domain/platform_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abonnement d'un club dans le Gestionnaire : état, actions (paiement,
/// période offerte, remboursement, tarif, accès), contacts et historique.
class PlatformBillingPanel extends ConsumerWidget {
  const PlatformBillingPanel({super.key, required this.team});

  final PlatformTeam team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billing = ref.watch(platformBillingProvider(team.id));
    return billing.when(
      loading: () => const Card(
        key: Key('platform-billing-panel'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        ),
      ),
      error: (_, __) => Card(
        key: const Key('platform-billing-panel'),
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: const Text('Paiements indisponibles'),
          subtitle: const Text('Réessaie dans un instant.'),
          trailing: IconButton(
            tooltip: 'Réessayer',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(platformBillingProvider(team.id)),
          ),
        ),
      ),
      data: (value) => Column(
        key: const Key('platform-billing-panel'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SubscriptionCard(team: team, billing: value),
          const SizedBox(height: 16),
          _ContactsCard(billing: value),
          const SizedBox(height: 16),
          _HistoryCard(team: team, billing: value),
        ],
      ),
    );
  }
}

void _refreshClub(WidgetRef ref, String clubId) {
  ref.invalidate(platformBillingProvider(clubId));
  ref.invalidate(platformSnapshotProvider);
  ref.invalidate(platformAlertsProvider);
}

void _toast(ScaffoldMessengerState messenger, String text) {
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(text)));
}

Widget _cardTitle(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
      ),
    );

// ---------------------------------------------------------------------------
// Abonnement et actions
// ---------------------------------------------------------------------------

class _SubscriptionCard extends ConsumerWidget {
  const _SubscriptionCard({required this.team, required this.billing});

  final PlatformTeam team;
  final PlatformBilling billing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoSuspended = billing.autoSuspendedAt != null;
    final suspended = team.status == 'suspended';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cardTitle('Abonnement'),
            ListTile(
              leading: Icon(
                billing.isTrial
                    ? Icons.card_giftcard_outlined
                    : Icons.verified_outlined,
              ),
              title: Text(
                billing.isTrial
                    ? 'Essai jusqu’au ${platformDay(billing.trialEndsAt)}'
                    : billing.currentPeriodEnd == null
                        ? 'Abonnement sans échéance'
                        : 'Payé jusqu’au ${platformDay(billing.currentPeriodEnd)}',
              ),
              subtitle: Text(
                'Tarif du club : ${formatEuros(billing.basePriceCents ?? 0)} par an'
                '${billing.referralDiscountPercent > 0 ? '' : ' · prochain paiement : ${formatEuros(billing.amountDueCents ?? 0)}'}',
              ),
            ),
            if (billing.referralDiscountPercent > 0)
              ListTile(
                key: const Key('platform-billing-referral'),
                leading: const Icon(Icons.groups_2_outlined),
                title: Text(
                  'Parrainage : −${billing.referralDiscountPercent} %',
                ),
                subtitle: Text(
                  'À demander pour la prochaine année : '
                  '${formatEuros(billing.amountDueCents ?? 0)}. '
                  'La réduction est utilisée au prochain paiement.',
                ),
              ),
            if (autoSuspended && suspended)
              ListTile(
                leading: const Icon(Icons.pause_circle_outlined,
                    color: AppTheme.warning),
                title: const Text('Suspendue automatiquement pour impayé'),
                subtitle: Text(
                  'Depuis le ${platformDay(billing.autoSuspendedAt)}. '
                  'Un paiement ou une période offerte rouvre l’accès aussitôt.',
                ),
              )
            else if (suspended)
              const ListTile(
                leading: Icon(Icons.pause_circle_outlined),
                title: Text('Suspendue à la main'),
                subtitle: Text(
                  'Un paiement prolonge l’abonnement mais ne rouvre pas '
                  'l’accès : utilise « Rouvrir l’accès ».',
                ),
              )
            else if (billing.suspensionOn != null)
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(
                  'Suspension prévue le ${platformDay(billing.suspensionOn)}',
                ),
                subtitle: const Text(
                  'Si aucun paiement n’est noté d’ici là. Les administrateurs '
                  'du club sont prévenus par e-mail 10 jours avant.',
                ),
              ),
            if (billing.notes != null)
              ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: const Text('Note interne'),
                subtitle: Text(billing.notes!),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: const Key('platform-record-payment'),
                    onPressed: () => _recordPayment(context, ref),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Noter un paiement reçu'),
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('platform-grant-period'),
                    onPressed: () => _grant(context, ref),
                    icon: const Icon(Icons.card_giftcard_outlined),
                    label: Text(
                      billing.isTrial
                          ? 'Prolonger l’essai'
                          : 'Offrir une période',
                    ),
                  ),
                  OutlinedButton(
                    key: const Key('platform-club-terms'),
                    onPressed: () => _terms(context, ref),
                    child: const Text('Tarif et note'),
                  ),
                  OutlinedButton(
                    key: const Key('platform-billing-details'),
                    onPressed: () => _billingDetails(context, ref),
                    child: const Text('Adresse de facturation'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('platform-club-access'),
                    onPressed: () => _toggleAccess(context, ref, suspended),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: suspended ? null : AppTheme.error,
                    ),
                    icon: Icon(suspended
                        ? Icons.play_circle_outlined
                        : Icons.pause_circle_outlined),
                    label: Text(
                        suspended ? 'Rouvrir l’accès' : 'Suspendre l’accès'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordPayment(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<RecordedPayment>(
      context: context,
      builder: (_) => _RecordPaymentDialog(
        team: team,
        defaultAmountCents:
            billing.amountDueCents ?? billing.basePriceCents ?? 7900,
        repository: ref.read(platformBillingRepositoryProvider),
      ),
    );
    if (result == null) return;
    _refreshClub(ref, team.id);
    _toast(
      messenger,
      'Paiement noté. Abonnement payé jusqu’au '
      '${platformDay(result.periodEnd)}.'
      '${result.reopened ? ' L’équipe a retrouvé l’accès.' : ''}',
    );
  }

  Future<void> _grant(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<GrantedPeriod>(
      context: context,
      builder: (_) => _GrantDialog(
        team: team,
        trial: billing.isTrial,
        repository: ref.read(platformBillingRepositoryProvider),
      ),
    );
    if (result == null) return;
    _refreshClub(ref, team.id);
    _toast(
      messenger,
      '${result.trialExtension ? 'Essai prolongé' : 'Période offerte'} '
      'jusqu’au ${platformDay(result.periodEnd)}.'
      '${result.reopened ? ' L’équipe a retrouvé l’accès.' : ''}',
    );
  }

  Future<void> _terms(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _TermsDialog(
        team: team,
        billing: billing,
        repository: ref.read(platformBillingRepositoryProvider),
      ),
    );
    if (saved != true) return;
    _refreshClub(ref, team.id);
    _toast(messenger, 'Tarif et note enregistrés.');
  }

  Future<void> _billingDetails(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _BillingDetailsDialog(
        team: team,
        billing: billing,
        repository: ref.read(platformBillingRepositoryProvider),
      ),
    );
    if (saved != true) return;
    _refreshClub(ref, team.id);
    _toast(messenger, 'Adresse de facturation enregistrée.');
  }

  Future<void> _toggleAccess(
    BuildContext context,
    WidgetRef ref,
    bool suspended,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
            suspended ? 'Rouvrir l’accès\u00A0?' : 'Suspendre l’accès\u00A0?'),
        content: Text(
          suspended
              ? 'Les membres de ${team.name} retrouvent l’appli tout de suite.'
              : 'Les membres de ${team.name} ne pourront plus utiliser '
                  'l’appli. Leurs données sont gardées. Une suspension à la '
                  'main n’est levée que par toi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const Key('platform-club-access-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(suspended ? 'Rouvrir' : 'Suspendre'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(platformBillingRepositoryProvider)
          .setClubAccess(clubId: team.id, suspended: !suspended);
      _refreshClub(ref, team.id);
      _toast(messenger, suspended ? 'Accès rouvert.' : 'Accès suspendu.');
    } catch (error) {
      _toast(messenger, humanizeError(error));
    }
  }
}

// ---------------------------------------------------------------------------
// Contacts
// ---------------------------------------------------------------------------

class _ContactsCard extends StatelessWidget {
  const _ContactsCard({required this.billing});

  final PlatformBilling billing;

  @override
  Widget build(BuildContext context) {
    final contact = billing.contact;
    Widget line(IconData icon, String label, String? value, {Uri? link}) =>
        ListTile(
          dense: true,
          leading: Icon(icon),
          title: Text(label),
          subtitle: SelectableText(value ?? 'Non renseigné'),
          trailing: value == null
              ? null
              : IconButton(
                  tooltip: 'Copier',
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: value)),
                ),
          onTap: link == null ? null : () => launchUrl(link),
        );
    return Card(
      key: const Key('platform-club-contacts'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cardTitle('Contacts'),
            if (contact.isEmpty)
              const ListTile(
                title: Text('Le club n’a pas encore saisi ses coordonnées.'),
                subtitle: Text('Réglages du club › Coordonnées du club.'),
              )
            else ...[
              line(Icons.person_outlined, 'Personne à contacter', contact.name),
              line(Icons.mail_outlined, 'E-mail du club', contact.email,
                  link: contact.email == null
                      ? null
                      : Uri(scheme: 'mailto', path: contact.email)),
              line(Icons.phone_outlined, 'Téléphone', contact.phone,
                  link: contact.phone == null
                      ? null
                      : Uri(scheme: 'tel', path: contact.phone)),
              line(Icons.markunread_mailbox_outlined, 'Adresse postale',
                  contact.postalAddress),
              line(Icons.badge_outlined, 'RNA ou SIRET',
                  contact.registrationNumber),
            ],
            line(
              Icons.receipt_outlined,
              'Facturé à',
              [
                billing.billingName,
                billing.billingAddress ?? contact.postalAddress,
              ].whereType<String>().join(' · ').ifEmpty,
            ),
            for (final admin in billing.admins)
              line(
                Icons.admin_panel_settings_outlined,
                'Administrateur : ${admin.name}',
                admin.email,
                link: admin.email == null
                    ? null
                    : Uri(scheme: 'mailto', path: admin.email),
              ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String? get ifEmpty => isEmpty ? null : this;
}

// ---------------------------------------------------------------------------
// Historique
// ---------------------------------------------------------------------------

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({required this.team, required this.billing});

  final PlatformTeam team;
  final PlatformBilling billing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refundsByPayment = <String, List<PlatformRefund>>{};
    for (final refund in billing.refunds) {
      final id = refund.paymentId;
      if (id != null) (refundsByPayment[id] ??= []).add(refund);
    }
    return Card(
      key: const Key('platform-club-history'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cardTitle('Paiements'),
            if (billing.payments.isEmpty)
              const ListTile(
                  title: Text('Aucun paiement noté pour cette équipe.'))
            else
              for (final payment in billing.payments) ...[
                _paymentTile(context, ref, payment),
                for (final refund in refundsByPayment[payment.id] ?? const [])
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.undo, color: AppTheme.warning),
                      title: Text(
                        'Remboursé ${formatEuros(refund.amountCents)} · '
                        '${refund.methodLabel}',
                      ),
                      subtitle: Text(
                        'Le ${platformDay(refund.refundedOn)}'
                        '${refund.creditNoteNumber == null ? ' · avoir en attente de la facture' : ' · avoir ${refund.creditNoteNumber}'}'
                        '${refund.reason == null ? '' : '\n${refund.reason}'}',
                      ),
                    ),
                  ),
              ],
            if (billing.grants.isNotEmpty) ...[
              const Divider(),
              _cardTitle('Périodes offertes'),
              for (final grant in billing.grants)
                ListTile(
                  leading: const Icon(Icons.card_giftcard_outlined),
                  title: Text(
                    '${grant.durationLabel} '
                    '${grant.trialExtension ? 'd’essai en plus' : 'offerts'}',
                  ),
                  subtitle: Text(
                    'Le ${platformDay(grant.createdAt)}, jusqu’au '
                    '${platformDay(grant.periodEnd)}\n${grant.reason}',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _paymentTile(
    BuildContext context,
    WidgetRef ref,
    PlatformPayment payment,
  ) {
    final details = [
      'Reçu le ${platformDay(payment.receivedOn)} · payé jusqu’au '
          '${platformDay(payment.periodEnd)}',
      if (payment.reference != null) payment.reference!,
      if (payment.stripeFeeCents != null)
        'Frais Stripe ${formatEuros(payment.stripeFeeCents!)} · net '
            '${formatEuros(payment.amountCents - payment.stripeFeeCents!)}',
      payment.invoiceNumber == null
          ? 'Facture en attente'
          : 'Facture ${payment.invoiceNumber}',
      if (payment.note != null) payment.note!,
    ];
    return ListTile(
      key: ValueKey('platform-payment-${payment.id}'),
      leading: Icon(
        payment.isCard
            ? Icons.credit_card_outlined
            : Icons.receipt_long_outlined,
      ),
      title: Text(
        '${formatEuros(payment.amountCents)} · ${payment.methodLabel}',
      ),
      subtitle: Text(details.join('\n')),
      isThreeLine: details.length > 1,
      trailing: Wrap(
        spacing: 4,
        children: [
          if (payment.receiptUrl != null)
            IconButton(
              tooltip: 'Reçu Stripe',
              icon: const Icon(Icons.receipt_outlined),
              onPressed: () => launchUrl(Uri.parse(payment.receiptUrl!)),
            ),
          if (payment.id != null && payment.refundableCents > 0)
            IconButton(
              key: ValueKey('platform-refund-${payment.id}'),
              tooltip: 'Rembourser',
              icon: const Icon(Icons.undo),
              onPressed: () => _refund(context, ref, payment),
            ),
        ],
      ),
    );
  }

  Future<void> _refund(
    BuildContext context,
    WidgetRef ref,
    PlatformPayment payment,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<RecordedRefund>(
      context: context,
      builder: (_) => _RefundDialog(
        team: team,
        payment: payment,
        repository: ref.read(platformBillingRepositoryProvider),
      ),
    );
    if (result == null) return;
    _refreshClub(ref, team.id);
    _toast(
      messenger,
      !result.recorded
          ? 'Remboursé par Stripe. Il apparaîtra ici dans quelques instants.'
          : result.creditNoteNumber == null
              ? 'Remboursement noté. L’avoir sera émis avec la facture.'
              : 'Remboursement noté, avoir ${result.creditNoteNumber}.',
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogues
// ---------------------------------------------------------------------------

/// Base commune : enregistrement, erreur affichée, boutons.
abstract class _ActionDialogState<T extends StatefulWidget> extends State<T> {
  bool saving = false;
  String? error;

  Future<void> run(Future<Object?> Function() action) async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final result = await action();
      if (mounted) Navigator.of(context).pop(result);
    } catch (caught) {
      if (!mounted) return;
      setState(() {
        saving = false;
        error = humanizeError(caught);
      });
    }
  }

  Widget dialog({
    required String title,
    required List<Widget> children,
    required Key saveKey,
    required String saveLabel,
    required VoidCallback onSave,
  }) =>
      AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...children,
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: saveKey,
            onPressed: saving ? null : onSave,
            child: Text(saving ? 'Enregistrement…' : saveLabel),
          ),
        ],
      );
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

class _RecordPaymentDialogState
    extends _ActionDialogState<_RecordPaymentDialog> {
  late final _amount =
      TextEditingController(text: centsToInput(widget.defaultAmountCents));
  final _reference = TextEditingController();
  final _note = TextEditingController();
  String _method = 'virement';
  DateTime _receivedOn = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
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

  void _save() {
    final cents = parseEurosToCents(_amount.text);
    if (cents == null) {
      setState(() => error = 'Montant illisible. Exemple : 79 ou 79,50.');
      return;
    }
    run(() => widget.repository.recordPayment(
          clubId: widget.team.id,
          amountCents: cents,
          method: _method,
          receivedOn: _receivedOn,
          note: _note.text,
          reference: _reference.text,
        ));
  }

  @override
  Widget build(BuildContext context) => dialog(
        title: 'Paiement reçu · ${widget.team.name}',
        saveKey: const Key('platform-payment-save'),
        saveLabel: 'Enregistrer',
        onSave: _save,
        children: [
          TextField(
            key: const Key('platform-payment-amount'),
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Montant reçu',
              suffixText: '€',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('platform-payment-method'),
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Moyen'),
            items: [
              for (final entry in platformPaymentMethods.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (value) => setState(() => _method = value ?? _method),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('platform-payment-reference'),
            controller: _reference,
            maxLength: 120,
            decoration: InputDecoration(
              labelText: 'Référence (facultatif)',
              hintText: switch (_method) {
                'cheque' => 'N° de chèque et banque',
                'virement' => 'Référence du virement',
                'especes' => 'Reçu remis, personne…',
                _ => 'Référence',
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: saving ? null : _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text('Reçu le ${platformDay(_receivedOn)}'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Note (facultatif)'),
          ),
          const Text(
            'Le paiement ouvre une année d’abonnement, à partir de la fin de '
            'l’essai ou de l’année en cours si elle n’est pas finie. Une '
            'facture est créée.',
            style: TextStyle(fontSize: 12, color: AppTheme.textFaint),
          ),
        ],
      );
}

class _GrantDialog extends StatefulWidget {
  const _GrantDialog({
    required this.team,
    required this.trial,
    required this.repository,
  });

  final PlatformTeam team;
  final bool trial;
  final PlatformBillingRepository repository;

  @override
  State<_GrantDialog> createState() => _GrantDialogState();
}

class _GrantDialogState extends _ActionDialogState<_GrantDialog> {
  static const _choices = <(int months, int days)>[
    (0, 15),
    (1, 0),
    (3, 0),
    (6, 0),
    (12, 0),
  ];
  (int, int) _choice = (1, 0);
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _save() {
    if (_reason.text.trim().length < 2) {
      setState(() => error = 'Indique un motif : pilote, geste commercial…');
      return;
    }
    run(() => widget.repository.grantFreePeriod(
          clubId: widget.team.id,
          months: _choice.$1,
          days: _choice.$2,
          reason: _reason.text,
        ));
  }

  @override
  Widget build(BuildContext context) => dialog(
        title: widget.trial
            ? 'Prolonger l’essai · ${widget.team.name}'
            : 'Offrir une période · ${widget.team.name}',
        saveKey: const Key('platform-grant-save'),
        saveLabel: widget.trial ? 'Prolonger' : 'Offrir',
        onSave: _save,
        children: [
          Text(
            widget.trial
                ? 'La durée s’ajoute à la fin de l’essai.'
                : 'La durée s’ajoute à la fin de l’abonnement en cours, ou '
                    'part d’aujourd’hui s’il est échu. Un club suspendu pour '
                    'impayé est rouvert. Aucune facture : rien n’est payé.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in _choices)
                ChoiceChip(
                  key: ValueKey('platform-grant-${choice.$1}-${choice.$2}'),
                  label: Text(formatGrantDuration(choice.$1, choice.$2)),
                  selected: _choice == choice,
                  onSelected: (_) => setState(() => _choice = choice),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('platform-grant-reason'),
            controller: _reason,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'Motif',
              hintText: 'Club pilote, geste commercial, panne…',
            ),
          ),
        ],
      );
}

class _RefundDialog extends StatefulWidget {
  const _RefundDialog({
    required this.team,
    required this.payment,
    required this.repository,
  });

  final PlatformTeam team;
  final PlatformPayment payment;
  final PlatformBillingRepository repository;

  @override
  State<_RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends _ActionDialogState<_RefundDialog> {
  late final _amount =
      TextEditingController(text: centsToInput(widget.payment.refundableCents));
  final _reason = TextEditingController();
  late String _method = widget.payment.refundableByCard ? 'carte' : 'virement';
  // Même identifiant pour chaque nouvel essai : Stripe ne rembourse qu'une
  // fois même après un double appui.
  final _requestId = newRequestId();

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _save() {
    final cents = parseEurosToCents(_amount.text);
    if (cents == null || cents < 1) {
      setState(() => error = 'Montant illisible. Exemple : 29 ou 29,50.');
      return;
    }
    if (cents > widget.payment.refundableCents) {
      setState(() => error = 'Au plus '
          '${formatEuros(widget.payment.refundableCents)} sur ce paiement.');
      return;
    }
    run(() => _method == 'carte'
        ? widget.repository.refundCard(
            paymentId: widget.payment.id!,
            amountCents: cents,
            reason: _reason.text,
            requestId: _requestId,
          )
        : widget.repository.recordManualRefund(
            paymentId: widget.payment.id!,
            amountCents: cents,
            method: _method,
            reason: _reason.text,
          ));
  }

  @override
  Widget build(BuildContext context) => dialog(
        title: 'Rembourser · ${widget.team.name}',
        saveKey: const Key('platform-refund-save'),
        saveLabel: _method == 'carte' ? 'Rembourser la carte' : 'Enregistrer',
        onSave: _save,
        children: [
          Text(
            'Paiement de ${formatEuros(widget.payment.amountCents)} '
            '(${widget.payment.methodLabel}) du '
            '${platformDay(widget.payment.receivedOn)}.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('platform-refund-amount'),
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Montant à rembourser',
              suffixText: '€',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('platform-refund-method'),
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Comment'),
            items: [
              if (widget.payment.refundableByCard)
                const DropdownMenuItem(
                  value: 'carte',
                  child: Text('Sur la carte, par Stripe'),
                ),
              for (final entry in platformPaymentMethods.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Text('${entry.value} (déjà fait de ton côté)'),
                ),
            ],
            onChanged: (value) => setState(() => _method = value ?? _method),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('platform-refund-reason'),
            controller: _reason,
            maxLength: 300,
            decoration: const InputDecoration(labelText: 'Motif'),
          ),
          const Text(
            'Un avoir est émis pour la facture du paiement. L’accès du club '
            'n’est pas modifié : suspends-le à part si besoin.',
            style: TextStyle(fontSize: 12, color: AppTheme.textFaint),
          ),
        ],
      );
}

class _TermsDialog extends StatefulWidget {
  const _TermsDialog({
    required this.team,
    required this.billing,
    required this.repository,
  });

  final PlatformTeam team;
  final PlatformBilling billing;
  final PlatformBillingRepository repository;

  @override
  State<_TermsDialog> createState() => _TermsDialogState();
}

class _TermsDialogState extends _ActionDialogState<_TermsDialog> {
  late final _price = TextEditingController(
    text: centsToInput(widget.billing.basePriceCents ?? 7900),
  );
  late final _notes = TextEditingController(text: widget.billing.notes ?? '');

  @override
  void dispose() {
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final cents = parseEurosToCents(_price.text);
    if (cents == null) {
      setState(() => error = 'Tarif illisible. Exemple : 79 ou 59,50.');
      return;
    }
    run(() async {
      await widget.repository.setClubTerms(
        clubId: widget.team.id,
        basePriceCents: cents,
        notes: _notes.text,
      );
      return true;
    });
  }

  @override
  Widget build(BuildContext context) => dialog(
        title: 'Tarif et note · ${widget.team.name}',
        saveKey: const Key('platform-terms-save'),
        saveLabel: 'Enregistrer',
        onSave: _save,
        children: [
          TextField(
            key: const Key('platform-terms-price'),
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Tarif annuel de ce club',
              suffixText: '€',
              helperText: 'Avant parrainage. Devis particulier, association…',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('platform-terms-notes'),
            controller: _notes,
            maxLength: 2000,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Note interne (visible par toi seul)',
            ),
          ),
        ],
      );
}

class _BillingDetailsDialog extends StatefulWidget {
  const _BillingDetailsDialog({
    required this.team,
    required this.billing,
    required this.repository,
  });

  final PlatformTeam team;
  final PlatformBilling billing;
  final PlatformBillingRepository repository;

  @override
  State<_BillingDetailsDialog> createState() => _BillingDetailsDialogState();
}

class _BillingDetailsDialogState
    extends _ActionDialogState<_BillingDetailsDialog> {
  late final _name = TextEditingController(
    text: widget.billing.billingName ?? widget.team.name,
  );
  late final _address = TextEditingController(
    text: widget.billing.billingAddress ??
        widget.billing.contact.postalAddress ??
        '',
  );

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  void _save() => run(() async {
        await widget.repository.setClubBillingDetails(
          clubId: widget.team.id,
          name: _name.text,
          address: _address.text,
        );
        return true;
      });

  @override
  Widget build(BuildContext context) => dialog(
        title: 'Adresse de facturation · ${widget.team.name}',
        saveKey: const Key('platform-billing-details-save'),
        saveLabel: 'Enregistrer',
        onSave: _save,
        children: [
          const Text(
            'Imprimée sur les prochaines factures. Sans adresse saisie ici, '
            'l’adresse postale indiquée par le club est utilisée.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Nom facturé'),
          ),
          TextField(
            key: const Key('platform-billing-details-address'),
            controller: _address,
            maxLength: 300,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Adresse'),
          ),
        ],
      );
}

/// Jour à la française, dans le fuseau de l'appareil.
String platformDay(DateTime? date) {
  if (date == null) return 'date inconnue';
  final local = date.toClub();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}
