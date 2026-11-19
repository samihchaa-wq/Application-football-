import 'package:petit_filet/core/widgets/support_contact.dart';
import 'package:petit_filet/features/club/presentation/club_suspended_page.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {required bool admin}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [isRealAdminProvider.overrideWithValue(admin)],
      child: const MaterialApp(home: ClubSuspendedPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('club suspendu : l’adresse pour régler l’abonnement est visible',
      (tester) async {
    await _pump(tester, admin: false);

    expect(find.byKey(const Key('club-suspended-title')), findsOneWidget);
    expect(
        find.text('Les données du club sont conservées. L’accès reviendra '
            'dès que l’administrateur de ton club aura régularisé '
            'l’abonnement.'),
        findsOneWidget);
    expect(find.text('contact@petitfilet.fr'), findsOneWidget);
    expect(find.byKey(const Key('support-contact-button')), findsOneWidget);
  });

  testWidgets('un joueur ne voit pas le bouton de paiement', (tester) async {
    await _pump(tester, admin: false);
    expect(find.byKey(const Key('club-pay-by-card')), findsNothing);
  });

  testWidgets('l’admin d’un club suspendu peut payer par carte pour rouvrir',
      (tester) async {
    await _pump(tester, admin: true);
    expect(find.byKey(const Key('club-pay-by-card')), findsOneWidget);
    expect(find.byKey(const Key('club-suspended-refresh')), findsOneWidget);
  });

  test('le lien d’écriture vise l’adresse de contact avec un objet', () {
    final uri = SupportContact.mailtoUri('Club suspendu : régler l’abonnement');
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'contact@petitfilet.fr');
    expect(Uri.decodeComponent(uri.query),
        'subject=Club suspendu : régler l’abonnement');
  });
}
