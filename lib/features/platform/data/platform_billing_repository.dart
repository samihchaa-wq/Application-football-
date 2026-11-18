import 'package:petit_filet/core/providers/supabase_provider.dart';
import 'package:petit_filet/features/platform/domain/platform_billing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Résultat d'un paiement noté : nouvelle échéance, club rouvert ou non.
class RecordedPayment {
  const RecordedPayment({required this.periodEnd, required this.reopened});

  final DateTime? periodEnd;
  final bool reopened;
}

/// Facturation hors ligne, par des fonctions serveur réservées à l'éditeur
/// (vérification de private.platform_operators côté base).
class PlatformBillingRepository {
  PlatformBillingRepository(this._rpc);

  final Future<dynamic> Function(String function, Map<String, dynamic> params)
      _rpc;

  Future<PlatformBilling> fetch(String clubId) async {
    final result = await _rpc('platform_club_billing', {'p_club_id': clubId})
        .timeout(const Duration(seconds: 15));
    if (result is! Map) throw const FormatException('Invalid billing');
    return PlatformBilling.fromJson(Map<String, dynamic>.from(result));
  }

  Future<RecordedPayment> recordPayment({
    required String clubId,
    required int amountCents,
    required String method,
    required DateTime receivedOn,
    String? note,
  }) async {
    final day = '${receivedOn.year.toString().padLeft(4, '0')}-'
        '${receivedOn.month.toString().padLeft(2, '0')}-'
        '${receivedOn.day.toString().padLeft(2, '0')}';
    final result = await _rpc('platform_record_offline_payment', {
      'p_club_id': clubId,
      'p_amount_cents': amountCents,
      'p_method': method,
      'p_received_on': day,
      'p_note': (note?.trim().isEmpty ?? true) ? null : note!.trim(),
    }).timeout(const Duration(seconds: 15));
    if (result is! Map) throw const FormatException('Invalid payment result');
    final end = result['period_end'];
    return RecordedPayment(
      periodEnd: end is String ? DateTime.tryParse(end)?.toUtc() : null,
      reopened: result['reopened'] == true,
    );
  }
}

final platformBillingRepositoryProvider =
    Provider<PlatformBillingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PlatformBillingRepository(
    (name, params) async => await client.rpc(name, params: params),
  );
});

final platformBillingProvider =
    FutureProvider.autoDispose.family<PlatformBilling, String>((ref, clubId) {
  return ref.watch(platformBillingRepositoryProvider).fetch(clubId);
});
