import 'package:as_grinta/core/club/club_identity.dart';
import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:as_grinta/core/widgets/grinta_app_bar.dart';
import 'package:as_grinta/core/widgets/grinta_loader.dart';
import 'package:as_grinta/features/admin/presentation/club_subscription_section.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Réglages du club, réservés à ses administrateurs : nom, invitation des
/// joueurs, fonctionnalités à activer ou non.
class ClubSettingsPage extends ConsumerStatefulWidget {
  const ClubSettingsPage({super.key});

  @override
  ConsumerState<ClubSettingsPage> createState() => _ClubSettingsPageState();
}

class _ClubSettingsPageState extends ConsumerState<ClubSettingsPage> {
  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();

  Club? _club;
  ClubModules _modules = const ClubModules.allEnabled();
  Object? _loadError;
  bool _loading = true;
  bool _savingIdentity = false;
  bool _renewingCode = false;
  final Set<ClubModule> _pendingModules = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final repository = ref.read(clubRepositoryProvider);
      final club = await repository.fetchMyClub();
      final modules = await repository.fetchModules();
      if (!mounted) return;
      setState(() {
        _club = club;
        _modules = modules;
        _nameController.text = club.name;
        _shortNameController.text = club.shortName;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveIdentity() async {
    final name = _nameController.text.trim();
    final shortName = _shortNameController.text.trim();
    if (name.length < 2 || name.length > 80) {
      _showMessage('Le nom du club doit compter entre 2 et 80 caractères.');
      return;
    }
    if (shortName.length < 2 || shortName.length > 12) {
      _showMessage('Le nom court doit compter entre 2 et 12 caractères.');
      return;
    }

    setState(() => _savingIdentity = true);
    try {
      final club = await ref
          .read(clubRepositoryProvider)
          .updateIdentity(name: name, shortName: shortName);
      if (!mounted) return;
      setState(() => _club = club);
      ref.invalidate(myClubProvider);
      ClubIdentity.set(name: club.name, shortName: club.shortName);
      _showMessage('Nom du club enregistré.');
    } catch (_) {
      if (mounted) _showMessage('Le nom du club n’a pas pu être enregistré.');
    } finally {
      if (mounted) setState(() => _savingIdentity = false);
    }
  }

  Future<void> _copyInviteLink() async {
    final club = _club;
    if (club == null) return;
    await Clipboard.setData(ClipboardData(text: club.inviteLink));
    if (mounted) {
      _showMessage('Lien d’inscription copié — partage-le à tes joueurs.');
    }
  }

  Future<void> _renewInviteCode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Changer le code d’invitation ?'),
        content: const Text(
          'L’ancien code et l’ancien lien ne fonctionneront plus. Les joueurs '
          'déjà inscrits ne sont pas concernés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Changer le code'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _renewingCode = true);
    try {
      final code =
          await ref.read(clubRepositoryProvider).regenerateInviteCode();
      if (!mounted) return;
      final club = _club;
      if (club != null) {
        setState(() {
          _club = Club(
            id: club.id,
            name: club.name,
            shortName: club.shortName,
            inviteCode: code,
          );
        });
      }
      ref.invalidate(myClubProvider);
      _showMessage('Nouveau code d’invitation : $code');
    } catch (_) {
      if (mounted) _showMessage('Le code n’a pas pu être changé.');
    } finally {
      if (mounted) setState(() => _renewingCode = false);
    }
  }

  Future<void> _setModule(ClubModule module, bool enabled) async {
    setState(() => _pendingModules.add(module));
    try {
      final modules = await ref
          .read(clubRepositoryProvider)
          .setModule(module, enabled: enabled);
      if (!mounted) return;
      setState(() => _modules = modules);
      // Les écrans qui dépendent de ce réglage se mettent à jour.
      ref.invalidate(clubModulesProvider);
    } catch (_) {
      if (mounted) _showMessage('Le réglage n’a pas pu être enregistré.');
    } finally {
      if (mounted) setState(() => _pendingModules.remove(module));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GrintaAppBar(title: const Text('Réglages du club')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: GrintaProgressIndicator());
    final club = _club;
    if (_loadError != null || club == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Impossible de charger les réglages du club.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Mon club', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          key: const Key('club-settings-name'),
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nom du club',
            prefixIcon: Icon(Icons.shield_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('club-settings-short-name'),
          controller: _shortNameController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Nom court',
            helperText: 'Affiché là où la place manque. 2 à 12 caractères.',
            prefixIcon: Icon(Icons.short_text),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _savingIdentity ? null : _saveIdentity,
            child: Text(_savingIdentity ? 'Enregistrement…' : 'Enregistrer'),
          ),
        ),
        const SizedBox(height: 28),
        Text('Inviter des joueurs', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          'Partage le lien, ou donne le code : le joueur crée son compte, puis '
          'tu le valides dans Administration.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.key_outlined, color: AppTheme.primaryBright),
            const SizedBox(width: 12),
            SelectableText(
              club.inviteCode,
              key: const Key('club-settings-invite-code'),
              style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 2),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: _copyInviteLink,
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Copier le lien d’inscription'),
            ),
            OutlinedButton.icon(
              onPressed: _renewingCode ? null : _renewInviteCode,
              icon: const Icon(Icons.autorenew_rounded, size: 18),
              label: const Text('Changer le code'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const ClubSubscriptionSection(),
        const SizedBox(height: 28),
        Text('Fonctionnalités', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          'Désactive ce dont ton club ne se sert pas : l’entrée disparaît pour '
          'tous les membres. Rien n’est effacé, tu peux réactiver à tout '
          'moment.',
        ),
        const SizedBox(height: 4),
        for (final module in ClubModule.values)
          SwitchListTile.adaptive(
            key: ValueKey('club-module-${module.key}'),
            contentPadding: EdgeInsets.zero,
            title: Text(module.label),
            subtitle: Text(module.description),
            value: _modules.isEnabled(module),
            onChanged: _pendingModules.contains(module)
                ? null
                : (value) => _setModule(module, value),
          ),
      ],
    );
  }
}
