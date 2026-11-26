/// Une dépense demandée par le club en plus de la licence (nom libre).
class LicenseExpense {
  const LicenseExpense({required this.id, required this.label});

  factory LicenseExpense.fromJson(Map<String, dynamic> json) => LicenseExpense(
        id: json['id'].toString(),
        label: (json['label'] ?? '').toString(),
      );

  final String id;
  final String label;
}

/// Paiements d'une saison : licences payées, et dépenses payées par joueur.
class SeasonLicenses {
  const SeasonLicenses({
    this.licensePaid = const {},
    this.expensePaid = const {},
  });

  /// Identifiants des fiches joueur dont la licence est payée.
  final Set<String> licensePaid;

  /// Pour chaque dépense : identifiants des fiches joueur qui l'ont payée.
  final Map<String, Set<String>> expensePaid;

  bool hasPaidLicense(String playerId) => licensePaid.contains(playerId);

  bool hasPaidExpense(String expenseId, String playerId) =>
      expensePaid[expenseId]?.contains(playerId) ?? false;
}
