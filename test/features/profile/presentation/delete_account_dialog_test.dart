import 'package:as_grinta/features/profile/presentation/my_data_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('supprimer son compte exige de recopier le mot de confirmation',
      (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => const DeleteAccountDialog(),
              );
            },
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    FilledButton confirm() => tester.widget<FilledButton>(
          find.byKey(const Key('delete-account-confirm')),
        );
    expect(confirm().onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('delete-account-confirmation')),
      'supprim',
    );
    await tester.pump();
    expect(confirm().onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('delete-account-confirmation')),
      'supprimer',
    );
    await tester.pump();
    expect(confirm().onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('delete-account-confirm')));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
