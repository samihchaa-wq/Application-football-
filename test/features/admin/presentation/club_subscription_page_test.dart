import 'package:petit_filet/features/admin/presentation/club_subscription_page.dart';
import 'package:petit_filet/features/billing/data/invoice_repository.dart';
import 'package:petit_filet/features/club/data/club_subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Écran Abonnement, ouvert depuis Paramètres (il était avant dans les
/// Réglages du club).
void main() {
  testWidgets('l’admin voit son essai, son forfait annuel et son espace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubSubscriptionProvider.overrideWith(
            (ref) async => const ClubSubscription(
              state: ClubSubscriptionState.trialEnding,
              trialEndsAt: null,
              trialDaysLeft: 5,
              currentPeriodEnd: null,
              billablePlayers: 24,
              pricePerPlayerCents: 0,
              basePriceCents: 7900,
              yearlyAmountCents: 7900,
            ),
          ),
          clubReferralsProvider.overrideWith((ref) async => null),
          clubInvoicesProvider.overrideWith((ref) async => const []),
          clubStorageUsageProvider.overrideWith(
            (ref) async => const ClubStorageUsage(
              usedBytes: 50 * 1024 * 1024,
              quotaBytes: 200 * 1024 * 1024,
            ),
          ),
        ],
        child: const MaterialApp(home: ClubSubscriptionPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Abonnement'), findsWidgets);
    expect(find.text('Essai gratuit : encore 5 jours'), findsOneWidget);
    expect(
      find.text('Forfait club, quel que soit le nombre de joueurs'),
      findsOneWidget,
    );
    expect(find.text('Total annuel : 79 €'), findsOneWidget);
    expect(find.text('50 Mo utilisés sur 200 Mo.'), findsOneWidget);
  });
}
