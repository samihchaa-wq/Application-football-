import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class _GrintaPageTransitionsBuilder extends PageTransitionsBuilder {
  const _GrintaPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(opacity: curved, child: child);
  }
}

abstract final class AppTheme {
  // Palette du blason AS La Grinta : bleu nuit, bleu royal, jaune club et blanc.
  static const Color background = Color(0xFF041224);
  static const Color surface = Color(0xFF091B33);
  static const Color surfaceHigh = Color(0xFF102A4A);
  static const Color surfaceHero = Color(0xFF173D6E);
  static const Color outline = Color(0xFF2A527E);
  // Bleu royal de l'écusson AS La Grinta (échantillonné sur le blason, ~#05299D)
  // repris comme fil conducteur : `primary` en porte l'identité pour les boutons
  // et actions, `primaryBright` en donne une déclinaison claire, lisible sur le
  // fond bleu nuit, pour les liens, icônes et bordures de champ actif.
  //
  // Ces trois couleurs suivent les couleurs choisies par le club (voir
  // [applyClubColors]) ; les valeurs par défaut sont celles d'origine.
  static const Color defaultPrimary = Color(0xFF1A4AC0);
  static const Color defaultPrimaryBright = Color(0xFF6E93F6);
  static const Color defaultAccent = Color(0xFFFBE80C);

  static Color _primary = defaultPrimary;
  static Color _primaryBright = defaultPrimaryBright;
  static Color _accent = defaultAccent;

  static Color get primary => _primary;
  static Color get primaryBright => _primaryBright;
  static Color get accent => _accent;

  static final ValueNotifier<int> _colorsRevision = ValueNotifier<int>(0);

  /// Change à chaque nouvelle couleur de club : l'application se redessine.
  static ValueListenable<int> get colorsRevision => _colorsRevision;

  /// Applique les couleurs du club. La couleur principale teinte les boutons
  /// et les liens, la seconde les mises en avant. Leur clarté est ramenée
  /// dans une plage lisible sur le fond sombre de l'application : un club
  /// aux couleurs très foncées ou très pâles garde une interface lisible.
  static void applyClubColors({Color? primary, Color? secondary}) {
    final nextPrimary =
        primary == null ? defaultPrimary : _withLightness(primary, .36, .50);
    final nextBright = primary == null
        ? defaultPrimaryBright
        : _withLightness(primary, .66, .76);
    final nextAccent =
        secondary == null ? defaultAccent : _withLightness(secondary, .52, 1);
    if (nextPrimary == _primary &&
        nextBright == _primaryBright &&
        nextAccent == _accent) {
      return;
    }
    _primary = nextPrimary;
    _primaryBright = nextBright;
    _accent = nextAccent;
    _colorsRevision.value += 1;
  }

  static void resetClubColors() => applyClubColors();

  static Color _withLightness(Color color, double min, double max) {
    final hsl = HSLColor.fromColor(color.withValues(alpha: 1));
    return hsl.withLightness(hsl.lightness.clamp(min, max)).toColor();
  }

  /// « #1F6FEB » → couleur ; null si le texte n'est pas une couleur valide.
  static Color? parseHex(String? hex) {
    if (hex == null) return null;
    final match = RegExp(r'^#([0-9A-Fa-f]{6})$').firstMatch(hex.trim());
    if (match == null) return null;
    return Color(0xFF000000 | int.parse(match.group(1)!, radix: 16));
  }

  static const Color reward = Color(0xFFFFD84A);
  static const Color success = Color(0xFF48C98B);
  static const Color warning = Color(0xFFF0A34A);
  static const Color admin = Color(0xFF5C9CE6);
  static const Color error = Color(0xFFFF6F7D);
  static const Color textPrimary = Color(0xFFF8FBFF);
  static const Color textSecondary = Color(0xFFDCE8F7);
  static const Color textFaint = Color(0xFF9FB4CC);

  // Statuts de disponibilité : convoqué, liste d'attente, absent, sans réponse.
  // Ces quatre couleurs servent de titre de colonne, de bordure et de teinte de
  // fond directement sur le bleu nuit de l'application. Les variantes sombres
  // employées auparavant (#168A52, #B33A3A, #6B7280) n'atteignaient que 3,4:1,
  // 2,6:1 et 3,1:1 sur ce fond, sous le seuil WCAG AA de 4,5:1 : les titres
  // « Convoqués », « Absents » et « Sans réponse » étaient difficilement
  // lisibles. Les teintes claires ci-dessous restent au-dessus de 6:1.
  //
  // Ces couleurs ne conviennent qu'au texte et aux fonds teintés : sur un
  // bouton plein, c'est le libellé clair qui deviendrait illisible.
  static const Color availabilityIn = success;
  static const Color availabilityWaiting = warning;
  static const Color availabilityOut = error;
  static const Color availabilityUnknown = textFaint;

