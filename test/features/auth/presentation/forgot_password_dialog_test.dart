import 'package:as_grinta/features/auth/data/account_email_repository.dart';
import 'package:as_grinta/features/auth/presentation/auth_sign_in_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAccountEmailRepository implements AccountEmailRepository {
  final requested = <String>[];
  Object? failure;

  @override
  Future<void> requestPasswordReset(String email) async {
    if (failure != null) throw failure!;
    requested.add(email);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeAccountEmailRepository repository;

  setUp(() => repository = _FakeAccountEmailRepository());

  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountEmailRepositoryProvider.overrideWithValue(repository)
        ],
        child: const MaterialApp(home: Scaffold(body: ForgotPasswordDialog())),
      ),
    );
  }

  testWidgets('une adresse invalide n’envoie rien', (tester) async {
    await pumpDialog(tester);
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.text('Envoyer le lien'));
    await tester.pump();

    expect(find.text('Saisis une adresse e-mail valide.'), findsOneWidget);
    expect(repository.requested, isEmpty);
  });

  testWidgets('la réponse ne dit pas si l’adresse est connue', (tester) async {
    await pumpDialog(tester);
    await tester.enterText(find.byType(TextField), 'karim@example.com');
    await tester.tap(find.text('Envoyer le lien'));
    await tester.pumpAndSettle();

    expect(repository.requested, ['karim@example.com']);
    expect(
        find.textContaining('Si cette adresse est confirmée'), findsOneWidget);
  });

  testWidgets('une erreur du serveur est affichée', (tester) async {
    repository.failure = StateError('Trop de demandes.');
    await pumpDialog(tester);
    await tester.enterText(find.byType(TextField), 'karim@example.com');
    await tester.tap(find.text('Envoyer le lien'));
    await tester.pumpAndSettle();

    expect(find.text('Trop de demandes.'), findsOneWidget);
  });
}
