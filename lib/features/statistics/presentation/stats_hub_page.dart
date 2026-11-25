import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/app/shell/module_navigation.dart';
import 'package:petit_filet/core/theme/app_spacing.dart';
import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:petit_filet/core/utils/ranking.dart';
import 'package:petit_filet/core/widgets/pf_app_bar.dart';
import 'package:petit_filet/core/widgets/pf_empty_state.dart';
import 'package:petit_filet/core/widgets/pf_secondary_tabs.dart';
import 'package:petit_filet/core/widgets/pf_skeleton.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/badges/presentation/badge_display_scope.dart';
import 'package:petit_filet/features/badges/presentation/name_with_badges.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/players/presentation/player_card_link.dart';
import 'package:petit_filet/features/predictions/presentation/pronos_hub_page.dart';
import 'package:petit_filet/features/statistics/data/statistics_repository.dart';
import 'package:petit_filet/features/statistics/presentation/team_statistics_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _StatsSection { rankings, players, team }

class StatsHubPage extends ConsumerStatefulWidget {
  const StatsHubPage({super.key, this.initialSection});

  final String? initialSection;

  @override
  ConsumerState<StatsHubPage> createState() => _StatsHubPageState();
}

class _StatsHubPageState extends ConsumerState<StatsHubPage> {
  late _StatsSection _section = switch (widget.initialSection) {
    'rankings' => _StatsSection.rankings,
    'team' => _StatsSection.team,
    _ => _StatsSection.players,
  };
  StatisticsPeriod _period = StatisticsPeriod.current;

