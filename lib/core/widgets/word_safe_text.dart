import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Texte court qui ne coupe jamais un mot en deux.
///
/// Flutter coupe un mot trop long pour la largeur disponible au milieu
/// (« Compétite / ur »). Ici, la police est réduite juste assez pour que le
/// mot le plus long tienne sur une ligne, sans descendre sous [minScale].
/// Les retours à la ligne se font donc entre les mots.
class WordSafeText extends StatelessWidget {
  const WordSafeText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.minScale = 0.7,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double minScale;

  /// Facteur à appliquer à [style] pour que le mot le plus long de [text]
  /// tienne dans [maxWidth]. Exposé pour les tests.
  static double scaleFor({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required TextScaler textScaler,
    required TextDirection textDirection,
    double minScale = 0.7,
  }) {
    if (!maxWidth.isFinite || maxWidth <= 0) return 1;
    var widest = 0.0;
    for (final word in text.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    if (widest <= maxWidth) return 1;
    // Petite marge : sans elle, les arrondis du tracé faisaient encore
    // tomber la dernière lettre sur la ligne suivante.
    return math.max(minScale, maxWidth * 0.97 / widest);
  }

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = scaleFor(
          text: text,
          style: base,
          maxWidth: constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: Directionality.of(context),
          minScale: minScale,
        );
        final fontSize = base.fontSize ?? 14;
        return Text(
          text,
          style: scale == 1 ? base : base.copyWith(fontSize: fontSize * scale),
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}
