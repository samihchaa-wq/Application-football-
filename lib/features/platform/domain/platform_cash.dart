import 'package:petit_filet/features/billing/domain/invoice.dart';
import 'package:petit_filet/features/platform/domain/platform_billing.dart';
import 'package:petit_filet/features/platform/domain/platform_snapshot.dart';

/// Une ligne du registre de caisse : encaissement, remboursement ou période
/// offerte.
enum LedgerKind {
  payment,
  refund,
  gift;

  static LedgerKind parse(Object? value) => switch (value) {
        'refund' => refund,
        'gift' => gift,
        _ => payment,
      };
}

class PlatformLedgerEntry {
  const PlatformLedgerEntry({
    required this.kind,
    required this.id,
    required this.clubName,
    required this.amountCents,
    this.day,
    this.clubId,
    this.method,
    this.reference,
    this.label,
    this.feeCents = 0,
    this.refundedCents = 0,
    this.receiptUrl,
    this.documentNumber,
    this.documentIssued = false,
    this.periodLabel,
  });

  factory PlatformLedgerEntry.fromJson(Map<String, dynamic> json) =>
      PlatformLedgerEntry(
        kind: LedgerKind.parse(json['kind']),
        id: json['id'] as String? ?? '',
        day: _day(json['day']),
        clubId: json['club_id'] as String?,
        clubName: json['club_name'] as String? ?? 'Club',
        amountCents: (json['amount_cents'] as num?)?.toInt() ?? 0,
        method: json['method'] as String?,
        reference: json['reference'] as String?,
        label: json['label'] as String?,
        feeCents: (json['fee_cents'] as num?)?.toInt() ?? 0,
        refundedCents: (json['refunded_cents'] as num?)?.toInt() ?? 0,
        receiptUrl: json['receipt_url'] as String?,
        documentNumber: json['document_number'] as String?,
        documentIssued: json['document_status'] == 'issued',
        periodLabel: json['period_label'] as String?,
      );

  final LedgerKind kind;
  final String id;
  final DateTime? day;
  final String? clubId;
  final String clubName;

  /// Positif pour un encaissement, négatif pour un remboursement, nul pour
  /// une période offerte.
  final int amountCents;
  final String? method;
  final String? reference;

  /// Note du paiement, motif du remboursement ou de la période offerte.
  final String? label;
  final int feeCents;
  final int refundedCents;
  final String? receiptUrl;

  /// Numéro de facture (encaissement) ou d'avoir (remboursement).
  final String? documentNumber;
  final bool documentIssued;

  /// Pour un remboursement : la facture d'origine. Pour une période offerte :
  /// sa durée et sa fin.
  final String? periodLabel;

  String get methodLabel =>
      method == null ? '' : platformPaymentMethodLabels[method] ?? 'Autre';
}

class PlatformLedgerTotals {
  const PlatformLedgerTotals({
    this.collectedCents = 0,
    this.refundedCents = 0,
    this.feesCents = 0,
    this.netCents = 0,
    this.payments = 0,
    this.refunds = 0,
    this.gifts = 0,
    this.byMethod = const {},
  });

  factory PlatformLedgerTotals.fromJson(Map<String, dynamic> json) {
    int value(String key) => (json[key] as num?)?.toInt() ?? 0;
    final methods = json['by_method'];
    return PlatformLedgerTotals(
      collectedCents: value('collected_cents'),
      refundedCents: value('refunded_cents'),
      feesCents: value('fees_cents'),
      netCents: value('net_cents'),
      payments: value('payments'),
      refunds: value('refunds'),
      gifts: value('gifts'),
      byMethod: methods is Map
          ? {
              for (final entry in methods.entries)
                '${entry.key}': (entry.value as num?)?.toInt() ?? 0,
            }
          : const {},
    );
  }

  final int collectedCents;
  final int refundedCents;
  final int feesCents;
  final int netCents;
  final int payments;
  final int refunds;
  final int gifts;
  final Map<String, int> byMethod;
}

