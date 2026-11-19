import 'package:petit_filet/features/billing/domain/invoice.dart';
import 'package:petit_filet/features/billing/domain/invoice_pdf.dart';
import 'package:petit_filet/features/platform/domain/platform_cash.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> issuedRow({String number = 'PF-2027-0001'}) => {
      'id': 'inv-1',
      'club_id': 'club-a',
      'status': 'issued',
      'number': number,
      'issued_on': '2027-01-05',
      'amount_cents': 7900,
      'payment_method': 'virement',
      'received_on': '2027-01-04',
      'period_start': '2027-01-04',
      'period_end': '2028-01-04',
      'description': 'Abonnement annuel à l’application PetitFilet pour le '
          'club « FC "Test" »',
      'seller': {
        'name': 'Prénom NOM EI',
        'address': '1 rue du Test, 31000 Toulouse',
        'siret': '12345678900012',
        'email': 'contact@example.invalid',
      },
      'buyer_name': 'Association Test',
      'buyer_address': '2 place du Stade, 31150 Bruguières',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lit une facture émise de la base', () {
    final invoice = Invoice.fromJson(issuedRow());
    expect(invoice.isIssued, isTrue);
    expect(invoice.issuedOn, DateTime(2027, 1, 5));
    expect(invoice.seller.formattedSiret, '123 456 789 00012');
    expect(invoice.paymentMethodLabel, 'Virement');
    expect(invoice.fileName, 'facture-PF-2027-0001.pdf');
  });

  test('une facture en attente n’a ni numéro ni nom de fichier définitif', () {
    final invoice = Invoice.fromJson({
      ...issuedRow(),
      'status': 'pending',
      'number': null,
      'issued_on': null,
      'blocker': 'seller',
    });
    expect(invoice.isIssued, isFalse);
    expect(invoice.blocker, InvoiceBlocker.seller);
    expect(invoice.fileName, 'facture-brouillon-2027-01-04.pdf');
  });

  test('montants à la française', () {
    expect(formatInvoiceAmount(7900), '79,00 €');
    expect(formatInvoiceAmount(123450), '1 234,50 €');
    expect(formatInvoiceAmount(0), '0,00 €');
  });

  test('livre des recettes : factures émises seulement, dans l’ordre', () {
    final csv = invoicesToCsv([
      Invoice.fromJson(issuedRow(number: 'PF-2027-0002')),
      Invoice.fromJson({...issuedRow(), 'status': 'pending', 'number': null}),
      Invoice.fromJson(issuedRow()),
    ]);
    final lines = csv.substring(1).trim().split('\r\n');
    expect(csv.startsWith('﻿'), isTrue);
    expect(lines, hasLength(3));
    expect(lines[1], startsWith('"PF-2027-0001";"05/01/2027";"04/01/2027"'));
    expect(lines[2], startsWith('"PF-2027-0002"'));
    expect(lines[1], contains('FC ""Test""'));
    expect(lines[1], endsWith('"79,00";"Virement"'));
  });

  test('le PDF se construit pour une facture émise et un brouillon', () async {
    for (final row in [
      issuedRow(),
      {...issuedRow(), 'status': 'pending', 'number': null, 'seller': {}},
    ]) {
      final bytes = await buildInvoicePdf(Invoice.fromJson(row));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    }
  });

  test('le PDF d’un avoir se construit et renvoie à sa facture', () async {
    final note = CreditNote.fromJson({
      'id': 'r1',
      'number': 'AV-2027-0001',
      'issued_on': '2027-02-01',
      'refunded_on': '2027-02-01',
      'amount_cents': 2900,
      'method': 'carte',
      'reason': 'Geste commercial',
      'invoice_number': 'PF-2027-0001',
      'buyer_name': 'Association Test',
      'buyer_address': '2 place du Stade, 31150 Bruguières',
      'seller': issuedRow()['seller'],
    });
    expect(note.fileName, 'avoir-AV-2027-0001.pdf');
    expect(note.methodLabel, 'Carte bancaire');
    final bytes = await buildCreditNotePdf(note);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });
}
