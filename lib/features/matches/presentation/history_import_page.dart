import 'dart:convert';

import 'package:as_grinta/core/utils/app_errors.dart';
import 'package:as_grinta/core/widgets/grinta_app_bar.dart';
import 'package:as_grinta/features/matches/data/calendar_history_repository.dart';
import 'package:as_grinta/features/matches/data/history_entry_repository.dart';
import 'package:as_grinta/features/matches/domain/history_import_batch.dart';
import 'package:as_grinta/features/matches/domain/history_match_draft.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Choix local et prévisualisation du fichier, sans transfert avant accord.
class HistoryImportPage extends ConsumerStatefulWidget {
  const HistoryImportPage({super.key});

  @override
  ConsumerState<HistoryImportPage> createState() => _HistoryImportPageState();
}

class _HistoryImportPageState extends ConsumerState<HistoryImportPage> {
  HistoryEntryContext? _entry;
  HistoryImportBatch? _batch;
  String? _fileName;
  String? _error;
  bool _loading = true;
  bool _importing = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entry = await ref.read(historyEntryRepositoryProvider).fetchContext();
      if (!mounted) return;
      setState(() { _entry = entry; _error = null; _loading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = humanizeError(error); _loading = false; });
    }
  }

  Future<void> _chooseFile() async {
    final entry = _entry;
    if (entry == null || _importing) return;
    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json'],
        allowMultiple: false, withData: true,
      );
      if (selection == null || selection.files.isEmpty || !mounted) return;
      final file = selection.files.single;
      if (file.size > 3 * 1024 * 1024 || file.bytes == null) {
        throw const FormatException('Fichier JSON de 3 Mo maximum.');
      }
      final parsed = HistoryImportBatch.parse(
        utf8.decode(file.bytes!, allowMalformed: false), entry.lastAllowedDate,
      );
      setState(() {
        _batch = parsed; _fileName = file.name;
        _error = null; _result = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _batch = null; _fileName = null;
        _error = error is FormatException ? error.message : humanizeError(error);
      });
    }
  }

  Future<void> _import() async {
    final batch = _batch;
    final entry = _entry;
    if (_importing || batch == null || entry == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Importer les matchs ?'),
        content: Text(
          'Importer ' + batch.count.toString() +
          ' rencontres dans cette équipe ? Les doublons existants seront '
          'ignorés. Un conflit bloque intégralement le fichier.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Importer')),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _importing = true);
    try {
      final result = await ref.read(historyEntryRepositoryProvider)
          .importMatches(batch, entry);
      if (!mounted) return;
      refreshHistoricalArchives(ref);
      setState(() {
        _result = result.imported.toString() + ' matchs importés, ' +
            result.skipped.toString() + ' déjà présents.';
        _batch = null; _fileName = null; _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = humanizeError(error));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _copyPrompt() async {
    await Clipboard.setData(const ClipboardData(text: _prompt));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prompt copié. Colle-le dans ton IA.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final batch = _batch;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: GrintaAppBar(title: const Text('Importer l’historique')),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Transfère les anciens matchs de ton équipe. '
            'Aucune donnée ne quitte ton appareil avant confirmation.',
          ),
          const SizedBox(height: 16),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('1. Préparer le fichier', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('Fournis tes anciens matchs et ce prompt à ton IA, '
                  'puis demande historique_petit_filet.json. '
                  'Contrôle les informations générées.'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('history-import-copy-prompt'),
                  onPressed: _copyPrompt,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copier le prompt pour mon IA'),
                ),
              ],
            ),
          )),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('2. Choisir le document JSON',
                  style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('Maximum 400 matchs, antérieurs à la première '
                    'saison déjà suivie dans Petit Filet. '
                    'N’inclus pas de données personnelles inutiles.'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('history-import-select'),
                  onPressed: _entry == null || _importing ? null : _chooseFile,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Choisir le fichier'),
                ),
                if (_fileName != null) Text(_fileName!),
              ],
            ),
          )),
          if (_error != null)
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          if (_entry == null)
            FilledButton(onPressed: () {
              setState(() => _loading = true);
              _load();
            }, child: const Text('Réessayer')),
          if (batch != null)
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('3. Vérifier avant import',
                      style: theme.textTheme.titleMedium),
                  Text(batch.count.toString() + ' matchs à importer.'),
                  for (final match in batch.matches.take(20))
                    ListTile(
                      dense: true,
                      title: Text(match['date'].toString() +
                          ' — ' + match['opponent'].toString()),
                      subtitle: Text(match['score_for'].toString() +
                          ' – ' + match['score_against'].toString()),
                    ),
                  if (batch.count > 20)
                    Text('Et ' + (batch.count - 20).toString() + ' autres.'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const Key('history-import-confirm'),
                    onPressed: _importing ? null : _import,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(_importing
                        ? 'Import en cours…' : 'Confirmer l’import'),
                  ),
                ],
              ),
            )),
          if (_result != null) Text(_result!,
              key: const Key('history-import-result')),
        ],
      ),
    );
  }
}

const _prompt = '''
Convertis les anciens matchs de mon équipe [NOM] en fichier JSON UTF-8
compatible avec Petit Filet. N'invente aucune information.
Exclus tout match sans date, adversaire, score exact,
domicile/extérieur ou type (championnat/amical) connus.
Réponds uniquement avec un JSON valide :
{"format":"petit-filet-historique","version":1,"matches":[...]}.
Chaque match possède obligatoirement :
{"date":"AAAA-MM-JJ","opponent":"Adversaire","score_for":0,
"score_against":0,"is_home":true,"match_type":"championnat"}.
Le score est toujours présenté du point de vue de MON ÉQUIPE.
Si connus, ajoute "time":"HH:MM", "address", "present":[{"name":"Prénom Nom"}],
"scorers":[{"name":"Prénom Nom","goals":1}], "motm":[{"name":"Prénom Nom"}],
"formation", "starters" et "bench". N'invente pas de joueurs ni de composition.
Classe chronologiquement, conserve l'orthographe des noms, signale séparément
les matchs exclus et ambiguïtés. N'inclus aucun mot de passe, e-mail,
téléphone ou donnée personnelle inutile. Nom du fichier :
historique_petit_filet.json.
''';