class PlatformLedger {
  const PlatformLedger({
    required this.from,
    required this.to,
    required this.entries,
    required this.totals,
  });

  factory PlatformLedger.fromJson(Map<String, dynamic> json) {
    final rows = json['entries'];
    final totals = json['totals'];
    return PlatformLedger(
      from: _day(json['from']) ?? DateTime(1970),
      to: _day(json['to']) ?? DateTime(1970),
      entries: rows is List
          ? rows
              .whereType<Map>()
              .map((row) =>
                  PlatformLedgerEntry.fromJson(Map<String, dynamic>.from(row)))
              .toList()
          : const [],
      totals: totals is Map
          ? PlatformLedgerTotals.fromJson(Map<String, dynamic>.from(totals))
          : const PlatformLedgerTotals(),
    );
  }

  final DateTime from;
  final DateTime to;
  final List<PlatformLedgerEntry> entries;
  final PlatformLedgerTotals totals;
}

/// Période affichée dans la Caisse : un mois ou une année civile.
class LedgerPeriod {
  const LedgerPeriod.month(this.year, this.month);
  const LedgerPeriod.year(this.year) : month = null;

  factory LedgerPeriod.current(DateTime now) =>
      LedgerPeriod.month(now.year, now.month);

  final int year;

  /// Null pour une année entière.
  final int? month;

  DateTime get from => DateTime(year, month ?? 1, 1);
  DateTime get to => month == null
      ? DateTime(year, 12, 31)
      : DateTime(year, month! + 1, 1).subtract(const Duration(days: 1));

  LedgerPeriod get previous => month == null
      ? LedgerPeriod.year(year - 1)
      : month == 1
          ? LedgerPeriod.month(year - 1, 12)
          : LedgerPeriod.month(year, month! - 1);

  LedgerPeriod get next => month == null
      ? LedgerPeriod.year(year + 1)
      : month == 12
          ? LedgerPeriod.month(year + 1, 1)
          : LedgerPeriod.month(year, month! + 1);

  LedgerPeriod get asYear => LedgerPeriod.year(year);
  LedgerPeriod asMonth(int value) => LedgerPeriod.month(year, value);

  String get label =>
      month == null ? 'Année $year' : '${_monthNames[month! - 1]} $year';

  /// Nom de fichier : « caisse-2026-11 » ou « caisse-2026 ».
  String get fileStem => month == null
      ? 'caisse-$year'
      : 'caisse-$year-${month.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is LedgerPeriod && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

const _monthNames = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

/// Registre de caisse au format tableur (CSV « ; » pour Excel en français) :
/// une ligne par mouvement, du plus ancien au plus récent, puis les totaux.
String ledgerToCsv(PlatformLedger ledger) {
  String cell(String value) => '"${value.replaceAll('"', '""')}"';
  String euros(int cents) {
    final sign = cents < 0 ? '-' : '';
    final value = cents.abs();
    return '$sign${value ~/ 100},${(value % 100).toString().padLeft(2, '0')}';
  }

  final rows = <String>[
    [
      'Date',
      'Type',
      'Club',
      'Montant (€)',
      'Moyen',
      'Référence',
      'Frais Stripe (€)',
      'Net (€)',
      'Facture ou avoir',
      'Détail',
    ].map(cell).join(';'),
    for (final entry in ledger.entries.reversed)
      [
        formatInvoiceDay(entry.day),
        switch (entry.kind) {
          LedgerKind.payment => 'Encaissement',
          LedgerKind.refund => 'Remboursement',
          LedgerKind.gift => 'Période offerte',
        },
        entry.clubName,
        euros(entry.amountCents),
        entry.methodLabel,
        entry.reference ?? '',
        entry.feeCents == 0 ? '' : euros(entry.feeCents),
        euros(entry.amountCents - entry.feeCents),
        entry.documentNumber ?? '',
        [
          if (entry.label != null) entry.label!,
          if (entry.periodLabel != null) entry.periodLabel!,
        ].join(' · '),
      ].map(cell).join(';'),
    '',
    [
      'Totaux',
      '',
      '',
      euros(ledger.totals.collectedCents),
      'encaissé',
      '',
      euros(ledger.totals.feesCents),
      euros(ledger.totals.netCents),
      '',
      'Remboursé : ${euros(ledger.totals.refundedCents)} €',
    ].map(cell).join(';'),
  ];
  return '﻿${rows.join('\r\n')}\r\n';
}

/// Alerte à traiter : paiement (contestation de carte…) ou copie AS Grinta
/// en échec.
class PlatformAlert {
  const PlatformAlert({
    required this.id,
    required this.kind,
    required this.message,
    this.clubName,
    this.amountCents,
    this.updatedAt,
  });

