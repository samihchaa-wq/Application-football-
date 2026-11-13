import 'package:as_grinta/core/club/club_identity.dart';
import 'package:as_grinta/core/club/club_rules.dart';
import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:as_grinta/core/widgets/grinta_app_bar.dart';
import 'package:as_grinta/core/widgets/grinta_loader.dart';
import 'package:as_grinta/features/admin/presentation/club_subscription_section.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:as_grinta/features/club/presentation/club_identity_sync.dart';
import 'package:as_grinta/features/club/presentation/club_rules_sync.dart';
import 'package:as_grinta/features/feature_flags/presentation/feature_flags_controller.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final _homeAddressController = TextEditingController();

  Club? _club;
  ClubModules _modules = const ClubModules.allEnabled();
  List<ClubRule> _rules = const [];
  int _usualSquadSize = 14;
  final Set<String> _pendingRules = {};
  Object? _loadError;
  bool _loading = true;
  bool _savingIdentity = false;
  bool _savingHomeAddress = false;
  bool _savingUsualSquadSize = false;
  bool _renewingCode = false;
  bool _savingColors = false;
  bool _savingLogo = false;

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
    _homeAddressController.dispose();
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
      final homeAddress = await repository.fetchHomeAddress();
      final usualSquadSize = await repository.fetchUsualSquadSize();
      if (!mounted) return;
      setState(() {
        _club = club;
        _modules = modules;
        _rules = rules;
        _nameController.text = club.name;
        _shortNameController.text = club.shortName;
        _homeAddressController.text = homeAddress ?? '';
        _usualSquadSize = usualSquadSize;
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
          logoPath: previous?.logoPath,
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

  Future<void> _saveHomeAddress() async {
    final address = _homeAddressController.text.trim();
    if (address.length > 200 || address.contains(RegExp(r'[\r\n\t]'))) {
      _showMessage(
          'L’adresse doit tenir sur une ligne (200 caractères maximum).');
      return;
    }
    setState(() => _savingHomeAddress = true);
    try {
      final saved = await ref
          .read(clubRepositoryProvider)
          .updateHomeAddress(address.isEmpty ? null : address);
      if (!mounted) return;
      _homeAddressController.text = saved ?? '';
      _showMessage(saved == null
          ? 'Adresse du terrain effacée.'
          : 'Adresse du terrain enregistrée.');
    } catch (_) {
      if (mounted) {
        _showMessage('L’adresse du terrain n’a pas pu être enregistrée.');
      }
    } finally {
      if (mounted) setState(() => _savingHomeAddress = false);
    }
  }

  Future<void> _saveUsualSquadSize(int value) async {
    if (_savingUsualSquadSize || value < 1 || value > 30) return;
    setState(() => _savingUsualSquadSize = true);
    try {
      final saved =
          await ref.read(clubRepositoryProvider).updateUsualSquadSize(value);
      if (!mounted) return;
      setState(() => _usualSquadSize = saved);
      // Les formulaires de futurs matchs relisent le quota du club.
      ref.invalidate(featureFlagsControllerProvider);
    } catch (_) {
      if (mounted) {
        _showMessage('Le nombre de convoqués n’a pas pu être enregistré.');
      }
    } finally {
      if (mounted) setState(() => _savingUsualSquadSize = false);
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

  void _adoptClub(Club club) {
    setState(() => _club = club);
    ref.invalidate(myClubProvider);
    ClubIdentity.setLogoUrl(ref.read(clubRepositoryProvider).logoUrl(club));
  }

  Future<void> _pickLogo() async {
    final club = _club;
    if (club == null || _savingLogo) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (file == null || !mounted) return;
    setState(() => _savingLogo = true);
    try {
      final bytes = await file.readAsBytes();
      final name = file.name;
      final ext = name.contains('.') ? name.split('.').last : 'png';
      final updated = await ref
          .read(clubRepositoryProvider)
          .uploadLogo(bytes, ext, club.id);
      if (!mounted) return;
      _adoptClub(updated);
      _showMessage('Logo enregistré.');
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Le logo n’a pas pu être envoyé (image JPEG, PNG ou WebP, 5 Mo max).',
        );
      }
    } finally {
      if (mounted) setState(() => _savingLogo = false);
    }
  }

  Future<void> _removeLogo() async {
    if (_savingLogo) return;
    setState(() => _savingLogo = true);
    try {
      final updated = await ref.read(clubRepositoryProvider).removeLogo();
      if (!mounted) return;
      _adoptClub(updated);
      _showMessage('Logo retiré.');
    } catch (_) {
      if (mounted) _showMessage('Le logo n’a pas pu être retiré.');
    } finally {
      if (mounted) setState(() => _savingLogo = false);
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
            primaryColor: club.primaryColor,
            secondaryColor: club.secondaryColor,
            logoPath: club.logoPath,
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


  void _showInfo(String title, String description) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(description)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _infoButton(String key, String title, String description) =>
      IconButton(
        key: ValueKey('club-info-$key'),
        tooltip: 'Informations : $title',
        icon: const Icon(Icons.info_outline_rounded, size: 20),
        onPressed: () => _showInfo(title, description),
      );

  Widget _labelWithInfo(String key, String label, String description) =>
      Row(
        children: [
          Expanded(child: Text(label)),
          _infoButton(key, label, description),
        ],
      );

  Widget _section(String key, String title, IconData icon,
      List<Widget> children, {bool expanded = false}) => Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 10),
        child: ExpansionTile(
          key: ValueKey('club-section-$key'),
          initiallyExpanded: expanded,
          leading: Icon(icon),
          title: Text(title),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ],
        ),
      );

  String _moduleCategory(ClubModule module) {
    if (module == ClubModule.weather || module == ClubModule.liveMode) {
      return 'matches';
    }
    if (module == ClubModule.predictions) return 'predictions';
    if (module == ClubModule.statistics ||
        module == ClubModule.manOfTheMatch ||
        module == ClubModule.badges ||
        module == ClubModule.seasonWrapped) {
      return 'rewards';
    }
    return 'other';
  }

  String _ruleCategory(ClubRule rule) {
    if (rule.key == ClubRules.waitlistModeKey ||
        rule.key == ClubRules.featuresOpenDaysKey ||
        rule.key == ClubRules.featuresOpenHourKey) return 'squad';
    if (rule.key == ClubRules.correctionWindowHoursKey) return 'matches';
    if (rule.key.startsWith('prediction_')) return 'predictions';
    return 'other';
  }

  bool _isRelevantRule(ClubRule rule) =>
      rule.key != 'waitlist_cutoff_days' &&
      rule.key != 'waitlist_cutoff_hour';

  List<Widget> _modulesFor(String category) => [
        for (final module in ClubModule.values)
          if (_moduleCategory(module) == category)
            SwitchListTile.adaptive(
              key: ValueKey('club-module-' + module.key),
              contentPadding: EdgeInsets.zero,
              title: _labelWithInfo('module-' + module.key, module.label,
                module.description +
                  '\n\nLa désactivation conserve les données existantes.'),
              value: _modules.isEnabled(module),
              onChanged: _pendingModules.contains(module)
                  ? null
                  : (value) => _setModule(module, value),
            ),
      ];

  List<Widget> _rulesFor(String category) => [
        for (final rule in _rules)
          if (_isRelevantRule(rule) && _ruleCategory(rule) == category)
            if (rule.key == ClubRules.waitlistModeKey)
              _waitlistModeTile(rule)
            else
              ListTile(
                key: ValueKey('club-rule-' + rule.key),
                contentPadding: EdgeInsets.zero,
                title: _labelWithInfo('rule-' + rule.key, rule.label,
                  rule.description + '\n\nValeur par défaut : ' +
                  _ruleValueLabel(rule, rule.defaultValue)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: ValueKey('club-rule-' + rule.key + '-minus'),
                      tooltip: 'Diminuer',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _pendingRules.contains(rule.key) ||
                              rule.value <= rule.min
                          ? null
                          : () => _setRule(rule, rule.value - 1),
                    ),
                    Text(_ruleValueLabel(rule, rule.value)),
                    IconButton(
                      key: ValueKey('club-rule-' + rule.key + '-plus'),
                      tooltip: 'Augmenter',
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _pendingRules.contains(rule.key) ||
                              rule.value >= rule.max
                          ? null
                          : () => _setRule(rule, rule.value + 1),
                    ),
                  ],
                ),
              ),
      ];

  String _ruleValueLabel(ClubRule rule, int value) =>
      rule.unit == ClubRules.multiplierUnit
          ? ClubRules.formatMultiplier(value)
          : '$value ' + rule.unit;

  Widget _waitlistModeTile(ClubRule rule) {
    final current = WaitlistMode.fromValue(rule.value);
    final pending = _pendingRules.contains(rule.key);
    final info = [
      rule.description,
      for (final mode in WaitlistMode.values)
        mode.label + ' : ' + mode.description,
      'Les +1 sont attribués et retirés uniquement par les admins. '
          'Aucun +1 n’est automatique.',
    ].join('\n\n');
    return Padding(
      key: ValueKey('club-rule-' + rule.key),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelWithInfo('rule-' + rule.key, rule.label, info),
          DropdownButton<WaitlistMode>(
            key: ValueKey('club-rule-' + rule.key + '-select'),
            value: current,
            isExpanded: true,
            items: [
              for (final mode in WaitlistMode.values)
                DropdownMenuItem(value: mode, child: Text(mode.label)),
            ],
            onChanged: pending
                ? null
                : (selected) {
                    if (selected == null || selected == current) return;
                    _setRule(rule, selected.value);
                  },
          ),
        ],
      ),
    );
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
              const Text('Impossible de charger les réglages du club.'),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    return ListView(
      key: const Key('club-settings-list'),
      padding: const EdgeInsets.all(12),
      children: [
        _section('identity', 'Identité et maillots',
          Icons.shield_outlined, [
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
          decoration: InputDecoration(
            labelText: 'Nom court',
            suffixIcon: _infoButton('short-name', 'Nom court',
                'Utilisé quand la place manque (2 à 12 caractères).'),
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

_labelWithInfo('logo', 'Écusson du club', 'Écusson affiché dans l’application. Image JPEG, PNG ou WebP, de préférence carrée.'),
const SizedBox(height: 8),
        const SizedBox(height: 12),
        Row(
          children: [
            Image(image: ClubIdentity.crestImage, width: 56, height: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    key: const Key('club-logo-pick'),
                    onPressed: _savingLogo ? null : _pickLogo,
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: Text(_savingLogo ? 'Envoi…' : 'Choisir un logo'),
                  ),
                  if (club.logoPath != null)
                    OutlinedButton(
                      key: const Key('club-logo-remove'),
                      onPressed: _savingLogo ? null : _removeLogo,
                      child: const Text('Retirer'),
                    ),
                ],
              ),
            ),
          ],
        ),

_labelWithInfo('colors', 'Couleurs du club', 'Couleurs de l’interface pour tous les membres du club.'),
const SizedBox(height: 8),
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
        const SizedBox(height: 12),
        ListTile(
          key: const ValueKey('club-kits-entry'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.checkroom_rounded),
          title: _labelWithInfo('kits', 'Maillots du club',
            'Choisis les tenues des joueurs et des gardiens. Elles sont '
            'utilisées dans les compositions et les matchs.'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/admin/club/maillots'),
        ),

        ], expanded: true),
        _section('squad', 'Effectif et convocations',
          Icons.groups_outlined, [
const SizedBox(height: 8),
        ListTile(
          key: const Key('club-usual-squad-size'),
          contentPadding: EdgeInsets.zero,
          title: _labelWithInfo('quota', 'Convoqués par défaut',
                'Nombre prévu à la création d’un match (1 à 30). Peut être modifié par rencontre.'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('club-usual-squad-size-minus'),
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _savingUsualSquadSize || _usualSquadSize <= 1
                    ? null
                    : () => _saveUsualSquadSize(_usualSquadSize - 1),
              ),
              Text('$_usualSquadSize'),
              IconButton(
                key: const Key('club-usual-squad-size-plus'),
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _savingUsualSquadSize || _usualSquadSize >= 30
                    ? null
                    : () => _saveUsualSquadSize(_usualSquadSize + 1),
              ),
            ],
          ),
        ),

          ..._rulesFor('squad'),
        ]),
        _section('matches', 'Matchs et direct',
          Icons.sports_soccer_outlined, [
const SizedBox(height: 8),
        const SizedBox(height: 12),
        TextField(
          key: const Key('club-settings-home-address'),
          controller: _homeAddressController,
          maxLength: 200,
          keyboardType: TextInputType.streetAddress,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Adresse du terrain',
            suffixIcon: _infoButton('home-address', 'Terrain à domicile',
                'Proposé par défaut pour les matchs à domicile. Modifiable par match.'),
            hintText: 'Rue, code postal, ville',
            prefixIcon: Icon(Icons.place_outlined),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            key: const Key('club-settings-save-home-address'),
            onPressed: _savingHomeAddress ? null : _saveHomeAddress,
            child: Text(_savingHomeAddress
                ? 'Enregistrement…'
                : 'Enregistrer l’adresse'),
          ),
        ),

          ..._modulesFor('matches'),
          ..._rulesFor('matches'),
        ]),
        _section('predictions', 'Pronostics',
          Icons.emoji_events_outlined, [
          ..._modulesFor('predictions'),
          ..._rulesFor('predictions'),
        ]),
        _section('rewards', 'Statistiques et récompenses',
          Icons.bar_chart_rounded, [
          ..._modulesFor('rewards'),
          ..._rulesFor('rewards'),
        ]),
        if (ClubModule.values.any((m) => _moduleCategory(m) == 'other') ||
            _rules.any((r) => _isRelevantRule(r) &&
                _ruleCategory(r) == 'other'))
          _section('other', 'Autres réglages', Icons.tune_rounded, [
            ..._modulesFor('other'),
            ..._rulesFor('other'),
          ]),
        _section('members', 'Membres et invitations',
          Icons.person_add_alt_1_outlined, [
_labelWithInfo('invite', 'Code d’invitation', 'Lien ou code à donner aux futurs membres. L’administrateur valide ensuite les inscriptions.'),
const SizedBox(height: 8),
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

        ]),
        _section('subscription', 'Abonnement',
          Icons.credit_card_outlined, [
          const ClubSubscriptionSection(),
        ]),
      ],
    );
  }

}
