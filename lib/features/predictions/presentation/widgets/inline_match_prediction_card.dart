import 'package:petit_filet/core/club/club_identity.dart';
import 'package:petit_filet/core/club/club_rules.dart';
import 'package:petit_filet/core/theme/app_spacing.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:petit_filet/core/utils/app_formats.dart';
import 'package:petit_filet/features/matches/data/match_details_repository.dart';
import 'package:petit_filet/features/matches/presentation/match_encounter_route.dart';
import 'package:petit_filet/features/matches/presentation/widgets/match_result_score_chip.dart';
import 'package:petit_filet/features/notifications/data/notification_inbox_repository.dart';
import 'package:petit_filet/features/predictions/data/predictions_repository.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petit_filet/core/widgets/pf_loader.dart';

const Color _pfOddAccent = Color(0xFF1B8A4B);
const Color _opponentOddAccent = Color(0xFFC62A3B);

Color predictionOddAccentForSide({
  required bool isHomeSide,
  required bool isOwnHome,
}) {
  return isHomeSide == isOwnHome ? _pfOddAccent : _opponentOddAccent;
}

final inlineMatchPredictionProvider = FutureProvider.autoDispose
    .family<MatchPredictionItem?, String>((ref, matchId) {
  return ref.watch(predictionsRepositoryProvider).fetchMatchPrediction(matchId);
});

