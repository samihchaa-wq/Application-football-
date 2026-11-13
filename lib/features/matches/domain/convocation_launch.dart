import 'package:as_grinta/core/club/club_rules.dart';

enum ConvocationLaunchMode { automatic, custom, now }

extension ConvocationLaunchModeApi on ConvocationLaunchMode {
  String get apiValue => switch (this) {
        ConvocationLaunchMode.automatic => 'automatic',
        ConvocationLaunchMode.custom => 'custom',
        ConvocationLaunchMode.now => 'now',
      };
}

/// Ouverture automatique réglée par le club (J-6 à 12 h par défaut).
///
/// This value is only used for display. Supabase remains authoritative and
/// resolves the final timestamp in Europe/Paris when the match is persisted.
DateTime defaultConvocationLaunchAt(DateTime kickoffAt) => DateTime(
      kickoffAt.year,
      kickoffAt.month,
      kickoffAt.day,
      ClubRules.featuresOpenHour,
    ).subtract(Duration(days: ClubRules.featuresOpenDays));

DateTime suggestedCustomConvocationLaunchAt({
  required DateTime kickoffAt,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final automatic = defaultConvocationLaunchAt(kickoffAt);
  if (automatic.isAfter(reference) && automatic.isBefore(kickoffAt)) {
    return automatic;
  }

  final oneHourFromNow = reference.add(const Duration(hours: 1));
  if (oneHourFromNow.isBefore(kickoffAt)) return oneHourFromNow;

  return kickoffAt.subtract(const Duration(minutes: 1));
}

String? validateConvocationLaunch({
  required ConvocationLaunchMode mode,
  required DateTime kickoffAt,
  required DateTime? customAt,
  DateTime? now,
}) {
  if (mode != ConvocationLaunchMode.custom) return null;
  if (customAt == null) return 'Choisis une date et une heure de lancement.';
  if (!customAt.isBefore(kickoffAt)) {
    return 'Le lancement doit avoir lieu avant le début du match.';
  }

  // A minute of tolerance avoids rejecting a selection that was valid when
  // the dialog closed but crossed the current minute during a slow request.
  final reference = now ?? DateTime.now();
  if (customAt.isBefore(reference.subtract(const Duration(minutes: 1)))) {
    return 'Cette heure est déjà passée. Choisis « Maintenant ».';
  }
  return null;
}
