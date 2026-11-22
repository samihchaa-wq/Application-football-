import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petit_filet/core/club/club_identity.dart';
import 'package:petit_filet/core/theme/app_spacing.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/utils/app_formats.dart';
import 'package:petit_filet/core/utils/match_window.dart';
import 'package:petit_filet/core/widgets/match_fixture.dart';
import 'package:petit_filet/core/widgets/pf_app_bar.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/matches/domain/match_model.dart';
import 'package:petit_filet/features/matches/presentation/matches_controller.dart';
import 'package:petit_filet/features/matches/presentation/widgets/next_match_hero.dart';
import 'package:petit_filet/features/sports_management/data/sport_motm_vote_repository.dart';
import 'package:petit_filet/features/sports_management/presentation/match_availability_provider.dart';
import 'package:petit_filet/features/sports_management/presentation/widgets/match_availability_selector.dart';

/// Accueil : ce qu'il faut savoir en ouvrant l'appli. Le prochain match en
/// point focal, ta présence, les derniers résultats, le dernier Homme du match
/// et les raccourcis. Le calendrier complet reste dans son onglet.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchesControllerProvider);
    final profile = ref.watch(authControllerProvider).profile;
    final isAdmin = ref.watch(isAdminViewProvider);
    final now = DateTime.now();
    final sorted = [...state.matches]
      ..sort((a, b) => a.kickoffAt.compareTo(b.kickoffAt));
    final next = sorted.cast<MatchModel?>().firstWhere(
          (m) => m!.kickoffAt.isAfter(now) && !m.isCancelled && !m.isInternal,
          orElse: () => null,
        );
    final played = sorted
        .where((m) => m.isFinished && !m.isCancelled && !m.isInternal)
        .toList()
        .reversed
        .take(3)
        .toList();
    final firstName = profile?.firstName.trim() ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PfAppBar(title: const Text('Accueil')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final hero =
              next == null ? const _EmptyNext() : _NextMatchPanel(match: next);
          final side = <Widget>[
            _Section(
              title: 'Derniers résultats',
              child: played.isEmpty
                  ? const _Quiet('Aucun match joué pour le moment.')
                  : Column(
                      children: [
                        for (final m in played) _ResultRow(match: m),
                      ],
                    ),
            ),
            if (played.isNotEmpty) _LastMotm(match: played.first),
          ];
          final quick = _QuickActions(isAdmin: isAdmin);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenGutter + 4,
              12,
              AppSpacing.screenGutter + 4,
              28,
            ),
            children: [
              Text(
                firstName.isEmpty ? 'Salut' : 'Salut $firstName',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                '${ClubIdentity.name} · ${AppFormats.weekdayLong(now)} '
                '${now.day} ${AppFormats.monthLong(now).toLowerCase()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textFaint,
                ),
              ),
              const SizedBox(height: 14),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: hero),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [...side, quick],
                      ),
                    ),
                  ],
                )
              else ...[hero, const SizedBox(height: 16), ...side, quick],
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textFaint,
                      letterSpacing: .8,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Quiet extends StatelessWidget {
  const _Quiet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppTheme.textFaint),
      );
}

class _EmptyNext extends StatelessWidget {
  const _EmptyNext();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aucun match prévu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
            ),
            const SizedBox(height: 6),
            const _Quiet(
              'Dès qu’un match est ajouté au calendrier, il apparaît ici '
              'avec le compte à rebours et ta présence.',
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/matches'),
              child: const Text('Ouvrir le calendrier'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextMatchPanel extends ConsumerWidget {
  const _NextMatchPanel({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opponent = match.opponentName ?? 'Adversaire';
    final homeName = match.isHome ? ClubIdentity.name : opponent;
    final awayName = match.isHome ? opponent : ClubIdentity.name;
    final now = DateTime.now();
    final availability = ref.watch(myMatchAvailabilityProvider(match.id));
    final server = availability.valueOrNull;
    final open = now.isBefore(match.kickoffAt) &&
        (server?.canRespond == true ||
            (server == null &&
                !now.isBefore(matchFeaturesOpenAt(match.kickoffAt))));
    final accent = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: accent, width: 2),
      ),
      child: InkWell(
        onTap: () => context.push('/matches/${match.id}/lineup?section=info'),
        child: NextMatchHeroBody(
          match: match,
          homeName: homeName,
          awayName: awayName,
          actionInset: 0,
          address: match.address?.trim(),
          availability: open
              ? MatchAvailabilitySelector(
                  matchId: match.id,
                  embeddedOnDark: true,
                  topSpacing: 0,
                )
              : null,
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final own = match.ownScore;
    final opp = match.opponentScore;
    final color = own != null && opp != null
        ? MatchFixture.resultColor(own, opp)
        : AppTheme.textFaint;
    final letter = own == null || opp == null
        ? '–'
        : own > opp
            ? 'V'
            : own < opp
                ? 'D'
                : 'N';
    final theme = Theme.of(context);
    final opponent = match.opponentName ?? 'Adversaire';
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      onTap: () => context.push('/matches/${match.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color),
              ),
              child: Text(letter,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w400,
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.isHome
                        ? '${ClubIdentity.name} – $opponent'
                        : '$opponent – ${ClubIdentity.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    AppFormats.date(match.kickoffAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textFaint,
                    ),
                  ),
                ],
              ),
            ),
            if (own != null && opp != null)
              Text(
                match.isHome ? '$own – $opp' : '$opp – $own',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LastMotm extends ConsumerWidget {
  const _LastMotm({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vote = ref.watch(sportMotmVoteProvider(match.id)).valueOrNull;
    if (vote == null || !vote.isClosed || vote.winners.isEmpty) {
      return const SizedBox.shrink();
    }
    final names = vote.winners.map((w) => w.displayName).join(' et ');
    final theme = Theme.of(context);
    return _Section(
      title: 'Homme du match',
      child: InkWell(
        onTap: () => context.push('/matches/${match.id}/vote'),
        child: Row(
          children: [
            const Text('🏅', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    names,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    'contre ${match.opponentName ?? 'l’adversaire'} · '
                    '${AppFormats.date(match.kickoffAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textFaint,
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
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      (Icons.calendar_month_rounded, 'Calendrier', '/matches'),
      (Icons.leaderboard_rounded, 'Statistiques', '/stats'),
      (Icons.group_rounded, 'Effectif', '/effectif'),
      (Icons.event_busy_rounded, 'Indisponibilité', '/unavailability'),
      if (isAdmin) (Icons.tune_rounded, 'Réglages du club', '/admin/club'),
    ];
    return _Section(
      title: 'Raccourcis',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (icon, label, route) in items)
            ActionChip(
              avatar: Icon(icon, size: 18),
              label: Text(label),
              onPressed: () => context.go(route),
            ),
        ],
      ),
    );
  }
}
