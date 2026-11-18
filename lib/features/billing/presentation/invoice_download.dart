import 'dart:convert';
import 'dart:typed_data';

import 'package:petit_filet/features/billing/domain/invoice.dart';
// Chargé à la demande : la bibliothèque PDF reste hors du bundle principal
// (budget de téléchargement de l'appli web).
import 'package:petit_filet/features/billing/domain/invoice_pdf.dart'
    deferred as invoice_pdf;
import 'package:share_plus/share_plus.dart';

/// Propose le fichier à l'utilisateur : téléchargement sur le web, feuille de
/// partage sur téléphone.
typedef FileSaver = Future<void> Function(
  Uint8List bytes,
  String name,
  String mimeType,
);

Future<void> shareFile(Uint8List bytes, String name, String mimeType) async {
  await Share.shareXFiles(
    [XFile.fromData(bytes, mimeType: mimeType, name: name)],
    fileNameOverrides: [name],
  );
}

Future<void> downloadInvoicePdf(
  Invoice invoice, {
  FileSaver save = shareFile,
}) async {
  await invoice_pdf.loadLibrary();
  final bytes = await invoice_pdf.buildInvoicePdf(invoice);
  await save(bytes, invoice.fileName, 'application/pdf');
}

Future<void> downloadInvoicesCsv(
  List<Invoice> invoices, {
  FileSaver save = shareFile,
}) async {
  final bytes = Uint8List.fromList(utf8.encode(invoicesToCsv(invoices)));
  await save(bytes, 'livre-des-recettes.csv', 'text/csv');
}
