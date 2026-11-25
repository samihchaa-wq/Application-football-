import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Styles de boutons pleins à couleur propre.
///
/// Le thème peint un dégradé rouge (la couleur de la marque) sur TOUS les
/// boutons pleins, quelle que soit leur `backgroundColor` : un bouton
/// « Supprimer » ou « Présent » forcé en rouge d'erreur ou en vert gardait
/// donc l'aspect d'un bouton normal. Ces styles remplacent le dégradé par un
/// aplat de la couleur voulue.
abstract final class PfButtonStyles {
  /// Bouton plein d'une couleur sémantique (vert, rouge d'erreur…), texte
  /// sombre : le blanc ne passe pas le contraste de 4,5:1 sur ces teintes
  /// claires.
  static ButtonStyle solid(
    Color color, {
    Color foreground = AppTheme.background,
  }) =>
      FilledButton.styleFrom(
        foregroundColor: foreground,
        disabledForegroundColor: foreground.withValues(alpha: .6),
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundBuilder: (context, states, child) => DecoratedBox(
          decoration: BoxDecoration(
            color: states.contains(WidgetState.disabled)
                ? color.withValues(alpha: .45)
                : states.contains(WidgetState.pressed)
                    ? color.withValues(alpha: .85)
                    : color,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: child,
        ),
      );

  /// Action destructive (supprimer, retirer, tout effacer). Le rouge d'erreur,
  /// plus clair et plus rose que le rouge de la marque, la distingue d'un
  /// « Confirmer » ordinaire dans une même fenêtre.
  static ButtonStyle get danger => solid(AppTheme.error);

  /// « Présent » choisi.
  static ButtonStyle get success => solid(AppTheme.success);
}
