import 'dart:async';
import 'dart:math' as math;

import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/auth/presentation/sign_out_confirmation.dart';
import 'package:petit_filet/features/club/data/club_subscription.dart';
import 'package:petit_filet/features/platform/data/platform_billing_repository.dart';
import 'package:petit_filet/features/platform/data/platform_repository.dart';
import 'package:petit_filet/features/platform/domain/platform_snapshot.dart';
import 'package:petit_filet/features/platform/presentation/platform_alerts_panel.dart';
import 'package:petit_filet/features/platform/presentation/platform_billing_panel.dart';
import 'package:petit_filet/features/platform/presentation/platform_cash_section.dart';
import 'package:petit_filet/features/platform/presentation/platform_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _sections = ['À faire', 'Clubs', 'Caisse', 'Réglages'];
const _shortSections = ['À faire', 'Clubs', 'Caisse', 'Réglages'];
const _icons = [
  Icons.checklist_rtl_outlined,
  Icons.groups_outlined,
  Icons.point_of_sale_outlined,
  Icons.settings_outlined,
];
const _clubsSection = 1;
const _cashSection = 2;
const _settingsSection = 3;

/// Separate from the team shell: never changes team, role or JWT metadata.
class PlatformControlPage extends ConsumerStatefulWidget {
  const PlatformControlPage({super.key});

  @override
  ConsumerState<PlatformControlPage> createState() =>
      _PlatformControlPageState();
}

