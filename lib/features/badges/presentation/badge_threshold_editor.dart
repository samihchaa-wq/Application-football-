import 'package:as_grinta/core/utils/app_errors.dart';
import 'package:as_grinta/features/badges/data/badge_admin_repository.dart';
import 'package:as_grinta/features/badges/data/badge_repository.dart';
import 'package:as_grinta/features/badges/data/featured_badges_repository.dart';
import 'package:as_grinta/features/badges/data/statistics_badge_emblems_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Action d'administration : changer le nombre à atteindre pour un badge à
/// paliers (par exemple 50 buts → 40 buts), pour le club seulement.
class BadgeThresholdEditorButton extends StatelessWidget {
  const BadgeThresholdEditorButton({super.key, required this.badge});

  final BadgeDef badge;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: const Key('badge-threshold-edit'),
      onPressed: () => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _BadgeThresholdDialog(badge: badge),
      ),
      child: Text('Seuil : ${badge.threshold}'),
    );
  }
}

class _BadgeThresholdDialog extends ConsumerStatefulWidget {
  const _BadgeThresholdDialog({required this.badge});

  final BadgeDef badge;

  @override
  ConsumerState<_BadgeThresholdDialog> createState() =>
      _BadgeThresholdDialogState();
}

class _BadgeThresholdDialogState extends ConsumerState<_BadgeThresholdDialog> {
  late final TextEditingController _value =
      TextEditingController(text: '${widget.badge.threshold ?? ''}');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _value.addListener(_refresh);
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  int? get _parsed => int.tryParse(_value.text.trim());

  bool get _canSave {
    final value = _parsed;
    return !_saving &&
        value != null &&
        value >= 1 &&
        value <= 10000 &&
        value != widget.badge.threshold;
  }

  Future<void> _save() async {
    final value = _parsed;
    if (!_canSave || value == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(badgeAdminRepositoryProvider).updateBadgeThreshold(
            badgeCode: widget.badge.code,
            threshold: value,
          );
      ref.invalidate(badgeCatalogProvider);
      ref.invalidate(myArmoireProvider);
      ref.invalidate(featuredBadgesProvider);
      ref.invalidate(statisticsBadgeEmblemsProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Nouveau seuil : $value.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanizeError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Seuil de « ${widget.badge.name} »'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Le nombre à atteindre pour gagner ce badge dans ton club. Il '
            'doit rester entre les paliers voisins. Un seuil abaissé décerne '
            'aussitôt le badge à ceux qui l’atteignent ; un seuil relevé ne '
            'retire pas un badge déjà gagné.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('badge-threshold-field'),
            controller: _value,
            enabled: !_saving,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Seuil'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          key: const Key('badge-threshold-save'),
          onPressed: _canSave ? _save : null,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
