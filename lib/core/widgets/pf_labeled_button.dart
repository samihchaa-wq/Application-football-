import 'package:flutter/material.dart';

/// Bouton d'en-tête en forme de bulle : icône et nom dans la même bulle,
/// de la même couleur.
class PfLabeledButton extends StatelessWidget {
  const PfLabeledButton({
    required this.label,
    this.semanticLabel,
    required this.color,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.borderColor,
    super.key,
  });

  final String label;

  /// Libellé lu par le lecteur d'écran, s'il diffère du texte affiché.
  final String? semanticLabel;
  final Color color;
  final Widget icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    // Contenu exclu, mais pas l'InkWell : il porte l'appui et le focus, sans
    // quoi la touche Tab sautait ce bouton (sémantique activée sur le web).
    return Semantics(
      container: true,
      button: true,
      label: semanticLabel ?? label,
      child: Material(
        color: backgroundColor ?? color.withValues(alpha: .08),
        shape: StadiumBorder(
          side: BorderSide(color: borderColor ?? color.withValues(alpha: .18)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 38,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 10),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(width: 4),
                    Text(
                      label,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 13,
                            color: color,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