class _PlatformControlPageState extends ConsumerState<PlatformControlPage>
    with WidgetsBindingObserver {
  int _section = 0;
  String? _selectedTeamId;
  PlatformClubFilter _filter = PlatformClubFilter.all;
  PlatformClubSort _sort = PlatformClubSort.nextDue;
  final _search = TextEditingController();
  bool _obscured = false;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRefresh();
  }

  void _startRefresh() {
    _refresh?.cancel();
    _refresh = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && !_obscured) ref.invalidate(platformSnapshotProvider);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Do not keep showing a privileged snapshot after background/resume.
    final obscured = state != AppLifecycleState.resumed;
    if (!mounted) return;
    _refresh?.cancel();
    ref.invalidate(platformSnapshotProvider);
    setState(() => _obscured = obscured);
    if (!obscured) _startRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refresh?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _navigate(int index) => setState(() {
        _section = index;
        _selectedTeamId = null;
      });

  void _openClubs(PlatformClubFilter filter, {PlatformClubSort? sort}) =>
      setState(() {
        _section = _clubsSection;
        _selectedTeamId = null;
        _filter = filter;
        if (sort != null) _sort = sort;
      });

  void _openTeam(String id) => setState(() => _selectedTeamId = id);

  /// Fiche d'un club depuis la Caisse ou « À faire ».
  void _openClub(String id) => setState(() {
        _section = _clubsSection;
        _selectedTeamId = id;
      });

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTheme.defaultPrimary,
      brightness: Brightness.dark,
    );
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: scheme),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1000;
          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 80,
              automaticallyImplyLeading: false,
              title: Tooltip(
                message: 'Revenir au tableau de bord',
                child: InkWell(
                  key: const Key('platform-home-button'),
                  onTap: () => _navigate(0),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PETIT FILET',
                        style: TextStyle(fontSize: 13, letterSpacing: 2),
                      ),
                      Text('Poste de contrôle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Actualiser les données',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.invalidate(platformSnapshotProvider);
                    ref.invalidate(platformAlertsProvider);
                    ref.invalidate(platformLedgerProvider);
                  },
                ),
                IconButton(
                  tooltip: 'Se déconnecter',
                  icon: const Icon(Icons.logout_outlined),
                  onPressed: () => confirmAndSignOut(context, ref),
                ),
              ],
            ),
            bottomNavigationBar: wide
                ? null
                : NavigationBar(
                    selectedIndex: _section,
                    onDestinationSelected: _navigate,
                    destinations: List.generate(
                      _sections.length,
                      (i) => NavigationDestination(
                        icon: Icon(_icons[i]),
                        label: _shortSections[i],
                      ),
                    ),
                  ),
            body: Row(
              children: [
                if (wide)
                  NavigationRail(
                    extended: true,
                    selectedIndex: _section,
                    onDestinationSelected: _navigate,
                    destinations: List.generate(
                      _sections.length,
                      (i) => NavigationRailDestination(
                        icon: Icon(_icons[i]),
                        label: Text(_sections[i]),
                      ),
                    ),
                  ),
                Expanded(
                  child: _obscured || !auth.hasSession || auth.isLoading
                      ? const Center(child: Text('Vérification de l’accès…'))
                      : ref.watch(platformSnapshotProvider).when(
                            skipLoadingOnRefresh: false,
                            skipLoadingOnReload: false,
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, _) => _failure(error),
                            data: (snapshot) => _content(snapshot),
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _failure(Object error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                error is PlatformAccessDenied
                    ? Icons.lock_outlined
                    : Icons.cloud_off_outlined,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                error is PlatformAccessDenied
                    ? 'Accès gestionnaire requis'
                    : 'Données indisponibles',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                error is PlatformAccessDenied
                    ? 'Ce compte n’est pas autorisé à consulter le poste de contrôle.'
                    : 'La connexion n’a pas permis de vérifier les données. Réessaie dans un instant.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(platformSnapshotProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );

  Widget _content(PlatformSnapshot snapshot) {
    final selected =
        snapshot.teams.where((team) => team.id == _selectedTeamId).firstOrNull;
    return SingleChildScrollView(
      key: const Key('platform-content'),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    selected == null ? _sections[_section] : selected.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  // La liste des clubs ne fait que lire ; on agit depuis la
                  // fiche d'un club, la Caisse et les Réglages.
                  if (selected == null && _section == _clubsSection)
                    const Chip(
                      avatar: Icon(Icons.visibility_outlined, size: 16),
                      label: Text('Lecture seule'),
                    ),
                ],
              ),
              Text(
                'Données chargées le ${_date(snapshot.fetchedAt)} · heure de cet appareil',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              if (selected != null)
                _teamDetail(selected, snapshot.fetchedAt)
              else
                switch (_section) {
                  0 => _dashboard(snapshot),
                  _clubsSection => _clubs(snapshot),
                  _cashSection => PlatformCashSection(onOpenClub: _openClub),
                  _ => PlatformSettingsSection(
                      supervision: _health(snapshot),
                    ),
                },
              const SizedBox(height: 24),
              const Text(
                'Les données sont revérifiées chaque minute et au retour sur cet écran. '
                'Une mesure manquante n’est jamais remplacée par zéro.',
                style: TextStyle(color: AppTheme.textFaint, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Tableau de bord
  // -------------------------------------------------------------------------

  Widget _dashboard(PlatformSnapshot snapshot) {
    final totals = snapshot.totals;
    final now = snapshot.fetchedAt;
    final due = snapshot.dueWithin(now, const Duration(days: 30));
    final health = snapshot.health;
    final quiet = snapshot.teams
        .where(
          (team) =>
              team.status == 'active' &&
              team.createdAt != null &&
              now.difference(team.createdAt!).inDays >= 7 &&
              (team.lastVisitOn == null ||
                  now.difference(team.lastVisitOn!).inDays >= 14),
        )
        .toList();
    final toDelete = snapshot.teams
        .where(
          (team) =>
              team.deletionAt != null &&
              team.deletionAt!.isBefore(now.add(const Duration(days: 90))),
        )
        .toList();
    final mostActive = [...snapshot.teams]
      ..removeWhere((team) => (team.visitsPerDay ?? 0) <= 0)
      ..sort((a, b) => b.visitsPerDay!.compareTo(a.visitsPerDay!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformAlertsPanel(
          onOpenCash: () => _navigate(_cashSection),
          onOpenSettings: () => _navigate(_settingsSection),
          onOpenClub: _openClub,
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Argent'),
        _metrics([
          (
            'Encaissé cette année',
            _euros(totals.collectedYearCents),
            'Paiements reçus depuis le 1er janvier (avant remboursements)',
          ),
          (
            'À encaisser sous 30 jours',
            _euros(totals.due30dCents),
            totals.due30d == null
                ? 'Non mesuré'
                : '${totals.due30d} club(s) arrivent à échéance',
          ),
          (
            'Prévu sur 12 mois',
            _euros(totals.expected12mCents),
            'Si chaque club actif paie à son échéance',
          ),
          (
            'Total encaissé',
            _euros(totals.collectedTotalCents),
            'Depuis le premier paiement',
          ),
        ]),
        const SizedBox(height: 24),
        const _SectionTitle('Clubs'),
        _metrics([
          (
            'Clubs',
            _count(totals.clubs),
            '${_count(totals.trialing)} en mois gratuit · ${_count(totals.paying)} abonnés · ${_count(totals.suspended)} suspendus',
          ),
          (
            'Nouveaux clubs',
            _count(totals.new30d),
            'Inscrits ces 30 derniers jours',
          ),
          (
            'Effectif total',
            _count(totals.players),
            '${_count(totals.members)} comptes actifs',
          ),
          (
            'Visiteurs aujourd’hui',
            _count(totals.visitsToday),
            '${_count(totals.people7d)} personnes venues ces 7 jours',
          ),
        ]),
        const SizedBox(height: 24),
        _panel('Visites des 30 derniers jours', [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: _VisitsChart(snapshot.dailyVisits),
          ),
        ]),
        const SizedBox(height: 24),
        _panel('À traiter', [
          if ((totals.trialsEnding7d ?? 0) > 0)
            _actionTile(
              key: 'platform-todo-trials',
              icon: Icons.hourglass_bottom_outlined,
              color: AppTheme.warning,
              title:
                  '${totals.trialsEnding7d} mois gratuit(s) finissent cette semaine',
              subtitle:
                  'Les administrateurs ont reçu l’e-mail de rappel 10 jours avant.',
              onTap: () => _openClubs(
                PlatformClubFilter.trial,
                sort: PlatformClubSort.nextDue,
              ),
            ),
          if (due.isNotEmpty) ...[
            ListTile(
              title: const Text('Échéances des 30 prochains jours'),
              subtitle: Text(
                '${due.length} club(s) · ${_euros(totals.due30dCents)} attendus',
              ),
            ),
            ...due.take(5).map((team) => _dueTile(team, now)),
            if (due.length > 5)
              TextButton(
                onPressed: () => _openClubs(PlatformClubFilter.dueSoon),
                child: Text('Voir les ${due.length} clubs concernés'),
              ),
          ] else
            const ListTile(
              leading: Icon(Icons.event_available_outlined),
              title: Text('Aucune échéance dans les 30 prochains jours'),
            ),
          if ((totals.suspended ?? 0) > 0)
            _actionTile(
              key: 'platform-todo-suspended',
              icon: Icons.pause_circle_outlined,
              color: AppTheme.error,
              title: '${totals.suspended} club(s) suspendu(s)',
              subtitle:
                  'Leurs données sont gardées 3 ans : un paiement noté rouvre l’accès.',
              onTap: () => _openClubs(PlatformClubFilter.suspended),
            ),
          if (toDelete.isNotEmpty)
            _actionTile(
              key: 'platform-todo-delete',
              icon: Icons.delete_outlined,
              color: AppTheme.error,
              title:
                  '${toDelete.length} club(s) effacé(s) dans moins de 90 jours',
              subtitle:
                  'Impayés depuis presque 3 ans. Un paiement noté annule l’effacement.',
              onTap: () => _openClubs(PlatformClubFilter.suspended),
            ),
          if (quiet.isNotEmpty)
            _actionTile(
              key: 'platform-todo-quiet',
              icon: Icons.bedtime_outlined,
              color: AppTheme.warning,
              title: '${quiet.length} club(s) sans visite depuis 14 jours',
              subtitle: quiet.take(3).map((team) => team.name).join(' · '),
              onTap: () => _openClubs(
                PlatformClubFilter.all,
                sort: PlatformClubSort.visits,
              ),
            ),
          if (health == null)
            const ListTile(
              leading: Icon(Icons.cloud_off_outlined),
              title: Text('La supervision est indisponible'),
              subtitle: Text(
                'Impossible de conclure sur l’état de l’application.',
              ),
            ),
          if ((health?.failedJobs ?? 0) > 0)
            _actionTile(
              icon: Icons.warning_amber_outlined,
              color: AppTheme.warning,
              title: '${health!.failedJobs} exécution(s) de tâche en échec',
              subtitle: 'Dernière heure · ouvrir la supervision',
              onTap: () => _navigate(_settingsSection),
            ),
          if ((health?.failedPush ?? 0) > 0)
            _actionTile(
              icon: Icons.notifications_off_outlined,
              color: AppTheme.warning,
              title:
                  '${health!.failedPush} tentative(s) de notification en échec',
              subtitle:
                  'Dernière heure · un échec ne prouve pas une panne générale',
              onTap: () => _navigate(_settingsSection),
            ),
          if (health?.failedJobs == 0 && health?.failedPush == 0)
            const ListTile(
              leading: Icon(
                Icons.check_circle_outlined,
                color: AppTheme.success,
              ),
              title: Text('Aucun échec technique sur la dernière heure'),
              subtitle: Text('Tâches planifiées et notifications.'),
            ),
        ]),
        if (mostActive.isNotEmpty) ...[
          const SizedBox(height: 24),
          _panel('Les clubs les plus actifs', [
            for (final team in mostActive.take(5))
              ListTile(
                key: ValueKey('platform-active-${team.id}'),
                leading: const Icon(Icons.trending_up),
                title: Text(team.name),
                subtitle: Text(
                  '${_rate(team.visitsPerDay)} visites par jour · ${_count(team.people7d)} personnes cette semaine',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openTeam(team.id),
              ),
          ]),
        ],
      ],
    );
  }

  Widget _actionTile({
    String? key,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      ListTile(
        key: key == null ? null : Key(key),
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );

  Widget _dueTile(PlatformTeam team, DateTime now) => ListTile(
        key: ValueKey('platform-due-${team.id}'),
        leading: Icon(
          team.isTrial
              ? Icons.card_giftcard_outlined
              : Icons.autorenew_outlined,
          color: _dueColor(team.daysUntilDue(now)),
        ),
        title: Text(team.name),
        subtitle: Text(
          '${team.isTrial ? 'Fin du mois gratuit' : 'Renouvellement'} le ${_day(team.nextDueAt)} '
          '(${formatDueIn(team.daysUntilDue(now))})',
        ),
        trailing: Text(_euros(team.amountDueCents)),
        onTap: () => _openTeam(team.id),
      );

  // -------------------------------------------------------------------------
  // Clubs
  // -------------------------------------------------------------------------

  Widget _clubs(PlatformSnapshot snapshot) {
    final now = snapshot.fetchedAt;
    final clubs = selectPlatformClubs(
      snapshot.teams,
      now: now,
      query: _search.text,
      filter: _filter,
      sort: _sort,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: TextField(
                key: const Key('platform-club-search'),
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Rechercher un club',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: DropdownButton<PlatformClubSort>(
                key: const Key('platform-club-sort'),
                isExpanded: true,
                value: _sort,
                onChanged: (value) {
                  if (value != null) setState(() => _sort = value);
                },
                items: [
                  for (final sort in PlatformClubSort.values)
                    DropdownMenuItem(
                      value: sort,
                      child: Text(
                        'Trier : ${sort.label}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in PlatformClubFilter.values)
              ChoiceChip(
                key: Key('platform-filter-${filter.name}'),
                label: Text(filter.label),
                selected: _filter == filter,
                onSelected: (_) => setState(() => _filter = filter),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('${clubs.length} club(s) sur ${snapshot.teams.length}'),
        const SizedBox(height: 8),
        if (snapshot.teams.isEmpty)
          const _Empty('Aucun club inscrit pour le moment.')
        else if (clubs.isEmpty)
          const _Empty('Aucun club ne correspond à cette recherche.')
        else
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final table = constraints.maxWidth >= 860;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (table) const _ClubHeader(),
                    for (final team in clubs) ...[
                      table ? _clubRow(team, now) : _clubTile(team, now),
                      const Divider(height: 1),
                    ],
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _clubRow(PlatformTeam team, DateTime now) {
    final days = team.daysUntilDue(now);
    return InkWell(
      key: ValueKey('platform-team-${team.id}'),
      onTap: () => _openTeam(team.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: _columns[0].$2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  _StateLabel(team),
                ],
              ),
            ),
            _cell(1, '${_count(team.players)} joueurs',
                '${_count(team.members)} comptes'),
            _cell(2, _rate(team.visitsPerDay), 'par jour'),
            _cell(
                3, formatSeniority(team.createdAt, now), _day(team.createdAt)),
            Expanded(
              flex: _columns[4].$2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_day(team.nextDueAt)),
                  Text(
                    team.nextDueAt == null
                        ? '—'
                        : '${team.isTrial ? 'fin d’essai' : 'renouvellement'} ${formatDueIn(days)}',
                    style: TextStyle(fontSize: 12, color: _dueColor(days)),
                  ),
                ],
              ),
            ),
            _cell(
                5,
                _referrals(team),
                team.referredBy == null
                    ? ''
                    : 'parrainé par ${team.referredBy}'),
            Expanded(
              flex: _columns[6].$2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_euros(team.amountDueCents)),
                  if ((team.discountPercent ?? 0) > 0)
                    Text(
                      '−${team.discountPercent} %',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.success,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(int column, String value, String detail) => Expanded(
        flex: _columns[column].$2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (detail.isNotEmpty)
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppTheme.textFaint),
              ),
          ],
        ),
      );

  Widget _clubTile(PlatformTeam team, DateTime now) {
    final days = team.daysUntilDue(now);
    return ListTile(
      key: ValueKey('platform-team-${team.id}'),
      onTap: () => _openTeam(team.id),
      title: Text(team.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StateLabel(team),
          Text(
            '${_count(team.players)} joueurs · ${_rate(team.visitsPerDay)} visites/jour · '
            'depuis ${formatSeniority(team.createdAt, now)}',
          ),
          Text(
            team.nextDueAt == null
                ? 'Pas d’échéance'
                : 'Échéance le ${_day(team.nextDueAt)} (${formatDueIn(days)}) · ${_euros(team.amountDueCents)}',
            style: TextStyle(color: _dueColor(days)),
          ),
          Text('Filleuls : ${_referrals(team)}'),
        ],
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
    );
  }

  // -------------------------------------------------------------------------
  // Fiche club
  // -------------------------------------------------------------------------

  Widget _teamDetail(PlatformTeam team, DateTime now) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _selectedTeamId = null),
              child: const Text('Retour à la liste'),
            ),
          ),
          _metrics([
            (
              'Prochaine échéance',
              _day(team.nextDueAt),
              team.nextDueAt == null
                  ? 'Aucune'
                  : '${team.isTrial ? 'Fin du mois gratuit' : 'Fin de l’année payée'} · ${formatDueIn(team.daysUntilDue(now))}',
            ),
            (
              'À payer à l’échéance',
              _euros(team.amountDueCents),
              (team.discountPercent ?? 0) > 0
                  ? 'Tarif ${_euros(team.basePriceCents)}, parrainage −${team.discountPercent} %'
                  : 'Tarif plein',
            ),
            (
              'Visites par jour',
              _rate(team.visitsPerDay),
              '${_count(team.visits30d)} visites sur 30 jours',
            ),
            (
              'Effectif',
              _count(team.players),
              'joueurs · ${_count(team.members)} comptes actifs',
            ),
          ]),
          const SizedBox(height: 16),
          _panel('Fiche club', [
            _detail('Accès', team.statusLabel),
            _detail('Abonnement', team.subscriptionLabel),
            _detail(
              'Sur l’appli depuis',
              '${formatSeniority(team.createdAt, now)} (${_day(team.createdAt)})',
            ),
            _detail('Fin du mois gratuit', _day(team.trialEndsAt)),
            _detail('Fin de l’année payée', _day(team.currentPeriodEnd)),
            _detail('Total payé', _euros(team.paidCents)),
            _detail('Dernier paiement', _day(team.lastPaymentOn)),
            _detail('Personnes venues cette semaine', _count(team.people7d)),
            _detail('Dernière visite', _day(team.lastVisitOn)),
            _detail('Matchs créés', _count(team.matches)),
            _detail('Parrainé par', team.referredBy ?? 'Personne'),
            _detail('Clubs parrainés', _referrals(team)),
            if (team.deletionAt != null)
              _detail('Effacement prévu si impayé', _day(team.deletionAt)),
          ]),
          const SizedBox(height: 16),
          PlatformBillingPanel(team: team),
        ],
      );

  // -------------------------------------------------------------------------
  // Supervision
  // -------------------------------------------------------------------------

  Widget _health(PlatformSnapshot snapshot) {
    final health = snapshot.health;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Supervision technique'),
        Text(
          health == null
              ? 'Supervision indisponible'
              : 'Observation serveur du ${_date(health.checkedAt)}',
        ),
        const SizedBox(height: 16),
        _metrics([
          (
            'Tâches en échec',
            _count(health?.failedJobs),
            'Exécutions enregistrées sur la dernière heure',
          ),
          (
            'Notifications en échec',
            _count(health?.failedPush),
            'Tentatives enregistrées sur la dernière heure',
          ),
          (
            'Notifications envoyées',
            _count(health?.sentPush),
            'Envois déclarés réussis, sans preuve de lecture',
          ),
          (
            'Base de données',
            health?.databaseBytes == null
                ? 'Non mesuré'
                : _bytes(health!.databaseBytes!),
            'Taille totale observée de la base',
          ),
        ]),
        const SizedBox(height: 20),
        _panel('Tâches automatiques', const [
          ListTile(
            leading: Icon(Icons.mail_outlined),
            title: Text('Rappel d’échéance, chaque matin'),
            subtitle: Text(
              'E-mail aux administrateurs 10 jours avant la fin du mois gratuit ou de l’année payée.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.pause_circle_outlined),
            title: Text('Suspension le jour de l’échéance'),
            subtitle: Text(
              'Sans paiement noté. Un paiement rouvre l’accès, données intactes.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.delete_outlined),
            title: Text('Effacement après 3 ans d’impayé, chaque nuit'),
            subtitle: Text(
              'Club, données et comptes. Jamais un club suspendu à la main.',
            ),
          ),
        ]),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Éléments communs
  // -------------------------------------------------------------------------

  Widget _metrics(List<(String, String, String)> values) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 850
              ? 4
              : constraints.maxWidth >= 500
                  ? 2
                  : 1;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: values
                .map(
                  (value) => SizedBox(
                    width:
                        (constraints.maxWidth - 12 * (columns - 1)) / columns,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value.$1,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              value.$2,
                              style: TextStyle(
                                fontSize: value.$2 == 'Non mesuré' ? 22 : 30,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              value.$3,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      );

  Widget _panel(String title, List<Widget> children) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w400),
                ),
              ),
              ...children,
            ],
          ),
        ),
      );

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 20,
          runSpacing: 4,
          children: [
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w400)),
          ],
        ),
      );
}

