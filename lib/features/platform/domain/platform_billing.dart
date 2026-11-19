import 'package:petit_filet/features/platform/domain/platform_snapshot.dart';

/// Moyens de paiement hors ligne acceptés par le serveur.
const platformPaymentMethods = <String, String>{
  'virement': 'Virement',
  'cheque': 'Chèque',
  'especes': 'Espèces',
  'autre': 'Autre',
};

/// Libellés de tous les moyens, y compris la carte (venue de Stripe, jamais
/// notée à la main).
const platformPaymentMethodLabels = <String, String>{
  ...platformPaymentMethods,
  'carte': 'Carte (Stripe)',
};

/// Un paiement reçu (hors ligne ou par carte).
class PlatformPayment {
  const PlatformPayment({
    required this.amountCents,
    required this.method,
    this.id,
    this.receivedOn,
    this.periodEnd,
    this.note,
    this.reference,
    this.stripeFeeCents,
    this.receiptUrl,
    this.refundedCents = 0,
    this.refundableByCard = false,
    this.invoiceNumber,
    this.invoiceIssued = false,
  });

  factory PlatformPayment.fromJson(Map<String, dynamic> json) =>
      PlatformPayment(
        id: json['id'] as String?,
        amountCents: measuredCount(json['amount_cents']) ?? 0,
        method: json['method'] as String? ?? 'autre',
        receivedOn: measuredDate(json['received_on']),
        periodEnd: measuredDate(json['period_end']),
        note: json['note'] as String?,
        reference: json['reference'] as String?,
        stripeFeeCents: measuredCount(json['stripe_fee_cents']),
        receiptUrl: json['stripe_receipt_url'] as String?,
        refundedCents: measuredCount(json['refunded_cents']) ?? 0,
        refundableByCard: json['refundable_by_card'] == true,
        invoiceNumber: json['invoice_number'] as String?,
        invoiceIssued: json['invoice_status'] == 'issued',
      );

  final String? id;
  final int amountCents;
  final String method;
  final DateTime? receivedOn;
  final DateTime? periodEnd;
  final String? note;

  /// Numéro de chèque et banque, référence du virement…
  final String? reference;
  final int? stripeFeeCents;
  final String? receiptUrl;
  final int refundedCents;

  /// Vrai si le paiement peut être remboursé sur la carte, par Stripe.
  final bool refundableByCard;
  final String? invoiceNumber;
  final bool invoiceIssued;

  String get methodLabel => platformPaymentMethodLabels[method] ?? 'Autre';

  int get refundableCents => amountCents - refundedCents;
  bool get isCard => method == 'carte';
}

/// Remboursement noté sur un paiement.
class PlatformRefund {
  const PlatformRefund({
    required this.amountCents,
    required this.method,
    this.id,
    this.paymentId,
    this.reason,
    this.refundedOn,
    this.creditNoteNumber,
  });

  factory PlatformRefund.fromJson(Map<String, dynamic> json) => PlatformRefund(
        id: json['id'] as String?,
        paymentId: json['payment_id'] as String?,
        amountCents: measuredCount(json['amount_cents']) ?? 0,
        method: json['method'] as String? ?? 'autre',
        reason: json['reason'] as String?,
        refundedOn: measuredDate(json['refunded_on']),
        creditNoteNumber: json['credit_note_number'] as String?,
      );

  final String? id;
  final String? paymentId;
  final int amountCents;
  final String method;
  final String? reason;
  final DateTime? refundedOn;
  final String? creditNoteNumber;

  String get methodLabel => platformPaymentMethodLabels[method] ?? 'Autre';
}

/// Période offerte : mois gratuits ou essai prolongé.
class PlatformGrant {
  const PlatformGrant({
    required this.trialExtension,
    required this.months,
    required this.days,
    required this.reason,
    this.periodEnd,
    this.createdAt,
  });

  factory PlatformGrant.fromJson(Map<String, dynamic> json) => PlatformGrant(
        trialExtension: json['kind'] == 'trial_extension',
        months: measuredCount(json['months']) ?? 0,
        days: measuredCount(json['days']) ?? 0,
        reason: json['reason'] as String? ?? '',
        periodEnd: measuredDate(json['period_end']),
        createdAt: measuredDate(json['created_at']),
      );

  final bool trialExtension;
  final int months;
  final int days;
  final String reason;
  final DateTime? periodEnd;
  final DateTime? createdAt;

  String get durationLabel => formatGrantDuration(months, days);
}

/// « 3 mois », « 15 j », « 1 mois et 15 j ».
String formatGrantDuration(int months, int days) {
  final parts = [
    if (months > 0) '$months mois',
    if (days > 0) '$days j',
  ];
  return parts.join(' et ');
}

