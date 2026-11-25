/// Réglages des licences du club (une ligne par club).
class LicenseSettings {
  const LicenseSettings({
    this.clubNumber = '',
    this.presidentName = '',
    this.leagueName = '',
    this.licenseAmountCents,
    this.otherLabel = '',
    this.otherAmountCents,
  });

  factory LicenseSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LicenseSettings();
    return LicenseSettings(
      clubNumber: (json['club_number'] ?? '').toString(),
      presidentName: (json['president_name'] ?? '').toString(),
      leagueName: (json['league_name'] ?? '').toString(),
      licenseAmountCents: json['license_amount_cents'] as int?,
      otherLabel: (json['other_expense_label'] ?? '').toString(),
      otherAmountCents: json['other_expense_amount_cents'] as int?,
    );
  }

  final String clubNumber;
  final String presidentName;
  final String leagueName;
  final int? licenseAmountCents;
  final String otherLabel;
  final int? otherAmountCents;

  /// Intitulé de l'autre dépense, ou un mot neutre si le club n'en a pas donné.
  String get otherTitle =>
      otherLabel.trim().isEmpty ? 'Autre dépense' : otherLabel.trim();

  Map<String, dynamic> toJson() => {
        'club_number': _nullIfBlank(clubNumber),
        'president_name': _nullIfBlank(presidentName),
        'league_name': _nullIfBlank(leagueName),
        'license_amount_cents': licenseAmountCents,
        'other_expense_label': _nullIfBlank(otherLabel),
        'other_expense_amount_cents': otherAmountCents,
      };
}

/// Statut de licence d'un joueur pour une saison.
class PlayerLicense {
  const PlayerLicense({
    required this.seasonPlayerId,
    this.licenseNumber = '',
    this.licensePaid = false,
    this.otherPaid = false,
  });

  factory PlayerLicense.fromJson(Map<String, dynamic> json) => PlayerLicense(
        seasonPlayerId: json['season_player_id'].toString(),
        licenseNumber: (json['license_number'] ?? '').toString(),
        licensePaid: json['license_paid'] == true,
        otherPaid: json['other_paid'] == true,
      );

  final String seasonPlayerId;
  final String licenseNumber;
  final bool licensePaid;
  final bool otherPaid;

  PlayerLicense copyWith({
    String? licenseNumber,
    bool? licensePaid,
    bool? otherPaid,
  }) =>
      PlayerLicense(
        seasonPlayerId: seasonPlayerId,
        licenseNumber: licenseNumber ?? this.licenseNumber,
        licensePaid: licensePaid ?? this.licensePaid,
        otherPaid: otherPaid ?? this.otherPaid,
      );

  Map<String, dynamic> toJson() => {
        'season_player_id': seasonPlayerId,
        'license_number': _nullIfBlank(licenseNumber),
        'license_paid': licensePaid,
        'other_paid': otherPaid,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
}

String? _nullIfBlank(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// « 120 € » ou « 12,50 € » ; vide si le montant n'est pas renseigné.
String formatLicenseAmount(int? cents) {
  if (cents == null) return '';
  final euros = cents ~/ 100;
  final rest = cents % 100;
  return rest == 0 ? '$euros €' : '$euros,${rest.toString().padLeft(2, '0')} €';
}

/// Lit « 120 », « 12,5 » ou « 12.50 » en centimes ; null si illisible ou vide.
int? parseLicenseAmount(String text) {
  final cleaned =
      text.replaceAll('€', '').replaceAll(' ', '').replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value < 0 || value > 1000) return null;
  return (value * 100).round();
}

/// Données de l'attestation, prêtes à imprimer.
class LicenseAttestation {
  const LicenseAttestation({
    required this.clubName,
    required this.clubNumber,
    required this.clubAddress,
    required this.clubEmail,
    required this.presidentName,
    required this.leagueName,
    required this.playerName,
    required this.licenseNumber,
    required this.seasonName,
    required this.amountCents,
    required this.city,
    required this.date,
  });

  final String clubName;
  final String clubNumber;
  final String clubAddress;
  final String clubEmail;
  final String presidentName;
  final String leagueName;
  final String playerName;
  final String licenseNumber;
  final String seasonName;
  final int? amountCents;
  final String city;
  final DateTime date;

  String get fileName {
    final slug = playerName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'attestation-licence-${slug.isEmpty ? 'joueur' : slug}.pdf';
  }
}

const _months = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// « 8 novembre 2025 ».
String formatLongFrenchDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';