class InlineMatchPredictionCard extends ConsumerStatefulWidget {
  const InlineMatchPredictionCard({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<InlineMatchPredictionCard> createState() =>
      _InlineMatchPredictionCardState();
}

class _InlineMatchPredictionCardState
    extends ConsumerState<InlineMatchPredictionCard> {
  int? _scoreOwn;
  int? _scoreOpponent;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    // Pronostics désactivés par l'administrateur du club : rien n'est affiché.
    if (!ref.watch(clubModuleEnabledProvider(ClubModule.predictions))) {
      return const SizedBox.shrink();
    }
    final prediction = ref.watch(inlineMatchPredictionProvider(widget.matchId));
    final details = ref.watch(matchDetailsProvider(widget.matchId));

    return prediction.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.cardPadding),
          child: Center(child: PfProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Text(humanizeError(error)),
        ),
      ),
      data: (item) {
        if (item == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.cardPadding),
              child: Text('Ce match est introuvable.'),
            ),
          );
        }

        _scoreOwn ??= item.scoreOwn;
        _scoreOpponent ??= item.scoreOpponent;

        final own = _scoreOwn ?? item.scoreOwn;
        final opponent = _scoreOpponent ?? item.scoreOpponent;
        final now = DateTime.now();
        final notOpenYet = now.isBefore(item.opensAt);
        final closed = !notOpenYet && !item.canEditAt(now);
        final canEdit = !notOpenYet && !closed && !_saving;

        final pfPicker = Expanded(
          child: _ScorePicker(
            label: ClubIdentity.name,
            value: own,
            enabled: canEdit,
            onMinus: () => setState(() {
              if (own > 0) _scoreOwn = own - 1;
            }),
            onPlus: () => setState(() => _scoreOwn = own + 1),
          ),
        );
        final opponentPicker = Expanded(
          child: _ScorePicker(
            label: item.opponentName,
            value: opponent,
            enabled: canEdit,
            onMinus: () => setState(() {
              if (opponent > 0) _scoreOpponent = opponent - 1;
            }),
            onPlus: () => setState(() => _scoreOpponent = opponent + 1),
          ),
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.primaryBright, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _StatusChip(
                  item: item,
                  notOpenYet: notOpenYet,
                  closed: closed,
                ),
              ),
              const SizedBox(height: AppSpacing.contentGap),
              details.when(
                loading: () => const Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: PfProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => const Text(
                  'Historique des confrontations momentanément indisponible.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                data: (data) => _HeadToHead(data: data),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sectionGap),
              Row(
                children: [
                  if (item.isHome) pfPicker else opponentPicker,
                  const Text('–'),
                  if (item.isHome) opponentPicker else pfPicker,
                ],
              ),
              // Club sans cotes : chaque issue vaut 1, inutile de l’afficher.
              if (!ClubRules.oddsDisabled) ...[
                const SizedBox(height: AppSpacing.sectionGap),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sectionGap),
                Row(
                  children: [
                    Expanded(
                      child: _Odd(
                        label: '1',
                        value: AppFormats.odds(
                          item.isHome ? item.oddsWin : item.oddsLoss,
                        ),
                        selected: item.isHome ? own > opponent : opponent > own,
                        accent: predictionOddAccentForSide(
                          isHomeSide: true,
                          isOwnHome: item.isHome,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.contentGap),
                    Expanded(
                      child: _Odd(
                        label: 'N',
                        value: AppFormats.odds(item.oddsDraw),
                        selected: own == opponent,
                        accent: const Color(0xFFB4610D),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.contentGap),
                    Expanded(
                      child: _Odd(
                        label: '2',
                        value: AppFormats.odds(
                          item.isHome ? item.oddsLoss : item.oddsWin,
                        ),
                        selected: item.isHome ? own < opponent : opponent < own,
                        accent: predictionOddAccentForSide(
                          isHomeSide: false,
                          isOwnHome: item.isHome,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sectionGap),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: canEdit ? () => _save(item) : null,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: PfProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
                ),
              ),
              if (notOpenYet || closed) ...[
                const SizedBox(height: AppSpacing.contentGap),
                Text(
                  notOpenYet
                      ? 'Disponible à partir de J−${ClubRules.featuresOpenDays} '
                          'à ${ClubRules.featuresOpenHour} h, heure de Paris.'
                      : _closedReason(item.status) ??
                          (ClubRules.liveEnabled
                              ? 'Pronostic fermé : le Live est désormais ouvert.'
                              : 'Pronostic fermé.'),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _save(MatchPredictionItem item) async {
    setState(() => _saving = true);
    try {
      await ref.read(predictionsRepositoryProvider).savePrediction(
            matchId: item.matchId,
            scoreOwn: _scoreOwn ?? item.scoreOwn,
            scoreOpponent: _scoreOpponent ?? item.scoreOpponent,
          );
      ref
        ..invalidate(inlineMatchPredictionProvider(widget.matchId))
        ..invalidate(matchDetailsProvider(widget.matchId))
        // Le rappel de pronostic devient lu.
        ..invalidate(unreadNotificationCountProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pronostic enregistré.')));
      }
    } on PredictionWriteOutcomeUnknown {
      // L'écriture a peut-être abouti : annoncer un échec pousserait à
      // ressaisir un pronostic déjà enregistré.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Connexion interrompue : ton pronostic a peut-être été '
              'enregistré. Actualise la page avant de réessayer.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(humanizeError(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Raison affichée quand le pronostic est fermé parce que le match n'aura
/// plus lieu ou est fini : « le Live est ouvert » serait faux.
String? _closedReason(String status) => switch (status) {
      'termine' || 'archive' => 'Pronostic fermé : match terminé.',
      'annule' => 'Pronostic fermé : match annulé.',
      _ => null,
    };

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.item,
    required this.notOpenYet,
    required this.closed,
  });

  final MatchPredictionItem item;
  final bool notOpenYet;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    final saved = item.isFilled;
    final label = notOpenYet
        ? 'Pas encore ouvert'
        : closed
            ? 'Fermé'
            : saved
                ? 'Enregistré'
                : 'À saisir';
    final highlighted = saved && !notOpenYet && !closed;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.compactCardPadding,
        vertical: AppSpacing.contentGap,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFF1B8A4B).withValues(alpha: .10)
            : AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF1B8A4B).withValues(alpha: .34)
              : AppTheme.outline,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted ? const Color(0xFF157A3F) : AppTheme.textSecondary,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _HeadToHead extends StatelessWidget {
  const _HeadToHead({required this.data});

  final MatchDetailsData data;

  @override
  Widget build(BuildContext context) {
    const slots = 5;
    final matches = data.headToHead.take(slots).toList();
    final chips = <Widget>[];
    for (final match in matches) {
      final route = matchEncounterRoute(
        encounterId: match.id,
        isHistorical: match.isHistorical,
      );
      final dateLabel = AppFormats.date(match.date);
      if (chips.isNotEmpty) {
        chips.add(const SizedBox(width: 5));
      }
      chips.add(
        Expanded(
          child: MatchResultScoreChip(
            scoreOwn: match.scoreOwn ?? 0,
            scoreOpponent: match.scoreOpponent ?? 0,
            subtitle: dateLabel,
            semanticLabel:
                route == null ? null : 'Ouvrir le match du $dateLabel',
            onTap: route == null ? null : () => context.push(route),
          ),
        ),
      );
    }
    // Cases vides pour garder la même largeur de score qu'avec cinq
    // confrontations, même s'il n'y en a qu'une.
    for (var i = matches.length; i < slots; i++) {
      chips
        ..add(const SizedBox(width: 5))
        ..add(const Expanded(child: SizedBox.shrink()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (matches.isEmpty)
          const Text(
            'Aucune confrontation précédente.',
            style: TextStyle(color: AppTheme.textSecondary),
          )
        else
          Row(children: chips),
      ],
    );
  }
}

class _ScorePicker extends StatelessWidget {
  const _ScorePicker({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final int value;
  final bool enabled;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Retirer un but pour $label',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              onPressed: enabled && value > 0 ? onMinus : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$value',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w400),
            ),
            IconButton(
              tooltip: 'Ajouter un but pour $label',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              onPressed: enabled && value < 99 ? onPlus : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}

class _Odd extends StatelessWidget {
  const _Odd({
    required this.label,
    required this.value,
    required this.selected,
    required this.accent,
  });

  final String label;
  final String value;
  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.contentGap),
      decoration: BoxDecoration(
        color: selected ? accent.withValues(alpha: .16) : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? accent : AppTheme.outline,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: selected ? accent : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: selected ? accent : null,
            ),
          ),
        ],
      ),
    );
  }
}
