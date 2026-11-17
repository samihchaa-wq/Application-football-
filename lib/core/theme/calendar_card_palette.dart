import 'package:flutter/material.dart';

/// Couleurs des cartes du calendrier (« Défilé » et « Par mois ») :
/// bleu foncé = championnat, bleu clair = amical, violet foncé = match entre
/// nous, or = événement.
///
/// Les fonds restent sombres pour préserver le thème de l'app, mais les
/// familles de couleurs sont volontairement assez éloignées pour que le type
/// de rendez-vous soit identifiable au premier coup d'œil.
abstract final class CalendarCardPalette {
  /// Repli pour un ancien match dont le type n'est pas encore connu.
  static const Color finishedSurface = Color(0xFF20242C);
  static const Color finishedBorder = Color(0xFF626A78);

  /// Championnat : bleu foncé.
  static const Color championshipSurface = Color(0xFF0C234D);
  static const Color championshipBorder = Color(0xFF2459C6);

  /// Amical : bleu clair, distinct du championnat.
  static const Color friendlySurface = Color(0xFF173B59);
  static const Color friendlyBorder = Color(0xFF6CCBFF);

  /// Match entre nous : violet foncé.
  static const Color internalSurface = Color(0xFF281739);
  static const Color internalBorder = Color(0xFF7435B5);

  /// Événement : or.
  static const Color eventSurface = Color(0xFF3F3213);
  static const Color eventBorder = Color(0xFFE8BF4A);

  /// Événement annulé : rouge.
  static const Color cancelledSurface = Color(0xFF481C22);
  static const Color cancelledBorder = Color(0xFFEB4056);

  /// Couleur d'un match d'après son identité sportive, indépendamment du fait
  /// qu'il soit à venir ou terminé. Les archives sans type confirmé restent
  /// volontairement grises plutôt que d'inventer « Championnat ».
  static Color matchSurface(
    String? matchType, {
    bool unknownAsFinished = false,
  }) {
    return switch (matchType) {
      'entre_nous' => internalSurface,
      'amical' => friendlySurface,
      'championnat' => championshipSurface,
      _ => unknownAsFinished ? finishedSurface : championshipSurface,
    };
  }

  static Color matchBorder(
    String? matchType, {
    bool unknownAsFinished = false,
  }) {
    return switch (matchType) {
      'entre_nous' => internalBorder,
      'amical' => friendlyBorder,
      'championnat' => championshipBorder,
      _ => unknownAsFinished ? finishedBorder : championshipBorder,
    };
  }
}
