import 'package:as_grinta/core/club/club_identity.dart';
import 'package:as_grinta/core/utils/app_errors.dart';
import 'package:as_grinta/core/widgets/grinta_app_bar.dart';
import 'package:as_grinta/core/widgets/grinta_loader.dart';
import 'package:as_grinta/features/matches/data/calendar_history_repository.dart';
import 'package:as_grinta/features/matches/data/history_entry_repository.dart';
import 'package:as_grinta/features/matches/domain/history_match_draft.dart';
import 'package:as_grinta/features/matches/presentation/widgets/match_wheel_picker.dart';
import 'package:as_grinta/features/sports_management/domain/football_formation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ajout d'un match passé à l'historique du club, en un seul formulaire.
///
/// Seuls l'adversaire, la date et le score sont obligatoires. Le bouton
/// « Enregistrer et ajouter le suivant » garde l'effectif et avance d'une
/// semaine : c'est la saisie rapide d'une saison entière.
class HistoryEntryPage extends ConsumerStatefulWidget {
  const HistoryEntryPage({super.key});

  @override
  ConsumerState<HistoryEntryPage> createState() => _HistoryEntryPageState();
}

class _HistoryEntryPageState extends ConsumerState<HistoryEntryPage> {
  final _opponentController = TextEditingController();
  final _addressController = TextEditingController();
  final _scrollController = ScrollController();
  final _opponentFocus = FocusNode();

  HistoryEntryContext? _context;
  Object? _loadError;
  bool _loading = true;
  bool _saving = false;
  int _savedCount = 0;
  String? _lastSavedOpponent;
  HistoryMatchDraft _draft = const HistoryMatchDraft();

