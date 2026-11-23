import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:petit_filet/core/theme/pf_card_border.dart';

class _PfPageTransitionsBuilder extends PageTransitionsBuilder {
  const _PfPageTransitionsBuilder();

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
  // Habillage « Nuit » : fond nuit, cartes en relief, rouge vif et ambre,
  // titres et scores en condensée de stade (Oswald).
  static const Color background = Color(0xFF0B0F14);
  static const Color surface = Color(0xFF141A22);
  static const Color surfaceHigh = Color(0xFF1F2733);
  static const Color surfaceHero = Color(0xFF2B1D24);
  static const Color outline = Color(0xFF6B7885);
  static const Color defaultPrimary = Color(0xFFD71932);
  static const Color defaultPrimaryBright = Color(0xFFFF6B7D);
  static const Color defaultAccent = Color(0xFFFFB020);

  /// Famille des titres et des scores (condensée de stade).
  static const String displayFont = 'Oswald';

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
        : _withLightness(primary, .62, .78);
    final nextAccent = secondary == null
        ? defaultAccent
        : _readableOn(_withLightness(secondary, .5, 1), selectedSurface);
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

  /// Texte des boutons pleins : blanc tant qu'il reste lisible sur la couleur
  /// du bouton, sinon la couleur de fond sombre (couleur de club très claire).
  static Color get onPrimaryButton =>
      contrastRatio(Colors.white, primary) >= minAccentContrast
          ? Colors.white
          : background;

  /// Haut du dégradé des boutons pleins : un peu plus clair que [primary],
  /// sans jamais faire passer le texte sous le contraste AA.
  static Color get primaryLit {
    final lit = Color.lerp(primary, Colors.white, .10)!;
    return contrastRatio(onPrimaryButton, lit) >= minAccentContrast
        ? lit
        : primary;
  }

  /// Fond d'un onglet ou d'un choix sélectionné. Le texte sélectionné y est
  /// écrit avec [accent] : il doit rester lisible quelle que soit la couleur
  /// secondaire du club.
  static const Color selectedSurface = Color(0xFF3A202A);

  /// Contraste minimal (WCAG AA, texte normal) visé pour [accent].
  static const double minAccentContrast = 4.5;

  /// Éclaircit [color] jusqu'à atteindre [minAccentContrast] sur [surface].
  /// Un accent trop sombre serait illisible sur les fonds nuit.
  static Color _readableOn(Color color, Color surface) {
    var hsl = HSLColor.fromColor(color);
    while (contrastRatio(hsl.toColor(), surface) < minAccentContrast &&
        hsl.lightness < .97) {
      hsl = hsl.withLightness((hsl.lightness + .02).clamp(0, 1));
    }
    return hsl.toColor();
  }

