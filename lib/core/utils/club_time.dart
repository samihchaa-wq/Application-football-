import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// L'heure du club, quel que soit le fuseau du téléphone.
///
/// La base garde les instants en UTC. Pour l'affichage et la saisie, un match
/// du lundi 20:45 à Paris doit rester « lundi 20:45 » sur un téléphone réglé
/// sur New York ou Tokyo. Tout passe donc par le fuseau du club
/// (`clubs.timezone`, « Europe/Paris » par défaut) au lieu de `toLocal()`.
///
/// Les dates renvoyées sont des [tz.TZDateTime] : leurs champs (jour, heure…)
/// sont ceux du club, et leur instant reste exact pour les comparaisons
/// (`isBefore`, `difference`) et l'envoi au serveur (`toUtc()`).
///
/// Base de fuseaux embarquée : version « 10 ans » (5 ans avant, 5 ans après),
/// la plus légère. Au-delà, le décalage peut être faux d'une heure en été.
class ClubTime {
  ClubTime._();

  static const String defaultTimezone = 'Europe/Paris';

  static bool _databaseLoaded = false;
  static tz.Location? _location;

  static void _ensureDatabase() {
    if (_databaseLoaded) return;
    tz_data.initializeTimeZones();
    _databaseLoaded = true;
  }

  /// Fuseau du club en cours (Paris tant que le club n'est pas chargé).
  static tz.Location get location {
    _ensureDatabase();
    return _location ??= tz.getLocation(defaultTimezone);
  }

  /// Nom IANA du fuseau du club, par exemple « Europe/Paris ».
  static String get timezoneName => location.name;

  /// Adopte le fuseau du club. Un nom vide ou inconnu retombe sur Paris.
  static void use(String? timezoneName) {
    _ensureDatabase();
    final name = timezoneName?.trim() ?? '';
    try {
      _location = tz.getLocation(name.isEmpty ? defaultTimezone : name);
    } catch (_) {
      _location = tz.getLocation(defaultTimezone);
    }
  }

  /// Revient au fuseau par défaut (déconnexion, tests).
  static void reset() => _location = null;

  /// Le même instant, exprimé à l'heure du club.
  static tz.TZDateTime of(DateTime instant) =>
      tz.TZDateTime.from(instant, location);

  /// Lit une date du serveur (texte ISO) et la passe à l'heure du club.
  static tz.TZDateTime? tryParse(Object? value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    return parsed == null ? null : of(parsed);
  }

  /// Maintenant, à l'heure du club.
  static tz.TZDateTime now() => tz.TZDateTime.now(location);

  /// Une heure saisie « au mur » du club (jour, heure, minute) devient un
  /// instant. Les champs de [wall] sont lus tels quels, sans tenir compte du
  /// fuseau du téléphone.
  static tz.TZDateTime fromWallClock(DateTime wall) => tz.TZDateTime(
        location,
        wall.year,
        wall.month,
        wall.day,
        wall.hour,
        wall.minute,
        wall.second,
        wall.millisecond,
      );

  /// Interprète une date venue de l'appli : un instant UTC est converti, une
  /// date déjà à l'heure du club ou une date simple (saisie) est lue « au
  /// mur ». Ne change pas une valeur déjà à l'heure du club.
  static tz.TZDateTime asClub(DateTime value) =>
      value.isUtc ? of(value) : fromWallClock(value);

  /// Raccourci de [fromWallClock] à partir des champs.
  static tz.TZDateTime wallClock(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
  ]) =>
      tz.TZDateTime(location, year, month, day, hour, minute);

  /// Jour du club (minuit, sans heure) qui contient [instant], sous forme de
  /// date simple : utile pour comparer des jours entre eux.
  static DateTime dayOf(DateTime instant) {
    final club = of(instant);
    return DateTime(club.year, club.month, club.day);
  }

  /// Fuseau du téléphone, remplaçable dans les tests.
  static Duration Function(DateTime instant) deviceOffset =
      (instant) => instant.toLocal().timeZoneOffset;

  /// Vrai quand le téléphone n'est pas à l'heure du club, maintenant ou dans
  /// six mois (les passages heure d'été / hiver diffèrent selon les pays).
  static bool get deviceDiffersFromClub {
    final instant = DateTime.now().toUtc();
    for (final probe in [instant, instant.add(const Duration(days: 182))]) {
      if (deviceOffset(probe) != of(probe).timeZoneOffset) return true;
    }
    return false;
  }

  /// « heure de Paris », d'après la ville du fuseau.
  static String get label {
    final city = timezoneName.split('/').last.replaceAll('_', ' ');
    return 'heure de $city';
  }

  /// « (heure de Paris) » à ajouter après une heure, seulement si le
  /// téléphone est sur un autre fuseau ; sinon une chaîne vide.
  static String get suffix => deviceDiffersFromClub ? ' ($label)' : '';
}

/// `dt.toClub()` remplace `dt.toLocal()` partout dans l'appli.
extension ClubTimeConversion on DateTime {
  tz.TZDateTime toClub() => ClubTime.of(this);
}