  /// Anciens joueurs ajoutés pendant cette saisie.
  final List<HistoryPlayer> _extraPlayers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _opponentController.dispose();
    _addressController.dispose();
    _scrollController.dispose();
    _opponentFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final context =
          await ref.read(historyEntryRepositoryProvider).fetchContext();
      if (!mounted) return;
      setState(() {
        _context = context;
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

  List<HistoryPlayer> get _allPlayers {
    final seen = <String>{};
    return [
      for (final player in [...?_context?.players, ..._extraPlayers])
        if (seen.add(player.key)) player,
    ];
  }

  void _update(HistoryMatchDraft Function(HistoryMatchDraft) change) {
    setState(() => _draft = change(_draft));
  }

  Future<void> _pickDate() async {
    final last = _context!.lastAllowedDate;
    final picked = await MatchWheelPicker.pickDate(
      context: context,
      initialDate: _draft.date ?? last,
      firstDate: DateTime(1950),
      lastDate: last,
      title: 'Date du match',
    );
    if (picked != null) _update((d) => d.copyWith(date: picked));
  }

  Future<void> _addFormerPlayer() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ancien joueur'),
        content: TextField(
          key: const Key('history-former-player-name'),
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Prénom et nom',
            helperText: 'Pour un joueur qui n’a pas de compte.',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    controller.dispose();
    final clean = name?.trim() ?? '';
    if (clean.length < 2 || !mounted) return;
    final player = HistoryPlayer.former(clean);
    setState(() {
      if (!_allPlayers.contains(player)) _extraPlayers.add(player);
      if (!_draft.present.contains(player)) {
        _draft = _draft.togglePresent(player);
      }
    });
  }

  Future<void> _save({required bool addAnother}) async {
    final context = _context;
    if (context == null || _saving) return;
    final draft = _draft.copyWith(
      opponent: _opponentController.text,
      address: _addressController.text,
    );
    final missing = draft.missingRequirement(context.lastAllowedDate);
    if (missing != null) {
      _showMessage(missing);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(historyEntryRepositoryProvider).addMatch(draft);
      if (!mounted) return;
      _savedCount += 1;
      // Le calendrier relit les archives au lieu d'attendre son cache.
      refreshHistoricalArchives(ref);
      final opponent = draft.opponent.trim();
      if (!context.opponents.contains(opponent)) {
        _context = HistoryEntryContext(
          lastAllowedDate: context.lastAllowedDate,
          players: context.players,
          opponents: [...context.opponents, opponent],
        );
      }
      if (addAnother) {
        setState(() {
          _draft = draft.nextQuickEntry(context.lastAllowedDate);
          _opponentController.clear();
          _addressController.clear();
        });
        // Confirmation dans le formulaire plutôt qu'en bandeau : le bandeau
        // masquerait les boutons pendant qu'on enchaîne les matchs.
        ScaffoldMessenger.of(this.context).hideCurrentSnackBar();
        _lastSavedOpponent = opponent;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      } else {
        _showMessage('Match contre $opponent ajouté à l’historique.');
        Navigator.of(this.context).maybePop();
      }
    } catch (error) {
      if (mounted) _showMessage(humanizeError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GrintaAppBar(title: const Text('Ajouter un match passé')),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) return const Center(child: GrintaProgressIndicator());
    final entryContext = _context;
    if (_loadError != null || entryContext == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(humanizeError(_loadError), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                'Seuls l’adversaire, la date et le score sont obligatoires. '
                'Le reste peut être complété si tu t’en souviens.',
                style: theme.textTheme.bodySmall,
              ),
              if (_savedCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  [
                    if (_lastSavedOpponent != null)
                      'Match contre $_lastSavedOpponent ajouté. Au suivant : '
                          'même effectif, une semaine plus tard.',
                    _savedCount == 1
                        ? '1 match ajouté pendant cette saisie.'
                        : '$_savedCount matchs ajoutés pendant cette saisie.',
                  ].join(' '),
                  key: const Key('history-saved-count'),
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              _section(theme, 'Affiche', _posterFields(entryContext)),
              _section(theme, 'Score', [_scoreRow(theme)]),
              _section(theme, 'Joueurs présents', _presentFields(theme)),
              if (_draft.scoreFor > 0)
                _section(theme, 'Buteurs', _scorerFields(theme)),
              _section(theme, 'Homme du match', _motmFields(theme)),
              _compositionSection(theme),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  key: const Key('history-save'),
                  onPressed: _saving ? null : () => _save(addAnother: false),
                  child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('history-save-next'),
                  onPressed: _saving ? null : () => _save(addAnother: true),
                  child: const Text('Enregistrer et ajouter le suivant'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(ThemeData theme, String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  List<Widget> _posterFields(HistoryEntryContext entryContext) {
    final date = _draft.date;
    return [
      RawAutocomplete<String>(
        textEditingController: _opponentController,
        focusNode: _opponentFocus,
        optionsBuilder: (value) {
          final query = value.text.trim().toLowerCase();
          if (query.isEmpty) return const Iterable<String>.empty();
          return entryContext.opponents
              .where((name) => name.toLowerCase().contains(query))
              .take(8);
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmit) {
          return TextField(
            key: const Key('history-opponent'),
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Adversaire',
              prefixIcon: const Icon(Icons.shield_outlined),
              helperText: '${ClubIdentity.name} contre…',
            ),
            onSubmitted: (_) => onSubmit(),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 240, maxWidth: 360),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    for (final option in options)
                      ListTile(
                        title: Text(option),
                        onTap: () => onSelected(option),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        key: const Key('history-date'),
        onPressed: _pickDate,
        icon: const Icon(Icons.event_outlined),
        label: Text(date == null ? 'Choisir la date' : _formatDate(date)),
      ),
      const SizedBox(height: 12),
      SegmentedButton<bool>(
        key: const Key('history-home'),
        segments: const [
          ButtonSegment(value: true, label: Text('Domicile')),
          ButtonSegment(value: false, label: Text('Extérieur')),
        ],
        selected: {_draft.isHome},
        onSelectionChanged: (value) =>
            _update((d) => d.copyWith(isHome: value.first)),
      ),
      const SizedBox(height: 12),
      SegmentedButton<bool>(
        key: const Key('history-type'),
        segments: const [
          ButtonSegment(value: false, label: Text('Championnat')),
          ButtonSegment(value: true, label: Text('Amical')),
        ],
        selected: {_draft.isFriendly},
        onSelectionChanged: (value) =>
            _update((d) => d.copyWith(isFriendly: value.first)),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('history-address'),
        controller: _addressController,
        decoration: const InputDecoration(
          labelText: 'Lieu (facultatif)',
          prefixIcon: Icon(Icons.place_outlined),
        ),
      ),
    ];
  }

  Widget _scoreRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _Stepper(
            key: const Key('history-score-for'),
            label: ClubIdentity.shortName,
            value: _draft.scoreFor,
            onChanged: (value) => _update((d) => d.setScoreFor(value)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('–', style: theme.textTheme.headlineSmall),
        ),
        Expanded(
          child: _Stepper(
            key: const Key('history-score-against'),
            label: 'Adversaire',
            value: _draft.scoreAgainst,
            onChanged: (value) =>
                _update((d) => d.copyWith(scoreAgainst: value.clamp(0, 99))),
          ),
        ),
      ],
    );
  }

  List<Widget> _presentFields(ThemeData theme) {
    final players = _allPlayers;
    return [
      Text(
        'Touche les joueurs qui étaient là.',
        style: theme.textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final player in players)
            FilterChip(
              key: ValueKey('history-present-${player.key}'),
              label: Text(player.displayName),
              selected: _draft.present.contains(player),
              onSelected: (_) => _update((d) => d.togglePresent(player)),
            ),
          ActionChip(
            key: const Key('history-add-former'),
            avatar: const Icon(Icons.person_add_alt_1_outlined, size: 18),
            label: const Text('Ancien joueur'),
            onPressed: _addFormerPlayer,
          ),
        ],
      ),
      if (_draft.present.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          '${_draft.present.length} présent${_draft.present.length > 1 ? 's' : ''}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    ];
  }

  List<Widget> _scorerFields(ThemeData theme) {
    if (_draft.present.isEmpty) {
      return [
        Text(
          'Coche d’abord les joueurs présents pour choisir les buteurs.',
          style: theme.textTheme.bodySmall,
        ),
      ];
    }
    return [
      Text(
        'Buts attribués : ${_draft.assignedGoals} sur ${_draft.scoreFor}. '
        'Tu peux en laisser sans buteur (contre son camp, oubli…).',
        style: theme.textTheme.bodySmall,
      ),
      const SizedBox(height: 4),
      for (final player in _draft.present)
        Row(
          key: ValueKey('history-goals-${player.key}'),
          children: [
            Expanded(child: Text(player.displayName)),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: (_draft.goals[player.key] ?? 0) == 0
                  ? null
                  : () => _update(
                        (d) =>
                            d.setGoals(player, (d.goals[player.key] ?? 0) - 1),
                      ),
            ),
            SizedBox(
              width: 24,
              child: Text(
                '${_draft.goals[player.key] ?? 0}',
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              key: ValueKey('history-goals-plus-${player.key}'),
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _draft.assignedGoals >= _draft.scoreFor
                  ? null
                  : () => _update(
                        (d) =>
                            d.setGoals(player, (d.goals[player.key] ?? 0) + 1),
                      ),
            ),
          ],
        ),
    ];
  }

  List<Widget> _motmFields(ThemeData theme) {
    if (_draft.present.isEmpty) {
      return [
        Text(
          'Coche d’abord les joueurs présents.',
          style: theme.textTheme.bodySmall,
        ),
      ];
    }
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final player in _draft.present)
            ChoiceChip(
              key: ValueKey('history-motm-${player.key}'),
              label: Text(player.displayName),
              selected: _draft.manOfTheMatch == player,
              onSelected: (selected) => _update(
                (d) => selected
                    ? d.copyWith(manOfTheMatch: player)
                    : d.copyWith(clearManOfTheMatch: true),
              ),
            ),
        ],
      ),
    ];
  }

  Widget _compositionSection(ThemeData theme) {
    final formation = formationForCodeOrNull(_draft.formation);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        key: const Key('history-composition'),
        title: Text('Composition', style: theme.textTheme.titleMedium),
        subtitle: const Text('Facultatif : les titulaires et leur poste.'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (_draft.present.isEmpty)
            Text(
              'Coche d’abord les joueurs présents.',
              style: theme.textTheme.bodySmall,
            )
          else ...[
            DropdownButtonFormField<String?>(
              key: const Key('history-formation'),
              initialValue: formation?.code,
              decoration: const InputDecoration(labelText: 'Dispositif'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Pas de composition'),
                ),
                for (final option in footballFormations)
                  DropdownMenuItem<String?>(
                    value: option.code,
                    child: Text(option.code),
                  ),
              ],
              onChanged: (code) => _update(
                (d) => code == null
                    ? d.copyWith(clearFormation: true, starters: const [])
                    : d.copyWith(formation: code, starters: const []),
              ),
            ),
            if (formation != null) ...[
              const SizedBox(height: 8),
              Text(
                'Les présents qui ne sont pas placés seront sur le banc.',
                style: theme.textTheme.bodySmall,
              ),
              for (final slot in formation.slots) _slotRow(slot),
            ],
          ],
        ],
      ),
    );
  }

  Widget _slotRow(FootballFormationSlot slot) {
    final current = _draft.starters
        .where((starter) => starter.slotLabel == slot.label)
        .map((starter) => starter.player)
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(width: 48, child: Text(slot.label)),
          Expanded(
            child: DropdownButton<HistoryPlayer?>(
              key: ValueKey('history-slot-${slot.label}'),
              isExpanded: true,
              value: current,
              hint: const Text('—'),
              items: [
                const DropdownMenuItem<HistoryPlayer?>(
                  value: null,
                  child: Text('—'),
                ),
                for (final player in _draft.present)
                  DropdownMenuItem<HistoryPlayer?>(
                    value: player,
                    child: Text(player.displayName),
                  ),
              ],
              onChanged: (player) => _update(
                (d) => d.placeStarter(
                  slotLabel: slot.label,
                  xPct: slot.position.dx * 100,
                  yPct: slot.position.dy * 100,
                  player: player,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value <= 0 ? null : () => onChanged(value - 1),
            ),
            Text('$value', style: theme.textTheme.headlineSmall),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value >= 99 ? null : () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  const days = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche'
  ];
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
}
