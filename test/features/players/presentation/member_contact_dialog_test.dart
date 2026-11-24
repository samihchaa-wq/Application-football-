import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/features/players/presentation/member_contact_dialog.dart';
import 'package:petit_filet/features/profile/data/personal_data_repository.dart';

Future<void> _open(WidgetTester tester, PrivateDetails initial) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showMemberContactDialog(
            context,
            memberName: 'Hugo',
            initial: initial,
          ),
          child: const Text('ouvrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'le champ date de naissance vide a un nom pour le lecteur d’écran',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, const PrivateDetails());
    expect(find.bySemanticsLabel('Choisir la date de naissance'), findsOne);
    semantics.dispose();
  });

  testWidgets('une date choisie est annoncée avec sa valeur', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, PrivateDetails(birthDate: DateTime(1990, 5, 14)));
    expect(
      find.bySemanticsLabel(RegExp(r'^Date de naissance : .+, modifier$')),
      findsOne,
    );
    semantics.dispose();
  });
}
