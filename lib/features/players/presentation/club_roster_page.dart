import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:petit_filet/core/widgets/pf_app_bar.dart';
import 'package:petit_filet/core/widgets/pf_empty_state.dart';
import 'package:petit_filet/core/widgets/pf_loader.dart';
import 'package:petit_filet/features/players/data/member_contacts_repository.dart';
import 'package:petit_filet/features/players/data/roster_repository.dart';
import 'package:petit_filet/features/profile/data/personal_data_repository.dart';
import 'package:petit_filet/features/sports_management/presentation/widgets/composition_pitch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Effectif de la saison en lecture seule, pour tous les membres : nom,
/// photo, téléphone et date de naissance. Les admins le modifient depuis
/// leur propre écran Effectif.
class ClubRosterPage extends ConsumerWidget {
  const ClubRosterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonAsync = ref.watch(openSeasonIdProvider);
    return Scaffold(
      appBar: PfAppBar(title: const Text('Effectif')),
      body: seasonAsync.when(
        loading: () => const Center(child: PfProgressIndicator()),
        error: (error, _) => Center(child: Text(humanizeError(error))),
        data: (seasonId) => seasonId == null
            ? const Center(
                child: PfEmptyState(
                  icon: Icons.calendar_month_rounded,
                  title: 'Aucune saison ouverte',
                  message: 'L’effectif apparaîtra quand le club aura ouvert '
                      'une saison.',
                ),
              )
            : _RosterList(seasonId: seasonId),
      ),
    );
  }
}

class _RosterList extends ConsumerWidget {
  const _RosterList({required this.seasonId});

  final String seasonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(rosterProvider(seasonId));
    // Sans coordonnées (erreur réseau), la liste s'affiche quand même.
    final contacts =
        ref.watch(clubMemberContactsProvider).asData?.value ?? const {};

    return rosterAsync.when(
      loading: () => const Center(child: PfProgressIndicator()),
      error: (error, _) => Center(child: Text(humanizeError(error))),
      data: (all) {
        final players = [
          for (final player in all)
            if (player.isActive) player,
        ]..sort(
            (a, b) => a.displayName
                .toLowerCase()
                .compareTo(b.displayName.toLowerCase()),
          );
        if (players.isEmpty) {
          return const Center(
            child: PfEmptyState(
              icon: Icons.groups_outlined,
              title: 'Effectif vide',
              message: 'Aucun joueur dans l’effectif de la saison.',
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(rosterProvider(seasonId));
            ref.invalidate(clubMemberContactsProvider);
            await ref.read(rosterProvider(seasonId).future);
          },
          child: ListView.separated(
            key: const Key('club-roster-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: players.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final player = players[index];
              final details = player.linkedProfileId == null
                  ? null
                  : contacts[player.linkedProfileId];
              return _PlayerTile(player: player, details: details);
            },
          ),
        );
      },
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player, required this.details});

  final RosterPlayer player;
  final PrivateDetails? details;

  Future<void> _call(BuildContext context, String phone) async {
    final uri =
        Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[ .()-]'), ''));
    final opened = await launchUrl(uri).catchError((_) => false);
    if (opened || !context.mounted) return;
    // Pas d'appli téléphone (ordinateur) : on copie le numéro.
    await Clipboard.setData(ClipboardData(text: phone));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Numéro copié : $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = details?.phone;
    final birthDate = details?.birthDate;
    final role = [
      if (player.isGoalkeeper) 'Gardien',
      if (player.isCoach) 'Coach',
    ].join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: ExcludeSemantics(
        child: PlayerAvatar(
          photoUrl: player.photoUrl,
          name: player.displayName,
          lastName: player.lastName,
          isGoalkeeper: player.isGoalkeeper,
          size: 44,
        ),
      ),
      title: Text(player.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (role.isNotEmpty)
            Text(role, style: TextStyle(color: AppTheme.textFaint)),
          if (phone != null) Text(phone),
          if (birthDate != null)
            Text(
              'Né(e) le ${formatDay(birthDate)} '
              '(${ageOn(birthDate, DateTime.now())} ans)',
            ),
          if (phone == null && birthDate == null)
            Text(
              'Pas de coordonnées',
              style: TextStyle(color: AppTheme.textFaint),
            ),
        ],
      ),
      trailing: phone == null
          ? null
          : IconButton(
              tooltip: 'Appeler ${player.displayName}',
              icon: const Icon(Icons.phone_outlined),
              onPressed: () => _call(context, phone),
            ),
    );
  }
}
