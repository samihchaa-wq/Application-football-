import 'dart:convert';
import 'dart:typed_data';

import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:as_grinta/features/profile/data/personal_data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// Mot à recopier pour confirmer la suppression du compte.
const String deleteAccountConfirmationWord = 'SUPPRIMER';

/// Les droits du membre sur ses données, depuis son profil : télécharger ses
/// données, lire les textes légaux, supprimer son compte.
class MyDataSection extends ConsumerStatefulWidget {
  const MyDataSection({super.key});

  @override
  ConsumerState<MyDataSection> createState() => _MyDataSectionState();
}

class _MyDataSectionState extends ConsumerState<MyDataSection> {
  bool _exporting = false;
  bool _deleting = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final json =
          await ref.read(personalDataRepositoryProvider).exportMyData();
      const name = 'mes-donnees.json';
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(json)),
            mimeType: 'application/json',
            name: name,
          ),
        ],
        fileNameOverrides: [name],
      );
    } catch (_) {
      if (mounted) _showMessage('Tes données n’ont pas pu être préparées.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(personalDataRepositoryProvider).deleteMyAccount();
      if (!mounted) return;
      _showMessage('Ton compte a été supprimé.');
      await ref.read(authControllerProvider.notifier).signOut();
    } on StateError catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('La suppression du compte a échoué.');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mes données', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('profile-export-data'),
              onPressed: _exporting ? null : _export,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: Text(
                _exporting ? 'Préparation…' : 'Télécharger mes données',
              ),
            ),
            TextButton(
              onPressed: () => context.push('/legal/confidentialite'),
              child: const Text('Confidentialité'),
            ),
            TextButton(
              onPressed: () => context.push('/legal/cgu'),
              child: const Text('Conditions d’utilisation'),
            ),
            TextButton(
              onPressed: () => context.push('/legal/mentions'),
              child: const Text('Mentions légales'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const Key('profile-delete-account'),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
          onPressed: _deleting ? null : _delete,
          icon: const Icon(Icons.delete_forever_outlined, size: 18),
          label: Text(_deleting ? 'Suppression…' : 'Supprimer mon compte'),
        ),
      ],
    );
  }
}

/// Confirmation de la suppression : il faut recopier un mot, pour éviter une
/// suppression par erreur.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canDelete =
        _controller.text.trim().toUpperCase() == deleteAccountConfirmationWord;
    return AlertDialog(
      title: const Text('Supprimer ton compte ?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ton compte, ta photo, tes pronostics et tes préférences seront '
            'effacés. Les résultats de matchs déjà joués restent dans '
            'l’historique du club. Cette action est définitive.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('delete-account-confirmation'),
            controller: _controller,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Écris $deleteAccountConfirmationWord pour confirmer',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('delete-account-confirm'),
          onPressed: canDelete ? () => Navigator.pop(context, true) : null,
          child: const Text('Supprimer'),
        ),
      ],
    );
  }
}
