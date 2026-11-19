import 'package:petit_filet/core/providers/supabase_provider.dart';
import 'package:petit_filet/features/billing/domain/invoice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Factures : lecture par l'administrateur du club (règles d'accès de la
/// base), gestion par l'éditeur (fonctions serveur qui vérifient son statut).
class InvoiceRepository {
  InvoiceRepository({required this.rpc, required this.selectClubInvoices});

  final Future<dynamic> Function(String function, Map<String, dynamic> params)
      rpc;

  /// Factures émises du club du compte connecté, la plus récente d'abord.
  final Future<List<Map<String, dynamic>>> Function() selectClubInvoices;

  static const _timeout = Duration(seconds: 15);

  Future<List<Invoice>> clubInvoices() async {
    final rows = await selectClubInvoices().timeout(_timeout);
    return rows.map(Invoice.fromJson).toList();
  }

  Future<List<Invoice>> allInvoices() async {
    final result =
        await rpc('platform_list_invoices', const {}).timeout(_timeout);
    if (result is! List) throw const FormatException('Invalid invoices');
    return result
        .whereType<Map>()
        .map((row) => Invoice.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<InvoiceSettings> settings() async {
    final result =
        await rpc('platform_invoice_settings', const {}).timeout(_timeout);
    if (result is! Map) throw const FormatException('Invalid settings');
    return InvoiceSettings.fromJson(Map<String, dynamic>.from(result));
  }

  Future<InvoiceSettings> saveSettings({
    required String sellerName,
    required String sellerAddress,
    required String siret,
    required String contactEmail,
  }) async {
    final result = await rpc('platform_save_invoice_settings', {
      'p_seller_name': sellerName,
      'p_seller_address': sellerAddress,
      'p_siret': siret,
      'p_contact_email': contactEmail,
    }).timeout(_timeout);
    if (result is! Map) throw const FormatException('Invalid settings');
    return InvoiceSettings.fromJson(Map<String, dynamic>.from(result));
  }

  Future<void> setClubBillingDetails({
    required String clubId,
    required String name,
    required String address,
  }) async {
    await rpc('platform_set_club_billing_details', {
      'p_club_id': clubId,
      'p_billing_name': name,
      'p_billing_address': address,
    }).timeout(_timeout);
  }

  /// Émet les factures qui peuvent l'être ; renvoie le nombre émis.
  Future<int> issuePending() async {
    final result = await rpc('platform_issue_pending_invoices', const {})
        .timeout(_timeout);
    return result is Map ? (result['issued'] as num?)?.toInt() ?? 0 : 0;
  }

  Future<void> discardPending(String invoiceId) async {
    await rpc('platform_discard_pending_invoice', {'p_invoice_id': invoiceId})
        .timeout(_timeout);
  }
}

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return InvoiceRepository(
    rpc: (name, params) async => await client.rpc(name, params: params),
    selectClubInvoices: () async {
      final rows = await client
          .from('club_invoices')
          .select()
          .eq('status', 'issued')
          .order('issued_on', ascending: false)
          .order('number', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    },
  );
});

final clubInvoicesProvider = FutureProvider.autoDispose<List<Invoice>>((ref) {
  return ref.watch(invoiceRepositoryProvider).clubInvoices();
});

final platformInvoicesProvider =
    FutureProvider.autoDispose<List<Invoice>>((ref) {
  return ref.watch(invoiceRepositoryProvider).allInvoices();
});

final platformInvoiceSettingsProvider =
    FutureProvider.autoDispose<InvoiceSettings>((ref) {
  return ref.watch(invoiceRepositoryProvider).settings();
});
