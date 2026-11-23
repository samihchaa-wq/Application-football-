import 'package:petit_filet/core/theme/pf_card_border.dart';
import 'package:petit_filet/core/club/club_identity.dart';
import 'package:petit_filet/core/theme/app_spacing.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/theme/calendar_card_palette.dart';
import 'package:petit_filet/core/widgets/match_address_sheet.dart';
import 'package:petit_filet/core/widgets/match_date_column.dart';
import 'package:petit_filet/core/widgets/calendar_scoreline.dart';
import 'package:petit_filet/features/match_live/data/match_live_notification_repository.dart';
import 'package:petit_filet/features/match_live/presentation/widgets/match_live_notification_bell.dart';
import 'package:petit_filet/features/matches/domain/match_model.dart';
import 'package:petit_filet/features/matches/presentation/widgets/admin_match_options_button.dart';
import 'package:petit_filet/features/sports_management/presentation/widgets/match_availability_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carte d'un match actif, réutilisable pour « Prochain », « En direct »
/// et « À valider », avec le même rendu que les autres matchs du calendrier.
class HomeNextMatchCard extends ConsumerWidget {
  const HomeNextMatchCard({
    required this.match,
    required this.isAdmin,
    this.initialSection = 'info',
    this.showAvailability = true,
    super.key,
  });

  final MatchModel match;
  final bool isAdmin;
  final String initialSection;
  final bool showAvailability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opponent = match.opponentName ?? 'Adversaire';
    final homeName = match.isHome ? ClubIdentity.name : opponent;
    final awayName = match.isHome ? opponent : ClubIdentity.name;
    final cardSurface = CalendarCardPalette.matchSurface(match.matchType);
    final cardBorder = CalendarCardPalette.matchBorder(match.matchType);
    final canHaveGoalAlerts = !match.isInternal &&
        !match.isCancelled &&
        !match.isFinished &&
        !match.isLiveSessionFinished;
    final goalAlertStatus = canHaveGoalAlerts
        ? ref.watch(matchLiveNotificationStatusProvider(match.id)).valueOrNull
        : null;
    final showGoalBell = goalAlertStatus?.eligible == true;

    // Les actions appartiennent au bandeau de date, pas à la ligne des équipes.
    // Même implantation que les autres cartes du calendrier.
    final actionWidgets = <Widget>[
      if (showGoalBell)
        SizedBox.square(
          dimension: CalendarCardActionsOverlay.actionExtent,
          child: MatchLiveNotificationBell(
            matchId: match.id,
            subscribed: goalAlertStatus!.subscribed,
          ),
        ),
      if (isAdmin && AdminMatchOptionsButton.hasOptions(match))
        SizedBox.square(
          dimension: CalendarCardActionsOverlay.actionExtent,
          child: IconTheme(
            data: IconThemeData(color: cardBorder),
            child: AdminMatchOptionsButton(match: match),
          ),
        ),
    ];
    final actionCount = actionWidgets.length;
    final cardActions = actionWidgets.isEmpty
        ? null
        : Row(mainAxisSize: MainAxisSize.min, children: actionWidgets);

    final fixtureRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: match.isInternal
              ? Text(
                  'Match entre nous',
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textPrimary,
                      ),
                )
              : CalendarScoreline(
                  homeName: homeName,
                  awayName: awayName,
                  ownIsHome: match.isHome,
                  foreground: AppTheme.textPrimary,
                ),
        ),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppTheme.textFaint,
        ),
      ],
    );

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.cardPadding,
        12,
        AppSpacing.cardPadding,
        13,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MatchDateHeader(
            kickoffAt: match.kickoffAt,
            foreground: AppTheme.textPrimary,
            secondary: AppTheme.textPrimary,
            dividerColor: cardBorder,
            dateEndInset: CalendarCardActionsOverlay.dateInsetFor(actionCount),
            child: fixtureRow,
          ),
          const SizedBox(height: 7),
          Text(
            match.calendarTypeLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cardBorder,
                  fontWeight: FontWeight.w400,
                ),
          ),
          if (match.address case final address?) ...[
            const SizedBox(height: AppSpacing.contentGap),
            InkWell(
              onTap: () => showMatchAddressSheet(context, address),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.place_outlined, size: 16, color: cardBorder),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (showAvailability)
            MatchAvailabilitySelector(
              matchId: match.id,
              embeddedOnDark: true,
              topSpacing: 10,
            ),
        ],
      ),
    );

    return Card(
      color: cardSurface,
      shape: PfCardBorder(
          radius: AppTheme.radiusMd, borderColor: cardBorder, borderWidth: 1.2),
      clipBehavior: Clip.antiAlias,
      child: CalendarCardActionsOverlay(
        actions: cardActions,
        actionsWidth: actionCount * CalendarCardActionsOverlay.actionExtent,
        child: InkWell(
          onTap: () => context.push(
            '/matches/${match.id}/lineup?section=$initialSection',
          ),
          child: content,
        ),
      ),
    );
  }
}
