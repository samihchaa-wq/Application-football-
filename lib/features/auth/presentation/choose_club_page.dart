import 'package:as_grinta/core/widgets/grinta_auth_surface.dart';
import 'package:as_grinta/core/widgets/grinta_loader.dart';
import 'package:as_grinta/features/auth/presentation/auth_register_page.dart'
    show RegisterMode;
import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dernière étape d'une connexion par Facebook : le compte n'a pas encore de
/// club. La personne en rejoint un avec un code d'invitation, ou en crée un.
class ChooseClubPage extends ConsumerStatefulWidget {
  const ChooseClubPage({super.key});

  @override
  ConsumerState<ChooseClubPage> createState() => _ChooseClubPageState();
}

class _ChooseClubPageState extends ConsumerState<ChooseClubPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _clubNameController = TextEditingController();
  final _clubShortNameController = TextEditingController();
  RegisterMode _mode = RegisterMode.join;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final names = ref.read(authControllerProvider.notifier).suggestedNames;
    _firstNameController.text = names.firstName;
    _lastNameController.text = names.lastName;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _inviteCodeController.dispose();
    _clubNameController.dispose();
    _clubShortNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final code = normalizeInviteCode(_inviteCodeController.text);
    final clubName = _clubNameController.text.trim();
    final shortName = _clubShortNameController.text.trim();
    final create = _mode == RegisterMode.create;

    String? problem;
    if (firstName.length < 2 || lastName.length < 2) {
      problem = 'Renseigne ton prénom et ton nom.';
    } else if (!create && !inviteCodePattern.hasMatch(code)) {
      problem =
          'Saisis le code d’invitation de ton club : 8 lettres ou chiffres.';
    } else if (create && (clubName.length < 2 || clubName.length > 80)) {
      problem = 'Le nom du club doit compter entre 2 et 80 caractères.';
    } else if (create && shortName.length > 12) {
      problem = 'Le nom court ne doit pas dépasser 12 caractères.';
    }
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(clubRepositoryProvider).claimClub(
            create: create,
            inviteCode: code,
            clubName: clubName,
            clubShortName: shortName,
            firstName: firstName,
            lastName: lastName,
          );
      // Le profil existe maintenant : le routeur fait entrer dans le club, ou
      // sur l'écran d'attente quand un admin doit valider le compte.
      await ref.read(authControllerProvider.notifier).refreshProfile();
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Le rattachement au club a échoué.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final create = _mode == RegisterMode.create;
    return GrintaAuthSurface(
      maxWidth: 760,
      title: 'Ton club',
      subtitle: 'Dernière étape : rejoins ton club ou crée-le.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<RegisterMode>(
            segments: const [
              ButtonSegment(
                value: RegisterMode.join,
                icon: Icon(Icons.group_add_outlined),
                label: Text('Rejoindre un club'),
              ),
              ButtonSegment(
                value: RegisterMode.create,
                icon: Icon(Icons.add_business_outlined),
                label: Text('Créer un club'),
              ),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged: _submitting
                ? null
                : (selection) => setState(() => _mode = selection.first),
          ),
          const SizedBox(height: 20),
          if (create) ...[
            TextField(
              key: const Key('choose-club-name'),
              controller: _clubNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom du club',
                prefixIcon: Icon(Icons.shield_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clubShortNameController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Nom court (facultatif)',
                prefixIcon: Icon(Icons.short_text),
              ),
            ),
          ] else
            TextField(
              key: const Key('choose-club-code'),
              controller: _inviteCodeController,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Code d’invitation du club',
                helperText: 'Donné par l’administrateur de ton club.',
                prefixIcon: Icon(Icons.key_outlined),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Prénom',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nom',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: GrintaProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sports_soccer),
            label: Text(
              _submitting
                  ? 'En cours…'
                  : create
                      ? 'Créer mon club'
                      : 'Rejoindre le club',
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _submitting
                ? null
                : () => ref.read(authControllerProvider.notifier).signOut(),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
