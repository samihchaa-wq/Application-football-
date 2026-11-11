import 'package:as_grinta/core/providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Où en est l'abonnement du club, du point de vue de son administrateur.
enum ClubSubscriptionState {
  /// Essai gratuit en cours, plus de 7 jours restants.
  trial,

  /// Moins de 7 jours d'essai : il est temps de s'abonner.
  trialEnding,

  /// Essai terminé sans abonnement.
  toPay,
  active,

  /// Le dernier paiement a échoué.
  pastDue,
  canceled;

  static ClubSubscriptionState parse(Object? value) => switch (value) {
        'trial' => trial,
        'trial_ending' => trialEnding,
        'to_pay' => toPay,
        'active' => active,
        'past_due' => pastDue,
        'canceled' => canceled,
        _ => trial,
      };

  /// Vrai quand l'administrateur doit agir.
  bool get needsAttention =>
      this == trialEnding || this == toPay || this == pastDue;
}

class ClubSubscription {
  const ClubSubscription({
    required this.state,
    required this.trialEndsAt,
    required this.trialDaysLeft,
    required this.currentPeriodEnd,
    required this.billablePlayers,
    required this.pricePerPlayerCents,
    required this.basePriceCents,
    required this.yearlyAmountCents,
  });

  factory ClubSubscription.fromJson(Map<String, dynamic> json) {
    DateTime? date(Object? value) =>
        value is String ? DateTime.tryParse(value)?.toLocal() : null;
    int number(Object? value) => value is num ? value.toInt() : 0;
    return ClubSubscription(
      state: ClubSubscriptionState.parse(json['state']),
      trialEndsAt: date(json['trial_ends_at']),
      trialDaysLeft: number(json['trial_days_left']),
      currentPeriodEnd: date(json['current_period_end']),
      billablePlayers: number(json['billable_players']),
      pricePerPlayerCents: number(json['price_per_player_cents']),
      basePriceCents: number(json['base_price_cents']),
      yearlyAmountCents: number(json['yearly_amount_cents']),
    );
  }

  final ClubSubscriptionState state;
  final DateTime? trialEndsAt;
  final int trialDaysLeft;
  final DateTime? currentPeriodEnd;
  final int billablePlayers;
  final int pricePerPlayerCents;
  final int basePriceCents;
  final int yearlyAmountCents;
}

/// Espace de fichiers occupé par le club et son quota.
class ClubStorageUsage {
  const ClubStorageUsage({required this.usedBytes, required this.quotaBytes});

  factory ClubStorageUsage.fromJson(Map<String, dynamic> json) =>
      ClubStorageUsage(
        usedBytes: (json['used_bytes'] as num?)?.toInt() ?? 0,
        quotaBytes: (json['quota_bytes'] as num?)?.toInt() ?? 0,
      );

  final int usedBytes;
  final int quotaBytes;

  double get ratio =>
      quotaBytes <= 0 ? 1 : (usedBytes / quotaBytes).clamp(0, 1).toDouble();
}

/// Montant en euros, à la française : « 1 250 € » ou « 12,50 € ».
String formatEuros(int cents) {
  final euros = cents ~/ 100;
  final rest = cents % 100;
  final digits = euros.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(' ');
    grouped.write(digits[i]);
  }
  return rest == 0
      ? '$grouped €'
      : '$grouped,${rest.toString().padLeft(2, '0')} €';
}

/// Taille de fichiers lisible : « 12 Mo », « 1,5 Go ».
String formatBytes(int bytes) {
  const mega = 1024 * 1024;
  const giga = 1024 * mega;
  if (bytes >= giga) {
    final value = (bytes / giga * 10).round() / 10;
    return '${value.toString().replaceAll('.', ',')} Go';
  }
  return '${(bytes / mega).ceil()} Mo';
}

class ClubSubscriptionRepository {
  ClubSubscriptionRepository(this._client);

  final SupabaseClient _client;

  /// Réservé aux administrateurs du club.
  Future<ClubSubscription?> fetchSubscription() async {
    final result = await _client.rpc('admin_get_club_subscription');
    if (result is! Map) return null;
    return ClubSubscription.fromJson(Map<String, dynamic>.from(result));
  }

  /// Réservé aux administrateurs du club.
  Future<ClubStorageUsage?> fetchStorageUsage() async {
    final result = await _client.rpc('admin_get_club_storage_usage');
    if (result is! Map) return null;
    return ClubStorageUsage.fromJson(Map<String, dynamic>.from(result));
  }

  /// État du club du compte connecté : 'active', 'suspended'…
  /// Lisible même quand le club est suspendu.
  Future<String> fetchMyClubAccess() async {
    final result = await _client.rpc('get_my_club_access');
    if (result is Map && result['status'] is String) {
      return result['status'] as String;
    }
    return 'unknown';
  }
}

final clubSubscriptionRepositoryProvider =
    Provider<ClubSubscriptionRepository>((ref) {
  return ClubSubscriptionRepository(ref.watch(supabaseClientProvider));
});

final clubSubscriptionProvider =
    FutureProvider.autoDispose<ClubSubscription?>((ref) {
  return ref.watch(clubSubscriptionRepositoryProvider).fetchSubscription();
});

final clubStorageUsageProvider =
    FutureProvider.autoDispose<ClubStorageUsage?>((ref) {
  return ref.watch(clubSubscriptionRepositoryProvider).fetchStorageUsage();
});

/// État du club du compte connecté. En cas d'erreur, le club est considéré
/// comme ouvert : un souci réseau ne doit jamais afficher l'écran de club
/// suspendu par erreur.
final myClubAccessProvider = FutureProvider<String>((ref) {
  return ref.watch(clubSubscriptionRepositoryProvider).fetchMyClubAccess();
});
