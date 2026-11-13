import 'package:as_grinta/core/config/app_config.dart';
import 'package:as_grinta/core/widgets/grinta_auth_surface.dart';
import 'package:as_grinta/core/widgets/grinta_loader.dart';
import 'package:as_grinta/core/widgets/grinta_status_banner.dart';
import 'package:as_grinta/features/auth/data/account_email_repository.dart';
import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuthSignInPage extends ConsumerStatefulWidget {
  const AuthSignInPage({super.key});

  @override
  ConsumerState<AuthSignInPage> createState() => _AuthSignInPageState();
}

class _AuthSignInPageState extends ConsumerState<AuthSignInPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Renseigne ton identifiant et ton mot de passe.'),
        ),
      );
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .signIn(username: username, password: password);
  }

  Future<void> _forgotPassword() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const ForgotPasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final error = authState.error;

    return GrintaAuthSurface(
      subtitle: 'L’application de gestion sportive de ton club.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null && error.isNotEmpty) ...[
            GrintaStatusBanner(
              title: signInErrorTitle(error),
              message: signInErrorDetail(error),
              tone: GrintaStatusTone.error,
              compact: true,
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(
              labelText: 'Identifiant',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) {
              if (!authState.isLoading) _submit();
            },
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Afficher le mot de passe'
                    : 'Masquer le mot de passe',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(
                  () => _obscurePassword = !_obscurePassword,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: authState.isLoading ? null : _forgotPassword,
              child: const Text('Mot de passe oublié ?'),
            ),
          ),
          FilledButton.icon(
            onPressed: authState.isLoading ? null : _submit,
            icon: authState.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: GrintaProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login_rounded),
            label: Text(authState.isLoading ? 'Connexion…' : 'Se connecter'),
          ),
          if (AppConfig.facebookLoginEnabled) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('sign-in-facebook'),
              onPressed: authState.isLoading
                  ? null
                  : () => ref
                      .read(authControllerProvider.notifier)
                      .signInWithFacebook(),
              icon: const Icon(Icons.facebook),
              label: const Text('Continuer avec Facebook'),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed:
                authState.isLoading ? null : () => context.go('/auth/register'),
            icon: const Icon(Icons.person_add_alt_outlined),
            label: const Text('Créer mon compte'),
          ),
        ],
      ),
    );
  }
}

/// Titre du bandeau d'erreur de connexion.
@visibleForTesting
String signInErrorTitle(String error) => error == 'Ce compte n’est pas actif.'
    ? 'Accès refusé'
    : 'Connexion impossible';

/// Texte du bandeau, sans répéter son titre : « Connexion impossible » en
/// titre suivi de « Connexion impossible. Vérifie ton identifiant… » disait
/// deux fois la même chose.
@visibleForTesting
String signInErrorDetail(String error) {
  final title = signInErrorTitle(error);
  final repeated = '$title. ';
  if (error.startsWith(repeated) && error.length > repeated.length) {
    return error.substring(repeated.length);
  }
  return error;
}

/// Mot de passe oublié : un lien est envoyé à l'adresse e-mail confirmée du
/// compte. La réponse est la même que l'adresse soit connue ou non.
class ForgotPasswordDialog extends ConsumerStatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  ConsumerState<ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<ForgotPasswordDialog> {
  final _controller = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _controller.text.trim();
    if (!looksLikeEmail(email)) {
      setState(() => _error = 'Saisis une adresse e-mail valide.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(accountEmailRepositoryProvider)
          .requestPasswordReset(email);
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error'.replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mot de passe oublié'),
      content: _sent
          ? const Text(
              'Si cette adresse est confirmée sur un compte, un lien vient '
              'd’être envoyé. Il est valable peu de temps.',
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saisis l’adresse e-mail confirmée sur ton compte : tu '
                  'recevras un lien pour choisir un nouveau mot de passe. '
                  'Sans adresse confirmée, demande à un administrateur du '
                  'club de réinitialiser ton mot de passe.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: 'Adresse e-mail',
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ],
            ),
      actions: [
        if (_sent)
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          )
        else ...[
          TextButton(
            onPressed: _sending ? null : () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: _sending ? null : _send,
            child: Text(_sending ? 'Envoi…' : 'Envoyer le lien'),
          ),
        ],
      ],
    );
  }
}
