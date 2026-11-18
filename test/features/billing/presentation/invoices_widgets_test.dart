import 'dart:typed_data';

import 'package:petit_filet/features/billing/data/invoice_repository.dart';
import 'package:petit_filet/features/billing/domain/invoice.dart';
import 'package:petit_filet/features/billing/presentation/club_invoices_list.dart';
import 'package:petit_filet/features/billing/presentation/platform_invoices_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Invoice invoice({
  String id = 'inv-1',
  String? number = 'PF-2027-0001',
  String? blocker,
}) =>
    Invoice.fromJson({
      'id': id,
      'club_id': 'club-a',
      'status': number == null ? 'pending' : 'issued',
      'number': number,
      'issued_on': number == null ? null : '2027-01-05',
      'amount_cents': 7900,
      'payment_method': 'cheque',
      'received_on': '2027-01-04',
      'period_start': '2027-01-04',
      'period_end': '2028-01-04',
      'description': 'Abonnement annuel',
      'seller': {'name': 'Vendeur EI', 'siret': '12345678900012'},
      'buyer_name': 'Club Alpha',
      'buyer_address': number == null ? null : '2 place du Stade',
      'blocker': blocker,
    });

class _Saved {
  final files = <String>[];
  Future<void> call(Uint8List bytes, String name, String mime) async =>
      files.add(name);
}

void main() {
  testWidgets('l’admin du club télécharge sa facture', (tester) async {
    final saved = _Saved();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubInvoicesProvider.overrideWith((ref) async => [invoice()]),
        ],
        child: MaterialApp(
          home: Scaffold(body: ClubInvoicesList(save: saved.call)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('PF-2027-0001 · 79,00 €'), findsOneWidget);
    await tester.tap(find.byTooltip('Télécharger la facture'));
    await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 500),
        ));
    await tester.pumpAndSettle();
    expect(saved.files, ['facture-PF-2027-0001.pdf']);
  });

  testWidgets('sans facture, le club voit une explication', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clubInvoicesProvider.overrideWith((ref) async => [])],
        child: const MaterialApp(home: Scaffold(body: ClubInvoicesList())),
      ),
    );
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Aucune facture pour l’instant'), findsOneWidget);
  });

  testWidgets(
      'l’éditeur voit ses factures en attente, saisit l’adresse et exporte',
      (tester) async {
    final calls = <String>[];
    final saved = _Saved();
    final repository = InvoiceRepository(
      rpc: (name, params) async {
        calls.add(name);
        return null;
      },
      selectClubInvoices: () async => const [],
    );
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          invoiceRepositoryProvider.overrideWithValue(repository),
          platformInvoiceSettingsProvider.overrideWith(
            (ref) async => const InvoiceSettings(
              sellerName: '',
              sellerAddress: '',
              siret: '',
              contactEmail: '',
              ready: false,
            ),
          ),
          platformInvoicesProvider.overrideWith(
            (ref) async => [
              invoice(id: 'p1', number: null, blocker: 'buyer_address'),
              invoice(),
            ],
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlatformInvoicesSection(save: saved.call),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Incomplètes'), findsOneWidget);
    expect(find.text('En attente (1)'), findsOneWidget);
    expect(
        find.textContaining('En attente de l’adresse du club'), findsOneWidget);
    // Rien n'est prêt : pas de bouton d'émission.
    expect(find.byKey(const Key('platform-invoices-issue')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('platform-invoice-buyer-p1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('platform-invoice-buyer-address')),
      '2 place du Stade, 31150 Bruguières',
    );
    await tester.tap(find.byKey(const Key('platform-invoice-buyer-save')));
    await tester.pumpAndSettle();
    expect(calls, contains('platform_set_club_billing_details'));

    await tester.tap(find.byKey(const Key('platform-invoices-export')));
    await tester.pumpAndSettle();
    expect(saved.files, ['livre-des-recettes.csv']);
  });
}
