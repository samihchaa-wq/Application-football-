import 'package:petit_filet/core/widgets/pf_loader.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/auth/presentation/consent_fields.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/legal/domain/legal_documents.dart';
import 'package:petit_filet/features/profile/data/personal_data_repository.dart';
import 'package:petit_filet/features/profile/presentation/my_data_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Les CGU ou la politique de confidentialité ont changé depuis l'accord de
/// ce compte : il accepte la nouvelle version pour continuer, ou supprime son
/// compte. L'accord est enregistré comme à l'inscription (version, date,
/// déclaration d'âge).
class AcceptUpdatedTermsPage extends ConsumerStatefulWidget {
  const AcceptUpdatedTermsPage({super.key});

  @override
  ConsumerState<AcceptUpdatedTermsPage> createState() =>
      _AcceptUpdatedTermsPageState();
}

class _AcceptUpdatedTermsPageState
    extends ConsumerState<AcceptUpdatedTermsPage> {
  AgeConfirmation? _age;
  bool _accepted = false;
  bool _busy = false;
  bool _ageInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ageInitialized) return;
    _ageInitialized = true;
    // La déclaration d'âge déjà faite est reprise : la personne la confirme
    // ou la corrige.
    final previous = ref.read(authControllerProvider).profile?.ageConfirmation;
    for (final value in AgeConfirmation.values) {
      if (value.serverValue == previous) _age = value;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _accept() async {
    final age = _age;
    if (age == null || !_accepted) return;
    setState(() => _busy = true);
    try {
      await ref.read(personalDataRepositoryProvider).acceptTerms(
            version: legalVersion,
            ageConfirmation: age.serverValue,
          );
      // Le profil rechargé porte la nouvelle version : le routeur laisse
      // alors entrer dans l'application.
      await ref.read(authControllerProvider.notifier).refreshProfile();
    } catch (_) {
      if (mounted) {
        _showMessage('Ton accord n’a pas pu être enregistré. Réessaie.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
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
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAccept = !_busy && _age != null && _accepted;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.gavel_outlined, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Les conditions ont changé',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Les conditions d’utilisation ou la politique de '
                        'confidentialité ont été mises à jour. Pour continuer '
                        'à utiliser l’application, lis-les et accepte la '
                        'nouvelle version.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version du $legalVersion',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      ConsentFields(
                        ageConfirmation: _age,
                        acceptedTerms: _accepted,
                        enabled: !_busy,
                        onAgeChanged: (value) => setState(() => _age = value),
                        onTermsChanged: (value) =>
                            setState(() => _accepted = value),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const Key('accept-updated-terms'),
                        onPressed: canAccept ? _accept : null,
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: PfProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outlined),
                        label: const Text('Accepter et continuer'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tu ne veux pas accepter ? Tu peux supprimer ton '
                        'compte, ou simplement te déconnecter.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          TextButton(
                            key: const Key('updated-terms-sign-out'),
                            onPressed: _busy
                                ? null
                                : () => ref
                                    .read(authControllerProvider.notifier)
                                    .signOut(),
                            child: const Text('Me déconnecter'),
                          ),
                          TextButton(
                            key: const Key('updated-terms-delete-account'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            onPressed: _busy ? null : _delete,
                            child: const Text('Supprimer mon compte'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
