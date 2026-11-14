import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:as_grinta/core/widgets/grinta_app_bar.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:as_grinta/features/matches/presentation/widgets/kit_jersey.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Maillots du club, réservés aux administrateurs : jusqu'à trois maillots,
/// chacun avec les couleurs des joueurs et du gardien, et proposé ou non
/// au choix pour un match.
class ClubKitsPage extends ConsumerStatefulWidget {
  const ClubKitsPage({super.key});

  @override
  ConsumerState<ClubKitsPage> createState() => _ClubKitsPageState();
}

class _ClubKitsPageState extends ConsumerState<ClubKitsPage> {
  static const palette = <String>[
    '#FFFFFF',
    '#000000',
    '#1B1F2A',
    '#0B2545',
    '#1A4AC0',
    '#1F6FEB',
    '#5BC0EB',
    '#0E9F9A',
    '#168A52',
    '#7CB518',
    '#FBE80C',
    '#F5A300',
    '#E8590C',
    '#D62828',
    '#7A1F2B',
    '#C2185B',
    '#7B2CBF',
    '#8D99AE',
  ];

  late List<ClubKit> _kits = List.of(ClubKits.all);
  late final List<TextEditingController> _labels = [
    for (final kit in _kits) TextEditingController(text: kit.label),
  ];
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _labels) {
      controller.dispose();
    }
    super.dispose();
  }

  void _update(int index, ClubKit kit) => setState(() => _kits[index] = kit);

  Future<void> _save() async {
    final kits = [
      for (var i = 0; i < _kits.length; i++)
        _kits[i].copyWith(label: _labels[i].text.trim()),
    ];
    if (kits.any((kit) => kit.label.isEmpty)) {
      _showMessage('Donne un nom à chaque maillot.');
      return;
    }
    if (!kits.any((kit) => kit.enabled)) {
      _showMessage('Au moins un maillot doit être proposé.');
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await ref.read(clubRepositoryProvider).updateKits(kits);
      ClubKits.setFromJson([for (final kit in saved) kit.toJson()]);
      refreshClubConfiguration(ref.invalidate);
      if (!mounted) return;
      setState(() => _kits = List.of(saved));
      _showMessage('Maillots enregistrés.');
    } catch (_) {
      if (mounted) _showMessage('Les maillots n’ont pas pu être enregistrés.');
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: GrintaAppBar(title: const Text('Maillots du club')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Text(
            'Les maillots que tu proposes au choix pour chaque match. Les '
            'joueurs voient celui retenu sur la fiche du match, les '
            'compositions et la vidéo.',
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.check_circle_outline),
            title: Text('Maillot automatiquement sur les photos'),
            subtitle: Text(
              'Le maillot du club accompagne chaque photo de joueur : '
              'profil, fiche, effectif et listes. Pour un match, la tenue '
              'choisie remplace la tenue par défaut dans les compositions '
              'et la vidéo. Les photos originales restent intactes.',
            ),
          ),
          if (ClubKits.usesDefaults) ...[
            const SizedBox(height: 8),
            Text(
              'Proposition tirée des couleurs du club : modifie-la puis '
              'enregistre.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          for (var i = 0; i < _kits.length; i++) ...[
            _KitEditor(
              key: ValueKey('kit-editor-${_kits[i].slot.id}'),
              kit: _kits[i],
              labelController: _labels[i],
              palette: palette,
              enabled: !_saving,
              onChanged: (kit) => _update(i, kit),
              onLabelChanged: () => setState(() {}),
            ),
            const SizedBox(height: 16),
          ],
          FilledButton(
            key: const ValueKey('club-kits-save'),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _KitEditor extends StatelessWidget {
  const _KitEditor({
    required this.kit,
    required this.labelController,
    required this.palette,
    required this.enabled,
    required this.onChanged,
    required this.onLabelChanged,
    super.key,
  });

  final ClubKit kit;
  final TextEditingController labelController;
  final List<String> palette;
  final bool enabled;
  final ValueChanged<ClubKit> onChanged;
  final VoidCallback onLabelChanged;

  @override
  Widget build(BuildContext context) {
    final preview = kit.copyWith(
      label: labelController.text.trim().isEmpty
          ? kit.label
          : labelController.text.trim(),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Opacity(
                      opacity: kit.enabled ? 1 : .4,
                      child: SizedBox(
                        width: 54,
                        height: 62,
                        child: KitJersey(kit: preview),
                      ),
                    ),
                    const Text('Joueurs'),
                    Opacity(
                      opacity: kit.enabled ? 1 : .4,
                      child: SizedBox(
                        width: 54,
                        height: 62,
                        child: KitJersey(kit: preview, isGoalkeeper: true),
                      ),
                    ),
                    const Text('Gardien'),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        key: ValueKey('kit-label-${kit.slot.id}'),
                        controller: labelController,
                        enabled: enabled,
                        maxLength: ClubKits.maxLabelLength,
                        decoration: const InputDecoration(
                          labelText: 'Nom du maillot',
                          counterText: '',
                        ),
                        onChanged: (_) => onLabelChanged(),
                      ),
                      SwitchListTile.adaptive(
                        key: ValueKey('kit-enabled-${kit.slot.id}'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Proposé pour les matchs'),
                        value: kit.enabled,
                        onChanged: enabled
                            ? (value) => onChanged(kit.copyWith(enabled: value))
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Joueurs', style: Theme.of(context).textTheme.titleSmall),
            _PatternChoice(
              key: ValueKey('kit-pattern-${kit.slot.id}'),
              value: kit.pattern,
              enabled: enabled,
              onChanged: (value) => onChanged(kit.copyWith(pattern: value)),
            ),
            const SizedBox(height: 8),
            _ColorChoice(
              label: 'Couleur du maillot',
              keyPrefix: 'kit-body-${kit.slot.id}',
              current: kit.body,
              palette: palette,
              enabled: enabled,
              onPick: (color) => onChanged(kit.copyWith(body: color)),
            ),
            const SizedBox(height: 12),
            _ColorChoice(
              label: 'Manches et col',
              keyPrefix: 'kit-trim-${kit.slot.id}',
              current: kit.trim,
              palette: palette,
              enabled: enabled,
              onPick: (color) => onChanged(kit.copyWith(trim: color)),
            ),
            const Divider(height: 28),
            Text('Gardien', style: Theme.of(context).textTheme.titleSmall),
            _PatternChoice(
              key: ValueKey('kit-goalkeeper-pattern-${kit.slot.id}'),
              value: kit.goalkeeperPattern,
              enabled: enabled,
              onChanged: (value) =>
                  onChanged(kit.copyWith(goalkeeperPattern: value)),
            ),
            const SizedBox(height: 8),
            _ColorChoice(
              label: 'Couleur du maillot de gardien',
              keyPrefix: 'kit-goalkeeper-body-${kit.slot.id}',
              current: kit.goalkeeperBody,
              palette: palette,
              enabled: enabled,
              onPick: (color) => onChanged(kit.copyWith(goalkeeperBody: color)),
            ),
            const SizedBox(height: 12),
            _ColorChoice(
              label: 'Manches et col du gardien',
              keyPrefix: 'kit-goalkeeper-trim-${kit.slot.id}',
              current: kit.goalkeeperTrim,
              palette: palette,
              enabled: enabled,
              onPick: (color) => onChanged(kit.copyWith(goalkeeperTrim: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.label,
    required this.keyPrefix,
    required this.current,
    required this.palette,
    required this.enabled,
    required this.onPick,
  });

  final String label;
  final String keyPrefix;
  final Color current;
  final List<String> palette;
  final bool enabled;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    final currentHex = colorToHex(current);
    // Une couleur déjà choisie hors palette (maillots par défaut tirés des
    // couleurs du club) reste affichée et sélectionnée.
    final options = [if (!palette.contains(currentHex)) currentHex, ...palette];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final hex in options)
              Semantics(
                button: true,
                selected: hex == currentHex,
                label: '$label $hex',
                child: InkWell(
                  key: ValueKey('$keyPrefix-$hex'),
                  customBorder: const CircleBorder(),
                  onTap: enabled ? () => onPick(AppTheme.parseHex(hex)!) : null,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.parseHex(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hex == currentHex
                            ? AppTheme.textPrimary
                            : AppTheme.outline,
                        width: hex == currentHex ? 3 : 1,
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
}

class _PatternChoice extends StatelessWidget {
  const _PatternChoice({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final KitPattern value;
  final bool enabled;
  final ValueChanged<KitPattern> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: DropdownButtonFormField<KitPattern>(
          initialValue: value,
          decoration: const InputDecoration(labelText: 'Modèle du maillot'),
          isExpanded: true,
          items: [
            for (final pattern in KitPattern.values)
              DropdownMenuItem(value: pattern, child: Text(pattern.label)),
          ],
          onChanged: enabled
              ? (value) {
                  if (value != null) onChanged(value);
                }
              : null,
        ),
      );
}