const _columns = [
  ('Club', 5),
  ('Effectif', 3),
  ('Visites', 2),
  ('Ancienneté', 3),
  ('Prochaine échéance', 4),
  ('Filleuls', 3),
  ('À payer', 2),
];

class _ClubHeader extends StatelessWidget {
  const _ClubHeader();

  @override
  Widget build(BuildContext context) => Container(
        color: AppTheme.surfaceHigh,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            for (var i = 0; i < _columns.length; i++)
              Expanded(
                flex: _columns[i].$2,
                child: Text(
                  _columns[i].$1,
                  textAlign: i == _columns.length - 1
                      ? TextAlign.end
                      : TextAlign.start,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      );
}

class _StateLabel extends StatelessWidget {
  const _StateLabel(this.team);

  final PlatformTeam team;

  @override
  Widget build(BuildContext context) {
    final (label, color) = team.status == 'suspended'
        ? ('Suspendu', AppTheme.error)
        : team.isTrial
            ? ('Mois gratuit', AppTheme.warning)
            : team.subscriptionStatus == 'active'
                ? ('Abonné', AppTheme.success)
                : (team.subscriptionLabel, AppTheme.textFaint);
    return Text(label, style: TextStyle(fontSize: 12, color: color));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1.5,
            color: AppTheme.textFaint,
          ),
        ),
      );
}

