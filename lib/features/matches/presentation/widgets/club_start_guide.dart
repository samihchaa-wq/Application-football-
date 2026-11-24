import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petit_filet/features/admin/data/admin_repository.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/matches/domain/club_start_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _hiddenKey = 'pf-club-start-guide-hidden';

/// Le guide a été masqué sur cet appareil (« Masquer le guide »).
final clubStartGuideHiddenProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hiddenKey) ?? false;
  } catch (_) {
    return false;
  }
});

/// Avancement du club, lu à partir des données déjà chargées par
/// l'administration (comptes, saison ouverte) et de la fiche du club.
final clubStartProgressProvider =
    FutureProvider.autoDispose.family<ClubStartProgress, bool>((
  ref,
  hasMatches,
) async {
  final dashboard = await ref.watch(adminDashboardProvider.future);
  final club = await ref.watch(myClubProvider.future);
  return ClubStartProgress(
    hasLogo: (club.logoPath ?? '').isNotEmpty,
    hasOpenSeason: dashboard.openSeasonId != null,
    hasMatches: hasMatches,
    activeMembers: dashboard.profiles
        .where((profile) => profile.status == 'active')
        .length,
  );
});

/// Carte « Bien démarrer » du Calendrier, pour l'administrateur d'un club
/// qui n'a pas encore de saison, de match ou de joueurs inscrits.
class ClubStartGuide extends ConsumerWidget {
  const ClubStartGuide({
    super.key,
    required this.hasMatches,
    required this.onCreateMatch,
  });

  final bool hasMatches;
  final VoidCallback onCreateMatch;

  Future<void> _hide(WidgetRef ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hiddenKey, true);
    } catch (_) {
      // Au pire, le guide réapparaît à la prochaine ouverture.
    }
    ref.invalidate(clubStartGuideHiddenProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(clubStartGuideHiddenProvider).valueOrNull ?? true;
    final progress =
        ref.watch(clubStartProgressProvider(hasMatches)).valueOrNull;
    if (hidden || progress == null || progress.complete) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Card(
      key: const Key('club-start-guide'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bien démarrer',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${progress.doneCount}/4',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'Quatre étapes pour lancer ton club, dans cet ordre.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 6),
            _Step(
              key: const Key('club-start-step-identity'),
              done: progress.identityDone,
              title: 'Logo et couleurs du club',
              subtitle: 'Réglages du club › Identité et maillots',
              onTap: () => context.push('/admin/club'),
            ),
            _Step(
              key: const Key('club-start-step-season'),
              done: progress.seasonDone,
              title: 'Créer la saison',
              subtitle: 'Sans saison ouverte, aucun match ne peut être créé.',
              onTap: () => context.push('/admin/season'),
            ),
            _Step(
              key: const Key('club-start-step-match'),
              done: progress.matchDone,
              enabled: progress.seasonDone,
              title: 'Ajouter le premier match',
              subtitle: progress.seasonDone
                  ? 'Adversaire, date, heure et lieu.'
                  : 'Possible une fois la saison créée.',
              onTap: onCreateMatch,
            ),
            _Step(
              key: const Key('club-start-step-players'),
              done: progress.playersDone,
              title: 'Inviter les joueurs',
              subtitle:
                  'Envoie le lien d’inscription, puis valide les comptes.',
              onTap: () => context.push('/admin'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('club-start-guide-hide'),
                onPressed: () => _hide(ref),
                child: const Text('Masquer le guide'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    super.key,
    required this.done,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final bool done;
  final bool enabled;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.only(right: 8),
      dense: true,
      enabled: enabled && !done,
      leading: Icon(
        done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        color: done ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: done
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(subtitle),
      trailing: done ? null : const Icon(Icons.chevron_right_outlined),
      onTap: done || !enabled ? null : onTap,
    );
  }
}