  // Change à chaque appui sur l'onglet Statistiques : le panneau est recréé,
  // ce qui remet son tri à zéro et remonte le tableau en haut.
  int _resetGeneration = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(statsResetRequestProvider, (previous, next) {
      setState(() {
        _section = _StatsSection.players;
        _period = StatisticsPeriod.current;
        _resetGeneration++;
      });
    });
    // Pronostics coupés par le club : l'onglet de leur classement disparaît.
    final predictionsEnabled =
        ref.watch(clubModuleEnabledProvider(ClubModule.predictions));
    final section = !predictionsEnabled && _section == _StatsSection.rankings
        ? _StatsSection.players
        : _section;
    return Scaffold(
      appBar: PfAppBar(
        title: const Text('Statistiques'),
        actions: pfHomeActions(context),
      ),
      // Seul le module Statistiques arbore les badges à côté des noms : les
      // mêmes panneaux montés ailleurs (Prono, Calendrier) rendent le nom seul.
      body: BadgeDisplayScope(
        showBadges: true,
        // Partout dans le module, toucher un nom ouvre la fiche du joueur.
        child: PlayerCardLinkScope(
          enabled: true,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenGutter,
                  AppSpacing.contentGap,
                  AppSpacing.screenGutter,
                  AppSpacing.contentGap,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_StatsSection>(
                    expandedInsets: EdgeInsets.zero,
                    showSelectedIcon: false,
                    segments: [
                      const ButtonSegment(
                        value: _StatsSection.players,
                        label: Text('Joueurs'),
                      ),
                      const ButtonSegment(
                        value: _StatsSection.team,
                        label: Text('Équipe'),
                      ),
                      if (predictionsEnabled)
                        const ButtonSegment(
                          value: _StatsSection.rankings,
                          label: Text('Prono'),
                        ),
                    ],
                    selected: {section},
                    onSelectionChanged: (value) {
                      setState(() => _section = value.first);
                    },
                  ),
                ),
              ),
              PfSecondaryTabs<StatisticsPeriod>(
                segments: const [
                  ButtonSegment(
                    value: StatisticsPeriod.current,
                    label: Text('Actuelle'),
                  ),
                  ButtonSegment(
                    value: StatisticsPeriod.previous,
                    label: Text('Précédente'),
                  ),
                  ButtonSegment(
                    value: StatisticsPeriod.allTime,
                    label: Text('Toutes'),
                  ),
                ],
                selected: {_period},
                onSelectionChanged: (value) {
                  setState(() => _period = value.first);
                },
              ),
              Expanded(
                key: ValueKey<int>(_resetGeneration),
                child: switch (section) {
                  _StatsSection.rankings => RankingsPanel(period: _period),
                  _StatsSection.players => _PlayersPanel(period: _period),
                  _StatsSection.team => TeamStatisticsPanel(period: _period),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Statistique sur laquelle les joueurs sont classés.
enum _PlayerStatCol {
  goals('Buts', 'but', 'buts'),
  assists('Passes décisives', 'passe décisive', 'passes décisives'),
  played('Matchs', 'match', 'matchs'),
  hdm('Homme du match', 'Homme du match', 'Hommes du match'),
  wins('Victoires', 'victoire', 'victoires'),
  cleanSheets(
      'Sans encaisser', 'match sans encaisser', 'matchs sans encaisser');

  const _PlayerStatCol(this.chipLabel, this.singular, this.plural);

  final String chipLabel;
  final String singular;
  final String plural;
}

const _playerBadgeSize = statisticsBadgeSize;

/// Les passes décisives ne sont suivies que depuis leur mise en service : une
/// période antérieure n'en contient aucune, et afficher une colonne vide y
/// ferait croire à un manque de saisie plutôt qu'à une donnée qui n'existait
/// pas encore.
///
/// La saison en cours montre donc toujours la colonne — c'est là qu'on saisit —
/// et une période passée ne la montre que si elle porte réellement des passes.
/// Aucune date n'est écrite en dur : la colonne apparaîtra d'elle-même dans
/// « Saison précédente » et « Toutes saisons » dès que celles-ci couvriront une
/// saison où des passes ont été enregistrées.
bool statisticsShowsAssistsColumn(StatisticsPeriodData data) {
  if (data.period == StatisticsPeriod.current) return true;
  return data.players.any((player) => player.assists > 0);
}

class _PlayersPanel extends ConsumerStatefulWidget {
  const _PlayersPanel({required this.period});

  final StatisticsPeriod period;

  @override
  ConsumerState<_PlayersPanel> createState() => _PlayersPanelState();
}

class _PlayersPanelState extends ConsumerState<_PlayersPanel> {
  _PlayerStatCol _sort = _PlayerStatCol.goals;

  num _value(_PlayerStatCol column, PlayerStatistics player) {
    return switch (column) {
      _PlayerStatCol.played => player.matchesPlayed ?? 0,
      _PlayerStatCol.goals => player.goals,
      _PlayerStatCol.assists => player.assists,
      _PlayerStatCol.cleanSheets => player.teamCleanSheets,
      _PlayerStatCol.wins => player.wins ?? 0,
      _PlayerStatCol.hdm => player.hdm ?? 0,
    };
  }

  Future<void> _refresh() async {
    ref.invalidate(statisticsPeriodProvider(widget.period));
    await ref.read(statisticsPeriodProvider(widget.period).future);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(statisticsPeriodProvider(widget.period));
    final currentProfileId = ref.watch(
      authControllerProvider.select((state) => state.profile?.id),
    );

    return async.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: PfSkeleton.rows(itemCount: 7),
      ),
      error: (error, _) => _Message(
        title: 'Statistiques indisponibles',
        message: humanizeError(error),
        onRefresh: _refresh,
      ),
      data: (data) {
        if (data.players.isEmpty) {
          return _Message(
            title: 'Pas encore de statistiques',
            message: widget.period == StatisticsPeriod.previous
                ? 'Aucune statistique pour la saison précédente.'
                : 'Les stats apparaîtront après le premier match validé.',
            onRefresh: _refresh,
          );
        }

        final showsAssists = statisticsShowsAssistsColumn(data);
        final columns = [
          for (final column in _PlayerStatCol.values)
            if (showsAssists || column != _PlayerStatCol.assists) column,
        ];
        // Classer sur une statistique que cette période n'affiche pas donnerait
        // un classement inexplicable : on retombe sur les buts.
        final sort = columns.contains(_sort) ? _sort : _PlayerStatCol.goals;
        final players = [...data.players]..sort((a, b) {
            final comparison = _value(sort, b).compareTo(_value(sort, a));
            if (comparison != 0) return comparison;
            return a.playerName.toLowerCase().compareTo(
                  b.playerName.toLowerCase(),
                );
          });
        final ranks = competitionRanks(players, (p) => _value(sort, p));

        return Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenGutter,
                  vertical: 8,
                ),
                itemCount: columns.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final column = columns[index];
                  return ChoiceChip(
                    key: ValueKey('stats-sort-${column.name}'),
                    label: Text(column.chipLabel),
                    selected: column == sort,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _sort = column),
                  );
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenGutter,
                    4,
                    AppSpacing.screenGutter,
                    32,
                  ),
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _PlayerStatCard(
                    rank: ranks[index],
                    player: players[index],
                    sort: sort,
                    value: _value(sort, players[index]).toInt(),
                    showsAssists: showsAssists,
                    isCurrentUser: currentProfileId != null &&
                        players[index].profileId == currentProfileId,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlayerStatCard extends StatelessWidget {
  const _PlayerStatCard({
    required this.rank,
    required this.player,
    required this.sort,
    required this.value,
    required this.showsAssists,
    required this.isCurrentUser,
  });

  final int rank;
  final PlayerStatistics player;
  final _PlayerStatCol sort;
  final int value;
  final bool showsAssists;
  final bool isCurrentUser;

  static const _gold = Color(0xFFF2C94C);
  static const _silver = Color(0xFFC5CED8);
  static const _bronze = Color(0xFFD08A55);

  Color? get _medal => switch (rank) {
        1 => _gold,
        2 => _silver,
        3 => _bronze,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = _medal;
    final accent = isCurrentUser ? theme.colorScheme.secondary : null;
    final borderColor = accent ?? medal?.withValues(alpha: .55);

    Widget pill(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        );

    String count(int n, _PlayerStatCol column) =>
        '$n ${n > 1 ? column.plural : column.singular}';

    final details = <String>[
      if (sort != _PlayerStatCol.played)
        count(player.matchesPlayed ?? 0, _PlayerStatCol.played),
      if (sort != _PlayerStatCol.goals)
        count(player.goals, _PlayerStatCol.goals),
      if (showsAssists && sort != _PlayerStatCol.assists)
        count(player.assists, _PlayerStatCol.assists),
      if (sort != _PlayerStatCol.hdm) '${player.hdm ?? 0} HDM',
      if (sort != _PlayerStatCol.cleanSheets)
        '${player.teamCleanSheets} sans encaisser',
      '${player.wins ?? 0} V · ${player.draws ?? 0} N · ${player.losses ?? 0} D',
    ];

    return Container(
      decoration: BoxDecoration(
        color: accent?.withValues(alpha: .12) ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: .06),
          width: borderColor == null ? 1 : 1.4,
        ),
      ),
      child: PlayerCardLink(
        playerKey: (
          profileId: player.profileId,
          fullName: player.fullName,
          isGoalkeeper: player.isGoalkeeper,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: medal ?? AppTheme.surfaceHigh,
                ),
                child: Text(
                  '$rank',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: medal == null ? AppTheme.textPrimary : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NameWithBadges(
                      profileId: player.profileId,
                      name: player.playerName,
                      badgeSize: _playerBadgeSize,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [for (final text in details) pill(text)],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  Text(
                    '$value',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 30,
                      height: 1,
                      color: medal ?? AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value > 1 ? sort.plural : sort.singular,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    required this.message,
    required this.onRefresh,
  });

  final String title;
  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.sectionGap,
          AppSpacing.screenGutter,
          32,
        ),
        children: [
          Card(
            child: PfEmptyState(
              icon: Icons.bar_chart_outlined,
              title: title,
              message: message,
            ),
          ),
        ],
      ),
    );
  }
}