/// Barres des 30 derniers jours : une visite = une personne un jour donné.
class _VisitsChart extends StatelessWidget {
  const _VisitsChart(this.points);

  final List<PlatformDailyVisits> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Text('Non mesuré');
    }
    final maxVisits = points.map((point) => point.visits).reduce(math.max);
    final total = points.fold<int>(0, (sum, point) => sum + point.visits);
    final average = total / points.length;
    final bar = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Visites des 30 derniers jours : $total au total, '
          '${_rate(average)} par jour en moyenne, maximum $maxVisits.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$total visites · ${_rate(average)} par jour en moyenne · record $maxVisits',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final point in points)
                    Expanded(
                      child: Tooltip(
                        message: '${_day(point.day)} : ${point.visits}',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Container(
                            height: maxVisits == 0
                                ? 2
                                : math.max(2, 120 * point.visits / maxVisits),
                            decoration: BoxDecoration(
                              color: point.visits == 0 ? AppTheme.outline : bar,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _day(points.first.day),
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.textFaint),
                ),
                const Text(
                  'aujourd’hui',
                  style: TextStyle(fontSize: 12, color: AppTheme.textFaint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center),
      );
}

Color _dueColor(int? days) {
  if (days == null) return AppTheme.textFaint;
  if (days <= 3) return AppTheme.error;
  if (days <= 10) return AppTheme.warning;
  return AppTheme.textFaint;
}

String _referrals(PlatformTeam team) {
  if (team.referralsTotal == null) return 'Non mesuré';
  if (team.referralsTotal == 0) return 'Aucun';
  return '${team.referralsTotal} · ${team.referralsPaid ?? 0} payé(s)';
}

String _count(int? value) => value == null ? 'Non mesuré' : '$value';
String _euros(int? cents) => cents == null ? 'Non mesuré' : formatEuros(cents);
String _rate(double? value) => value == null
    ? 'Non mesuré'
    : value.toStringAsFixed(1).replaceAll('.', ',');

String _day(DateTime? date) {
  if (date == null) return 'Non renseigné';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}

String _date(DateTime? date) {
  if (date == null) return 'Non renseigné';
  final local = date.toLocal();
  return '${_day(date)} à ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _bytes(int bytes) => bytes < 1024 * 1024
    ? '$bytes octets'
    : '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} Mo';
