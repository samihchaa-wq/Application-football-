import 'package:petit_filet/core/club/club_identity.dart';
import 'package:petit_filet/core/theme/calendar_card_palette.dart';
import 'package:petit_filet/core/widgets/calendar_scoreline.dart';
import 'package:petit_filet/core/widgets/match_address_sheet.dart';
import 'package:petit_filet/features/matches/data/calendar_history_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Carte de rencontre en lecture seule pour un match de l'historique importé.
/// Un tap ouvre la fiche archivée (composition, buteurs, HDM) quand elle
/// existe ; ces rencontres n'ont ni pronostics ni vote HDM en base.
class HistoricalMatchCard extends StatelessWidget {
  const HistoricalMatchCard({required this.match, super.key});

  final HistoricalMatchResult match;

  @override
  Widget build(BuildContext context) {
    final isHome = match.isHome;
    final homeName = isHome ? ClubIdentity.name : match.opponentName;
    final awayName = isHome ? match.opponentName : ClubIdentity.name;
    final homeScore = isHome ? match.ownScore : match.opponentScore;
    final awayScore = isHome ? match.opponentScore : match.ownScore;
    final cleanAddress = match.address?.trim();
    final surface = CalendarCardPalette.matchSurface(
      match.matchType,
      unknownAsFinished: true,
    );
    final border = CalendarCardPalette.matchBorder(
      match.matchType,
      unknownAsFinished: true,
    );

    return Card(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border, width: 1.3),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/matches/history/${match.id}', extra: match),
        child: CalendarCardSections(
          header: CalendarDateLine(
            kickoffAt: match.date,
            showTime: match.hasTime,
            label: match.calendarTypeLabel,
          ),
          body: CalendarScoreline(
            homeName: homeName,
            awayName: awayName,
            ownIsHome: isHome,
            homeScore: homeScore,
            awayScore: awayScore,
            finished: true,
          ),
          footer: !match.hasKnownVenue
              ? const Text(
                  'Domicile / extérieur non renseigné',
                  textAlign: TextAlign.center,
                )
              : cleanAddress != null && cleanAddress.isNotEmpty
                  ? CalendarAddressLine(
                      cleanAddress,
                      onTap: () => showMatchAddressSheet(context, cleanAddress),
                    )
                  : null,
        ),
      ),
    );
  }
}
