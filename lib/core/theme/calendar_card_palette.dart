import 'package:flutter/material.dart';

/// Couleurs des cartes du calendrier (« Défilé » et « Par mois ») :
/// bleu foncé = championnat, bleu clair = amical, violet foncé = match entre
/// nous, or = événement.
///
/// Le fond est une vraie teinte de la famille (et non plus un noir à peine
/// coloré), le liseré une version claire : le type de rendez-vous se lit au
/// premier coup d'œil. Le liseré sert aussi de couleur de texte et d'icône
/// sur la carte : chaque paire garde un contraste d'au moins 4,5:1.
abstract final class CalendarCardPalette {
  /// Repli pour un ancien match dont le type n'est pas encore connu.
  static const Color finishedSurface = Color(0xFF1B2128);
  static const Color finishedBorder = Color(0xFF6B7885);

  /// Championnat : bleu foncé (marine).
  static const Color championshipSurface = Color(0xFF0F2557);
  static const Color championshipBorder = Color(0xFF5C8DFF);

  /// Amical : bleu clair. Le fond reste assez sombre pour que le score
  /// (vert, orange ou rouge selon le résultat) garde son contraste.
  static const Color friendlySurface = Color(0xFF1B4F7C);
  static const Color friendlyBorder = Color(0xFF8FD3FF);

  /// Match entre nous : violet foncé.
  static const Color internalSurface = Color(0xFF2A1B57);
  static const Color internalBorder = Color(0xFFA987FF);

  /// Événement : or.
  static const Color eventSurface = Color(0xFF3D2F0A);
  static const Color eventBorder = Color(0xFFF2C94C);

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
