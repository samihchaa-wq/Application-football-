import 'package:petit_filet/core/theme/pf_card_border.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/theme/calendar_card_palette.dart';
import 'package:petit_filet/core/widgets/calendar_scoreline.dart';
import 'package:petit_filet/features/matches/data/club_events_repository.dart';
import 'package:petit_filet/features/matches/domain/club_event.dart';
import 'package:petit_filet/features/matches/presentation/calendar_entry_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Carte événement dédiée au flux « Défilé » du calendrier.
class CalendarFeedEventCard extends ConsumerWidget {
  const CalendarFeedEventCard({
    super.key,
    required this.event,
    this.isAdmin = false,
  });

  final ClubEvent event;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> edit() async {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => CalendarEntryFormPage(event: event)),
      );
      if (changed != true) return;

      // CalendarEntryFormPage invalide déjà clubEventsProvider après une
      // mutation réussie. Attendre le snapshot rafraîchi suffit : la liste
      // conserve alors naturellement son viewport autour de la carte retirée.
      //
      // Ne surtout pas déclencher matchesFocusRequestProvider ici : ce signal
      // sert à un recentrage global du calendrier et peut envoyer l'utilisateur
      // loin de l'événement qu'il vient de supprimer.
      await ref.read(clubEventsProvider.future);
    }

    final editButton = isAdmin
        ? IconButton(
            tooltip: 'Modifier l’événement',
            onPressed: edit,
            color: CalendarCardPalette.eventBorder,
            icon: const Icon(Icons.edit_outlined),
          )
        : null;

    return Card(
      color: CalendarCardPalette.eventSurface,
      shape: PfCardBorder(
          radius: AppTheme.radiusMd,
          borderColor: CalendarCardPalette.eventBorder,
          borderWidth: 1.2,
          tint: .16,
          stripe: true),
      clipBehavior: Clip.antiAlias,
      child: CalendarCardSections(
        header: CalendarDateLine(
          kickoffAt: event.startsAt,
          label: 'Événement',
        ),
        body: CalendarCenteredTitle(event.title),
        // Le crayon est en bas avec le lieu : la ligne du haut garde toute
        // sa largeur, comme sur les cartes de match.
        footerVerticalPadding:
            editButton == null ? null : CalendarCardFooter.actionsBandPadding,
        footer: editButton == null && event.location.trim().isEmpty
            ? null
            : CalendarCardFooter(
                address: event.location.trim().isEmpty
                    ? null
                    : CalendarAddressLine(event.location),
                actions: editButton,
              ),
      ),
    );
  }
}
