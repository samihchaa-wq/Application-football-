import 'package:as_grinta/core/widgets/grinta_auth_surface.dart';
import 'package:as_grinta/core/widgets/grinta_loader.dart';
import 'package:as_grinta/features/auth/data/account_email_repository.dart';
import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page ouverte par le lien reçu par e-mail : elle confirme l'adresse. Elle
/// fonctionne connecté ou non, depuis n'importe quel appareil : le lien porte
/// lui-même la preuve.
class ConfirmEmailPage extends ConsumerStatefulWidget {
  const ConfirmEmailPage({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<ConfirmEmailPage> createState() => _ConfirmEmailPageState();
}

enum _ConfirmState { checking, confirmed, invalid, failed }

class _ConfirmEmailPageState extends ConsumerState<ConfirmEmailPage> {
  _ConfirmState _state = _ConfirmState.checking;

  @override
  void initState() {
    super.initState();
    _confirm();
  }

  Future<void> _confirm() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() => _state = _ConfirmState.invalid);
      return;
    }
    setState(() => _state = _ConfirmState.checking);
    try {
      final confirmed =
          await ref.read(accountEmailRepositoryProvider).confirm(token);
      if (!mounted) return;
      if (confirmed) {
        // Le profil affiché dans l'application doit montrer l'adresse
        // confirmée.
        if (ref.read(authControllerProvider).isAuthenticated) {
          await ref.read(authControllerProvider.notifier).refreshProfile();
        }
        if (!mounted) return;
      }
      setState(
        () => _state =
            confirmed ? _ConfirmState.confirmed : _ConfirmState.invalid,
      );
    } catch (_) {
      if (mounted) setState(() => _state = _ConfirmState.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, message, icon) = switch (_state) {
      _ConfirmState.checking => (
          'Confirmation en cours…',
          'Un instant.',
          Icons.hourglass_top_rounded,
        ),
      _ConfirmState.confirmed => (
          'Adresse confirmée',
          'Tu pourras retrouver ton compte par e-mail si tu perds ton mot de '
              'passe.',
          Icons.check_circle_outline_rounded,
        ),
      _ConfirmState.invalid => (
          'Lien invalide',
          'Ce lien a déjà servi, a expiré ou est incomplet. Demande un nouveau '
              'lien depuis ton profil.',
          Icons.error_outline_rounded,
        ),
      _ConfirmState.failed => (
          'Confirmation impossible',
          'La confirmation n’a pas pu aboutir pour l’instant. Réessaie dans un '
              'moment.',
          Icons.cloud_off_rounded,
        ),
    };

    return GrintaAuthSurface(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (_state == _ConfirmState.checking)
            const Center(child: GrintaProgressIndicator())
          else if (_state == _ConfirmState.failed)
            FilledButton(onPressed: _confirm, child: const Text('Réessayer'))
          else
            FilledButton(
              onPressed: () => context.go('/matches'),
              child: Text(
                ref.watch(authControllerProvider).isAuthenticated
                    ? 'Retour à l’application'
                    : 'Se connecter',
              ),
            ),
        ],
      ),
    );
  }
}
