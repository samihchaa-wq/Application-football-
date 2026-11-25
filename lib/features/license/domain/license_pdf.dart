import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:petit_filet/features/license/domain/license_models.dart';

/// Construit l'attestation de licence (une page A4), sur le modèle de
/// l'attestation papier du club : en-tête du club, titre, phrase de
/// certification, montant de la cotisation, signature du président.
Future<Uint8List> buildLicenseAttestationPdf(
  LicenseAttestation data,
) async {
  // Les polices standard du PDF n'ont ni « € » ni « ’ » : police embarquée
  // (Lora, serif comme l'attestation papier).
  final regular =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Lora-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Lora-Bold.ttf'));
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    title: 'Attestation de licence',
    author: data.clubName,
  );
  const ink = PdfColors.black;
  final body = const pw.TextStyle(fontSize: 12, color: ink, lineSpacing: 3);
  final strong =
      pw.TextStyle(fontSize: 12, color: ink, fontWeight: pw.FontWeight.bold);

  final numberPart = data.licenseNumber.trim().isEmpty
      ? ''
      : ' sous le n°${data.licenseNumber.trim()}';
  final leaguePart =
      data.leagueName.trim().isEmpty ? '' : ' de la ${data.leagueName.trim()}';
  final seasonPart = data.seasonName.trim().isEmpty
      ? ''
      : ' pour la saison ${data.seasonName.trim()}';
  final president = data.presidentName.trim().isEmpty
      ? 'le Président'
      : 'M. ${data.presidentName.trim()}, Président';

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(56, 56, 56, 48),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              '${data.city.trim().isEmpty ? '' : '${data.city.trim()} le '}'
              '${formatLongFrenchDate(data.date)}',
              style: body,
            ),
          ),
          pw.SizedBox(height: 28),
          pw.Text(data.clubName, style: strong),
          if (data.clubNumber.trim().isNotEmpty)
            pw.Text('Club n°${data.clubNumber.trim()}', style: strong),
          if (data.clubAddress.trim().isNotEmpty)
            pw.Text(data.clubAddress.trim(), style: strong),
          if (data.clubEmail.trim().isNotEmpty)
            pw.Text(data.clubEmail.trim(), style: strong),
          pw.SizedBox(height: 56),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(data.playerName, style: body),
          ),
          pw.SizedBox(height: 70),
          pw.Center(
            child: pw.Text(
              'ATTESTATION DE LICENCE',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: ink,
              ),
            ),
          ),
          pw.SizedBox(height: 56),
          pw.RichText(
            text: pw.TextSpan(
              style: body,
              children: [
                pw.TextSpan(
                  text: 'Je soussigné $president de ${data.clubName}, '
                      'certifie que ',
                ),
                pw.TextSpan(text: data.playerName, style: strong),
                pw.TextSpan(
                  text: ' est licencié dans notre club$numberPart$leaguePart'
                      '$seasonPart.',
                ),
              ],
            ),
          ),
          if (data.amountCents != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                'Montant de la cotisation annuelle : '
                '${formatLicenseAmount(data.amountCents)}',
                style: body,
              ),
            ),
          pw.SizedBox(height: 56),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 200),
            child: pw.Container(
              height: 90,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              alignment: pw.Alignment.topLeft,
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Cachet et signature',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  return doc.save();
}