  factory PlatformAlert.fromJson(Map<String, dynamic> json) => PlatformAlert(
        id: json['id'] as String? ?? '',
        kind: json['kind'] as String? ?? 'other',
        message: json['message'] as String? ?? '',
        clubName: json['club_name'] as String?,
        amountCents: (json['amount_cents'] as num?)?.toInt(),
        updatedAt: measuredDate(json['updated_at']),
      );

  final String id;
  final String kind;
  final String message;
  final String? clubName;
  final int? amountCents;
  final DateTime? updatedAt;

  String get title => switch (kind) {
        'dispute' => 'Contestation de carte',
        'refund_unmatched' => 'Remboursement Stripe inconnu',
        'payment_failed' => 'Paiement en échec',
        'sync_failed' => 'Copie AS Grinta en échec',
        _ => 'Alerte de paiement',
      };
}

/// Paiement par carte récent, pour « À faire ».
class PlatformRecentCardPayment {
  const PlatformRecentCardPayment({
    required this.clubName,
    required this.amountCents,
    this.clubId,
    this.createdAt,
  });

  factory PlatformRecentCardPayment.fromJson(Map<String, dynamic> json) =>
      PlatformRecentCardPayment(
        clubId: json['club_id'] as String?,
        clubName: json['club_name'] as String? ?? 'Club',
        amountCents: (json['amount_cents'] as num?)?.toInt() ?? 0,
        createdAt: measuredDate(json['created_at']),
      );

  final String? clubId;
  final String clubName;
  final int amountCents;
  final DateTime? createdAt;
}

/// État des confirmations envoyées par Stripe.
class PlatformStripeStatus {
  const PlatformStripeStatus({
    this.lastEventAt,
    this.lastLivemode,
    this.events7d = 0,
    this.failures7d = 0,
    this.lastFailureType,
    this.lastFailureError,
    this.lastFailureAt,
  });

  factory PlatformStripeStatus.fromJson(Map<String, dynamic> json) {
    final failure = json['last_failure'];
    return PlatformStripeStatus(
      lastEventAt: measuredDate(json['last_event_at']),
      lastLivemode: json['last_livemode'] as bool?,
      events7d: (json['events_7d'] as num?)?.toInt() ?? 0,
      failures7d: (json['failures_7d'] as num?)?.toInt() ?? 0,
      lastFailureType: failure is Map ? failure['type'] as String? : null,
      lastFailureError: failure is Map ? failure['error'] as String? : null,
      lastFailureAt:
          failure is Map ? measuredDate(failure['received_at']) : null,
    );
  }

  final DateTime? lastEventAt;
  final bool? lastLivemode;
  final int events7d;
  final int failures7d;
  final String? lastFailureType;
  final String? lastFailureError;
  final DateTime? lastFailureAt;
}

class PlatformAlerts {
  const PlatformAlerts({
    this.alerts = const [],
    this.stripe = const PlatformStripeStatus(),
    this.cardPayments7d = const [],
    this.pendingInvoices = 0,
    this.pendingCreditNotes = 0,
  });

  factory PlatformAlerts.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) {
      final rows = json[key];
      return rows is List
          ? rows
              .whereType<Map>()
              .map((row) => parse(Map<String, dynamic>.from(row)))
              .toList()
          : <T>[];
    }

