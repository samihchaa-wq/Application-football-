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
    this.players,
    this.nextDueAt,
    this.visits30d,
    this.visitsPerDay,
    this.people7d,
    this.visitsToday,
    this.lastVisitOn,
    this.matches,
    this.paidCents,
    this.lastPaymentOn,
    this.referralsTotal,
    this.referralsPaid,
    this.referredBy,
    this.basePriceCents,
    this.discountPercent,
    this.amountDueCents,
    this.deletionAt,
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
      players: measuredCount(json['players']),
      nextDueAt: measuredDate(json['next_due_at']),
      visits30d: measuredCount(json['visits_30d']),
      visitsPerDay: measuredRate(json['visits_per_day']),
      people7d: measuredCount(json['people_7d']),
      visitsToday: measuredCount(json['visits_today']),
      lastVisitOn: measuredDate(json['last_visit_on']),
      matches: measuredCount(json['matches']),
      paidCents: measuredCount(json['paid_cents']),
      lastPaymentOn: measuredDate(json['last_payment_on']),
      referralsTotal: measuredCount(json['referrals_total']),
      referralsPaid: measuredCount(json['referrals_paid']),
      referredBy: json['referred_by'] as String?,
      basePriceCents: measuredCount(json['base_price_cents']),
      discountPercent: measuredCount(json['discount_percent']),
      amountDueCents: measuredCount(json['amount_due_cents']),
      deletionAt: measuredDate(json['deletion_at']),
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

  /// Joueurs de la saison ouverte.
  final int? players;

  /// Fin du mois gratuit ou de l'année payée ; null pour un abonnement arrêté.
  final DateTime? nextDueAt;

  /// Jours-personnes sur 30 jours : une visite par personne et par jour.
  final int? visits30d;

  /// Moyenne de personnes par jour sur 30 jours (ou depuis la création).
  final double? visitsPerDay;
  final int? people7d;
  final int? visitsToday;
  final DateTime? lastVisitOn;
  final int? matches;
  final int? paidCents;
  final DateTime? lastPaymentOn;
  final int? referralsTotal;
  final int? referralsPaid;
  final String? referredBy;
  final int? basePriceCents;
  final int? discountPercent;
  final int? amountDueCents;

  /// Date d'effacement d'un club suspendu pour impayé (3 ans après).
  final DateTime? deletionAt;

  bool get isTrial =>
      subscriptionStatus == 'trialing' || subscriptionStatus == 'trial';

  /// Jours avant la prochaine échéance (négatif si elle est passée).
  int? daysUntilDue(DateTime now) {
    final due = nextDueAt;
    if (due == null) return null;
    return (due.difference(now).inHours / 24).ceil();
  }

  String get statusLabel => switch (status) {
        'active' => 'Active',
        'suspended' => 'Suspendue',
        _ => 'État inconnu',
      };

  String get subscriptionLabel => switch (subscriptionStatus) {
        // Le serveur écrit « trialing » ; « trial » reste lu par prudence.
        'trialing' || 'trial' => 'Essai',
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

/// Chiffres globaux calculés par le serveur. Chaque valeur absente reste
/// null (« Non mesuré »), jamais zéro.
class PlatformTotals {
  const PlatformTotals({
    this.clubs,
    this.trialing,
    this.paying,
    this.suspended,
    this.new30d,
    this.trialsEnding7d,
    this.due30d,
    this.due30dCents,
    this.expected12mCents,
    this.members,
    this.players,
    this.visitsToday,
    this.people7d,
    this.collectedTotalCents,
    this.collectedYearCents,
    this.toDelete90d,
  });

  factory PlatformTotals.fromJson(Map<String, dynamic> json) => PlatformTotals(
        clubs: measuredCount(json['clubs']),
        trialing: measuredCount(json['trialing']),
        paying: measuredCount(json['paying']),
        suspended: measuredCount(json['suspended']),
        new30d: measuredCount(json['new_30d']),
        trialsEnding7d: measuredCount(json['trials_ending_7d']),
        due30d: measuredCount(json['due_30d']),
        due30dCents: measuredCount(json['due_30d_cents']),
        expected12mCents: measuredCount(json['expected_12m_cents']),
        members: measuredCount(json['members']),
        players: measuredCount(json['players']),
        visitsToday: measuredCount(json['visits_today']),
        people7d: measuredCount(json['people_7d']),
        collectedTotalCents: measuredCount(json['collected_total_cents']),
        collectedYearCents: measuredCount(json['collected_year_cents']),
        toDelete90d: measuredCount(json['to_delete_90d']),
      );

  final int? clubs;
  final int? trialing;
  final int? paying;
  final int? suspended;
  final int? new30d;
  final int? trialsEnding7d;
  final int? due30d;
  final int? due30dCents;
  final int? expected12mCents;
  final int? members;
  final int? players;
  final int? visitsToday;
  final int? people7d;
  final int? collectedTotalCents;
  final int? collectedYearCents;
  final int? toDelete90d;
}

class PlatformDailyVisits {
  const PlatformDailyVisits(this.day, this.visits);

  final DateTime day;
  final int visits;
}

class PlatformSnapshot {
  PlatformSnapshot({
    required List<PlatformTeam> teams,
    required this.fetchedAt,
    this.health,
    this.totals = const PlatformTotals(),
    List<PlatformDailyVisits> dailyVisits = const [],
  })  : teams = List.unmodifiable(teams),
        dailyVisits = List.unmodifiable(dailyVisits);

  final List<PlatformTeam> teams;
  final DateTime fetchedAt;
  final PlatformHealth? health;
  final PlatformTotals totals;
  final List<PlatformDailyVisits> dailyVisits;

  /// Clubs dont l'échéance tombe dans [window] (essais et années payées),
  /// hors clubs suspendus, du plus proche au plus lointain.
  List<PlatformTeam> dueWithin(DateTime now, Duration window) => teams
      .where(
        (team) =>
            team.status == 'active' &&
            team.nextDueAt != null &&
            team.nextDueAt!.isBefore(now.add(window)),
      )
      .toList()
    ..sort((a, b) => a.nextDueAt!.compareTo(b.nextDueAt!));

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

double? measuredRate(Object? value) =>
    value is num && value.isFinite && value >= 0 ? value.toDouble() : null;

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
