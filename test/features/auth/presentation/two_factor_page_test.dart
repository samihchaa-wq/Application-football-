import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/features/auth/data/mfa_repository.dart';
import 'package:petit_filet/features/auth/presentation/two_factor_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Double authentification des admins (audit du 26/11/2026, point 39).
void main() {
  late _FakeMfa mfa;

  setUp(() => mfa = _FakeMfa());

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mfaRepositoryProvider.overrideWithValue(mfa)],
        child: const MaterialApp(home: TwoFactorPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('un code valide contient exactement 6 chiffres', () {
    expect(isValidTotpCode('123456'), isTrue);
    expect(isValidTotpCode('123 456'), isTrue);
    expect(isValidTotpCode('12345'), isFalse);
    expect(isValidTotpCode('12345a'), isFalse);
    expect(isValidTotpCode('1234567'), isFalse);
  });

  test('un code refusé par Supabase donne un message clair', () {
    expect(
      mfaErrorMessage(
        const AuthException('Invalid TOTP code',
            code: 'mfa_verification_failed'),
      ),
      contains('Code incorrect'),
    );
  });

  testWidgets('activer : QR code, code trop court refusé, puis activée',
      (tester) async {
    await pumpPage(tester);
    expect(find.text('Pas encore activée.'), findsOneWidget);

    await tester.tap(find.text('Activer'));
    await tester.pumpAndSettle();
    expect(find.byType(TotpQrCode), findsOneWidget);
    expect(find.text('SECRETCLE'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(find.text('Le code contient 6 chiffres.'), findsOneWidget);
    expect(mfa.confirmed, isEmpty);

    await tester.enterText(find.byType(TextField), '123 456');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(mfa.confirmed, ['nouveau:123456']);
    expect(find.text('Activée sur ce compte.'), findsOneWidget);
    expect(find.text('Double authentification activée.'), findsOneWidget);
  });

  testWidgets('annuler une activation retire le code préparé', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Activer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(mfa.removed, ['nouveau']);
    expect(find.text('Pas encore activée.'), findsOneWidget);
  });

  testWidgets('un mauvais code à l’activation affiche le message',
      (tester) async {
    mfa.failVerification = true;
    await pumpPage(tester);
    await tester.tap(find.text('Activer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '000000');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Code incorrect'), findsOneWidget);
    expect(find.text('Activée sur ce compte.'), findsNothing);
  });

  testWidgets('désactiver demande un code puis retire le facteur',
      (tester) async {
    mfa.factorId = 'actif';
    await pumpPage(tester);
    expect(find.text('Activée sur ce compte.'), findsOneWidget);

    await tester.tap(find.text('Désactiver'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '654321');
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pumpAndSettle();

    expect(mfa.verified, ['654321']);
    expect(mfa.removed, ['actif']);
    expect(find.text('Pas encore activée.'), findsOneWidget);
  });

  group('action sensible d’un admin', () {
    Future<bool?> runCheck(WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mfaRepositoryProvider.overrideWithValue(mfa)],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () async {
                    result =
                        await confirmTwoFactorForSensitiveAction(context, ref);
                  },
                  child: const Text('Agir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Agir'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('sans double authentification : aucune question',
        (tester) async {
      mfa.needsCode = false;
      expect(await runCheck(tester), isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('activée : code demandé, annuler bloque l’action',
        (tester) async {
      mfa.needsCode = true;
      await runCheck(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(mfa.verified, isEmpty);
    });

    testWidgets('activée : bon code, l’action continue', (tester) async {
      mfa.needsCode = true;
      bool? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mfaRepositoryProvider.overrideWithValue(mfa)],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () async {
                    result =
                        await confirmTwoFactorForSensitiveAction(context, ref);
                  },
                  child: const Text('Agir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Agir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '111222');
      await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
      await tester.pumpAndSettle();
      expect(mfa.verified, ['111222']);
      expect(result, isTrue);
    });
  });
}

class _FakeMfa implements MfaRepository {
  String? factorId;
  bool needsCode = false;
  bool failVerification = false;
  final confirmed = <String>[];
  final verified = <String>[];
  final removed = <String>[];

  @override
  Future<String?> verifiedTotpFactorId() async => factorId;

  @override
  bool needsCodeForSensitiveAction() => needsCode;

  @override
  Future<TotpEnrollmentStart> startEnrollment() async =>
      const TotpEnrollmentStart(
        factorId: 'nouveau',
        secret: 'SECRETCLE',
        uri:
            'otpauth://totp/Petit%20Filet:admin?secret=SECRETCLE&issuer=Petit%20Filet',
      );

  @override
  Future<void> confirmEnrollment({
    required String factorId,
    required String code,
  }) async {
    if (failVerification) {
      throw const AuthException('Invalid TOTP code',
          code: 'mfa_verification_failed');
    }
    confirmed.add('$factorId:$code');
  }

  @override
  Future<void> verifyCode(String code) async {
    if (failVerification) {
      throw const AuthException('Invalid TOTP code',
          code: 'mfa_verification_failed');
    }
    verified.add(code);
  }

  @override
  Future<void> removeFactor(String factorId) async => removed.add(factorId);
}
