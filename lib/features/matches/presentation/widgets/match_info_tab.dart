import 'package:petit_filet/core/theme/app_spacing.dart';
import 'package:petit_filet/core/utils/app_formats.dart';
import 'package:petit_filet/core/widgets/match_fixture.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/matches/data/match_info_repository.dart';
import 'package:petit_filet/features/matches/domain/jersey_option.dart';
import 'package:petit_filet/features/matches/presentation/match_encounter_route.dart';
import 'package:petit_filet/features/matches/presentation/widgets/kit_jersey.dart';
import 'package:petit_filet/features/weather/presentation/match_weather_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petit_filet/core/widgets/pf_loader.dart';

/// Onglet « Info » d'une fiche de match : rendez-vous, maillot, météo et les
/// dernières rencontres contre l'adversaire. Date, heure, type et adresse sont
/// portés par la carte du match au-dessus des onglets.
class MatchInfoTab extends ConsumerWidget {
  const MatchInfoTab({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(matchDetailedInfoProvider(matchId));
    return infoAsync.when(
      loading: () => const Center(child: PfProgressIndicator()),
      error: (_, __) => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.cardPadding),
          child: Text('Infos du match indisponibles.'),
        ),
      ),
      data: (info) {
        final encounters = info.lastEncounters.take(_encounterSlots).toList();
        final jersey = JerseyOption.fromId(info.jerseyNote);
        final hasMeeting = info.effectiveMeetingAt != null;
        final hasJersey = info.jerseyNote != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasMeeting || hasJersey)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasMeeting)
                      Expanded(
                        child: _InfoTile(
                          label: 'Rendez-vous',
                          child: Text(
                            AppFormats.time(info.effectiveMeetingAt!),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    if (hasMeeting && hasJersey)
                      const SizedBox(width: AppSpacing.sectionGap),
                    if (hasJersey)
                      Expanded(
                        child: _InfoTile(
                          label: 'Maillot',
                          child: Row(
                            children: [
                              if (jersey != null) ...[
                                SizedBox(
                                  width: 36,
                                  height: 42,
                                  child: KitJersey(kit: jersey.kit),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Flexible(
                                child: Text(
                                  jersey?.label ?? info.jerseyNote!,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // On ne récupère la météo au coup d'envoi que quand une
            // adresse est renseignée : sinon la carte affichait la météo
            // d'un lieu par défaut (généralement Toulouse), sans rapport
            // avec le match — trompeur.
            // Le club peut aussi avoir désactivé la météo.
            if (info.kickoffAt != null &&
                info.address != null &&
                ref.watch(clubModuleEnabledProvider(ClubModule.weather)))
              MatchWeatherCard(
                matchId: matchId,
                kickoffAt: info.kickoffAt!,
                plannedDurationMinutes: 90,
              ),
            if (!info.isInternal) ...[
              const SizedBox(height: AppSpacing.sectionGap * 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  encounters.length > 1
                      ? 'Dernières rencontres'
                      : 'Dernière rencontre',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w400),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              if (encounters.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Aucune rencontre passée contre cet adversaire.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < encounters.length; index++) ...[
                      if (index > 0) const SizedBox(width: AppSpacing.microGap),
                      Expanded(
                        child: _EncounterChip(encounter: encounters[index]),
                      ),
                    ],
                    // Cases vides : chaque score garde la largeur qu'il
                    // aurait avec cinq rencontres, même s'il est seul.
                    for (var index = encounters.length;
                        index < _encounterSlots;
                        index++) ...[
                      const SizedBox(width: AppSpacing.microGap),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ],
                ),
            ],
          ],
        );
      },
    );
  }
}

/// Nombre de dernières rencontres affichées sur une ligne.
const _encounterSlots = 5;

/// Petite carte « libellé + valeur » (rendez-vous, maillot).
class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15.5,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: AppSpacing.microGap),
            child,
          ],
        ),
      ),
    );
  }
}

class _EncounterChip extends StatelessWidget {
  const _EncounterChip({required this.encounter});

  final MatchEncounter encounter;

  @override
  Widget build(BuildContext context) {
    final color = MatchFixture.resultColor(
      encounter.ownScore,
      encounter.opponentScore,
    );
    final route = matchEncounterRoute(
      encounterId: encounter.id,
      isHistorical: encounter.isHistorical,
    );
    final dateLabel =
        encounter.date == null ? null : AppFormats.date(encounter.date!);
    final chip = Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .7), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dateLabel != null) ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                dateLabel,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 3),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              encounter.scoreLabel,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
    if (route == null) return chip;
    return Semantics(
      button: true,
      label: dateLabel == null
          ? 'Ouvrir ce match'
          : 'Ouvrir le match du $dateLabel',
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(8),
        child: chip,
      ),
    );
  }
}
