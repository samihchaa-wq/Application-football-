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
        _settingTitle(
          label,
          label == 'Couleur principale'
              ? 'Couleur de référence utilisée dans l’interface du club.'
              : 'Couleur complémentaire utilisée dans l’interface du club.',
        ),
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


  // L'aide est accessible sur demande ; elle ne surcharge pas l'écran.
  Widget _infoButton(String title, String description) => IconButton(
        tooltip: 'Informations : $title',
        icon: const Icon(Icons.info_outline_rounded, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(description),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      );

  Widget _settingTitle(String title, String description) => Row(
        children: [
          Expanded(child: Text(title)),
          _infoButton(title, description),
        ],
      );

  Widget _settingsSection(
    String id,
    String title,
    IconData icon,
    List<Widget> children, {
    bool initiallyExpanded = false,
  }) =>
      Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: PageStorageKey<String>('club-settings-section-$id'),
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: children,
        ),
      );

  List<Widget> _moduleTiles(Iterable<ClubModule> modules) => [
        for (final module in modules)
          SwitchListTile.adaptive(
            key: ValueKey('club-module-${module.key}'),
            contentPadding: EdgeInsets.zero,
            title: _settingTitle(module.label, module.description),
            value: _modules.isEnabled(module),
            onChanged: _pendingModules.contains(module)
                ? null
                : (value) => _setModule(module, value),
          ),
      ];

  List<Widget> _ruleTiles(bool Function(ClubRule) include) {
    final widgets = <Widget>[];
    for (final rule in _rules) {
      // Ces horaires sont sans effet depuis le passage aux +1 manuels.
      if (!include(rule) || rule.key == 'waitlist_cutoff_days' ||
          rule.key == 'waitlist_cutoff_hour') continue;
      if (rule.key == ClubRules.waitlistModeKey) {
        widgets.add(_waitlistModeTile(rule));
        continue;
      }
      widgets.add(
        Padding(
          key: ValueKey('club-rule-${rule.key}'),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(rule.label)),
              _infoButton(
                rule.label,
                '${rule.description}\nValeur par défaut : '
                '${_ruleValueLabel(rule, rule.defaultValue)}',
              ),
              IconButton(
                key: ValueKey('club-rule-${rule.key}-minus'),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 44),
                icon: const Icon(Icons.remove_circle_outline),
                onPressed:
                    _pendingRules.contains(rule.key) || rule.value <= rule.min
                        ? null
                        : () => _setRule(rule, rule.value - 1),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  _ruleValueLabel(rule, rule.value),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                key: ValueKey('club-rule-${rule.key}-plus'),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 44),
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

  /// Valeur affichée d'une règle : « 15 min », ou « × 1,5 » pour un
  /// multiplicateur du barème (enregistré en dixièmes).
  String _ruleValueLabel(ClubRule rule, int value) =>
      rule.unit == ClubRules.multiplierUnit
          ? ClubRules.formatMultiplier(value)
          : '$value ${rule.unit}';


  Widget _waitlistModeTile(ClubRule rule) {
    final current = WaitlistMode.fromValue(rule.value);
    final pending = _pendingRules.contains(rule.key);
    return Column(
      key: ValueKey('club-rule-${rule.key}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _settingTitle(
          rule.label,
          '${rule.description}\n'
          'Les +1 sont attribués ou retirés uniquement par un administrateur '
          'dans la liste d’attente. Aucun +1 n’est automatique.',
        ),
        RadioGroup<WaitlistMode>(
          groupValue: current,
          onChanged: (selected) {
            if (pending || selected == null || selected == current) return;
            _setRule(rule, selected.value);
          },
          child: Column(
            children: [
              for (final mode in WaitlistMode.values)
                RadioListTile<WaitlistMode>(
                  key: ValueKey('club-rule-${rule.key}-${mode.value}'),
                  contentPadding: EdgeInsets.zero,
                  value: mode,
                  enabled: !pending,
                  title: Text(mode.label),
                  secondary: _infoButton(mode.label, mode.description),
                ),
            ],
          ),
        ),
      ],
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

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _settingsSection(
          'identity',
          'Identité et maillots',
          Icons.shield_outlined,
          [
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
                prefixIcon: const Icon(Icons.short_text),
                suffixIcon: _infoButton(
                  'Nom court',
                  'Nom affiché dans les espaces réduits, de 2 à 12 caractères.',
                ),
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
            const Divider(height: 32),
            _settingTitle(
              'Logo du club',
              'Ton écusson apparaît dans l’application à la place du logo '
              'neutre. Formats JPEG, PNG ou WebP, de préférence carrés.',
            ),
            const SizedBox(height: 8),
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
            const Divider(height: 32),
            _colorRow(
              'Couleur principale',
              'club-color-primary',
              club.primaryColor,
              (hex) => _setColors(primary: hex),
            ),
            const SizedBox(height: 12),
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
              title: _settingTitle(
                'Maillots du club',
                'Personnalise les couleurs et les noms des tenues disponibles '
                'pour les matchs, y compris les tenues des gardiens.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/admin/club/maillots'),
            ),
          ],
          initiallyExpanded: true,
        ),
        _settingsSection(
          'invitations',
          'Invitations',
          Icons.person_add_alt_1_outlined,
          [
            _settingTitle(
              'Code d’invitation',
              'Partage ce code ou le lien d’inscription aux joueurs. '
              'Tu valideras ensuite leurs comptes dans Administration.',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.key_outlined, color: AppTheme.primaryBright),
                const SizedBox(width: 12),
                SelectableText(
                  club.inviteCode,
                  key: const Key('club-settings-invite-code'),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(letterSpacing: 2),
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
                  label: const Text('Copier le lien'),
                ),
                OutlinedButton.icon(
                  onPressed: _renewingCode ? null : _renewInviteCode,
                  icon: const Icon(Icons.autorenew_rounded, size: 18),
                  label: const Text('Changer le code'),
                ),
              ],
            ),
          ],
        ),
        _settingsSection(
          'matches',
          'Matchs et convocations',
          Icons.sports_soccer_outlined,
          [
            TextField(
              key: const Key('club-settings-home-address'),
              controller: _homeAddressController,
              maxLength: 200,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Terrain à domicile',
                hintText: 'Rue, code postal, ville',
                prefixIcon: const Icon(Icons.place_outlined),
                suffixIcon: _infoButton(
                  'Terrain à domicile',
                  'Adresse proposée pour chaque nouveau match à domicile. '
                  'Elle reste modifiable pour chaque rencontre.',
                ),
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
            const Divider(height: 32),
            Column(
              key: const Key('club-usual-squad-size'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _settingTitle(
                  'Joueurs convoqués par défaut',
                  'Nombre proposé pour les nouveaux matchs (de 1 à 30). '
                  'Tu peux le modifier individuellement pour chaque match.',
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const Key('club-usual-squad-size-minus'),
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed:
                            _savingUsualSquadSize || _usualSquadSize <= 1
                                ? null
                                : () => _saveUsualSquadSize(_usualSquadSize - 1),
                      ),
                      Text('$_usualSquadSize'),
                      IconButton(
                        key: const Key('club-usual-squad-size-plus'),
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed:
                            _savingUsualSquadSize || _usualSquadSize >= 30
                                ? null
                                : () => _saveUsualSquadSize(_usualSquadSize + 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ..._moduleTiles(const [ClubModule.liveMode, ClubModule.weather]),
            ..._ruleTiles((rule) => !rule.key.startsWith('prediction_')),
          ],
        ),
        _settingsSection(
          'predictions',
          'Pronostics et votes',
          Icons.emoji_events_outlined,
          [
            ..._moduleTiles(
              const [ClubModule.predictions, ClubModule.manOfTheMatch],
            ),
            ..._ruleTiles((rule) => rule.key.startsWith('prediction_')),
          ],
        ),
        _settingsSection(
          'rewards',
          'Statistiques et récompenses',
          Icons.bar_chart_rounded,
          [
            ..._moduleTiles(const [
              ClubModule.statistics,
              ClubModule.badges,
              ClubModule.seasonWrapped,
            ]),
          ],
        ),
        _settingsSection(
          'subscription',
          'Abonnement et stockage',
          Icons.credit_card_outlined,
          const [ClubSubscriptionSection()],
        ),
      ],
    );
  }
}
