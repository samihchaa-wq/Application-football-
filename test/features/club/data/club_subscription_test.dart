import 'package:as_grinta/features/club/data/club_subscription.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('les montants sont écrits à la française', () {
    expect(formatEuros(1000), '10 €');
    expect(formatEuros(125000), '1 250 €');
    expect(formatEuros(1250), '12,50 €');
    expect(formatEuros(0), '0 €');
  });

  test('les tailles de fichiers sont lisibles', () {
    expect(formatBytes(0), '0 Mo');
    expect(formatBytes(200 * 1024 * 1024), '200 Mo');
    expect(formatBytes(1536 * 1024 * 1024), '1,5 Go');
  });

  test('l’abonnement est lu depuis la réponse du serveur', () {
    final subscription = ClubSubscription.fromJson({
      'state': 'to_pay',
      'trial_ends_at': '2026-12-11T10:00:00Z',
      'trial_days_left': 0,
      'billable_players': 18,
      'price_per_player_cents': 1000,
      'base_price_cents': 5000,
      'yearly_amount_cents': 23000,
    });
    expect(subscription.state, ClubSubscriptionState.toPay);
    expect(subscription.state.needsAttention, isTrue);
    expect(subscription.billablePlayers, 18);
    expect(subscription.yearlyAmountCents, 23000);
    expect(subscription.trialEndsAt, isNotNull);
  });

  test('un état inconnu est traité comme un essai', () {
    expect(ClubSubscriptionState.parse('nouveau'), ClubSubscriptionState.trial);
    expect(ClubSubscriptionState.active.needsAttention, isFalse);
  });

  test('la jauge d’espace reste entre 0 et 1', () {
    expect(
      const ClubStorageUsage(usedBytes: 300, quotaBytes: 100).ratio,
      1,
    );
    expect(const ClubStorageUsage(usedBytes: 0, quotaBytes: 0).ratio, 1);
    expect(
      const ClubStorageUsage(usedBytes: 50, quotaBytes: 200).ratio,
      0.25,
    );
  });
}
