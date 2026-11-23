import 'package:flutter/material.dart';

/// Affiche un score entouré en vert, orange ou rouge selon le résultat
/// de l'équipe du club. La date éventuelle reste en blanc, lisible quelle que soit la
/// couleur du résultat.
class MatchResultScoreChip extends StatelessWidget {
  const MatchResultScoreChip({
    super.key,
    required this.scoreOwn,
    required this.scoreOpponent,
    this.textStyle,
    this.subtitle,
    this.onTap,
    this.semanticLabel,
  });

  final int scoreOwn;
  final int scoreOpponent;
  final TextStyle? textStyle;
  final String? subtitle;
  final VoidCallback? onTap;
  final String? semanticLabel;

  Color get _color {
    if (scoreOwn > scoreOpponent) return const Color(0xFF1B8A4B);
    if (scoreOwn == scoreOpponent) return const Color(0xFFB4610D);
    return const Color(0xFFC62A3B);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.7),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$scoreOwn–$scoreOpponent',
            style:
                (textStyle ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
              color: color,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return chip;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: chip,
      ),
    );
  }
}