    final stripe = json['stripe'];
    return PlatformAlerts(
      alerts: list('alerts', PlatformAlert.fromJson),
      stripe: stripe is Map
          ? PlatformStripeStatus.fromJson(Map<String, dynamic>.from(stripe))
          : const PlatformStripeStatus(),
      cardPayments7d:
          list('card_payments_7d', PlatformRecentCardPayment.fromJson),
      pendingInvoices: (json['pending_invoices'] as num?)?.toInt() ?? 0,
      pendingCreditNotes: (json['pending_credit_notes'] as num?)?.toInt() ?? 0,
    );
  }

  final List<PlatformAlert> alerts;
  final PlatformStripeStatus stripe;
  final List<PlatformRecentCardPayment> cardPayments7d;
  final int pendingInvoices;
  final int pendingCreditNotes;
}

/// Offre commerciale : tarif des nouveaux clubs, parrainage, essai.
class PlatformBillingSettings {
  const PlatformBillingSettings({
    required this.basePriceCents,
    required this.referralRatePercent,
    required this.referralCapPercent,
    required this.trialDays,
    this.updatedAt,
  });

  factory PlatformBillingSettings.fromJson(Map<String, dynamic> json) =>
      PlatformBillingSettings(
        basePriceCents: (json['base_price_cents'] as num?)?.toInt() ?? 7900,
        referralRatePercent:
            (json['referral_rate_percent'] as num?)?.toInt() ?? 5,
        referralCapPercent:
            (json['referral_cap_percent'] as num?)?.toInt() ?? 100,
        trialDays: (json['trial_days'] as num?)?.toInt() ?? 30,
        updatedAt: measuredDate(json['updated_at']),
      );

  final int basePriceCents;
  final int referralRatePercent;
  final int referralCapPercent;
  final int trialDays;
  final DateTime? updatedAt;

  /// Valeurs des conditions d'abonnement publiées (version 2026-11-19).
  bool get matchesPublishedTerms =>
      basePriceCents == 7900 &&
      referralRatePercent == 5 &&
      referralCapPercent == 100 &&
      trialDays == 30;
}

/// Avoir (remboursement facturé), pour son PDF.
class CreditNote {
  const CreditNote({
    required this.id,
    required this.amountCents,
    required this.method,
    required this.seller,
    this.number,
    this.issuedOn,
    this.refundedOn,
    this.reason,
    this.invoiceNumber,
    this.buyerName,
    this.buyerAddress,
  });

  factory CreditNote.fromJson(Map<String, dynamic> json) {
    final seller = json['seller'];
    return CreditNote(
      id: json['id'] as String? ?? '',
      number: json['number'] as String?,
      issuedOn: _day(json['issued_on']),
      refundedOn: _day(json['refunded_on']),
      amountCents: (json['amount_cents'] as num?)?.toInt() ?? 0,
      method: json['method'] as String? ?? 'autre',
      reason: json['reason'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      buyerName: json['buyer_name'] as String?,
      buyerAddress: json['buyer_address'] as String?,
      seller: InvoiceSeller.fromJson(
        seller is Map ? Map<String, dynamic>.from(seller) : const {},
      ),
    );
  }

  final String id;
  final String? number;
  final DateTime? issuedOn;
  final DateTime? refundedOn;
  final int amountCents;
  final String method;
  final String? reason;
  final String? invoiceNumber;
  final String? buyerName;
  final String? buyerAddress;
  final InvoiceSeller seller;

  bool get isIssued => number != null;

  String get methodLabel =>
      invoicePaymentMethods[method] ?? invoicePaymentMethods['autre']!;

  String get fileName => 'avoir-${number ?? 'brouillon'}.pdf';
}

DateTime? _day(Object? value) {
  if (value is! String || value.length < 10) return null;
  final parsed = DateTime.tryParse(value.substring(0, 10));
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}
