import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/core/widgets/copy_link_or_show.dart';
import 'package:petit_filet/features/badges/presentation/badge_emblem.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => copyLinkOrShow(
                context,
                link: 'https://app.petitfilet.fr/#/auth/register?code=ABCD1234',
                copiedMessage: 'Lien copié.',
                title: 'Lien d’inscription',
              ),
              child: const Text('Copier le lien'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('presse-papiers refusé : le lien s’affiche à copier à la main',
      (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'copy_fail');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await pumpButton(tester);
    await tester.tap(find.text('Copier le lien'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('copy-link-text')), findsOneWidget);
    expect(find.textContaining('code=ABCD1234'), findsOneWidget);
  });

  testWidgets('presse-papiers accepté : simple confirmation', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await pumpButton(tester);
    await tester.tap(find.text('Copier le lien'));
    await tester.pump();
    expect(find.text('Lien copié.'), findsOneWidget);
    expect(find.byKey(const Key('copy-link-text')), findsNothing);
  });

  test('l’icône calendrier des badges n’affiche plus de mois en anglais', () {
    expect(displayBadgeEmoji('📅'), isNot('📅'));
    expect(displayBadgeEmoji('📆'), isNot('📆'));
    expect(displayBadgeEmoji('⚽'), '⚽');
  });
}
