import 'package:petit_filet/features/platform/domain/platform_billing.dart';
import 'package:petit_filet/features/platform/domain/platform_cash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LedgerPeriod', () {
    test('un mois va du 1er au dernier jour', () {
      const period = LedgerPeriod.month(2026, 2);
      expect(period.from, DateTime(2026, 2, 1));
      expect(period.to, DateTime(2026, 2, 28));
      expect(period.label, 'Février 2026');
      expect(period.fileStem, 'caisse-2026-02');
    });

    test('précédent et suivant passent d’une année à l’autre', () {
      expect(const LedgerPeriod.month(2026, 1).previous,
          const LedgerPeriod.month(2025, 12));
      expect(const LedgerPeriod.month(2026, 12).next,
          const LedgerPeriod.month(2027, 1));
      expect(const LedgerPeriod.year(2026).previous,
          const LedgerPeriod.year(2025));
    });

    test('une année couvre tout l’an civil', () {
      const period = LedgerPeriod.year(2026);
      expect(period.from, DateTime(2026, 1, 1));
      expect(period.to, DateTime(2026, 12, 31));
      expect(period.label, 'Année 2026');
    });
  });

  test('le registre lit encaissements, remboursements et périodes offertes',
      () {
    final ledger = PlatformLedger.fromJson({
      'from': '2026-11-01',
      'to': '2026-11-30',
      'entries': [
        {
          'kind': 'refund',
          'id': 'r1',
          'day': '2026-11-12',
          'club_name': 'FC Test',
          'amount_cents': -2900,
          'method': 'cheque',
          'document_number': 'AV-2026-0001',
          'document_status': 'issued',
          'period_label': 'PF-2026-0001',
        },
        {
          'kind': 'payment',
          'id': 'p1',
          'day': '2026-11-10',
          'club_name': 'FC Test',
          'amount_cents': 7900,
          'method': 'carte',
          'fee_cents': 136,
          'reference': 'pi_123',
        },
      ],
      'totals': {
        'collected_cents': 7900,
        'refunded_cents': 2900,
        'fees_cents': 136,
        'net_cents': 4864,
        'by_method': {'carte': 7900},
      },
    });
    expect(ledger.entries.first.kind, LedgerKind.refund);
    expect(ledger.entries.first.day, DateTime(2026, 11, 12));
    expect(ledger.entries.last.methodLabel, 'Carte (Stripe)');
    expect(ledger.totals.byMethod, {'carte': 7900});

    final csv = ledgerToCsv(ledger);
    final lines = csv.trim().split('\r\n');
    // Du plus ancien au plus récent, puis les totaux.
    expect(lines[1], contains('"10/11/2026";"Encaissement";"FC Test";"79,00"'));
    expect(lines[1], contains('"1,36";"77,64"'));
    expect(lines[2], contains('"Remboursement";"FC Test";"-29,00"'));
    expect(lines[2], contains('"AV-2026-0001"'));
    expect(lines.last, contains('"48,64"'));
    expect(csv.startsWith('﻿'), isTrue);
  });

  test('la fiche club lit contacts, remboursements et périodes offertes', () {
    final billing = PlatformBilling.fromJson({
      'subscription_status': 'trialing',
      'base_price_cents': 7900,
      'contact': {'email': 'contact@club.fr', 'phone': ' '},
      'admins': [
        {'name': 'Marie Durand', 'email': 'marie@club.fr'},
      ],
      'payments': [
        {
          'id': 'p1',
          'amount_cents': 7900,
          'method': 'carte',
          'refunded_cents': 2900,
          'refundable_by_card': true,
          'invoice_number': 'PF-2026-0001',
          'invoice_status': 'issued',
        },
      ],
      'refunds': [
        {
          'id': 'r1',
          'payment_id': 'p1',
          'amount_cents': 2900,
          'method': 'carte',
          'credit_note_number': 'AV-2026-0001',
        },
      ],
      'grants': [
        {
          'kind': 'trial_extension',
          'months': 0,
          'days': 15,
          'reason': 'Rentrée'
        },
      ],
    });
    expect(billing.isTrial, isTrue);
    expect(billing.contact.email, 'contact@club.fr');
    expect(billing.contact.phone, isNull);
    expect(billing.admins.single.name, 'Marie Durand');
    expect(billing.payments.single.refundableCents, 5000);
    expect(billing.payments.single.refundableByCard, isTrue);
    expect(billing.refunds.single.creditNoteNumber, 'AV-2026-0001');
    expect(billing.grants.single.durationLabel, '15 j');
    expect(billing.grants.single.trialExtension, isTrue);
  });

  test('durées et montants lisibles', () {
    expect(formatGrantDuration(3, 0), '3 mois');
    expect(formatGrantDuration(1, 15), '1 mois et 15 j');
    expect(centsToInput(7900), '79');
    expect(centsToInput(7505), '75,05');
  });

  test('l’offre signale un écart avec les conditions publiées', () {
    const published = PlatformBillingSettings(
      basePriceCents: 7900,
      referralRatePercent: 5,
      referralCapPercent: 100,
      trialDays: 30,
    );
    const changed = PlatformBillingSettings(
      basePriceCents: 7900,
      referralRatePercent: 5,
      referralCapPercent: 100,
      trialDays: 90,
    );
    expect(published.matchesPublishedTerms, isTrue);
    expect(changed.matchesPublishedTerms, isFalse);
  });
}
