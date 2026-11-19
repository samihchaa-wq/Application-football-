/// Facture d'un abonnement payé, telle que la base la conserve.
///
/// Une facture émise est définitive : numéro, vendeur et client y sont figés.
/// Une facture en attente (SIRET ou adresse du club manquants) n'a pas de
/// numéro ; l'éditeur en voit un aperçu marqué « brouillon ».
class Invoice {
  const Invoice({
    required this.id,
    required this.status,
    required this.amountCents,
    required this.paymentMethod,
    required this.receivedOn,
    required this.periodStart,
    required this.periodEnd,
    required this.description,
    required this.seller,
    this.clubId,
    this.number,
    this.issuedOn,
    this.buyerName,
    this.buyerAddress,
    this.blocker,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final seller = json['seller'];
    return Invoice(
      id: json['id'] as String,
      clubId: json['club_id'] as String?,
      status: json['status'] == 'issued'
          ? InvoiceStatus.issued
          : InvoiceStatus.pending,
      number: json['number'] as String?,
      issuedOn: _day(json['issued_on']),
      amountCents: (json['amount_cents'] as num?)?.toInt() ?? 0,
      paymentMethod: json['payment_method'] as String? ?? 'autre',
      receivedOn: _day(json['received_on']) ?? DateTime(1970),
      periodStart: _day(json['period_start']) ?? DateTime(1970),
      periodEnd: _day(json['period_end']) ?? DateTime(1970),
      description: json['description'] as String? ?? '',
      seller: InvoiceSeller.fromJson(
        seller is Map ? Map<String, dynamic>.from(seller) : const {},
      ),
      buyerName: json['buyer_name'] as String?,
      buyerAddress: json['buyer_address'] as String?,
      blocker: InvoiceBlocker.parse(json['blocker']),
    );
  }

  final String id;
  final String? clubId;
  final InvoiceStatus status;
  final String? number;
  final DateTime? issuedOn;
  final int amountCents;
  final String paymentMethod;
  final DateTime receivedOn;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String description;
  final InvoiceSeller seller;
  final String? buyerName;
  final String? buyerAddress;

  /// Ce qui empêche d'émettre une facture en attente.
  final InvoiceBlocker? blocker;

  bool get isIssued => status == InvoiceStatus.issued && number != null;

  String get paymentMethodLabel =>
      invoicePaymentMethods[paymentMethod] ?? invoicePaymentMethods['autre']!;

  /// Nom du fichier PDF proposé au téléchargement.
  String get fileName => isIssued
      ? 'facture-$number.pdf'
      : 'facture-brouillon-${_iso(receivedOn)}.pdf';
}

enum InvoiceStatus { pending, issued }

enum InvoiceBlocker {
  /// Coordonnées de l'éditeur (dont le SIRET) incomplètes.
  seller,

  /// Adresse de facturation du club manquante.
  buyerAddress,

  /// Club supprimé avant l'émission.
  clubDeleted;

  static InvoiceBlocker? parse(Object? value) => switch (value) {
        'seller' => seller,
        'buyer_address' => buyerAddress,
        'club_deleted' => clubDeleted,
        _ => null,
      };

  String get label => switch (this) {
        seller => 'En attente de tes coordonnées (dont le SIRET)',
        buyerAddress => 'En attente de l’adresse du club',
        clubDeleted => 'Club supprimé : facture à écarter',
      };
}

/// Coordonnées du vendeur imprimées sur la facture.
class InvoiceSeller {
  const InvoiceSeller({
    this.name = '',
    this.address = '',
    this.siret = '',
    this.email = '',
  });

  factory InvoiceSeller.fromJson(Map<String, dynamic> json) => InvoiceSeller(
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        siret: json['siret'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );

  final String name;
  final String address;
  final String siret;
  final String email;

  /// SIRET lisible : 123 456 789 00012.
  String get formattedSiret => siret.length == 14
      ? '${siret.substring(0, 3)} ${siret.substring(3, 6)} '
          '${siret.substring(6, 9)} ${siret.substring(9)}'
      : siret;
}

/// Coordonnées de l'éditeur, modifiables dans la console.
class InvoiceSettings {
  const InvoiceSettings({
    required this.sellerName,
    required this.sellerAddress,
    required this.siret,
    required this.contactEmail,
    required this.ready,
  });

  factory InvoiceSettings.fromJson(Map<String, dynamic> json) =>
      InvoiceSettings(
        sellerName: json['seller_name'] as String? ?? '',
        sellerAddress: json['seller_address'] as String? ?? '',
        siret: json['siret'] as String? ?? '',
        contactEmail: json['contact_email'] as String? ?? '',
        ready: json['ready'] == true,
      );

  final String sellerName;
  final String sellerAddress;
  final String siret;
  final String contactEmail;

  /// Vrai quand toutes les coordonnées, dont un SIRET valide, sont saisies.
  final bool ready;
}

const invoicePaymentMethods = <String, String>{
  'virement': 'Virement',
  'cheque': 'Chèque',
  'especes': 'Espèces',
  'autre': 'Autre',
  'carte': 'Carte bancaire',
};

/// Montant à la française : « 79,00 € », « 1 234,50 € ».
String formatInvoiceAmount(int cents) {
  final euros = (cents ~/ 100).toString();
  final grouped = StringBuffer();
  for (var i = 0; i < euros.length; i++) {
    if (i > 0 && (euros.length - i) % 3 == 0) grouped.write(' ');
    grouped.write(euros[i]);
  }
  return '$grouped,${(cents % 100).toString().padLeft(2, '0')} €';
}

/// Jour à la française : 18/11/2026.
String formatInvoiceDay(DateTime? day) {
  if (day == null) return '';
  return '${day.day.toString().padLeft(2, '0')}/'
      '${day.month.toString().padLeft(2, '0')}/${day.year}';
}

/// Livre des recettes au format tableur (CSV, séparateur « ; » pour Excel
/// en français) : une ligne par facture émise, dans l'ordre des numéros.
String invoicesToCsv(Iterable<Invoice> invoices) {
  String cell(String value) => '"${value.replaceAll('"', '""')}"';
  final issued = invoices.where((invoice) => invoice.isIssued).toList()
    ..sort((a, b) => a.number!.compareTo(b.number!));
  final rows = <String>[
    [
      'Numéro',
      'Date de facture',
      'Date d’encaissement',
      'Client',
      'Désignation',
      'Période du',
      'Période au',
      'Montant (€)',
      'Mode de paiement',
    ].map(cell).join(';'),
    for (final invoice in issued)
      [
        invoice.number!,
        formatInvoiceDay(invoice.issuedOn),
        formatInvoiceDay(invoice.receivedOn),
        invoice.buyerName ?? '',
        invoice.description,
        formatInvoiceDay(invoice.periodStart),
        formatInvoiceDay(invoice.periodEnd),
        '${invoice.amountCents ~/ 100},'
            '${(invoice.amountCents % 100).toString().padLeft(2, '0')}',
        invoice.paymentMethodLabel,
      ].map(cell).join(';'),
  ];
  // Marque d'ordre des octets : Excel lit alors les accents correctement.
  return '﻿${rows.join('\r\n')}\r\n';
}

DateTime? _day(Object? value) {
  if (value is! String || value.length < 10) return null;
  final parsed = DateTime.tryParse(value.substring(0, 10));
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

String _iso(DateTime day) => '${day.year}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
