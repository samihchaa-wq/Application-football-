part of 'pronos_hub_page.dart';

/// Classement des pronostics de match : la seule compétition de pronostic.
class _GeneralRankingsSection extends ConsumerWidget {
  const _GeneralRankingsSection({this.badgeSize, this.period});

  final double? badgeSize;
  final StatisticsPeriod? period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = period == null
        ? leaderboardProvider
        : periodLeaderboardProvider(period!);
    final leaderboard = ref.watch(provider);
    Future<void> refresh() async {
      ref.invalidate(provider);
      await ref.read(provider.future);
    }

    return leaderboard.when(
      loading: () => const Center(
        child: GrintaLoader.page(
          message: 'Le classement se met en place…',
          semanticLabel: 'Chargement du classement des matchs',
        ),
      ),
      error: (_, __) => const _MessageCard(
        title: 'Classement indisponible',
        icon: Icons.wifi_off_rounded,
        message: 'Le classement des matchs n’a pas pu être chargé.',
        tone: GrintaEmptyTone.alert,
      ),
      data: (entries) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          6,
          AppSpacing.screenGutter,
          32,
        ),
        child: _LeaderboardCard(
          entries: entries,
          onRefresh: refresh,
          badgeSize: badgeSize,
        ),
      ),
    );
  }
}
