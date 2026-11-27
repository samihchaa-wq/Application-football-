import 'club_time.dart';

/// Utilitaires de formatage de dates et heures uniformisés pour toute l'app.
///
/// Format date : DD/MM/YY (ex. 12/07/26)
/// Format heure : 21h00
///
/// Toujours à l'heure du club (voir [ClubTime]), jamais à celle du téléphone.
class AppFormats {
  AppFormats._();

  /// Retourne la date au format DD/MM/YY.
  static String date(DateTime dt) {
    final local = dt.toClub();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = (local.year % 100).toString().padLeft(2, '0');
    return '$day/$month/$year';
  }

  /// Retourne l'heure au format 21h00.
  static String time(DateTime dt) {
    final local = dt.toClub();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${hour}h$minute';
  }

  /// Retourne date + heure : "12/07/26 • 21h00".
  static String dateTime(DateTime dt) => '${date(dt)} • ${time(dt)}';

  static const _weekdaysShort = [
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim',
  ];

  static const _weekdaysLong = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  static const _monthsShort = [
    'Janv',
    'Févr',
    'Mars',
    'Avr',
    'Mai',
    'Juin',
    'Juil',
    'Août',
    'Sept',
    'Oct',
    'Nov',
    'Déc',
  ];

  /// Mois abrégés en minuscules, avec leur point : « nov. », « août ».
  static const _monthsAbbreviated = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  static const _monthsLong = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  /// Jour de la semaine abrégé : "Lun", "Mar"… (DateTime.weekday va de 1 à 7).
  static String weekdayShort(DateTime dt) =>
      _weekdaysShort[dt.toClub().weekday - 1];

  /// Jour de la semaine en toutes lettres : "Lundi", "Mardi"…
  static String weekdayLong(DateTime dt) =>
      _weekdaysLong[dt.toClub().weekday - 1];

  /// Mois abrégé : "Janv", "Sept"…
  static String monthShort(DateTime dt) => _monthsShort[dt.toClub().month - 1];

  /// Mois en toutes lettres : "Janvier", "Septembre"…
  static String monthLong(DateTime dt) => _monthsLong[dt.toClub().month - 1];

  /// Numéro du jour sur deux chiffres : "07".
  static String dayNumber(DateTime dt) =>
      dt.toClub().day.toString().padLeft(2, '0');

  /// Heure au format "20:45" (deux points, pour l'affichage calendrier).
  static String hourMinute(DateTime dt) {
    final local = dt.toClub();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Date de calendrier lisible sur une seule ligne :
  /// "Jeudi 21 Mai 2026 • 20:45".
  static String calendarDateTimeLong(
    DateTime dt, {
    bool includeTime = true,
  }) {
    final local = dt.toClub();
    // « Dim. 22 nov. 2026 » plutôt que « Dimanche 22 Novembre 2026 » : même
    // information, mais la ligne tient avec le type de match (« Championnat ·
    // J8 ») au lieu de passer sur deux lignes sur un téléphone.
    final fullDate =
        '${weekdayShort(local)}. ${local.day} ${_monthsAbbreviated[local.month - 1]} ${local.year}';
    // Téléphone sur un autre fuseau : « 20:45 (heure de Paris) ».
    return includeTime
        ? '$fullDate • ${hourMinute(local)}${ClubTime.suffix}'
        : fullDate;
  }

  /// Accorde un nom en français : le pluriel n'apparaît qu'à partir de 2.
  /// Ex. : `plural(0, 'but')` → "but", `plural(1, 'but')` → "but",
  /// `plural(2, 'but')` → "buts". Utiliser [plural] pour un suffixe
  /// irrégulier (`plural(2, 'clean sheet', 'clean sheets')`).
  static String plural(int count, String singular, [String? pluralForm]) {
    if (count > 1) return pluralForm ?? '${singular}s';
    return singular;
  }

  /// Comme [plural] mais préfixé de la valeur : "0 but", "1 but", "2 buts".
  static String counted(int count, String singular, [String? pluralForm]) =>
      '$count ${plural(count, singular, pluralForm)}';

  /// Ordinal féminin français : 1 → « 1ʳᵉ », 2 → « 2ᵉ », 40 → « 40ᵉ ».
  ///
  /// Seul le premier rang porte un suffixe différent ; un « 1ᵉ » codé en dur
  /// est une faute.
  static String ordinalFeminine(int value) => value == 1 ? '1ʳᵉ' : '$valueᵉ';

  /// Cote affichée sur une base 100 : 2,00 → 200 ; 3,80 → 380.
  static String odds(double? value) =>
      value == null ? '—' : (value * 100).round().toString();
}
