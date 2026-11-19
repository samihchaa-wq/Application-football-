import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:petit_filet/features/billing/domain/invoice.dart';
import 'package:petit_filet/features/platform/domain/platform_cash.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Mention obligatoire d'une micro-entreprise en franchise de TVA.
const invoiceVatMention = 'TVA non applicable, art. 293 B du CGI';

/// Mentions de retard obligatoires entre professionnels, même pour une
/// facture déjà payée.
const invoiceLatePaymentMention =
    'En cas de retard de paiement : pénalités au taux de trois fois le taux '
    'd’intérêt légal et indemnité forfaitaire de 40 € pour frais de '
    'recouvrement (art. L441-10 et D441-5 du Code de commerce). '
    'Pas d’escompte pour paiement anticipé.';

/// Construit le PDF d'une facture. Une facture en attente (sans numéro) est
/// toujours marquée « BROUILLON » et ne vaut pas facture.
Future<Uint8List> buildInvoicePdf(Invoice invoice) async {
  final draft = !invoice.isIssued;
  // Les polices standard du PDF n'ont ni « € » ni « ’ » : police embarquée.
  final font =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: font),
    title: draft ? 'Facture (brouillon)' : 'Facture ${invoice.number}',
    author: invoice.seller.name,
  );
  const ink = PdfColor.fromInt(0xFF1F2328);
  const faint = PdfColor.fromInt(0xFF656D76);
  const line = PdfColor.fromInt(0xFFD0D7DE);
  final small = pw.TextStyle(fontSize: 9, color: faint);
  final body = const pw.TextStyle(fontSize: 10.5, color: ink);

  pw.Widget block(String title, List<String> lines) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title.toUpperCase(), style: small.copyWith(letterSpacing: 1)),
          pw.SizedBox(height: 4),
          for (final text in lines.where((text) => text.trim().isNotEmpty))
            pw.Text(text, style: body),
        ],
      );

  final seller = invoice.seller;
  final total = formatInvoiceAmount(invoice.amountCents);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 48, 48, 40),
      build: (context) => pw.Stack(
        children: [
          if (draft)
            pw.Positioned.fill(
              child: pw.Center(
                child: pw.Transform.rotate(
                  angle: 0.6,
                  child: pw.Opacity(
                    opacity: 0.12,
                    child: pw.Text(
                      'BROUILLON',
                      style: const pw.TextStyle(fontSize: 80, color: ink),
                    ),
                  ),
                ),
              ),
            ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: block('Vendeur', [
                      seller.name,
                      seller.address,
                      if (seller.siret.isNotEmpty)
                        'SIRET : ${seller.formattedSiret}',
                      seller.email,
                    ]),
                  ),
                  pw.SizedBox(width: 24),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        draft ? 'FACTURE (BROUILLON)' : 'FACTURE',
                        style: const pw.TextStyle(fontSize: 22, color: ink),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        draft
                            ? 'Numéro attribué à l’émission'
                            : 'N° ${invoice.number}',
                        style: body,
                      ),
                      pw.Text(
                        'Date : ${formatInvoiceDay(invoice.issuedOn ?? DateTime.now())}',
                        style: body,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              block('Client', [
                invoice.buyerName ?? '',
                invoice.buyerAddress ?? '[adresse du club à compléter]',
              ]),
              pw.SizedBox(height: 32),
              pw.Table(
                border: const pw.TableBorder(
                  top: pw.BorderSide(color: line),
                  bottom: pw.BorderSide(color: line),
                  horizontalInside: pw.BorderSide(color: line),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(4),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1.4),
                },
                children: [
                  pw.TableRow(
                    children: [
                      for (final title in [
                        'Désignation',
                        'Quantité',
                        'Montant'
                      ])
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6),
                          child: pw.Text(title, style: small),
                        ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(invoice.description, style: body),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Période du ${formatInvoiceDay(invoice.periodStart)} '
                              'au ${formatInvoiceDay(invoice.periodEnd)}',
                              style: small,
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8),
                        child: pw.Text('1', style: body),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8),
                        child: pw.Text(total, style: body),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Total HT : $total', style: body),
                    pw.Text(invoiceVatMention, style: small),
                    pw.SizedBox(height: 4),
                    pw.Text('Net à payer : $total',
                        style: const pw.TextStyle(fontSize: 14, color: ink)),
                  ],
                ),
              ),
              pw.SizedBox(height: 28),
              block('Règlement', [
                'Facture acquittée le ${formatInvoiceDay(invoice.receivedOn)} '
                    'par ${invoice.paymentMethodLabel.toLowerCase()}.',
              ]),
              pw.Spacer(),
              pw.Text(invoiceLatePaymentMention, style: small),
              if (draft) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  'Aperçu sans valeur de facture : le numéro est attribué '
                  'quand la facture est émise.',
                  style: small,
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
  return doc.save();
}

