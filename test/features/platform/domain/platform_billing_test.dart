import 'package:petit_filet/features/platform/domain/platform_billing.dart';
import 'package:petit_filet/features/platform/domain/platform_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('les montants saisis en euros deviennent des centimes', () {
    expect(parseEurosToCents('79'), 7900);
    expect(parseEurosToCents('79,5'), 7950);
    expect(parseEurosToCents(' 79.50 € '), 7950);
    expect(parseEurosToCents('0'), 0);
    for (final bad in ['', 'abc', '-5', '79,505', '1,2,3']) {
      expect(parseEurosToCents(bad), isNull, reason: bad);
    }
  });

  test('la fiche de facturation est lue depuis le serveur', () {
    final billing = PlatformBilling.fromJson({
      'base_price_cents': 7900,
      'suspension_on': '2026-12-03T10:00:00Z',
      'auto_suspended_at': null,
      'payments': [
        {
          'amount_cents': 7900,
          'method': 'cheque',
          'received_on': '2026-11-18',
          'period_end': '2027-11-18T10:00:00Z',
          'note': 'Chèque 123',
        },
        null,
      ],
    });
    expect(billing.basePriceCents, 7900);
    expect(billing.suspensionOn, isNotNull);
    expect(billing.autoSuspendedAt, isNull);
    expect(billing.payments.single.methodLabel, 'Chèque');
    expect(billing.payments.single.note, 'Chèque 123');
  });

  test('une équipe en essai est affichée comme telle', () {
    const team = PlatformTeam(
      id: 'a',
      name: 'A',
      status: 'active',
      subscriptionStatus: 'trialing',
    );
    expect(team.subscriptionLabel, 'Essai');
  });
}
