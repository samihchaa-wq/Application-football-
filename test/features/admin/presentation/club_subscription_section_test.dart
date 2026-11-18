import 'package:petit_filet/features/admin/presentation/club_subscription_section.dart';
import 'package:petit_filet/features/club/data/club_subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, ClubSubscription subscription) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubSubscriptionProvider.overrideWith((ref) async => subscription),
          clubStorageUsageProvider.overrideWith((ref) async => null),
          clubReferralsProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ClubSubscriptionSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ClubSubscription subscription({
    required ClubSubscriptionState state,
    DateTime? periodEnd,
    DateTime? suspensionOn,
  }) =>
      ClubSubscription(
        state: state,
        trialEndsAt: null,
        trialDaysLeft: 0,
        currentPeriodEnd: periodEnd,
        billablePlayers: 20,
        pricePerPlayerCents: 0,
        basePriceCents: 7900,
        yearlyAmountCents: 7900,
        suspensionOn: suspensionOn,
      );

  testWidgets('essai terminé : l’admin voit la date de suspension', (
    tester,
  ) async {
    await pump(
      tester,
      subscription(
        state: ClubSubscriptionState.toPay,
        suspensionOn: DateTime(2026, 12, 3, 12),
      ),
    );
    expect(find.text('Essai gratuit terminé'), findsOneWidget);
    expect(
      find.text(
        'Sans paiement, l’accès du club sera suspendu à partir du '
        '03/12/2026. Les données sont conservées.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('abonnement payé loin de l’échéance : aucune alerte', (
    tester,
  ) async {
    final end = DateTime.now().add(const Duration(days: 200));
    await pump(
      tester,
      subscription(
        state: ClubSubscriptionState.active,
        periodEnd: end,
        suspensionOn: end.add(const Duration(days: 15)),
      ),
    );
    expect(find.textContaining('Payé jusqu’au'), findsOneWidget);
    expect(
      find.byKey(const Key('club-subscription-suspension-warning')),
      findsNothing,
    );
  });

  testWidgets('échéance proche : rappel de renouvellement et de suspension', (
    tester,
  ) async {
    final end = DateTime.now().add(const Duration(days: 10));
    await pump(
      tester,
      subscription(
        state: ClubSubscriptionState.active,
        periodEnd: end,
        suspensionOn: end.add(const Duration(days: 15)),
      ),
    );
    expect(
      find.text(
        'L’abonnement arrive à échéance. Contacte-nous pour le renouveler.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('club-subscription-suspension-warning')),
      findsOneWidget,
    );
  });

  testWidgets('à régler : l’admin voit l’adresse où écrire pour payer', (
    tester,
  ) async {
    await pump(
      tester,
      subscription(
        state: ClubSubscriptionState.toPay,
        suspensionOn: DateTime(2026, 12, 3, 12),
      ),
    );
    expect(find.byKey(const Key('support-contact-email')), findsOneWidget);
    expect(find.text('contact@petitfilet.fr'), findsOneWidget);
    expect(find.byKey(const Key('support-contact-button')), findsOneWidget);
  });

  testWidgets('abonnement actif loin de l’échéance : pas d’adresse affichée', (
    tester,
  ) async {
    await pump(
      tester,
      subscription(
        state: ClubSubscriptionState.active,
        periodEnd: DateTime.now().add(const Duration(days: 300)),
        suspensionOn: DateTime.now().add(const Duration(days: 315)),
      ),
    );
    expect(find.byKey(const Key('support-contact-email')), findsNothing);
  });

  testWidgets('réduction de parrainage : le montant restant est affiché', (
    tester,
  ) async {
    await pump(
      tester,
      ClubSubscription(
        state: ClubSubscriptionState.active,
        trialEndsAt: null,
        trialDaysLeft: 0,
        currentPeriodEnd: DateTime.now().add(const Duration(days: 20)),
        billablePlayers: 20,
        pricePerPlayerCents: 0,
        basePriceCents: 7900,
        yearlyAmountCents: 7900,
        referralDiscountPercent: 15,
        amountDueCents: 6715,
      ),
    );
    expect(
      find.textContaining('Parrainage : −15 %, reste à payer 67,15'),
      findsOneWidget,
    );
  });

  testWidgets('sans parrainage : pas de ligne de réduction', (tester) async {
    await pump(
      tester,
      subscription(state: ClubSubscriptionState.toPay),
    );
    expect(find.byKey(const Key('club-subscription-amount-due')), findsNothing);
  });
}
