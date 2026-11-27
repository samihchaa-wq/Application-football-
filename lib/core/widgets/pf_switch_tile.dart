import 'package:flutter/material.dart';

/// Ligne « libellé + bouton d'information + interrupteur » lisible par un
/// lecteur d'écran.
///
/// Un `SwitchListTile` dont le titre contient un bouton (« Informations »)
/// fusionne le libellé, le bouton et l'interrupteur dans un seul nœud
/// d'accessibilité : l'état activé/désactivé s'y perd, et sur le web le
/// lecteur d'écran n'annonçait aucun interrupteur. Ici l'interrupteur reste
/// un nœud à part qui porte le libellé et son état ; le bouton
/// d'information reste atteignable à côté.
class PfSwitchTile extends StatelessWidget {
  const PfSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.trailingInfo,
  });

  /// Texte affiché et annoncé avec l'interrupteur.
  final String label;
  final bool value;

  /// `null` : interrupteur grisé (réglage verrouillé ou en cours d'envoi).
  final ValueChanged<bool>? onChanged;

  /// Bouton placé juste après le libellé (en général « Informations »).
  final Widget? trailingInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onChanged != null;
    final titleStyle = theme.listTileTheme.titleTextStyle ??
        theme.textTheme.bodyLarge ??
        const TextStyle();
    return InkWell(
      // La ligne entière bascule au toucher, comme avant ; l'action est
      // portée par l'interrupteur dans l'arbre d'accessibilité.
      excludeFromSemantics: true,
      canRequestFocus: false,
      onTap: enabled ? () => onChanged!(!value) : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            Expanded(
              // Le libellé est annoncé par l'interrupteur : pas de doublon.
              child: ExcludeSemantics(
                child: Text(
                  label,
                  style: enabled
                      ? titleStyle
                      : titleStyle.copyWith(color: theme.disabledColor),
                ),
              ),
            ),
            if (trailingInfo != null) trailingInfo!,
            Semantics(
              label: label,
              child: Switch.adaptive(value: value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
}
