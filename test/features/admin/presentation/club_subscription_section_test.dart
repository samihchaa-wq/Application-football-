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

  ClubSubscription subscription(
    ClubSubscriptionState state, {
    DateTime? accessEndsAt,
  }) =>
      ClubSubscription(
        state: state,
        trialEndsAt: null,
        trialDaysLeft: 0,
        currentPeriodEnd: null,
        accessEndsAt: accessEndsAt,
        billablePlayers: 18,
        pricePerPlayerCents: 0,
        basePriceCents: 7900,
        yearlyAmountCents: 7900,
      );

  testWidgets('essai fini : l’admin voit la date de coupure', (tester) async {
    await pump(
      tester,
      subscription(
        ClubSubscriptionState.toPay,
        accessEndsAt: DateTime(2026, 12, 26, 10),
      ),
    );
    expect(find.text('Essai gratuit terminé'), findsOneWidget);
    expect(
      find.textContaining('l’accès du club sera coupé le 26/12/2026'),
      findsOneWidget,
    );
    expect(find.textContaining('garde l’accès pour l’instant'), findsNothing);
  });

  testWidgets('abonnement actif : aucun avertissement', (tester) async {
    await pump(tester, subscription(ClubSubscriptionState.active));
    expect(find.text('Abonnement actif'), findsOneWidget);
    expect(find.textContaining('sera coupé'), findsNothing);
    expect(find.text('Total annuel : 79 €'), findsOneWidget);
  });
}