  // Les textes utilisent leur graisse native sans contour artificiel.
  static const List<Shadow> textOutline = [];

  // Grille de 8 px et niveaux de surfaces communs.
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 22;

  static ShapeBorder cardShape({
    double radius = radiusMd,
    Color? borderColor,
    double borderWidth = 1,
  }) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(
          color: borderColor ?? outline.withValues(alpha: .34),
          width: borderWidth,
        ),
      );

  static ThemeData get dark {
    final scheme = ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: surfaceHero,
      onPrimaryContainer: textPrimary,
      secondary: accent,
      onSecondary: background,
      secondaryContainer: Color(0xFF393506),
      onSecondaryContainer: Color(0xFFFFF6A8),
      tertiary: reward,
      onTertiary: background,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceContainerHighest: surfaceHigh,
      error: error,
      // `error` sert de FOND aux boutons de confirmation destructifs
      // (« Supprimer », « Tout effacer »). Blanc sur #FF6F7D ne donne que
      // 2,68:1, sous le seuil WCAG AA même pour du grand texte ; le bleu nuit
      // du fond général monte à 7,00:1. `error` employé en texte reste
      // inchangé et parfaitement lisible.
      onError: background,
      outline: outline,
      outlineVariant: Color(0xFF173755),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _GrintaPageTransitionsBuilder(),
          TargetPlatform.iOS: _GrintaPageTransitionsBuilder(),
          TargetPlatform.macOS: _GrintaPageTransitionsBuilder(),
          TargetPlatform.windows: _GrintaPageTransitionsBuilder(),
          TargetPlatform.linux: _GrintaPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _GrintaPageTransitionsBuilder(),
        },
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w400,
          letterSpacing: -1,
          shadows: textOutline,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w400,
          letterSpacing: -.55,
          shadows: textOutline,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w400,
          shadows: textOutline,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w400,
          letterSpacing: -.2,
          shadows: textOutline,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w400,
          shadows: textOutline,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          color: textPrimary,
          shadows: textOutline,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: textPrimary,
          height: 1.4,
          shadows: textOutline,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: textSecondary,
          height: 1.4,
          shadows: textOutline,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: textFaint,
          height: 1.35,
          shadows: textOutline,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w400,
          letterSpacing: .05,
          shadows: textOutline,
        ),
        labelMedium: base.textTheme.labelMedium?.copyWith(
          color: textSecondary,
          shadows: textOutline,
        ),
        labelSmall: base.textTheme.labelSmall?.copyWith(
          color: textFaint,
          shadows: textOutline,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        titleSpacing: 12,
        actionsPadding: EdgeInsets.only(right: 6),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w400,
          letterSpacing: -.3,
          shadows: textOutline,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: .18),
        shape: cardShape(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(64, 48)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return surfaceHigh;
            if (states.contains(WidgetState.pressed)) {
              return primary.withValues(alpha: .78);
            }
            return primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? textFaint
                : Colors.white;
          }),
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: .06),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          side: BorderSide(color: outline.withValues(alpha: .6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBright,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w400),
        ),
      ),
      iconTheme: const IconThemeData(color: textSecondary, size: 22),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        hintStyle: const TextStyle(color: textFaint),
        labelStyle: const TextStyle(color: textSecondary),
        helperStyle: const TextStyle(
          color: textFaint,
          fontSize: 12,
          height: 1.35,
        ),
        errorStyle: const TextStyle(color: error, fontSize: 12, height: 1.35),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: outline.withValues(alpha: .48)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: outline.withValues(alpha: .42)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: primaryBright, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1.4),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          // Les onglets principaux doivent rester lisibles sur téléphone,
          // y compris lorsque la fiche du match en affiche cinq côte à côte.
          minimumSize: WidgetStateProperty.all(const Size(48, 42)),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? const Color(0xFF17457A)
                : surfaceHigh;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? Colors.white
                : textSecondary;
          }),
          side: WidgetStateProperty.all(BorderSide.none),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSm),
            ),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHigh,
        side: BorderSide(color: outline.withValues(alpha: .28)),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w400,
          shadows: textOutline,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 62,
        backgroundColor: const Color(0xFF07182D),
        indicatorColor: accent.withValues(alpha: .13),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: selected ? 25 : 21,
            color: selected ? accent : textFaint,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: selected ? 11.5 : 11,
            height: 1.1,
            color: selected ? Colors.white : textFaint,
            fontWeight: selected ? FontWeight.w400 : FontWeight.w400,
            shadows: textOutline,
          );
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHero,
        contentTextStyle: const TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        circularTrackColor: surfaceHigh,
        linearTrackColor: surfaceHigh,
        linearMinHeight: 4,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      dividerTheme: DividerThemeData(
        color: outline.withValues(alpha: .3),
        space: 24,
        thickness: 1,
      ),
      dividerColor: outline.withValues(alpha: .3),
    );
  }
}
