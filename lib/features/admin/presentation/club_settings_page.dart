import 'package:petit_filet/core/club/club_identity.dart';
import 'package:petit_filet/core/club/club_rules.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/widgets/pf_app_bar.dart';
import 'package:petit_filet/core/widgets/pf_loader.dart';
import 'package:petit_filet/features/admin/presentation/club_season_tile.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/club/presentation/club_rules_sync.dart';
import 'package:petit_filet/features/feature_flags/presentation/feature_flags_controller.dart';
import 'package:petit_filet/features/season_wrapped/domain/wrapped_stat_selection.dart';
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
  final _contactNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _postalAddressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _settingsSearchController = TextEditingController();
  String _settingsSearch = '';

  Club? _club;
  ClubModules _modules = const ClubModules.allEnabled();
  List<ClubRule> _rules = const [];
  int _usualSquadSize = 14;
  final Set<String> _pendingRules = {};
  Object? _loadError;
  bool _loading = true;
  bool _savingIdentity = false;
  bool _savingHomeAddress = false;
  bool _savingContact = false;
  bool _savingUsualSquadSize = false;
  bool _renewingCode = false;
  bool _savingLogo = false;

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
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _postalAddressController.dispose();
    _websiteController.dispose();
    _registrationNumberController.dispose();
    _settingsSearchController.dispose();
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
      final contact = await repository.fetchContact();
      if (!mounted) return;
      _fillContact(contact);
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
      refreshClubConfiguration(ref.invalidate);
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
        'L’adresse doit tenir sur une ligne (200 caractères maximum).',
      );
      return;
    }
    setState(() => _savingHomeAddress = true);
    try {
      final saved = await ref
          .read(clubRepositoryProvider)
          .updateHomeAddress(address.isEmpty ? null : address);
      if (!mounted) return;
      _homeAddressController.text = saved ?? '';
      _showMessage(
        saved == null
            ? 'Adresse du terrain effacée.'
            : 'Adresse du terrain enregistrée.',
      );
    } catch (_) {
      if (mounted) {
        _showMessage('L’adresse du terrain n’a pas pu être enregistrée.');
      }
    } finally {
      if (mounted) setState(() => _savingHomeAddress = false);
    }
  }

  void _fillContact(ClubContact contact) {
    _contactNameController.text = contact.contactName ?? '';
    _contactEmailController.text = contact.email ?? '';
    _contactPhoneController.text = contact.phone ?? '';
    _postalAddressController.text = contact.postalAddress ?? '';
    _websiteController.text = contact.website ?? '';
    _registrationNumberController.text = contact.registrationNumber ?? '';
  }

  static String? _clean(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  /// Premier problème de saisie trouvé, ou null si tout est correct. Le
  /// serveur refait les mêmes contrôles.
  String? _contactProblem(ClubContact contact) {
    final email = contact.email;
    if (email != null &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'L’adresse e-mail du club n’est pas valide.';
    }
    final phone = contact.phone;
    if (phone != null &&
        !RegExp(r'^\+?[0-9][0-9 .()-]{5,24}$').hasMatch(phone)) {
      return 'Le numéro de téléphone n’est pas valide.';
    }
    final address = contact.postalAddress;
    if (address != null && (address.length < 5 || address.length > 300)) {
      return 'L’adresse postale doit compter entre 5 et 300 caractères.';
    }
    final website = contact.website;
    if (website != null && (website.length > 200 || website.contains(' '))) {
      return 'L’adresse du site n’est pas valide.';
    }
    final number = contact.registrationNumber?.replaceAll(' ', '');
    if (number != null &&
        !RegExp(r'^(W[0-9]{9}|[0-9]{9}|[0-9]{14})$')
            .hasMatch(number.toUpperCase())) {
      return 'Numéro attendu : RNA (W + 9 chiffres), SIREN (9 chiffres) '
          'ou SIRET (14 chiffres).';
    }
    return null;
  }

  Future<void> _saveContact() async {
    final contact = ClubContact(
      contactName: _clean(_contactNameController),
      email: _clean(_contactEmailController),
      phone: _clean(_contactPhoneController),
      postalAddress: _clean(_postalAddressController),
      website: _clean(_websiteController),
      registrationNumber: _clean(_registrationNumberController),
    );
    final problem = _contactProblem(contact);
    if (problem != null) {
      _showMessage(problem);
      return;
    }
    setState(() => _savingContact = true);
    try {
      final saved =
          await ref.read(clubRepositoryProvider).updateContact(contact);
      if (!mounted) return;
      _fillContact(saved);
      _showMessage('Coordonnées du club enregistrées.');
    } catch (_) {
      if (mounted) {
        _showMessage('Les coordonnées n’ont pas pu être enregistrées.');
      }
    } finally {
      if (mounted) setState(() => _savingContact = false);
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

  void _adoptClub(Club club) {
    setState(() => _club = club);
    refreshClubConfiguration(ref.invalidate);
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
      refreshClubConfiguration(ref.invalidate);
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
      refreshClubConfiguration(ref.invalidate);
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
      refreshClubConfiguration(ref.invalidate);
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

  Widget _labelWithInfo(String key, String label, String description) => Row(
        children: [
          Expanded(child: Text(label)),
          _infoButton(key, label, description),
        ],
      );

  // Recherche aussi sans accents et dans les descriptions des options.
  static String _normalizedSearch(String text) => text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[àâäáã]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[îïí]'), 'i')
      .replaceAll(RegExp('[ôöó]'), 'o')
      .replaceAll(RegExp('[ùûüú]'), 'u')
      .replaceAll('ç', 'c');

  bool _searchMatches(String text) {
    final query = _normalizedSearch(_settingsSearch);
    return query.isEmpty || _normalizedSearch(text).contains(query);
  }

  static const Map<String, String> _sectionTitles = {
    'identity': 'Identité et maillots',
    'contact': 'Coordonnées du club',
    'squad': 'Effectif et convocations',
    'matches': 'Matchs et direct',
    'composition': 'Composition et vidéo',
    'live': 'Direct : outils du coach',
    'predictions': 'Pronostics',
    'rewards': 'Statistiques et récompenses',
    'other': 'Autres réglages',
    'members': 'Membres et invitations',
    'season': 'Saison',
  };

  static const Map<String, String> _searchHints = {
    'identity': 'nom du club nom court écusson logo couleurs maillots',
    'squad': 'convoqués nombre de joueurs liste attente',
    'matches': 'terrain adresse domicile',
    'rewards': 'catalogue seuils badges bilan de fin de saison stats affichées',
    'members': 'code invitation inscrire membres',
    'contact':
        'adresse postale e-mail mail téléphone responsable président site rna siret',
    'season': 'finir terminer clôturer archiver créer nouvelle saison',
  };

  bool _sectionMatches(String category, String title) {
    if (_settingsSearch.trim().isEmpty) return true;
    if (_searchMatches(title) || _searchMatches(_searchHints[category] ?? '')) {
      return true;
    }
    for (final module in ClubModule.values) {
      if (_moduleCategory(module) == category &&
          _searchMatches(
              '${module.label} ${module.description} ${module.key}')) {
        return true;
      }
    }
    for (final rule in _rules) {
      if (_isRelevantRule(rule) &&
          _ruleCategory(rule) == category &&
          _searchMatches('${rule.label} ${rule.description} ${rule.key}')) {
        return true;
      }
    }
    return false;
  }

  Widget _section(
    String key,
    String title,
    IconData icon,
    List<Widget> children, {
    bool expanded = false,
  }) {
    if (!_sectionMatches(key, title)) return const SizedBox.shrink();
    final query = _normalizedSearch(_settingsSearch);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        // Le changement de recherche réouvre les sections filtrées.
        key: ValueKey(
            query.isEmpty ? 'club-section-$key' : 'club-section-$key-$query'),
        initiallyExpanded: expanded || query.isNotEmpty,
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
  }

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

  /// Section des Réglages où chaque règle est rangée : sous la
  /// fonctionnalité qu'elle règle.
  static const Map<String, String> _ruleSections = {
    ClubRules.featuresOpenDaysKey: 'squad',
    ClubRules.featuresOpenHourKey: 'squad',
    'notify_availability_open': 'squad',
    'notify_availability_reminders': 'squad',
    ClubRules.waitlistModeKey: 'squad',
    ClubRules.waitlistPriorityEnabledKey: 'squad',
    'notify_convocation': 'squad',
    'notify_composition': 'squad',
    ClubRules.correctionWindowHoursKey: 'matches',
    'match_duration_minutes': 'matches',
    ClubRules.livePilotModeKey: 'live',
    'notify_live_kickoff': 'live',
    'notify_live_goals': 'live',
    'notify_match_changes': 'matches',
    'notify_prediction_reminder': 'predictions',
    'motm_window_hours': 'rewards',
    ClubRules.motmSelfVoteKey: 'rewards',
    'notify_motm_open': 'rewards',
    'notify_motm_result': 'rewards',
    'notify_badges': 'rewards',
    ClubRules.wrappedMusicKey: 'rewards',
    ClubRules.wrappedStatsMaskKey: 'rewards',
    'notify_admin_signups': 'members',
  };

  /// Fonctionnalité dont dépend une règle : quand elle est désactivée, la
  /// règle reste visible mais grisée.
  static ClubModule? _ruleModule(String key) {
    if (key.startsWith('prediction_') ||
        key.startsWith('odds_') ||
        key == 'notify_prediction_reminder') {
      return ClubModule.predictions;
    }
    if (ClubFeature.forKey(key)?.section == 'live') return ClubModule.liveMode;
    if (key == ClubRules.livePilotModeKey ||
        key == 'notify_live_kickoff' ||
        key == 'notify_live_goals') {
      return ClubModule.liveMode;
    }
    if (key == 'notify_motm_winner') return ClubModule.manOfTheMatch;
    if (key.startsWith('motm_') || key.startsWith('notify_motm_')) {
      return ClubModule.manOfTheMatch;
    }
    if (key == 'notify_badges') return ClubModule.badges;
    if (key == ClubRules.wrappedMusicKey ||
        key == ClubRules.wrappedStatsMaskKey) {
      return ClubModule.seasonWrapped;
    }
    return null;
  }

  String _ruleCategory(ClubRule rule) {
    final feature = ClubFeature.forKey(rule.key);
    if (feature != null) return feature.section;
    final section = _ruleSections[rule.key];
    if (section != null) return section;
    if (rule.key.startsWith('prediction_') || rule.key.startsWith('odds_')) {
      return 'predictions';
    }
    return 'other';
  }

  static const _ruleParents = <String, String>{
    'live_assists': 'live_scorers',
    'live_own_goals': 'live_scorers',
    'composition_video_autoplay': 'composition_video',
    'composition_video_notification_replay': 'composition_video_autoplay',
    'notify_availability_j3': 'notify_availability_reminders',
    'notify_availability_j1': 'notify_availability_reminders',
    'notify_live_full_time': 'notify_live_kickoff',
    'notify_live_goal_us': 'notify_live_goals',
    'notify_live_goal_them': 'notify_live_goals',
    'notify_match_cancelled': 'notify_match_changes',
    'notify_match_rescheduled_date': 'notify_match_changes',
    'notify_match_rescheduled_time': 'notify_match_changes',
    'notify_convocation_promoted': 'notify_convocation',
    'notify_convocation_demoted': 'notify_convocation',
    'notify_motm_winner': 'notify_motm_result',
  };

  bool _parentDisabled(String key) {
    final parent = _ruleParents[key];
    if (parent == null) return false;
    for (final rule in _rules) {
      if (rule.key == parent && rule.value == 0) return true;
    }
    return _parentDisabled(parent);
  }

  bool _ruleLocked(ClubRule rule) {
    final module = _ruleModule(rule.key);
    return _parentDisabled(rule.key) ||
        _pendingRules.contains(rule.key) ||
        (module != null && !_modules.isEnabled(module));
  }

  String _ruleInfo(ClubRule rule) {
    final module = _ruleModule(rule.key);
    final lines = [
      rule.description,
      'Valeur par défaut : ${_ruleValueLabel(rule, rule.defaultValue)}',
      if (_parentDisabled(rule.key))
        'Activez d’abord le réglage parent pour modifier cette option.',
      if (module != null && !_modules.isEnabled(module))
        'Sans effet tant que « ${module.label} » est désactivé.',
    ];
    return lines.join('\n\n');
  }

  bool _isRelevantRule(ClubRule rule) =>
      rule.key != 'waitlist_cutoff_days' && rule.key != 'waitlist_cutoff_hour';

  List<Widget> _modulesFor(String category) => [
        for (final module in ClubModule.values)
          if (_moduleCategory(module) == category &&
              (_searchMatches(_sectionTitles[category] ?? '') ||
                  _searchMatches(
                      '${module.label} ${module.description} ${module.key}')))
            SwitchListTile.adaptive(
              key: ValueKey('club-module-${module.key}'),
              contentPadding: EdgeInsets.zero,
              title: _labelWithInfo(
                'module-${module.key}',
                module.label,
                '${module.description}\n\nLa désactivation conserve les données existantes.',
              ),
              value: _modules.isEnabled(module),
              onChanged: _pendingModules.contains(module)
                  ? null
                  : (value) => _setModule(module, value),
            ),
      ];

  List<Widget> _rulesFor(String category) => [
        for (final rule in _rules)
          if (_isRelevantRule(rule) &&
              _ruleCategory(rule) == category &&
              (_searchMatches(_sectionTitles[category] ?? '') ||
                  _searchMatches(
                      '${rule.label} ${rule.description} ${rule.key}')))
            if (rule.key == ClubRules.waitlistModeKey)
              _waitlistModeTile(rule)
            else if (rule.key == ClubRules.wrappedStatsMaskKey)
              _wrappedStatsRuleTile(rule)
            else if (rule.unit == ClubRules.boolUnit)
              _boolRuleTile(rule)
            else if (rule.unit == ClubRules.modeUnit)
              _modeRuleTile(rule)
            else
              _numberRuleTile(rule),
      ];

  Widget _wrappedStatsRuleTile(ClubRule rule) {
    final current = rule.value;
    final count = WrappedStatOption.values
        .where((stat) => stat.enabledIn(current))
        .length;
    return ListTile(
      key: const ValueKey('club-rule-wrapped_stats_mask'),
      contentPadding: EdgeInsets.zero,
      title: _labelWithInfo(
        'rule-${rule.key}',
        'Quelles stats apparaissent au bilan de fin de saison ?',
        _ruleInfo(rule),
      ),
      subtitle: Text('$count statistiques sur 9 sélectionnées'),
      trailing: const Icon(Icons.tune_rounded),
      onTap: _ruleLocked(rule) ? null : () => _chooseWrappedStats(rule),
    );
  }

  Future<void> _chooseWrappedStats(ClubRule rule) async {
    var mask = rule.value;
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, updateDialog) => AlertDialog(
          title: const Text('Statistiques du bilan de fin de saison'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final stat in WrappedStatOption.values)
                    CheckboxListTile(
                      key: ValueKey('wrapped-stat-${stat.name}'),
                      title: Text(stat.label),
                      subtitle: Text(stat.description),
                      controlAffinity: ListTileControlAffinity.leading,
                      value: stat.enabledIn(mask),
                      onChanged: (checked) => updateDialog(() {
                        if (checked == true) {
                          mask |= stat.bit;
                        } else {
                          mask &= ~stat.bit;
                        }
                      }),
                    ),
                  if (mask == 0)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Choisis au moins une statistique.'),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: mask == 0
                  ? null
                  : () => Navigator.of(dialogContext).pop(mask),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null || selected == rule.value) return;
    await _setRule(rule, selected);
  }

  Widget _boolRuleTile(ClubRule rule) => SwitchListTile.adaptive(
        key: ValueKey('club-rule-${rule.key}'),
        contentPadding: EdgeInsets.zero,
        title: _labelWithInfo('rule-${rule.key}', rule.label, _ruleInfo(rule)),
        value: rule.value == 1,
        onChanged:
            _ruleLocked(rule) ? null : (value) => _setRule(rule, value ? 1 : 0),
      );

  Widget _modeRuleTile(ClubRule rule) {
    final labels = ClubRules.modeLabels[rule.key] ??
        [for (var i = rule.min; i <= rule.max; i++) '$i'];
    final locked = _ruleLocked(rule);
    return Padding(
      key: ValueKey('club-rule-${rule.key}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelWithInfo('rule-${rule.key}', rule.label, _ruleInfo(rule)),
          DropdownButton<int>(
            key: ValueKey('club-rule-${rule.key}-select'),
            value: rule.value.clamp(0, labels.length - 1),
            isExpanded: true,
            items: [
              for (var i = 0; i < labels.length; i++)
                DropdownMenuItem(value: i, child: Text(labels[i])),
            ],
            onChanged: locked
                ? null
                : (selected) {
                    if (selected == null || selected == rule.value) return;
                    _setRule(rule, selected);
                  },
          ),
        ],
      ),
    );
  }

  Widget _numberRuleTile(ClubRule rule) {
    int stepped({required bool up}) => ClubRules.stepValue(
          rule.key,
          rule.value,
          up: up,
          min: rule.min,
          max: rule.max,
        );
    final locked = _ruleLocked(rule);
    return ListTile(
      key: ValueKey('club-rule-${rule.key}'),
      contentPadding: EdgeInsets.zero,
      title: _labelWithInfo('rule-${rule.key}', rule.label, _ruleInfo(rule)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('club-rule-${rule.key}-minus'),
            tooltip: 'Diminuer',
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: locked || rule.value <= rule.min
                ? null
                : () => _setRule(rule, stepped(up: false)),
          ),
          Text(_ruleValueLabel(rule, rule.value)),
          IconButton(
            key: ValueKey('club-rule-${rule.key}-plus'),
            tooltip: 'Augmenter',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: locked || rule.value >= rule.max
                ? null
                : () => _setRule(rule, stepped(up: true)),
          ),
        ],
      ),
    );
  }

  String _ruleValueLabel(ClubRule rule, int value) {
    if (rule.unit == ClubRules.multiplierUnit) {
      return ClubRules.formatMultiplier(value);
    }
    if (rule.unit == ClubRules.boolUnit) return value == 1 ? 'oui' : 'non';
    if (rule.unit == ClubRules.modeUnit) {
      final labels = ClubRules.modeLabels[rule.key];
      if (labels != null && value >= 0 && value < labels.length) {
        return labels[value];
      }
    }
    return '$value ${rule.unit}';
  }

  Widget _waitlistModeTile(ClubRule rule) {
    final current = WaitlistMode.fromValue(rule.value);
    final pending = _pendingRules.contains(rule.key);
    final info = [
      rule.description,
      for (final mode in WaitlistMode.values)
        '${mode.label} : ${mode.description}',
      'Au coup d’envoi, un joueur présent non retenu reçoit +1, '
          'même lorsque la priorité est désactivée. '
          'Le compteur se réinitialise à chaque saison ; les archives restent consultables. '
          'L’admin peut aussi corriger les +1 manuellement.',
    ].join('\n\n');
    return Padding(
      key: ValueKey('club-rule-${rule.key}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelWithInfo('rule-${rule.key}', rule.label, info),
          DropdownButton<WaitlistMode>(
            key: ValueKey('club-rule-${rule.key}-select'),
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
      appBar: PfAppBar(title: const Text('Réglages du club')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: PfProgressIndicator());
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
        TextField(
          key: const Key('club-settings-search'),
          controller: _settingsSearchController,
          onChanged: (value) => setState(() => _settingsSearch = value),
          decoration: InputDecoration(
            labelText: 'Rechercher un réglage',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _settingsSearch.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Effacer la recherche',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() {
                      _settingsSearchController.clear();
                      _settingsSearch = '';
                    }),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        if (_settingsSearch.trim().isNotEmpty &&
            !_sectionTitles.entries.any(
              (e) => _sectionMatches(e.key, e.value),
            ))
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Aucun réglage trouvé.'),
          ),
        _section(
            'identity',
            'Identité et maillots',
            Icons.shield_outlined,
            [
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
                  suffixIcon: _infoButton(
                    'short-name',
                    'Nom court',
                    'Utilisé quand la place manque (2 à 12 caractères).',
                  ),
                  prefixIcon: Icon(Icons.short_text),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: _savingIdentity ? null : _saveIdentity,
                  child:
                      Text(_savingIdentity ? 'Enregistrement…' : 'Enregistrer'),
                ),
              ),
              _labelWithInfo(
                'logo',
                'Écusson du club',
                'Écusson affiché dans l’application. Image JPEG, PNG ou WebP, de préférence carrée.',
              ),
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
                          label:
                              Text(_savingLogo ? 'Envoi…' : 'Choisir un logo'),
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
              ListTile(
                key: const ValueKey('club-kits-entry'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.checkroom_rounded),
                title: _labelWithInfo(
                  'kits',
                  'Maillots du club',
                  'Choisis les tenues des joueurs et des gardiens. Elles sont '
                      'utilisées dans les compositions et les matchs.',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/admin/club/maillots'),
              ),
            ],
            expanded: false),
        _section(
          'contact',
          'Coordonnées du club',
          Icons.contact_mail_outlined,
          [
            const SizedBox(height: 4),
            const Text(
              'Visibles par les membres du club. L’adresse postale sert aussi '
              'aux factures.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('club-contact-name'),
              controller: _contactNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Personne à contacter (président, secrétaire…)',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('club-contact-email'),
              controller: _contactEmailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'E-mail du club',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('club-contact-phone'),
              controller: _contactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('club-contact-address'),
              controller: _postalAddressController,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Adresse postale du club (siège)',
                prefixIcon: Icon(Icons.markunread_mailbox_outlined),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              key: const Key('club-contact-website'),
              controller: _websiteController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Site internet ou page du club',
                prefixIcon: Icon(Icons.language_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('club-contact-registration'),
              controller: _registrationNumberController,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'N° RNA ou SIRET de l’association',
                prefixIcon: const Icon(Icons.badge_outlined),
                suffixIcon: _infoButton(
                  'registration',
                  'Numéro de l’association',
                  'Facultatif. Numéro RNA (W suivi de 9 chiffres), SIREN '
                      '(9 chiffres) ou SIRET (14 chiffres). Il apparaît sur '
                      'les factures.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: const Key('club-contact-save'),
                onPressed: _savingContact ? null : _saveContact,
                child: Text(
                  _savingContact
                      ? 'Enregistrement…'
                      : 'Enregistrer les coordonnées',
                ),
              ),
            ),
          ],
        ),
        _section('squad', 'Effectif et convocations', Icons.groups_outlined, [
          const SizedBox(height: 8),
          ListTile(
            key: const Key('club-usual-squad-size'),
            contentPadding: EdgeInsets.zero,
            title: _labelWithInfo(
              'quota',
              'Convoqués par défaut',
              'Nombre prévu à la création d’un match (1 à 30). Peut être modifié par rencontre.',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const Key('club-usual-squad-size-minus'),
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Retirer',
                  onPressed: _savingUsualSquadSize || _usualSquadSize <= 1
                      ? null
                      : () => _saveUsualSquadSize(_usualSquadSize - 1),
                ),
                Text('$_usualSquadSize'),
                IconButton(
                  key: const Key('club-usual-squad-size-plus'),
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Ajouter',
                  onPressed: _savingUsualSquadSize || _usualSquadSize >= 30
                      ? null
                      : () => _saveUsualSquadSize(_usualSquadSize + 1),
                ),
              ],
            ),
          ),
          ..._rulesFor('squad'),
        ]),
        _section('matches', 'Matchs et direct', Icons.sports_soccer_outlined, [
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
              suffixIcon: _infoButton(
                'home-address',
                'Terrain à domicile',
                'Proposé par défaut pour les matchs à domicile. Modifiable par match.',
              ),
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              key: const Key('club-settings-save-home-address'),
              onPressed: _savingHomeAddress ? null : _saveHomeAddress,
              child: Text(
                _savingHomeAddress
                    ? 'Enregistrement…'
                    : 'Enregistrer l’adresse',
              ),
            ),
          ),
          ..._modulesFor('matches'),
          ..._rulesFor('matches'),
        ]),
        _section(
          'composition',
          'Composition et vidéo',
          Icons.view_quilt_outlined,
          [..._rulesFor('composition')],
        ),
        _section('live', 'Direct : outils du coach', Icons.timer_outlined, [
          ..._rulesFor('live'),
        ]),
        _section('predictions', 'Pronostics', Icons.emoji_events_outlined, [
          ..._modulesFor('predictions'),
          ..._rulesFor('predictions'),
        ]),
        _section(
          'rewards',
          'Statistiques et récompenses',
          Icons.bar_chart_rounded,
          [
            ..._modulesFor('rewards'),
            ..._rulesFor('rewards'),
            ListTile(
              key: const Key('club-settings-badge-catalogue'),
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Catalogue et seuils des badges'),
              subtitle: _modules.isEnabled(ClubModule.badges)
                  ? null
                  : const Text('Active d’abord « Badges » ci-dessus.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _modules.isEnabled(ClubModule.badges)
                  ? () => context.push('/admin/badges')
                  : null,
            ),
          ],
        ),
        if (ClubModule.values.any((m) => _moduleCategory(m) == 'other') ||
            _rules.any(
              (r) => _isRelevantRule(r) && _ruleCategory(r) == 'other',
            ))
          _section('other', 'Autres réglages', Icons.tune_rounded, [
            ..._modulesFor('other'),
            ..._rulesFor('other'),
          ]),
        _section(
          'members',
          'Membres et invitations',
          Icons.person_add_alt_1_outlined,
          [
            _labelWithInfo(
              'invite',
              'Code d’invitation',
              'Lien ou code à donner aux futurs membres. L’administrateur valide ensuite les inscriptions.',
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.key_outlined, color: AppTheme.primaryBright),
                const SizedBox(width: 12),
                SelectableText(
                  club.inviteCode,
                  key: const Key('club-settings-invite-code'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    letterSpacing: 2,
                  ),
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
            ..._rulesFor('members'),
          ],
        ),
        // L'abonnement a son propre écran, ouvert depuis Paramètres.
        _section('season', 'Saison', Icons.flag_outlined, [
          const Text(
            'Finir la saison archive le classement final. Tu pourras ensuite '
            'en créer une nouvelle.',
          ),
          const SizedBox(height: 8),
          const ClubSeasonTile(),
        ]),
      ],
    );
  }
}
