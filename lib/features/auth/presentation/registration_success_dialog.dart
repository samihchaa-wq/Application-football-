import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Confirmation commune aux inscriptions, sans dépendance au réseau.
class RegistrationSuccessDialog extends StatefulWidget {
  const RegistrationSuccessDialog({
    super.key,
    required this.username,
    required this.teamName,
    required this.isActive,
    required this.emailConfirmationSent,
  });

  final String username;
  final String teamName;
  final bool isActive;
  final bool emailConfirmationSent;

  @override
  State<RegistrationSuccessDialog> createState() =>
      _RegistrationSuccessDialogState();
}

class _RegistrationSuccessDialogState extends State<RegistrationSuccessDialog> {
  String? _copyStatus;
  bool _copying = false;

  Future<void> _copyUsername() async {
    setState(() => _copying = true);
    String status;
    try {
      await Clipboard.setData(ClipboardData(text: widget.username));
      status = 'Identifiant copié.';
    } catch (_) {
      status = 'Copie impossible. Sélectionne ton identifiant pour le copier.';
    }
    if (!mounted) return;
    setState(() {
      _copying = false;
      _copyStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(
        widget.isActive ? 'Équipe créée : ${widget.teamName}' : 'Compte créé',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Retiens bien ton identifiant, tu en auras besoin pour te '
            'connecter :',
          ),
          const SizedBox(height: 12),
          SelectableText(
            widget.username,
            style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
          ),
          TextButton(
            onPressed: _copying ? null : _copyUsername,
            child: const Text('Copier mon identifiant'),
          ),
          if (_copyStatus != null)
            Semantics(liveRegion: true, child: Text(_copyStatus!)),
          const SizedBox(height: 12),
          Text(
            widget.isActive
                ? 'Tu es l’administrateur de l’équipe. Connecte-toi, puis '
                    'ouvre Paramètres → Effectif → Lien d’inscription '
                    'pour inviter tes joueurs.'
                : 'Ton compte chez ${widget.teamName} restera en attente '
                    'jusqu’à sa validation par un admin.',
          ),
          if (widget.emailConfirmationSent) ...[
            const SizedBox(height: 12),
            const Text(
              'Un e-mail de confirmation vient d’être envoyé : ouvre le '
              'lien qu’il contient pour valider ton adresse.',
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Compris'),
        ),
      ],
    );
  }
}
