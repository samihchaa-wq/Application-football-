import 'package:as_grinta/features/legal/domain/legal_documents.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mentions légales, CGU ou politique de confidentialité. Accessible sans
/// être connecté : on doit pouvoir les lire avant de créer un compte.
class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final document = legalDocumentBySlug(slug);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/auth/sign-in');
            }
          },
        ),
        title: Text(document?.title ?? 'Document introuvable'),
      ),
      body: document == null
          ? const Center(child: Text('Ce document n’existe pas.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                for (final section in document.sections) ...[
                  Text(section.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final paragraph in section.paragraphs) ...[
                    SelectableText(paragraph),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 12),
                ],
                Text(
                  'Version du ${legalVersionOf(document)}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final other in legalDocuments)
                      if (other.slug != document.slug)
                        TextButton(
                          onPressed: () => context.go('/legal/${other.slug}'),
                          child: Text(other.title),
                        ),
                  ],
                ),
              ],
            ),
    );
  }
}
