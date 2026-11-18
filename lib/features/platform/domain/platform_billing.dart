import 'package:petit_filet/features/platform/domain/platform_snapshot.dart';

/// Moyens de paiement hors ligne acceptés par le serveur.
const platformPaymentMethods = <String, String>{
  'virement': 'Virement',
  'cheque': 'Chèque',
  'especes': 'Espèces',
  'autre': 'Autre',
};

/// Un paiement reçu hors ligne, noté par l'éditeur.
class PlatformPayment {
  const PlatformPayment({
    required this.amountCents,
    required this.method,
    this.receivedOn,
    this.periodEnd,
    this.note,
  });

  factory PlatformPayment.fromJson(Map<String, dynamic> json) =>
      PlatformPayment(
        amountCents: measuredCount(json['amount_cents']) ?? 0,
        method: json['method'] as String? ?? 'autre',
        receivedOn: measuredDate(json['received_on']),
        periodEnd: measuredDate(json['period_end']),
        note: json['note'] as String?,
      );

  final int amountCents;
  final String method;
  final DateTime? receivedOn;
  final DateTime? periodEnd;
  final String? note;

  String get methodLabel => platformPaymentMethods[method] ?? 'Autre';
}

/// Fiche de facturation d'une équipe dans la console de l'éditeur.
class PlatformBilling {
  const PlatformBilling({
    required this.payments,
    this.basePriceCents,
    this.suspensionOn,
    this.autoSuspendedAt,
  });

  factory PlatformBilling.fromJson(Map<String, dynamic> json) {
    final rows = json['payments'];
    return PlatformBilling(
      basePriceCents: measuredCount(json['base_price_cents']),
      suspensionOn: measuredDate(json['suspension_on']),
      autoSuspendedAt: measuredDate(json['auto_suspended_at']),
      payments: rows is List
          ? rows
              .whereType<Map>()
              .map((row) =>
                  PlatformPayment.fromJson(Map<String, dynamic>.from(row)))
              .toList()
          : const [],
    );
  }

  /// Forfait annuel du club, proposé par défaut comme montant reçu.
  final int? basePriceCents;

  /// Date à partir de laquelle le club sera suspendu s'il ne paie pas.
  final DateTime? suspensionOn;

  /// Renseignée quand le club a été suspendu automatiquement pour impayé.
  final DateTime? autoSuspendedAt;
  final List<PlatformPayment> payments;
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