  /// Rapport de contraste WCAG entre deux couleurs (de 1 à 21).
  static double contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + .05) / (lo + .05);
  }

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

  static const Color reward = Color(0xFFFFC24A);
  static const Color success = Color(0xFF34C98A);
  static const Color warning = Color(0xFFFFB020);
  static const Color admin = Color(0xFF9AA8B5);
  static const Color error = Color(0xFFFF5A6A);
  static const Color textPrimary = Color(0xFFF2F4F7);
  static const Color textSecondary = Color(0xFFC3CBD4);
  static const Color textFaint = Color(0xFF93A0AD);

  // Statuts de disponibilité : convoqué, liste d'attente, absent, sans réponse.
  // Ces quatre couleurs servent de titre de colonne, de bordure et de teinte de
  // fond directement sur les surfaces anthracite. Les variantes sombres
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
  static const double radiusMd = 18;
  static const double radiusLg = 22;

  static ShapeBorder cardShape({
    double radius = radiusMd,
    Color? borderColor,
    double borderWidth = 1,
  }) =>
      PfCardBorder(
        radius: radius,
        borderColor: borderColor ?? Colors.white.withValues(alpha: .12),
        borderWidth: borderWidth,
      );

  /// Relief des cartes : ombre profonde et fine lueur rouge.
  static List<BoxShadow> get cardShadows => [
        BoxShadow(
          color: Colors.black.withValues(alpha: .55),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: defaultPrimary.withValues(alpha: .06),
          blurRadius: 30,
          offset: const Offset(0, 2),
        ),
      ];

  static const TextStyle _display = TextStyle(
    fontFamily: displayFont,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    letterSpacing: .8,
  );

  static ThemeData get light {
    final scheme = ColorScheme.dark(
      primary: primary,
      onPrimary: onPrimaryButton,
      primaryContainer: surfaceHero,
      onPrimaryContainer: textPrimary,
      secondary: accent,
      onSecondary: background,
      secondaryContainer: selectedSurface,
      onSecondaryContainer: textPrimary,
      tertiary: reward,
      onTertiary: background,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHigh,
      error: error,
      onError: Colors.white,
      outline: outline,
      outlineVariant: const Color(0xFF2A3440),
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
          TargetPlatform.android: _PfPageTransitionsBuilder(),
          TargetPlatform.iOS: _PfPageTransitionsBuilder(),
          TargetPlatform.macOS: _PfPageTransitionsBuilder(),
          TargetPlatform.windows: _PfPageTransitionsBuilder(),
          TargetPlatform.linux: _PfPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _PfPageTransitionsBuilder(),
        },
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall
            ?.merge(_display)
            .copyWith(letterSpacing: -.6),
        headlineMedium: base.textTheme.headlineMedium
            ?.merge(_display)
            .copyWith(letterSpacing: -.4),
        headlineSmall: base.textTheme.headlineSmall
            ?.merge(_display)
            .copyWith(letterSpacing: -.2),
        titleLarge: base.textTheme.titleLarge
            ?.merge(_display)
            .copyWith(letterSpacing: -.2),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: textPrimary,
          height: 1.4,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: textSecondary,
          height: 1.4,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: textFaint,
          height: 1.35,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
          letterSpacing: .1,
        ),
        labelMedium: base.textTheme.labelMedium?.copyWith(
          color: textSecondary,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: base.textTheme.labelSmall?.copyWith(color: textFaint),
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
          fontFamily: displayFont,
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: -.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black,
        shape: cardShape(radius: radiusLg),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(64, 48)),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled) ? 0 : 4,
          ),
          shadowColor: WidgetStateProperty.all(
            defaultPrimary.withValues(alpha: .6),
          ),
          backgroundBuilder: (context, states, child) {
            if (states.contains(WidgetState.disabled)) return child!;
            final lit = primaryLit;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [lit, primary],
                ),
              ),
              child: child,
            );
          },
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return surfaceHigh;
            if (states.contains(WidgetState.pressed)) {
              return primary.withValues(alpha: .82);
            }
            return primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? textFaint
                : onPrimaryButton;
          }),
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: .10),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSm),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBright,
          backgroundColor: surface,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          side: BorderSide(color: primaryBright.withValues(alpha: .55)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBright,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      iconTheme: const IconThemeData(color: textSecondary, size: 22),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
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
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: outline.withValues(alpha: .45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: outline.withValues(alpha: .38)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: primaryBright, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: error, width: 1.6),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          // Les onglets principaux doivent rester lisibles sur téléphone,
          // y compris lorsque la fiche du match en affiche cinq côte à côte.
          minimumSize: WidgetStateProperty.all(const Size(48, 42)),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? selectedSurface
                : surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? primaryBright
                : textSecondary;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: outline.withValues(alpha: .28)),
          ),
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
        backgroundColor: surface,
        side: BorderSide(color: outline.withValues(alpha: .28)),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: .28),
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shadowColor: Colors.black,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: selected ? 25 : 22,
            color: selected ? primaryBright : textFaint,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            height: 1.1,
            color: selected ? primaryBright : textFaint,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: .28),
        selectedIconTheme: IconThemeData(color: primaryBright),
        unselectedIconTheme: const IconThemeData(color: textFaint),
        selectedLabelTextStyle: TextStyle(
          color: primaryBright,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelTextStyle: const TextStyle(color: textFaint),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: const TextStyle(color: textPrimary),
        actionTextColor: primaryBright,
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        circularTrackColor: surfaceHigh,
        linearTrackColor: surfaceHigh,
        linearMinHeight: 4,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      dividerTheme: DividerThemeData(
        color: outline.withValues(alpha: .24),
        space: 24,
        thickness: 1,
      ),
      dividerColor: outline.withValues(alpha: .24),
    );
  }
}
