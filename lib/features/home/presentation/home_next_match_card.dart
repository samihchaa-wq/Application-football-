import 'package:petit_filet/core/theme/pf_card_border.dart';
import 'package:petit_filet/core/club/club_identity.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/theme/calendar_card_palette.dart';
import 'package:petit_filet/core/widgets/match_address_sheet.dart';
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

    // Cloche et crayon sous l'affiche, à droite : la ligne du haut garde toute
    // sa largeur pour « date • heure • Championnat · J10 », comme les autres
    // cartes du calendrier.
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
    final cardActions = actionWidgets.isEmpty
        ? null
        : Row(mainAxisSize: MainAxisSize.min, children: actionWidgets);

    final fixture = match.isInternal
        ? const CalendarCenteredTitle('Match entre nous')
        : CalendarScoreline(
            homeName: homeName,
            awayName: awayName,
            ownIsHome: match.isHome,
            foreground: AppTheme.textPrimary,
          );

    final address = match.address?.trim();
    final hasAddress = address != null && address.isNotEmpty;

    // Même découpe que les autres cartes du calendrier : bandeau de date,
    // affiche au centre, bandeau du bas avec le lieu et les actions.
    final content = CalendarCardSections(
      header: CalendarDateLine(
        kickoffAt: match.kickoffAt,
        label: match.isInternal ? null : match.calendarTypeLabel,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          fixture,
          if (showAvailability)
            MatchAvailabilitySelector(
              matchId: match.id,
              embeddedOnDark: true,
              topSpacing: CalendarCardSpacing.line,
            ),
        ],
      ),
      footerVerticalPadding:
          cardActions == null ? null : CalendarCardFooter.actionsBandPadding,
      footer: cardActions != null || hasAddress
          ? CalendarCardFooter(
              address: hasAddress
                  ? CalendarAddressLine(
                      address,
                      onTap: () => showMatchAddressSheet(context, address),
                    )
                  : null,
              actions: cardActions,
            )
          : null,
    );

    return Card(
      color: cardSurface,
      shape: PfCardBorder(
          radius: AppTheme.radiusMd,
          borderColor: cardBorder,
          borderWidth: 1.2,
          stripe: true,
          flat: true),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          '/matches/${match.id}/lineup?section=$initialSection',
        ),
        child: content,
      ),
    );
  }
}
