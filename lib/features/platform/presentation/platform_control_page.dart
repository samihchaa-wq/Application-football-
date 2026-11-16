import 'dart:async';

import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:as_grinta/features/auth/presentation/sign_out_confirmation.dart';
import 'package:as_grinta/features/platform/data/platform_repository.dart';
import 'package:as_grinta/features/platform/domain/platform_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _sections = ['Vue générale', 'Équipes', 'Supervision', 'Évolutions'];
const _icons = [
  Icons.space_dashboard_outlined,
  Icons.groups_outlined,
  Icons.monitor_heart_outlined,
  Icons.route_outlined,
];

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
  String? _status;
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
                message: 'Revenir à la vue générale',
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
                  onPressed: () => ref.invalidate(platformSnapshotProvider),
                ),
                IconButton(
                  tooltip: 'Se déconnecter',
                  icon: const Icon(Icons.logout),
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
                        label: const [
                          'Accueil',
                          'Équipes',
                          'Santé',
                          'Suite'
                        ][i],
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
                    ? Icons.lock_outline
                    : Icons.cloud_off,
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
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(platformSnapshotProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
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
          constraints: const BoxConstraints(maxWidth: 1200),
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
                _teamDetail(selected)
              else
                switch (_section) {
                  0 => _overview(snapshot),
                  1 => _teams(snapshot),
                  2 => _health(snapshot),
                  _ => _roadmap(),
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

  Widget _overview(PlatformSnapshot snapshot) {
    final renewals = snapshot.renewalsBefore(
      snapshot.fetchedAt,
      const Duration(days: 30),
    );
    final health = snapshot.health;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _metrics([
          ('Équipes', '${snapshot.teams.length}', 'Espaces enregistrés'),
          (
            'Équipes actives',
            '${snapshot.activeTeams}',
            'Statut d’accès actif',
          ),
          (
            'Membres actifs',
            _count(snapshot.activeMemberCount),
            'Profils au statut actif, hors invités',
          ),
          ('Encaissements', 'Non mesuré', 'Registre de paiement à raccorder'),
        ]),
        const SizedBox(height: 24),
        _panel('À examiner', [
          if (health == null)
            const ListTile(
              leading: Icon(Icons.cloud_off_outlined),
              title: Text('La supervision est indisponible'),
              subtitle: Text(
                'Impossible de conclure sur l’état de l’application.',
              ),
            ),
          if (health?.failedJobs == null && health != null)
            const ListTile(title: Text('Échecs des tâches : non mesuré')),
          if ((health?.failedJobs ?? 0) > 0)
            ListTile(
              leading: const Icon(
                Icons.warning_amber_outlined,
                color: AppTheme.warning,
              ),
              title: Text(
                '${health!.failedJobs} exécution(s) de tâche en échec',
              ),
              subtitle: const Text('Dernière heure · ouvrir la supervision'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigate(2),
            ),
          if ((health?.failedPush ?? 0) > 0)
            ListTile(
              leading: const Icon(
                Icons.notifications_off_outlined,
                color: AppTheme.warning,
              ),
              title: Text(
                '${health!.failedPush} tentative(s) de notification en échec',
              ),
              subtitle: const Text(
                'Dernière heure · un échec ne prouve pas une panne générale',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigate(2),
            ),
          if (renewals.isNotEmpty) ...[
            const ListTile(
              title: Text('Échéances dans les 30 jours'),
              subtitle: Text(
                'Dates d’abonnement enregistrées, sans prévision d’encaissement.',
              ),
            ),
            ...renewals.take(5).map(_teamTile),
            if (renewals.length > 5)
              TextButton(
                onPressed: () => _navigate(1),
                child: Text(
                  'Consulter les ${renewals.length} équipes concernées dans le répertoire',
                ),
              ),
          ],
          if (renewals.isEmpty)
            const ListTile(
              title: Text('Aucune échéance enregistrée dans les 30 jours'),
            ),
          if (health?.failedJobs == 0 && health?.failedPush == 0)
            const ListTile(
              leading: Icon(
                Icons.check_circle_outline,
                color: AppTheme.success,
              ),
              title: Text('Aucun échec enregistré sur ces deux indicateurs'),
              subtitle: Text(
                'Cela ne constitue pas un bilan complet de disponibilité.',
              ),
            ),
        ]),
        const SizedBox(height: 16),
        _panel('Prochaine étape de pilotage', [
          const ListTile(
            leading: Icon(Icons.support_agent),
            title: Text('Assistance centralisée'),
            subtitle: Text(
              'Les espaces Idées et Problèmes sont prévus. Aucune demande n’est encore mesurée ici.',
            ),
          ),
        ]),
      ],
    );
  }

  Widget _teams(PlatformSnapshot snapshot) {
    final filtered = filterPlatformTeams(
      snapshot.teams,
      query: _search.text,
      status: _status,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Rechercher une équipe',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in <(String?, String)>[
              (null, 'Toutes'),
              ('active', 'Actives'),
              ('suspended', 'Suspendues'),
            ])
              ChoiceChip(
                label: Text(item.$2),
                selected: _status == item.$1,
                onSelected: (_) => setState(() => _status = item.$1),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('${filtered.length} équipe(s) sur ${snapshot.teams.length}'),
        const SizedBox(height: 8),
        if (snapshot.teams.isEmpty)
          const _Empty('Aucune équipe enregistrée pour le moment.')
        else if (filtered.isEmpty)
          const _Empty('Aucune équipe ne correspond à cette recherche.')
        else
          _panel('Répertoire des équipes', filtered.map(_teamTile).toList()),
      ],
    );
  }

  Widget _teamTile(PlatformTeam team) => ListTile(
        key: ValueKey('platform-team-${team.id}'),
        leading: CircleAvatar(
          child: Icon(
            team.status == 'suspended' ? Icons.pause : Icons.sports_soccer,
          ),
        ),
        title: Text(team.name),
        subtitle: Text(
          '${team.statusLabel} · ${team.subscriptionLabel}\n'
          '${_count(team.members)} membre(s) actif(s)${team.currentPeriodEnd == null ? '' : ' · échéance ${_day(team.currentPeriodEnd)}'}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => setState(() => _selectedTeamId = team.id),
      );

  Widget _teamDetail(PlatformTeam team) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _selectedTeamId = null),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour à la liste'),
            ),
          ),
          _panel('Fiche équipe', [
            _detail('Accès', team.statusLabel),
            _detail('Création', _date(team.createdAt)),
            _detail('Membres au statut actif', _count(team.members)),
            _detail('Abonnement', team.subscriptionLabel),
            _detail('Fin d’essai enregistrée', _date(team.trialEndsAt)),
            _detail('Fin de période enregistrée', _date(team.currentPeriodEnd)),
            _detail(
              'Dernière modification de profil ou match',
              _date(team.lastModifiedAt),
            ),
          ]),
          const SizedBox(height: 16),
          const Text(
            'Stockage complet, connexions et encaissements : mesures à raccorder pour cette équipe.',
          ),
        ],
      );

  Widget _health(PlatformSnapshot snapshot) {
    final health = snapshot.health;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        _panel('Preuves à raccorder', [
          _detail('Dernière sauvegarde vérifiée', 'Non mesuré'),
          _detail('Dernière restauration testée', 'Non mesuré'),
          _detail('Disponibilité et temps de réponse', 'Non mesuré'),
          _detail('E-mails et erreurs applicatives', 'Non mesuré'),
        ]),
      ],
    );
  }

  Widget _roadmap() =>
      _panel('Poste de contrôle · construction progressive', const [
        ListTile(
          leading: Icon(Icons.visibility_outlined),
          title: Text('Fondations de consultation'),
          subtitle: Text(
            'Vue générale, équipes et supervision dans cette version.',
          ),
        ),
        ListTile(
          leading: Icon(Icons.support_agent),
          title: Text('Assistance et enquêtes · prévu'),
          subtitle: Text(
            'Idées, problèmes, chronologie et diagnostic contextualisé.',
          ),
        ),
        ListTile(
          leading: Icon(Icons.payments_outlined),
          title: Text('Pilotage commercial · prévu'),
          subtitle: Text('Paiements, promotions, parrainage et simulations.'),
        ),
        ListTile(
          leading: Icon(Icons.campaign_outlined),
          title: Text('Communication et nouveautés · prévu'),
          subtitle: Text(
            'Aperçu des annonces, ciblage, suivi et déploiement progressif.',
          ),
        ),
        ListTile(
          leading: Icon(Icons.security_outlined),
          title: Text('Sécurité et reprise · prévu'),
          subtitle: Text(
            'Journal privé, second facteur, sessions, sauvegardes et restauration isolée.',
          ),
        ),
        ListTile(
          leading: Icon(Icons.assistant_outlined),
          title: Text('Assistant de pilotage · prévu'),
          subtitle: Text(
            'Réponses sourcées et préparation d’actions à confirmer.',
          ),
        ),
      ]);

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
                                fontSize: value.$2 == 'Non mesuré' ? 22 : 32,
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

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center),
      );
}

String _count(int? value) => value == null ? 'Non mesuré' : '$value';
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
