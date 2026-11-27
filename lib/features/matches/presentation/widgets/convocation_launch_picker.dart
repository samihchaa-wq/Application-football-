import 'package:petit_filet/core/utils/club_time.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/club/club_rules.dart';
import 'package:petit_filet/features/matches/domain/convocation_launch.dart';
import 'package:petit_filet/features/matches/presentation/widgets/match_wheel_picker.dart';
import 'package:flutter/material.dart';

class ConvocationLaunchPicker extends StatelessWidget {
  const ConvocationLaunchPicker({
    super.key,
    required this.kickoffAt,
    required this.mode,
    required this.customAt,
    required this.onModeChanged,
    required this.onCustomAtChanged,
    this.enabled = true,
    this.now,
  });

  final DateTime kickoffAt;
  final ConvocationLaunchMode mode;
  final DateTime? customAt;
  final ValueChanged<ConvocationLaunchMode> onModeChanged;
  final ValueChanged<DateTime> onCustomAtChanged;
  final bool enabled;

  /// Heure de référence, injectable pour les tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final automaticAt = defaultConvocationLaunchAt(kickoffAt);
    // Un match proche (moins de J-6) : l'ouverture automatique est déjà
    // passée, donc tout s'ouvre dès l'enregistrement. Le dire au lieu
    // d'afficher une date passée comme si elle était à venir.
    final automaticAlreadyPassed = !automaticAt.isAfter(now ?? DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Lancement des convocations',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ChoiceButton(
                label: 'J-${ClubRules.featuresOpenDays}',
                selected: mode == ConvocationLaunchMode.automatic,
                enabled: enabled,
                onPressed: () => onModeChanged(ConvocationLaunchMode.automatic),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ChoiceButton(
                label: 'Maintenant',
                selected: mode == ConvocationLaunchMode.now,
                enabled: enabled,
                onPressed: () => onModeChanged(ConvocationLaunchMode.now),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ChoiceButton(
                label: 'Choisir',
                selected: mode == ConvocationLaunchMode.custom,
                enabled: enabled,
                onPressed: () => _pickCustom(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          switch (mode) {
            ConvocationLaunchMode.automatic => automaticAlreadyPassed
                ? 'J-${ClubRules.featuresOpenDays} tombait le '
                    '${_formatDateTime(automaticAt)}, c’est déjà passé : '
                    'les disponibilités s’ouvrent tout de suite. '
                    'Pour les ouvrir plus tard, touche « Choisir ».'
                : 'Ouverture le ${_formatDateTime(automaticAt)}',
            ConvocationLaunchMode.now => 'Ouverture dès l’enregistrement',
            ConvocationLaunchMode.custom => customAt == null
                ? 'Choisis une date et une heure'
                : 'Ouverture le ${_formatDateTime(customAt!)}',
          },
          style:
              mode == ConvocationLaunchMode.automatic && automaticAlreadyPassed
                  ? Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.info)
                  : Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _pickCustom(BuildContext context) async {
    final now = ClubTime.now();
    final minimum = ClubTime.wallClock(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    final maximum = kickoffAt.subtract(const Duration(minutes: 1));
    if (maximum.isBefore(minimum)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le match est trop proche. Choisis « Maintenant ».'),
        ),
      );
      return;
    }

    final initial = customAt ??
        suggestedCustomConvocationLaunchAt(
          kickoffAt: kickoffAt,
          now: minimum,
        );
    final picked = await MatchWheelPicker.pickDateTime(
      context: context,
      title: 'Lancement des convocations',
      initialDateTime: initial,
      minimumDate: minimum,
      maximumDate: maximum,
    );
    if (picked == null || !context.mounted) return;

    final error = validateConvocationLaunch(
      mode: ConvocationLaunchMode.custom,
      kickoffAt: kickoffAt,
      customAt: picked,
      now: minimum,
    );
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    onCustomAtChanged(picked);
    onModeChanged(ConvocationLaunchMode.custom);
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime value) =>
      '${_formatDate(value)} à ${_formatTime(value)}';
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
      ),
    );
    if (selected) {
      // Texte blanc par défaut du bouton : l'orange sur fond rouge était
      // quasi illisible (contraste inférieur à 3:1).
      return FilledButton(
        style: style,
        onPressed: enabled ? onPressed : null,
        child: Text(label, maxLines: 1),
      );
    }
    return OutlinedButton(
      style: style,
      onPressed: enabled ? onPressed : null,
      child: Text(label, maxLines: 1),
    );
  }
}
