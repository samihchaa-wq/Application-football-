import 'package:petit_filet/core/theme/app_spacing.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
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
        final showWeather = info.kickoffAt != null &&
            info.address != null &&
            ref.watch(clubModuleEnabledProvider(ClubModule.weather));
        // Sur grand écran, la colonne garde une largeur lisible.
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (info.effectiveMeetingAt != null || info.jerseyNote != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (info.effectiveMeetingAt != null)
                            Expanded(
                              child: _InfoBlock(
                                label: 'Rendez-vous',
                                child: Text(
                                  AppFormats.time(info.effectiveMeetingAt!),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w400,
                                      ),
                                ),
                              ),
                            ),
                          if (info.jerseyNote != null)
                            Expanded(
                              child: _InfoBlock(
                                label: 'Maillot',
                                child: jersey == null
                                    ? Text(
                                        info.jerseyNote!,
                                        style: _valueStyle,
                                      )
                                    : Row(
                                        children: [
                                          SizedBox(
                                            width: 32,
                                            height: 38,
                                            child: KitJersey(kit: jersey.kit),
                                          ),
                                          const SizedBox(width: 4),
                                          SizedBox(
                                            width: 32,
                                            height: 38,
                                            child: KitJersey(
                                              kit: jersey.kit,
                                              isGoalkeeper: true,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Flexible(
                                            child: Text(
                                              jersey.label,
                                              style: _valueStyle,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                // On ne récupère la météo au coup d'envoi que quand une
                // adresse est renseignée : sinon la carte affichait la météo
                // d'un lieu par défaut, sans rapport avec le match.
                // Le club peut aussi avoir désactivé la météo.
                if (showWeather)
                  MatchWeatherCard(
                    matchId: matchId,
                    kickoffAt: info.kickoffAt!,
                    plannedDurationMinutes: 90,
                  ),
                if (!info.isInternal)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: _InfoBlock(
                        label: encounters.length > 1
                            ? 'Dernières rencontres'
                            : 'Dernière rencontre',
                        child: encounters.isEmpty
                            ? Text(
                                'Première confrontation : aucun précédent '
                                'enregistré.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).hintColor,
                                ),
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var index = 0;
                                      index < encounters.length;
                                      index++) ...[
                                    if (index > 0)
                                      const SizedBox(
                                        width: AppSpacing.microGap,
                                      ),
                                    Expanded(
                                      child: _EncounterChip(
                                        encounter: encounters[index],
                                      ),
                                    ),
                                  ],
                                  // Cases vides : chaque score garde la
                                  // largeur qu'il aurait avec cinq
                                  // rencontres, même s'il est seul.
                                  for (var index = encounters.length;
                                      index < _encounterSlots;
                                      index++) ...[
                                    const SizedBox(width: AppSpacing.microGap),
                                    const Expanded(child: SizedBox.shrink()),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

const _valueStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);

/// Nombre de dernières rencontres affichées sur une ligne.
const _encounterSlots = 5;

/// Petit libellé discret au-dessus d'une valeur plus grande : la taille et la
/// couleur portent la hiérarchie (le texte reste en graisse normale).
class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.textFaint,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w400,
              ),
        ),
        const SizedBox(height: AppSpacing.contentGap),
        child,
      ],
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
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              encounter.scoreLabel,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
            ),
          ),
          if (dateLabel != null) ...[
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                dateLabel,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
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
