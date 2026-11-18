import 'package:petit_filet/features/auth/presentation/registration_success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openDialog(WidgetTester tester, {bool active = true}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => RegistrationSuccessDialog(
                  username: 'joueurtest',
                  teamName: 'Équipe Test',
                  isActive: active,
                  emailConfirmationSent: true,
                ),
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('copie le véritable identifiant et indique le chemin admin',
      (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await openDialog(tester);
    await tester.tap(find.text('Copier mon identifiant'));
    await tester.pumpAndSettle();
    expect(copied, 'joueurtest');
    expect(find.text('Identifiant copié.'), findsOneWidget);
    expect(find.textContaining('Paramètres → Effectif'), findsOneWidget);
  });

  testWidgets('refus du presse-papiers conserve la copie manuelle',
      (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'denied');
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await openDialog(tester, active: false);
    await tester.tap(find.text('Copier mon identifiant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Copie impossible'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.textContaining('en attente'), findsOneWidget);
    expect(find.textContaining('Paramètres → Effectif'), findsNothing);
  });

  testWidgets('confirmation défilante sur petit écran et texte agrandi',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openDialog(tester);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Compris'));
    await tester.tap(find.text('Compris'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
