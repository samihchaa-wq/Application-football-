import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:petit_filet/core/widgets/pf_app_bar.dart';
import 'package:petit_filet/core/widgets/pf_loader.dart';
import 'package:petit_filet/features/license/data/license_repository.dart';
import 'package:petit_filet/features/license/domain/license_models.dart';
import 'package:petit_filet/features/players/data/roster_repository.dart';

/// Espace « Licence » de l'admin : qui a payé sa licence, et qui a payé les
/// autres dépenses du club (ajoutées avec « + », renommables).
class LicensePage extends ConsumerStatefulWidget {
  const LicensePage({super.key});

  @override
  ConsumerState<LicensePage> createState() => _LicensePageState();
}

class _LicensePageState extends ConsumerState<LicensePage> {
  bool _onlyUnpaid = false;

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Exécute une écriture puis recharge ; signale l'échec.
  Future<void> _run(Future<void> Function() action, {String? seasonId}) async {
    try {
      await action();
    } catch (error) {
      _toast('Enregistrement impossible. ${humanizeError(error)}');
    }
    ref.invalidate(licenseExpensesProvider);
    if (seasonId != null) ref.invalidate(seasonLicensesProvider(seasonId));
  }

  Future<String?> _askLabel({String initial = '', required String title}) {
    return showDialog<String>(
      context: context,
      builder: (_) => _LabelDialog(title: title, initial: initial),
    );
  }

  Future<void> _addExpense(String seasonId) async {
    final label = await _askLabel(title: 'Nouvelle dépense');
    if (label == null) return;
    await _run(
      () => ref.read(licenseRepositoryProvider).addExpense(label),
      seasonId: seasonId,
    );
  }

  Future<void> _editExpense(LicenseExpense expense, String seasonId) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Renommer'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Supprimer cette dépense'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    final repository = ref.read(licenseRepositoryProvider);
    if (choice == 'rename') {
      final label = await _askLabel(title: 'Renommer', initial: expense.label);
      if (label == null) return;
      await _run(() => repository.renameExpense(expense.id, label),
          seasonId: seasonId);
    } else {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Supprimer « ${expense.label} » ?'),
          content: const Text(
              'Les paiements cochés pour cette dépense seront effacés.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await _run(() => repository.deleteExpense(expense.id),
          seasonId: seasonId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seasonAsync = ref.watch(openSeasonIdProvider);
    return Scaffold(
      appBar: PfAppBar(title: const Text('Licence')),
      body: seasonAsync.when(
        loading: () => const Center(child: PfProgressIndicator()),
        error: (error, _) => _Message(
          'Impossible de charger la saison. ${humanizeError(error)}',
          onRetry: () => ref.invalidate(openSeasonIdProvider),
        ),
        data: (seasonId) => seasonId == null
            ? const _Message('Aucune saison ouverte.')
            : _body(seasonId),
      ),
    );
  }

  Widget _body(String seasonId) {
    final rosterAsync = ref.watch(rosterProvider(seasonId));
    final licensesAsync = ref.watch(seasonLicensesProvider(seasonId));
    final expensesAsync = ref.watch(licenseExpensesProvider);

    final error =
        rosterAsync.error ?? licensesAsync.error ?? expensesAsync.error;
    if (error != null) {
      return _Message(
        'Impossible de charger les licences. ${humanizeError(error)}',
        onRetry: () {
          ref.invalidate(rosterProvider(seasonId));
          ref.invalidate(seasonLicensesProvider(seasonId));
          ref.invalidate(licenseExpensesProvider);
        },
      );
    }
    final roster = rosterAsync.asData?.value;
    final paid = licensesAsync.asData?.value;
    final expenses = expensesAsync.asData?.value;
    if (roster == null || paid == null || expenses == null) {
      return const Center(child: PfProgressIndicator());
    }

    final players = roster.where((p) => p.isActive).toList()
      ..sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    bool upToDate(RosterPlayer p) =>
        paid.hasPaidLicense(p.id) &&
        expenses.every((e) => paid.hasPaidExpense(e.id, p.id));
    final shown =
        _onlyUnpaid ? players.where((p) => !upToDate(p)).toList() : players;
    final repository = ref.read(licenseRepositoryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(rosterProvider(seasonId));
        ref.invalidate(licenseExpensesProvider);
        ref.invalidate(seasonLicensesProvider(seasonId));
        await ref.read(seasonLicensesProvider(seasonId).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Licences payées : '
                    '${players.where((p) => paid.hasPaidLicense(p.id)).length}'
                    ' / ${players.length}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  // Renommer / supprimer une dépense se fait ici, une seule
                  // fois pour tout le club, pas sur chaque joueur.
                  for (final e in expenses)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${e.label} : '
                            '${players.where((p) => paid.hasPaidExpense(e.id, p.id)).length}'
                            ' / ${players.length}',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Renommer ou supprimer « ${e.label} »',
                          icon: const Icon(Icons.more_horiz),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _editExpense(e, seasonId),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _addExpense(seasonId),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter une dépense'),
                      ),
                      FilterChip(
                        label: const Text('Impayés seulement'),
                        selected: _onlyUnpaid,
                        onSelected: (value) =>
                            setState(() => _onlyUnpaid = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  players.isEmpty
                      ? 'Aucun joueur dans l’effectif.'
                      : 'Tout le monde est à jour.',
                ),
              ),
            ),
          for (final player in shown)
            Card(
              key: ValueKey(player.id),
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      _playerName(player),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  // Nom du joueur dans ce qui est lu : sinon le lecteur
                  // d'écran répétait « Licence, case cochée » sans dire pour
                  // qui.
                  CheckboxListTile(
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      'Licence',
                      semanticsLabel: 'Licence de ${_playerName(player)}',
                    ),
                    value: paid.hasPaidLicense(player.id),
                    onChanged: (value) => _run(
                      () =>
                          repository.setLicensePaid(player.id, value ?? false),
                      seasonId: seasonId,
                    ),
                  ),
                  for (final e in expenses)
                    CheckboxListTile(
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        e.label,
                        semanticsLabel: '${e.label} de ${_playerName(player)}',
                      ),
                      value: paid.hasPaidExpense(e.id, player.id),
                      onChanged: (value) => _run(
                        () => repository.setExpensePaid(
                            e.id, player.id, value ?? false),
                        seasonId: seasonId,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(text),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ],
      );
}

class _LabelDialog extends StatefulWidget {
  const _LabelDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<_LabelDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.length >= 2) Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          controller: _controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: 'Nom de la dépense',
          ),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(onPressed: _submit, child: const Text('Valider')),
        ],
      );
}

String _playerName(RosterPlayer player) =>
    player.fullName.isEmpty ? player.displayName : player.fullName;
