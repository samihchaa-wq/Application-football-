import 'dart:async';

import 'package:flutter/material.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/utils/app_formats.dart';
import 'package:petit_filet/core/widgets/calendar_scoreline.dart';
import 'package:petit_filet/core/widgets/match_address_sheet.dart';
import 'package:petit_filet/features/matches/domain/match_model.dart';

/// Corps de la carte « prochain match » : point focal du calendrier.
class NextMatchHeroBody extends StatefulWidget {
  const NextMatchHeroBody({
    super.key,
    required this.match,
    required this.homeName,
    required this.awayName,
    required this.actionInset,
    required this.address,
    required this.availability,
  });

  final MatchModel match;
  final String homeName;
  final String awayName;
  final double actionInset;
  final String? address;
  final Widget? availability;

  static String countdown(DateTime kickoff, DateTime now) {
    final diff = kickoff.difference(now);
    if (diff.isNegative) return 'En cours';
    if (diff.inMinutes < 60) return 'Dans ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Dans ${diff.inHours} h';
    final days = DateTime(kickoff.year, kickoff.month, kickoff.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days == 1) return 'Demain';
    return 'Dans $days jours';
  }

  @override
  State<NextMatchHeroBody> createState() => _NextMatchHeroBodyState();
}

class _NextMatchHeroBodyState extends State<NextMatchHeroBody> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Le compte à rebours se met à jour tout seul, sans attendre un autre
    // rafraîchissement de l'écran.
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final homeName = widget.homeName;
    final awayName = widget.awayName;
    final actionInset = widget.actionInset;
    final address = widget.address;
    final availability = widget.availability;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final kickoff = match.kickoffAt.toLocal();
    final opponent = match.opponentName ?? 'Adversaire';
    final venue = match.isHome ? 'À domicile' : 'À l’extérieur';
    final addr = address;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(accent.withValues(alpha: .38), AppTheme.surface),
            AppTheme.surface,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(end: actionInset),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'PROCHAIN MATCH',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      child: Text(
                        NextMatchHeroBody.countdown(kickoff, DateTime.now()),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    opponent,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: 30,
                      height: 1.05,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppFormats.time(kickoff),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${match.isHome ? homeName : awayName} · $venue · '
              '${AppFormats.calendarDateTimeLong(kickoff, includeTime: false)}'
              '${match.calendarTypeLabel.isEmpty ? '' : ' · ${match.calendarTypeLabel}'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            if (addr != null && addr.isNotEmpty) ...[
              const SizedBox(height: 4),
              CalendarAddressLine(
                addr,
                onTap: () => showMatchAddressSheet(context, addr),
              ),
            ],
            if (availability != null) ...[
              const SizedBox(height: 14),
              availability,
            ],
          ],
        ),
      ),
    );
  }
}
