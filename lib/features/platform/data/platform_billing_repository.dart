import 'dart:math';

import 'package:petit_filet/core/providers/supabase_provider.dart';
import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:petit_filet/features/platform/domain/platform_billing.dart';
import 'package:petit_filet/features/platform/domain/platform_cash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Résultat d'un paiement noté : nouvelle échéance, club rouvert ou non.
class RecordedPayment {
  const RecordedPayment({required this.periodEnd, required this.reopened});

  final DateTime? periodEnd;
  final bool reopened;
}

/// Résultat d'une période offerte.
class GrantedPeriod {
  const GrantedPeriod({
    required this.periodEnd,
    required this.reopened,
    required this.trialExtension,
  });

  final DateTime? periodEnd;
  final bool reopened;
  final bool trialExtension;
}

/// Résultat d'un remboursement : numéro d'avoir s'il a pu être émis.
class RecordedRefund {
  const RecordedRefund({this.creditNoteNumber, this.recorded = true});

  final String? creditNoteNumber;

  /// Faux quand Stripe a remboursé mais que l'appli l'enregistrera plus tard
  /// (à la confirmation de Stripe).
  final bool recorded;
}

typedef PlatformRpc = Future<dynamic> Function(
  String function,
  Map<String, dynamic> params,
);
typedef PlatformInvoke = Future<dynamic> Function(
  String function,
  Map<String, dynamic> body,
);

/// Gestionnaire de l'éditeur : chaque appel passe par une fonction serveur
/// qui vérifie que le compte est bien éditeur (private.platform_operators).
class PlatformBillingRepository {
  PlatformBillingRepository(this._rpc, {PlatformInvoke? invoke})
      : _invoke = invoke;

  final PlatformRpc _rpc;
  final PlatformInvoke? _invoke;

  static const _timeout = Duration(seconds: 15);

