import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:petit_filet/core/widgets/pf_app_bar.dart';
import 'package:petit_filet/core/widgets/pf_loader.dart';
import 'package:petit_filet/features/admin/data/former_players_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Anciens joueurs du club : à la demande d'un ancien joueur, raccourcir son
/// nom (« Yves D. ») ou le remplacer par « Ancien joueur » dans tout
/// l'historique. Réservé aux administrateurs (route `/admin/...`).
class FormerPlayersPage extends ConsumerStatefulWidget {
  const FormerPlayersPage({super.key});

  @override
  ConsumerState<FormerPlayersPage> createState() => _FormerPlayersPageState();
}

class _FormerPlayersPageState extends ConsumerState<FormerPlayersPage> {
  List<FormerPlayer>? _players;
  String? _error;
  String _query = '';
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final players = await ref.read(formerPlayersRepositoryProvider).list();
      if (mounted) setState(() => _players = players);
    } catch (error) {
      if (mounted) setState(() => _error = humanizeError(error));
    }
  }

  Future<void> _rename(FormerPlayer player) async {
    final mode = await showDialog<FormerPlayerRename>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(player.displayName),
        content: const Text(
          'Ce nom sera changé partout dans l’historique du club (feuilles de '
          'match, statistiques, compositions). Les statistiques restent '
          'attachées au même joueur. Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            key: const Key('former-player-shorten'),
            onPressed: () => Navigator.pop(context, FormerPlayerRename.shorten),
            child: const Text('Raccourcir (Yves D.)'),
          ),
          TextButton(
            key: const Key('former-player-anonymize'),
            onPressed: () =>
                Navigator.pop(context, FormerPlayerRename.anonymize),
            child: const Text('Ancien joueur'),
          ),
        ],
      ),
    );
    if (mode == null || !mounted) return;

    setState(() => _busyId = player.id);
    try {
      final newName = await ref
          .read(formerPlayersRepositoryProvider)
          .rename(player.id, mode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nom remplacé par « $newName ».')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanizeError(error))),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = _players;
    final query = _query.trim().toLowerCase();
    final visible = players
        ?.where((p) => p.displayName.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      appBar: PfAppBar(title: const Text('Anciens joueurs')),
      body: ListView(
        key: const Key('former-players-page'),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Joueurs sans compte actif : anciens membres et invités. À la '
            'demande d’un ancien joueur, son nom peut être raccourci ou '
            'remplacé dans tout l’historique du club. Quand un membre supprime '
            'son compte, son nom est déjà raccourci automatiquement.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('former-players-search'),
            decoration: const InputDecoration(
              labelText: 'Rechercher un nom',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(onPressed: _load, child: const Text('Réessayer')),
          ] else if (visible == null)
            const Center(child: PfProgressIndicator())
          else if (visible.isEmpty)
            const Text('Aucun ancien joueur.')
          else
            for (final player in visible)
              ListTile(
                key: Key('former-player-${player.id}'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(player.displayName),
                trailing: _busyId == player.id
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: PfProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_outlined),
                onTap: _busyId == null ? () => _rename(player) : null,
              ),
        ],
      ),
    );
  }
}