/// Construit le PDF d'un avoir : remboursement d'une facture émise.
Future<Uint8List> buildCreditNotePdf(CreditNote note) async {
  final font =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: font),
    title: 'Avoir ${note.number ?? ''}',
    author: note.seller.name,
  );
  const ink = PdfColor.fromInt(0xFF1F2328);
  const faint = PdfColor.fromInt(0xFF656D76);
  const line = PdfColor.fromInt(0xFFD0D7DE);
  final small = pw.TextStyle(fontSize: 9, color: faint);
  final body = const pw.TextStyle(fontSize: 10.5, color: ink);

  pw.Widget block(String title, List<String> lines) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title.toUpperCase(), style: small.copyWith(letterSpacing: 1)),
          pw.SizedBox(height: 4),
          for (final text in lines.where((text) => text.trim().isNotEmpty))
            pw.Text(text, style: body),
        ],
      );

  final seller = note.seller;
  final total = '−${formatInvoiceAmount(note.amountCents)}';
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 48, 48, 40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: block('Vendeur', [
                  seller.name,
                  seller.address,
                  if (seller.siret.isNotEmpty)
                    'SIRET : ${seller.formattedSiret}',
                  seller.email,
                ]),
              ),
              pw.SizedBox(width: 24),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('AVOIR',
                      style: const pw.TextStyle(fontSize: 22, color: ink)),
                  pw.SizedBox(height: 6),
                  pw.Text('N° ${note.number ?? ''}', style: body),
                  pw.Text(
                    'Date : ${formatInvoiceDay(note.issuedOn ?? DateTime.now())}',
                    style: body,
                  ),
                  if (note.invoiceNumber != null)
                    pw.Text('Facture d’origine : ${note.invoiceNumber}',
                        style: body),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 32),
          block('Client', [note.buyerName ?? '', note.buyerAddress ?? '']),
          pw.SizedBox(height: 32),
          pw.Table(
            border: const pw.TableBorder(
              top: pw.BorderSide(color: line),
              bottom: pw.BorderSide(color: line),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(4),
              1: pw.FlexColumnWidth(1.4),
            },
            children: [
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Remboursement sur la facture '
                        '${note.invoiceNumber ?? ''}',
                        style: body,
                      ),
                      if (note.reason != null && note.reason!.isNotEmpty)
                        pw.Text(note.reason!, style: small),
                    ],
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Text(total, style: body),
                ),
              ]),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Total HT : $total', style: body),
                pw.Text(invoiceVatMention, style: small),
                pw.SizedBox(height: 4),
                pw.Text('Montant remboursé : $total',
                    style: const pw.TextStyle(fontSize: 14, color: ink)),
              ],
            ),
          ),
          pw.SizedBox(height: 28),
          block('Remboursement', [
            'Remboursé le ${formatInvoiceDay(note.refundedOn)} '
                'par ${note.methodLabel.toLowerCase()}.',
          ]),
        ],
      ),
    ),
  );
  return doc.save();
}