/// Coordonnées saisies par le club et administrateurs à contacter.
class PlatformClubContact {
  const PlatformClubContact({
    this.name,
    this.email,
    this.phone,
    this.postalAddress,
    this.website,
    this.registrationNumber,
  });

  factory PlatformClubContact.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final value = json[key]?.toString().trim() ?? '';
      return value.isEmpty ? null : value;
    }

    return PlatformClubContact(
      name: text('name'),
      email: text('email'),
      phone: text('phone'),
      postalAddress: text('postal_address'),
      website: text('website'),
      registrationNumber: text('registration_number'),
    );
  }

  final String? name;
  final String? email;
  final String? phone;
  final String? postalAddress;
  final String? website;
  final String? registrationNumber;

  bool get isEmpty =>
      name == null &&
      email == null &&
      phone == null &&
      postalAddress == null &&
      website == null &&
      registrationNumber == null;
}

class PlatformClubAdmin {
  const PlatformClubAdmin({required this.name, this.email});

  final String name;
  final String? email;
}

/// Fiche de facturation d'une équipe dans la console de l'éditeur.
class PlatformBilling {
  const PlatformBilling({
    required this.payments,
    this.basePriceCents,
    this.suspensionOn,
    this.autoSuspendedAt,
    this.referralDiscountPercent = 0,
    this.amountDueCents,
    this.subscriptionStatus,
    this.trialEndsAt,
    this.currentPeriodEnd,
    this.notes,
    this.billingName,
    this.billingAddress,
    this.contact = const PlatformClubContact(),
    this.admins = const [],
    this.refunds = const [],
    this.grants = const [],
  });

  factory PlatformBilling.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) {
      final rows = json[key];
      return rows is List
          ? rows
              .whereType<Map>()
              .map((row) => parse(Map<String, dynamic>.from(row)))
              .toList()
          : <T>[];
    }

    final contact = json['contact'];
    return PlatformBilling(
      basePriceCents: measuredCount(json['base_price_cents']),
      suspensionOn: measuredDate(json['suspension_on']),
      autoSuspendedAt: measuredDate(json['auto_suspended_at']),
      referralDiscountPercent:
          measuredCount(json['referral_discount_percent']) ?? 0,
      amountDueCents: measuredCount(json['amount_due_cents']),
      subscriptionStatus: json['subscription_status'] as String?,
      trialEndsAt: measuredDate(json['trial_ends_at']),
      currentPeriodEnd: measuredDate(json['current_period_end']),
      notes: json['notes'] as String?,
      billingName: json['billing_name'] as String?,
      billingAddress: json['billing_address'] as String?,
      contact: contact is Map
          ? PlatformClubContact.fromJson(Map<String, dynamic>.from(contact))
          : const PlatformClubContact(),
      admins: list(
        'admins',
        (row) => PlatformClubAdmin(
          name: row['name'] as String? ?? '',
          email: row['email'] as String?,
        ),
      ),
      payments: list('payments', PlatformPayment.fromJson),
      refunds: list('refunds', PlatformRefund.fromJson),
      grants: list('grants', PlatformGrant.fromJson),
    );
  }

  /// Forfait annuel du club, proposé par défaut comme montant reçu.
  final int? basePriceCents;

  /// Date à partir de laquelle le club sera suspendu s'il ne paie pas.
  final DateTime? suspensionOn;

  /// Renseignée quand le club a été suspendu automatiquement pour impayé.
  final DateTime? autoSuspendedAt;

  /// Réduction de parrainage acquise par le club (0 à 100).
  final int referralDiscountPercent;

  /// Montant à demander pour la prochaine année, réduction déduite.
  final int? amountDueCents;
  final String? subscriptionStatus;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodEnd;

  /// Note interne de l'éditeur sur ce club.
  final String? notes;
  final String? billingName;
  final String? billingAddress;
  final PlatformClubContact contact;
  final List<PlatformClubAdmin> admins;
  final List<PlatformPayment> payments;
  final List<PlatformRefund> refunds;
  final List<PlatformGrant> grants;

  bool get isTrial => subscriptionStatus == 'trialing';
}

/// Montant saisi en euros (« 79 », « 79,50 », « 79.5 ») converti en
/// centimes, ou null s'il est illisible.
int? parseEurosToCents(String input) {
  final text = input.replaceAll(RegExp(r'[\s€]'), '').replaceAll(',', '.');
  if (!RegExp(r'^\d{1,5}(\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.');
  final cents = parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0'));
  return int.parse(parts[0]) * 100 + cents;
}

/// Centimes affichés dans un champ de saisie : « 79 » ou « 79,50 ».
String centsToInput(int cents) => cents % 100 == 0
    ? '${cents ~/ 100}'
    : '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';