  static String _isoDay(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static String? _clean(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  Future<PlatformBilling> fetch(String clubId) async {
    final result = await _rpc('platform_club_billing', {'p_club_id': clubId})
        .timeout(_timeout);
    if (result is! Map) throw const FormatException('Invalid billing');
    return PlatformBilling.fromJson(Map<String, dynamic>.from(result));
  }

  Future<RecordedPayment> recordPayment({
    required String clubId,
    required int amountCents,
    required String method,
    required DateTime receivedOn,
    String? note,
    String? reference,
  }) async {
    final result = await _rpc('platform_record_manual_payment', {
      'p_club_id': clubId,
      'p_amount_cents': amountCents,
      'p_method': method,
      'p_received_on': _isoDay(receivedOn),
      'p_note': _clean(note),
      'p_reference': _clean(reference),
    }).timeout(_timeout);
    if (result is! Map) throw const FormatException('Invalid payment result');
    final end = result['period_end'];
    return RecordedPayment(
      periodEnd: end is String ? DateTime.tryParse(end)?.toUtc() : null,
      reopened: result['reopened'] == true,
    );
  }

  Future<GrantedPeriod> grantFreePeriod({
    required String clubId,
    required int months,
    required int days,
    required String reason,
  }) async {
    final result = await _rpc('platform_grant_free_period', {
      'p_club_id': clubId,
      'p_months': months,
      'p_days': days,
      'p_reason': reason.trim(),
    }).timeout(_timeout);
    if (result is! Map) throw const FormatException('Invalid grant result');
    final end = result['period_end'];
    return GrantedPeriod(
      periodEnd: end is String ? DateTime.tryParse(end)?.toUtc() : null,
      reopened: result['reopened'] == true,
      trialExtension: result['kind'] == 'trial_extension',
    );
  }

  /// Remboursement hors ligne (chèque, virement, espèces…).
  Future<RecordedRefund> recordManualRefund({
    required String paymentId,
    required int amountCents,
    required String method,
    String? reason,
  }) async {
    final result = await _rpc('platform_record_refund', {
      'p_payment_id': paymentId,
      'p_amount_cents': amountCents,
      'p_method': method,
      'p_reason': _clean(reason),
      'p_stripe_refund_id': null,
    }).timeout(_timeout);
    return RecordedRefund(
      creditNoteNumber:
          result is Map ? result['credit_note_number'] as String? : null,
    );
  }

  /// Remboursement sur la carte, par Stripe (fonction stripe-refund).
  Future<RecordedRefund> refundCard({
    required String paymentId,
    required int amountCents,
    String? reason,
    String? requestId,
  }) async {
    final invoke = _invoke;
    if (invoke == null) {
      throw UserFacingError('Le remboursement par carte est indisponible.');
    }
    final result = await invoke('stripe-refund', {
      'payment_id': paymentId,
      'amount_cents': amountCents,
      'reason': _clean(reason) ?? '',
      'request_id': requestId ?? newRequestId(),
    }).timeout(const Duration(seconds: 30));
    if (result is! Map || result['refunded'] != true) {
      throw UserFacingError('Stripe n’a pas confirmé le remboursement.');
    }
    final recorded = result['result'];
    return RecordedRefund(
      recorded: result['recorded'] == true,
      creditNoteNumber:
          recorded is Map ? recorded['credit_note_number'] as String? : null,
    );
  }

  Future<void> setClubTerms({
    required String clubId,
    required int basePriceCents,
    String? notes,
  }) async {
    await _rpc('platform_set_club_terms', {
      'p_club_id': clubId,
      'p_base_price_cents': basePriceCents,
      'p_notes': _clean(notes),
    }).timeout(_timeout);
  }

  Future<void> setClubAccess({
    required String clubId,
    required bool suspended,
  }) async {
    await _rpc('platform_set_club_access', {
      'p_club_id': clubId,
      'p_suspended': suspended,
    }).timeout(_timeout);
  }

  Future<void> setClubBillingDetails({
    required String clubId,
    required String name,
    required String address,
  }) async {
    await _rpc('platform_set_club_billing_details', {
      'p_club_id': clubId,
      'p_billing_name': name,
      'p_billing_address': address,
    }).timeout(_timeout);
  }

  Future<PlatformLedger> ledger(LedgerPeriod period) async {
    final result = await _rpc('platform_ledger', {
      'p_from': _isoDay(period.from),
      'p_to': _isoDay(period.to),
    }).timeout(_timeout);
    if (result is! Map) throw const FormatException('Invalid ledger');
    return PlatformLedger.fromJson(Map<String, dynamic>.from(result));
  }

  Future<PlatformAlerts> alerts() async {
    final result =
        await _rpc('platform_payment_alerts', const {}).timeout(_timeout);
    if (result is! Map) throw const FormatException('Invalid alerts');
    return PlatformAlerts.fromJson(Map<String, dynamic>.from(result));
  }

  Future<void> resolveAlert(String alertId) async {
    await _rpc('platform_resolve_alert', {'p_alert_id': alertId})
        .timeout(_timeout);
  }

  Future<PlatformBillingSettings> settings() async {
    final result =
        await _rpc('platform_billing_settings', const {}).timeout(_timeout);
    if (result is! Map) throw const FormatException('Invalid settings');
    return PlatformBillingSettings.fromJson(Map<String, dynamic>.from(result));
  }

  Future<PlatformBillingSettings> saveSettings({
    required int basePriceCents,
    required int referralRatePercent,
    required int referralCapPercent,
    required int trialDays,
  }) async {
    final result = await _rpc('platform_save_billing_settings', {
      'p_base_price_cents': basePriceCents,
      'p_referral_rate_percent': referralRatePercent,
      'p_referral_cap_percent': referralCapPercent,
      'p_trial_days': trialDays,
    }).timeout(_timeout);
    if (result is! Map) throw const FormatException('Invalid settings');
    return PlatformBillingSettings.fromJson(Map<String, dynamic>.from(result));
  }

  Future<List<CreditNote>> creditNotes() async {
    final result =
        await _rpc('platform_list_credit_notes', const {}).timeout(_timeout);
    if (result is! List) throw const FormatException('Invalid credit notes');
    return result
        .whereType<Map>()
        .map((row) => CreditNote.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}

/// Identifiant unique d'une demande (anti double-clic côté Stripe).
String newRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int from, int to) => bytes
      .sublist(from, to)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

final platformBillingRepositoryProvider =
    Provider<PlatformBillingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PlatformBillingRepository(
    (name, params) async => await client.rpc(name, params: params),
    invoke: (name, body) async {
      try {
        final response = await client.functions.invoke(name, body: body);
        return response.data;
      } on FunctionsHttpException catch (error) {
        throw functionHttpError(
          error,
          fallback: 'Le remboursement n’a pas pu être fait.',
        );
      }
    },
  );
});

final platformBillingProvider =
    FutureProvider.autoDispose.family<PlatformBilling, String>((ref, clubId) {
  return ref.watch(platformBillingRepositoryProvider).fetch(clubId);
});

final platformLedgerProvider = FutureProvider.autoDispose
    .family<PlatformLedger, LedgerPeriod>((ref, period) {
  return ref.watch(platformBillingRepositoryProvider).ledger(period);
});

final platformAlertsProvider =
    FutureProvider.autoDispose<PlatformAlerts>((ref) {
  return ref.watch(platformBillingRepositoryProvider).alerts();
});

final platformBillingSettingsProvider =
    FutureProvider.autoDispose<PlatformBillingSettings>((ref) {
  return ref.watch(platformBillingRepositoryProvider).settings();
});

final platformCreditNotesProvider =
    FutureProvider.autoDispose<List<CreditNote>>((ref) {
  return ref.watch(platformBillingRepositoryProvider).creditNotes();
});
