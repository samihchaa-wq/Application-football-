import 'package:as_grinta/features/auth/presentation/widgets/email_verification_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('étape e-mail à $width px, texte ×$scale', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final status in EmailVerificationStatus.values) {
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: EmailVerificationPanel(
                    email: 'joueur.test.long@example.invalid',
                    status: status,
                    onResend: () {},
                    onEditEmail: () {},
                  ),
                ),
              ),
            ),
          ));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: '$status');
          expect(find.textContaining('club'), findsNothing);
          if (status == EmailVerificationStatus.awaitingAdmin) {
            expect(find.text('Renvoyer le lien'), findsNothing);
            expect(find.textContaining('administrateur'), findsOneWidget);
          }
        }
      });
    }
  }

  testWidgets('renvoi limité et correction appellent seulement les callbacks',
      (tester) async {
    var resent = 0;
    var edited = 0;
    Future<void> pump(int delay) => tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: EmailVerificationPanel(
              email: 'joueur@example.invalid',
              status: EmailVerificationStatus.waiting,
              retryAfterSeconds: delay,
              onResend: () => resent++,
              onEditEmail: () => edited++,
            ),
          ),
        ));
    await pump(30);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.tap(find.text('Corriger mon adresse e-mail'));
    expect(edited, 1);
    await pump(0);
    await tester.tap(find.text('Renvoyer le lien'));
    expect(resent, 1);
  });
}
