import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copie [link] dans le presse-papiers et l'annonce par [copiedMessage].
///
/// Le navigateur peut refuser la copie (autorisation refusée, ou copie
/// demandée après une attente réseau). Dans ce cas, le lien s'affiche dans
/// une fenêtre pour être sélectionné et copié à la main, avec un bouton
/// « Copier » : cet appui direct est un nouveau geste, que le navigateur
/// accepte en général.
Future<void> copyLinkOrShow(
  BuildContext context, {
  required String link,
  required String copiedMessage,
  String title = 'Lien à partager',
}) async {
  try {
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(copiedMessage)));
  } catch (_) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => CopyLinkDialog(title: title, link: link),
    );
  }
}

/// Fenêtre qui montre un lien que le presse-papiers n'a pas pu recevoir.
class CopyLinkDialog extends StatefulWidget {
  const CopyLinkDialog({super.key, required this.title, required this.link});

  final String title;
  final String link;

  @override
  State<CopyLinkDialog> createState() => _CopyLinkDialogState();
}

class _CopyLinkDialogState extends State<CopyLinkDialog> {
  String? _status;

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.link));
      if (mounted) setState(() => _status = 'Lien copié.');
    } catch (_) {
      if (mounted) {
        setState(
          () => _status = 'Copie refusée : sélectionne le lien et copie-le.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'La copie automatique n’a pas marché. Copie ce lien à la main :',
          ),
          const SizedBox(height: 12),
          SelectableText(widget.link, key: const Key('copy-link-text')),
          if (status != null) ...[
            const SizedBox(height: 12),
            Text(status, key: const Key('copy-link-status')),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: _copy, child: const Text('Copier')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
