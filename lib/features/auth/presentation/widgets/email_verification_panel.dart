import 'package:flutter/material.dart';

/// Vue de l'étape e-mail de #160. M02 fournit l'état issu du serveur ; cette
/// vue n'accorde aucun accès et n'effectue ni requête ni validation de compte.
enum EmailVerificationStatus {
  waiting,
  sending,
  sent,
  failed,
  expired,
  awaitingAdmin,
}

class EmailVerificationPanel extends StatelessWidget {
  const EmailVerificationPanel({
    super.key,
    required this.email,
    required this.status,
    required this.onResend,
    required this.onEditEmail,
    this.retryAfterSeconds = 0,
  });

  final String email;
  final EmailVerificationStatus status;
  final VoidCallback onResend;
  final VoidCallback onEditEmail;
  final int retryAfterSeconds;

  @override
  Widget build(BuildContext context) {
    final awaitingAdmin = status == EmailVerificationStatus.awaitingAdmin;
    final sending = status == EmailVerificationStatus.sending;
    final message = switch (status) {
      EmailVerificationStatus.waiting =>
        'Ouvre le lien de confirmation reçu à cette adresse. Vérifie aussi les courriers indésirables.',
      EmailVerificationStatus.sending => 'Envoi en cours…',
      EmailVerificationStatus.sent =>
        'Un nouveau lien a été envoyé. Utilise le plus récent.',
      EmailVerificationStatus.failed =>
        'L’envoi n’a pas pu aboutir. Vérifie ton adresse puis réessaie.',
      EmailVerificationStatus.expired =>
        'Ce lien a expiré ou a déjà été utilisé. Demande un nouveau lien.',
      EmailVerificationStatus.awaitingAdmin =>
        'Ton adresse est confirmée. Un administrateur doit encore accepter ton arrivée dans l’équipe.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          awaitingAdmin
              ? 'En attente de l’équipe'
              : 'Confirme ton adresse e-mail',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        SelectableText(email),
        const SizedBox(height: 12),
        Semantics(liveRegion: true, child: Text(message)),
        if (!awaitingAdmin) ...[
          const SizedBox(height: 20),
          FilledButton(
            onPressed: sending || retryAfterSeconds > 0 ? null : onResend,
            child: Text(
              retryAfterSeconds > 0
                  ? 'Renvoyer dans $retryAfterSeconds s'
                  : 'Renvoyer le lien',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: sending ? null : onEditEmail,
            child: const Text(
              'Corriger mon adresse e-mail',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
