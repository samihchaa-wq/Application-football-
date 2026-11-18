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
}
