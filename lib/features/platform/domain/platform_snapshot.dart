/// Models for the operator console. Missing measurements remain null.
/// The historical server identifier `club` represents one team.
class PlatformTeam {
  const PlatformTeam({
    required this.id,
    required this.name,
    required this.status,
    this.members,
    this.subscriptionStatus,
    this.createdAt,
    this.trialEndsAt,
    this.currentPeriodEnd,
    this.lastModifiedAt,
  });

  factory PlatformTeam.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty || name is! String) {
      throw const FormatException('Invalid team response');
    }
    return PlatformTeam(
      id: id,
      name: name,
      status: json['status'] as String? ?? 'unknown',
      members: measuredCount(json['members']),
      subscriptionStatus: json['subscription_status'] as String?,
      createdAt: measuredDate(json['created_at']),
      trialEndsAt: measuredDate(json['trial_ends_at']),
      currentPeriodEnd: measuredDate(json['current_period_end']),
      // The RPC measures profile/match updates, not user connections.
      lastModifiedAt: measuredDate(json['last_activity_at']),
    );
  }

  final String id;
  final String name;
  final String status;
  final int? members;
  final String? subscriptionStatus;
  final DateTime? createdAt;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodEnd;
  final DateTime? lastModifiedAt;

  String get statusLabel => switch (status) {
        'active' => 'Active',
        'suspended' => 'Suspendue',
        _ => 'État inconnu',
      };

  String get subscriptionLabel => switch (subscriptionStatus) {
        'trial' => 'Essai',
        'active' => 'Abonnement actif',
        'past_due' => 'Paiement à régulariser',
        'canceled' => 'Abonnement arrêté',
        _ => 'Abonnement non renseigné',
      };
}

class PlatformHealth {
  const PlatformHealth({
    required this.checkedAt,
    this.failedJobs,
    this.failedPush,
    this.sentPush,
    this.databaseBytes,
  });

  factory PlatformHealth.fromJson(Map<String, dynamic> json) {
    final checkedAt = measuredDate(json['checked_at']);
    if (checkedAt == null) {
      throw const FormatException('Health response has no observation date');
    }
    return PlatformHealth(
      checkedAt: checkedAt,
      failedJobs: measuredCount(json['failed_jobs_last_hour']),
      failedPush: measuredCount(json['push_failed_last_hour']),
      sentPush: measuredCount(json['push_sent_last_hour']),
      databaseBytes: measuredCount(json['database_bytes']),
    );
  }

  final DateTime checkedAt;
  final int? failedJobs;
  final int? failedPush;
  final int? sentPush;
  final int? databaseBytes;
}

class PlatformSnapshot {
  PlatformSnapshot({
    required List<PlatformTeam> teams,
    required this.fetchedAt,
    this.health,
  }) : teams = List.unmodifiable(teams);

  final List<PlatformTeam> teams;
  final DateTime fetchedAt;
  final PlatformHealth? health;

  int get activeTeams => teams.where((team) => team.status == 'active').length;

  int? get activeMemberCount {
    if (teams.any((team) => team.members == null)) return null;
    return teams.fold<int>(0, (sum, team) => sum + team.members!);
  }

  List<PlatformTeam> renewalsBefore(DateTime now, Duration window) => teams
      .where(
        (team) =>
            team.subscriptionStatus == 'active' &&
            team.currentPeriodEnd != null &&
            !team.currentPeriodEnd!.isBefore(now) &&
            !team.currentPeriodEnd!.isAfter(now.add(window)),
      )
      .toList()
    ..sort((a, b) => a.currentPeriodEnd!.compareTo(b.currentPeriodEnd!));
}

int? measuredCount(Object? value) => value is int && value >= 0 ? value : null;

DateTime? measuredDate(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

List<PlatformTeam> filterPlatformTeams(
  List<PlatformTeam> teams, {
  String query = '',
  String? status,
}) {
  final normalized = query.trim().toLowerCase();
  return teams
      .where(
        (team) =>
            (status == null || team.status == status) &&
            (normalized.isEmpty ||
                team.name.toLowerCase().contains(normalized)),
      )
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}
