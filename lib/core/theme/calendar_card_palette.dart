import 'package:flutter/material.dart';

/// Couleurs des cartes du calendrier (« Défilé » et « Par mois ») :
/// bleu = championnat, bleu ciel = amical, violet = match entre nous,
/// or = événement.
///
/// Les fonds sont des teintes pâles de l'habillage clair, mais les
/// familles de couleurs sont volontairement assez éloignées pour que le type
/// de rendez-vous soit identifiable au premier coup d'œil.
abstract final class CalendarCardPalette {
  /// Repli pour un ancien match dont le type n'est pas encore connu.
  static const Color finishedSurface = Color(0xFF1B2128);
  static const Color finishedBorder = Color(0xFF6B7885);

  /// Championnat : bleu foncé.
  static const Color championshipSurface = Color(0xFF132033);
  static const Color championshipBorder = Color(0xFF4C8DFF);

  /// Amical : bleu clair, distinct du championnat.
  static const Color friendlySurface = Color(0xFF11262C);
  static const Color friendlyBorder = Color(0xFF3FB8D8);

  /// Match entre nous : violet foncé.
  static const Color internalSurface = Color(0xFF221A33);
  static const Color internalBorder = Color(0xFFA27BE8);

  /// Événement : or.
  static const Color eventSurface = Color(0xFF2A2312);
  static const Color eventBorder = Color(0xFFFFB020);

  /// Événement annulé : rouge.
  static const Color cancelledSurface = Color(0xFF2B161A);
  static const Color cancelledBorder = Color(0xFFFF5A6A);

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
