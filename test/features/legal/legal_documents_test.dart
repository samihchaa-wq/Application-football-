import 'package:as_grinta/features/auth/presentation/legal_document_page.dart';
import 'package:as_grinta/features/legal/domain/legal_documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('les trois textes légaux existent, chacun à sa propre adresse', () {
    expect(
      legalDocuments.map((document) => document.slug),
      ['mentions', 'cgu', 'confidentialite'],
    );
    for (final document in legalDocuments) {
      expect(document.sections, isNotEmpty);
      expect(legalDocumentBySlug(document.slug), same(document));
    }
    expect(legalDocumentBySlug('inconnu'), isNull);
  });

  test('la version des textes suit le format attendu par le serveur', () {
    expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(legalVersion), isTrue);
  });

  test('la politique de confidentialité couvre les points obligatoires', () {
    final text = privacyPolicy.sections
        .expand((section) => [section.title, ...section.paragraphs])
        .join(' ')
        .toLowerCase();
    for (final topic in [
      'responsable',
      'combien de temps',
      'cnil',
      'moins de 15 ans',
      'supprimer ton compte',
      'télécharger tes données',
    ]) {
      expect(text, contains(topic), reason: topic);
    }
  });

  testWidgets('la page affiche le document demandé', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LegalDocumentPage(slug: 'cgu')),
    );
    expect(find.text('Conditions générales d’utilisation'), findsOneWidget);
    expect(find.text('1. Objet'), findsOneWidget);
  });

  testWidgets('une adresse inconnue ne plante pas', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LegalDocumentPage(slug: 'rien')),
    );
    expect(find.text('Ce document n’existe pas.'), findsOneWidget);
  });
}
