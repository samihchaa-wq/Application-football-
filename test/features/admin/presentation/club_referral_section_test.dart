import 'package:petit_filet/features/admin/presentation/club_referral_section.dart';
import 'package:petit_filet/features/club/data/club_subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, ClubReferrals? referrals) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubReferralsProvider.overrideWith((ref) async => referrals),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ClubReferralSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ClubReferrals referrals({
    int discount = 0,
    List<ClubReferral> list = const [],
    String? referredBy,
  }) =>
      ClubReferrals(
        code: 'PFABCD23',
        ratePercent: 5,
        capPercent: 100,
        discountPercent: discount,
        referrals: list,
        referredBy: referredBy,
      );

  testWidgets('explique la règle et montre le code à partager', (
    tester,
  ) async {
    await pump(tester, referrals());
    expect(
      find.textContaining('−5\u00A0% sur son prochain renouvellement'),
      findsOneWidget,
    );
    expect(find.textContaining('jusqu’à −100\u00A0% : 20 clubs parrainés'),
        findsOneWidget);
    expect(find.text('PFABCD23'), findsOneWidget);
    expect(find.byKey(const Key('club-referral-share')), findsOneWidget);
    expect(find.byKey(const Key('club-referral-empty')), findsOneWidget);
    expect(find.byKey(const Key('club-referral-discount')), findsNothing);
  });

  testWidgets('copier le code le met dans le presse-papiers', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    await pump(tester, referrals());
    await tester.tap(find.byKey(const Key('club-referral-copy')));
    await tester.pumpAndSettle();
    expect(copied, ['PFABCD23']);
    expect(find.text('Code parrain copié.'), findsOneWidget);
  });

  testWidgets('liste les clubs parrainés avec leur état et la réduction', (
    tester,
  ) async {
    await pump(
      tester,
      referrals(
        discount: 5,
        referredBy: 'FC Parrain',
        list: const [
          ClubReferral(clubName: 'US Filleul', state: ClubReferralState.paid),
          ClubReferral(clubName: 'AS Essai', state: ClubReferralState.trial),
          ClubReferral(clubName: 'FC Ancien', state: ClubReferralState.used),
        ],
      ),
    );
    expect(find.text('US Filleul'), findsOneWidget);
    expect(find.text('Abonné : −5\u00A0% acquis'), findsOneWidget);
    expect(find.text('En essai : compte dès son premier paiement'),
        findsOneWidget);
    expect(find.text('Abonné : réduction déjà utilisée'), findsOneWidget);
    expect(
      find.text(
          'Réduction acquise : −5\u00A0% sur le prochain renouvellement.'),
      findsOneWidget,
    );
    expect(
        find.text('Ton club a été parrainé par FC Parrain.'), findsOneWidget);
  });

  testWidgets('un club parrainé voit sa réduction de bienvenue', (
    tester,
  ) async {
    await pump(
      tester,
      const ClubReferrals(
        code: 'PFABCDEF',
        ratePercent: 5,
        capPercent: 100,
        discountPercent: 5,
        welcomePercent: 5,
        referredBy: 'FC Parrain',
        referrals: [],
      ),
    );
    expect(
      find.text('Ton club a été parrainé par FC Parrain : −5\u00A0% sur ta '
          'première année.'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
          'Le club parrainé a lui aussi −5\u00A0% sur sa première '
          'année.'),
      findsOneWidget,
    );
  });

  testWidgets('rien n’est affiché si le serveur ne renvoie rien', (
    tester,
  ) async {
    await pump(tester, null);
    expect(find.byKey(const Key('club-referral-card')), findsNothing);
  });

  test('le message de partage contient le code', () {
    expect(referralShareText('PFABCD23'), contains('PFABCD23'));
  });

  test('lecture de la réponse du serveur', () {
    final parsed = ClubReferrals.fromJson({
      'code': 'PFABCD23',
      'rate_percent': 5,
      'cap_percent': 100,
      'discount_percent': 10,
      'referred_by': null,
      'referrals': [
        {
          'club_name': 'US A',
          'state': 'paid',
          'joined_at': '2026-11-18T10:00:00Z'
        },
        {'club_name': 'US B', 'state': 'bizarre'},
      ],
    });
    expect(parsed.discountPercent, 10);
    expect(parsed.referrals.length, 2);
    expect(parsed.referrals[0].state, ClubReferralState.paid);
    expect(parsed.referrals[1].state, ClubReferralState.trial);
    expect(parsed.referredBy, isNull);
  });
}
