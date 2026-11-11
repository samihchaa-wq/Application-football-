import 'package:as_grinta/core/club/club_identity.dart';
import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:as_grinta/core/widgets/grinta_app_bar.dart';
import 'package:as_grinta/core/widgets/grinta_loader.dart';
import 'package:as_grinta/features/admin/presentation/club_subscription_section.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:as_grinta/features/club/presentation/club_identity_sync.dart';
import 'package:as_grinta/features/club/presentation/club_rules_sync.dart';
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
  List<ClubRule> _rules = const [];
  final Set<String> _pendingRules = {};
  Object? _loadError;
  bool _loading = true;
  bool _savingIdentity = false;
  bool _renewingCode = false;
  bool _savingColors = false;

  /// Choix proposés : des teintes franches, lisibles une fois ajustées au
  /// fond sombre de l'application.
  static const _palette = <String>[
    '#1A4AC0',
    '#1F6FEB',
    '#0E9F9A',
    '#168A52',
    '#7CB518',
    '#FBE80C',
    '#F5A300',
    '#E8590C',
    '#D62828',
    '#C2185B',
    '#7B2CBF',
    '#FFFFFF',
  ];
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
      final rules = await repository.fetchRules();
      if (!mounted) return;
      setState(() {
        _club = club;
        _modules = modules;
        _rules = rules;
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
      final previous = _club;
      setState(() {
        _club = Club(
          id: club.id,
          name: club.name,
          shortName: club.shortName,
          inviteCode: club.inviteCode,
          primaryColor: club.primaryColor ?? previous?.primaryColor,
          secondaryColor: club.secondaryColor ?? previous?.secondaryColor,
        );
      });
      ref.invalidate(myClubProvider);
      ClubIdentity.set(name: club.name, shortName: club.shortName);
      _showMessage('Nom du club enregistré.');
    } catch (_) {
      if (mounted) _showMessage('Le nom du club n’a pas pu être enregistré.');
    } finally {
      if (mounted) setState(() => _savingIdentity = false);
    }
  }

  Future<void> _setColors({String? primary, String? secondary}) async {
    final club = _club;
    if (club == null || _savingColors) return;
    setState(() => _savingColors = true);
    try {
      final updated = await ref.read(clubRepositoryProvider).updateColors(
            primary: primary ?? club.primaryColor ?? '#1A4AC0',
            secondary: secondary ?? club.secondaryColor ?? '#FBE80C',
          );
      if (!mounted) return;
      setState(() => _club = updated);
      ref.invalidate(myClubProvider);
      applyClubColors(updated);
    } catch (_) {
      if (mounted) _showMessage('Les couleurs n’ont pas pu être enregistrées.');
    } finally {
      if (mounted) setState(() => _savingColors = false);
    }
  }

  Widget _colorRow(String label, String keyPrefix, String? current,
      void Function(String hex) onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final hex in _palette)
              Semantics(
                button: true,
                selected: current?.toUpperCase() == hex,
                label: '$label $hex',
                child: InkWell(
                  key: ValueKey('$keyPrefix-$hex'),
                  customBorder: const CircleBorder(),
                  onTap: _savingColors ? null : () => onPick(hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.parseHex(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: current?.toUpperCase() == hex
                            ? AppTheme.textPrimary
                            : AppTheme.outline,
                        width: current?.toUpperCase() == hex ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
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
            primaryColor: club.primaryColor,
            secondaryColor: club.secondaryColor,
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

  Future<void> _setRule(ClubRule rule, int? value) async {
    setState(() => _pendingRules.add(rule.key));
    try {
      final rules =
          await ref.read(clubRepositoryProvider).setRule(rule.key, value);
      if (!mounted) return;
      setState(() => _rules = rules);
      applyClubRules(rules);
    } catch (_) {
      if (mounted) _showMessage('La règle n’a pas pu être enregistrée.');
    } finally {
      if (mounted) setState(() => _pendingRules.remove(rule.key));
    }
  }

  List<Widget> _ruleSection(ThemeData theme) {
    if (_rules.isEmpty) return const [];
    final widgets = <Widget>[
      const SizedBox(height: 28),
      Text('Règles du club', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      const Text(
        'Les horaires et délais propres à ton club. Les changements '
        's’appliquent à tous les membres, pour les matchs à venir.',
      ),
    ];
    String? group;
    for (final rule in _rules) {
      if (rule.group != group) {
        group = rule.group;
        widgets
          ..add(const SizedBox(height: 16))
          ..add(Text(rule.group, style: theme.textTheme.titleSmall));
      }
      widgets.add(
        ListTile(
          key: ValueKey('club-rule-${rule.key}'),
          contentPadding: EdgeInsets.zero,
          title: Text(rule.label),
          subtitle: Text(
            '${rule.description}\nPar défaut : ${rule.defaultValue} '
            '${rule.unit}',
          ),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: ValueKey('club-rule-${rule.key}-minus'),
                icon: const Icon(Icons.remove_circle_outline),
                onPressed:
                    _pendingRules.contains(rule.key) || rule.value <= rule.min
                        ? null
                        : () => _setRule(rule, rule.value - 1),
              ),
              Text('${rule.value} ${rule.unit}'),
              IconButton(
                key: ValueKey('club-rule-${rule.key}-plus'),
                icon: const Icon(Icons.add_circle_outline),
                onPressed:
                    _pendingRules.contains(rule.key) || rule.value >= rule.max
                        ? null
                        : () => _setRule(rule, rule.value + 1),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
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
        Text('Couleurs du club', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          'L’application s’habille à ces couleurs pour tous les membres.',
        ),
        const SizedBox(height: 12),
        _colorRow(
          'Couleur principale',
          'club-color-primary',
          club.primaryColor,
          (hex) => _setColors(primary: hex),
        ),
        const SizedBox(height: 14),
        _colorRow(
          'Couleur secondaire',
          'club-color-secondary',
          club.secondaryColor,
          (hex) => _setColors(secondary: hex),
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
            Icon(Icons.key_outlined, color: AppTheme.primaryBright),
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
        ..._ruleSection(theme),
      ],
    );
  }
}
