import 'package:petit_filet/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Adresse de contact de l'éditeur, sélectionnable, avec un bouton qui ouvre
/// la messagerie. Sans elle, « contacte-nous » ne mène nulle part.
class SupportContact extends StatelessWidget {
  const SupportContact({
    super.key,
    this.subject = 'Abonnement Petit Filet',
    this.center = false,
  });

  final String subject;
  final bool center;

  static Uri mailtoUri(String subject) => Uri(
        scheme: 'mailto',
        path: AppConfig.supportEmail,
        query: 'subject=${Uri.encodeComponent(subject)}',
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectableText(
          AppConfig.supportEmail,
          key: const Key('support-contact-email'),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
        TextButton.icon(
          key: const Key('support-contact-button'),
          onPressed: () => launchUrl(mailtoUri(subject)),
          icon: const Icon(Icons.mail_outline),
          label: const Text('Nous écrire'),
        ),
      ],
    );
  }
}
