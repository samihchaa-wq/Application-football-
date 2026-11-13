# Contrôles Flutter — lot 8

Fichiers lus 12/12; positions 85–96/181. Occurrences 71. Contrôles sources, pas boutons rendus ; aucune interaction à l'écran : **NON VÉRIFIÉ**.

| ID | Constructeur | Fichier/ligne | Extrait | Test écran |
|---|---|---|---|---|
| UI-8-1 | IconButton | `lib/features/match_live/presentation/widgets/match_live_notification_bell.dart:122` | child: IconButton( tooltip: label, | **NON VÉRIFIÉ** |
| UI-8-2 | ListTile | `lib/features/match_live/presentation/widgets/match_live_remove_player_sheet.dart:58` | ListTile( leading: const Icon(Icons.person_remove_rounded), | **NON VÉRIFIÉ** |
| UI-8-3 | TextButton | `lib/features/match_live/presentation/widgets/match_live_remove_player_sheet.dart:83` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-8-4 | FilledButton | `lib/features/match_live/presentation/widgets/match_live_remove_player_sheet.dart:87` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-8-5 | TextButton.icon | `lib/features/match_live/presentation/widgets/match_live_scorer_picker_dialog.dart:60` | TextButton.icon( onPressed: () => Navigator.of(context).pop(), | **NON VÉRIFIÉ** |
| UI-8-6 | ListTile | `lib/features/match_live/presentation/widgets/match_live_scorer_picker_dialog.dart:69` | ListTile( leading: Icon(extraChoiceIcon), | **NON VÉRIFIÉ** |
| UI-8-7 | ListTile | `lib/features/match_live/presentation/widgets/match_live_scorer_picker_dialog.dart:76` | ListTile( leading: Icon(clearChoiceIcon), | **NON VÉRIFIÉ** |
| UI-8-8 | ListTile | `lib/features/match_live/presentation/widgets/match_live_scorer_picker_dialog.dart:90` | return ListTile( leading: playerLeading ?? Icon(icon), | **NON VÉRIFIÉ** |
| UI-8-9 | IconButton | `lib/features/matches/presentation/calendar_entry_form_page.dart:229` | IconButton( tooltip: 'Supprimer l’événement', | **NON VÉRIFIÉ** |
| UI-8-10 | ListTile | `lib/features/matches/presentation/calendar_entry_form_page.dart:252` | const ListTile( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-8-11 | DropdownButtonFormField | `lib/features/matches/presentation/calendar_entry_form_page.dart:259` | DropdownButtonFormField<String>( initialValue: _seasonId.isEmpty ? null : _seasonId, | **NON VÉRIFIÉ** |
| UI-8-12 | FilledButton.icon | `lib/features/matches/presentation/calendar_entry_form_page.dart:289` | FilledButton.icon( onPressed: isAdmin && !busy ? _submit : null, | **NON VÉRIFIÉ** |
| UI-8-13 | OutlinedButton.icon | `lib/features/matches/presentation/calendar_entry_form_page.dart:302` | OutlinedButton.icon( style: OutlinedButton.styleFrom( | **NON VÉRIFIÉ** |
| UI-8-14 | OutlinedButton.styleFrom | `lib/features/matches/presentation/calendar_entry_form_page.dart:303` | style: OutlinedButton.styleFrom( foregroundColor: Theme.of(context).colorScheme.error, | **NON VÉRIFIÉ** |
| UI-8-15 | TextFormField | `lib/features/matches/presentation/calendar_entry_form_page.dart:319` | TextFormField( controller: _eventTitleController, | **NON VÉRIFIÉ** |
| UI-8-16 | TextFormField | `lib/features/matches/presentation/calendar_entry_form_page.dart:338` | TextFormField( controller: _addressController, | **NON VÉRIFIÉ** |
| UI-8-17 | TextFormField | `lib/features/matches/presentation/calendar_entry_form_page.dart:461` | return TextFormField( controller: textController, | **NON VÉRIFIÉ** |
| UI-8-18 | OutlinedButton.icon | `lib/features/matches/presentation/calendar_entry_form_page.dart:512` | child: OutlinedButton.icon( style: OutlinedButton.styleFrom( | **NON VÉRIFIÉ** |
| UI-8-19 | OutlinedButton.styleFrom | `lib/features/matches/presentation/calendar_entry_form_page.dart:513` | style: OutlinedButton.styleFrom( minimumSize: const Size.fromHeight(56), | **NON VÉRIFIÉ** |
| UI-8-20 | TextFormField | `lib/features/matches/presentation/calendar_entry_form_page.dart:576` | TextFormField( controller: _addressController, | **NON VÉRIFIÉ** |
| UI-8-21 | CheckboxListTile | `lib/features/matches/presentation/calendar_entry_form_page.dart:591` | CheckboxListTile( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-8-22 | ListTile | `lib/features/matches/presentation/calendar_entry_form_page.dart:672` | ListTile( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-8-23 | ListTile | `lib/features/matches/presentation/calendar_entry_form_page.dart:716` | Widget _dateTile({required bool busy}) => ListTile( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-8-24 | ListTile | `lib/features/matches/presentation/calendar_entry_form_page.dart:724` | Widget _timeTile({required bool busy}) => ListTile( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-8-25 | TextField | `lib/features/matches/presentation/calendar_entry_form_page.dart:823` | content: TextField( controller: controller, | **NON VÉRIFIÉ** |
| UI-8-26 | TextButton | `lib/features/matches/presentation/calendar_entry_form_page.dart:829` | TextButton( onPressed: () => Navigator.pop(dialogContext), | **NON VÉRIFIÉ** |
| UI-8-27 | FilledButton | `lib/features/matches/presentation/calendar_entry_form_page.dart:833` | FilledButton( onPressed: () => Navigator.pop(dialogContext, controller.text), | **NON VÉRIFIÉ** |
| UI-8-28 | TextButton | `lib/features/matches/presentation/calendar_entry_form_page.dart:857` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-8-29 | FilledButton | `lib/features/matches/presentation/calendar_entry_form_page.dart:861` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-8-30 | TextButton | `lib/features/matches/presentation/calendar_entry_form_page.dart:1132` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-8-31 | FilledButton | `lib/features/matches/presentation/calendar_entry_form_page.dart:1136` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-8-32 | FilledButton | `lib/features/matches/presentation/calendar_entry_form_page.dart:1272` | return FilledButton( style: style.copyWith( | **NON VÉRIFIÉ** |
| UI-8-33 | OutlinedButton | `lib/features/matches/presentation/calendar_entry_form_page.dart:1282` | return OutlinedButton( style: style, | **NON VÉRIFIÉ** |
| UI-8-34 | ListTile | `lib/features/matches/presentation/calendar_matches_view.dart:256` | ListTile( leading: const Icon(Icons.calendar_month_rounded), | **NON VÉRIFIÉ** |
| UI-8-35 | ListTile | `lib/features/matches/presentation/calendar_matches_view.dart:263` | ListTile( leading: const Icon(Icons.event_rounded), | **NON VÉRIFIÉ** |
| UI-8-36 | ListTile | `lib/features/matches/presentation/calendar_matches_view.dart:272` | ListTile( leading: const Icon(Icons.mail_outline_rounded), | **NON VÉRIFIÉ** |
| UI-8-37 | ListTile | `lib/features/matches/presentation/calendar_matches_view.dart:279` | ListTile( leading: const Icon(Icons.link_rounded), | **NON VÉRIFIÉ** |
| UI-8-38 | SegmentedButton | `lib/features/matches/presentation/calendar_matches_widgets.dart:44` | final modeSelector = SegmentedButton<_CalendarDisplayMode>( showSelectedIcon: false, | **NON VÉRIFIÉ** |
| UI-8-39 | IconButton.outlined | `lib/features/matches/presentation/calendar_matches_widgets.dart:65` | final exportIconButton = IconButton.outlined( onPressed: onExport, | **NON VÉRIFIÉ** |
| UI-8-40 | IconButton.outlined | `lib/features/matches/presentation/calendar_matches_widgets.dart:70` | final createIconButton = IconButton.outlined( onPressed: onCreate, | **NON VÉRIFIÉ** |
| UI-8-41 | IconButton | `lib/features/matches/presentation/calendar_matches_widgets.dart:191` | IconButton( tooltip: previousTooltip, | **NON VÉRIFIÉ** |
| UI-8-42 | IconButton | `lib/features/matches/presentation/calendar_matches_widgets.dart:205` | IconButton( tooltip: nextTooltip, | **NON VÉRIFIÉ** |
| UI-8-43 | IconButton | `lib/features/matches/presentation/calendar_matches_widgets.dart:440` | ? IconButton( tooltip: 'Modifier l’événement', | **NON VÉRIFIÉ** |
| UI-8-44 | InkWell | `lib/features/matches/presentation/calendar_matches_widgets.dart:544` | child: InkWell( onTap: _onTap(context, phase), | **NON VÉRIFIÉ** |
| UI-8-45 | TextButton | `lib/features/matches/presentation/historical_match_detail_page.dart:323` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-8-46 | FilledButton | `lib/features/matches/presentation/historical_match_detail_page.dart:327` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-8-47 | TextButton.icon | `lib/features/matches/presentation/historical_match_detail_page.dart:359` | child: TextButton.icon( key: const Key('historical-match-delete'), | **NON VÉRIFIÉ** |
| UI-8-48 | TextField | `lib/features/matches/presentation/history_entry_page.dart:109` | content: TextField( key: const Key('history-former-player-name'), | **NON VÉRIFIÉ** |
| UI-8-49 | TextButton | `lib/features/matches/presentation/history_entry_page.dart:121` | TextButton( onPressed: () => Navigator.pop(dialogContext), | **NON VÉRIFIÉ** |
| UI-8-50 | FilledButton | `lib/features/matches/presentation/history_entry_page.dart:125` | FilledButton( onPressed: () => Navigator.pop(dialogContext, controller.text), | **NON VÉRIFIÉ** |
| UI-8-51 | FilledButton | `lib/features/matches/presentation/history_entry_page.dart:226` | FilledButton(onPressed: _load, child: const Text('Réessayer')), ], | **NON VÉRIFIÉ** |
| UI-8-52 | FilledButton | `lib/features/matches/presentation/history_entry_page.dart:279` | FilledButton( key: const Key('history-save'), | **NON VÉRIFIÉ** |
| UI-8-53 | OutlinedButton | `lib/features/matches/presentation/history_entry_page.dart:285` | OutlinedButton( key: const Key('history-save-next'), | **NON VÉRIFIÉ** |
| UI-8-54 | TextField | `lib/features/matches/presentation/history_entry_page.dart:329` | return TextField( key: const Key('history-opponent'), | **NON VÉRIFIÉ** |
| UI-8-55 | ListTile | `lib/features/matches/presentation/history_entry_page.dart:356` | ListTile( title: Text(option), | **NON VÉRIFIÉ** |
| UI-8-56 | OutlinedButton.icon | `lib/features/matches/presentation/history_entry_page.dart:368` | OutlinedButton.icon( key: const Key('history-date'), | **NON VÉRIFIÉ** |
| UI-8-57 | SegmentedButton | `lib/features/matches/presentation/history_entry_page.dart:375` | SegmentedButton<bool>( key: const Key('history-home'), | **NON VÉRIFIÉ** |
| UI-8-58 | SegmentedButton | `lib/features/matches/presentation/history_entry_page.dart:386` | SegmentedButton<bool>( key: const Key('history-type'), | **NON VÉRIFIÉ** |
| UI-8-59 | TextField | `lib/features/matches/presentation/history_entry_page.dart:397` | TextField( key: const Key('history-address'), | **NON VÉRIFIÉ** |
| UI-8-60 | FilterChip | `lib/features/matches/presentation/history_entry_page.dart:449` | FilterChip( key: ValueKey('history-present-${player.key}'), | **NON VÉRIFIÉ** |
| UI-8-61 | ActionChip | `lib/features/matches/presentation/history_entry_page.dart:455` | ActionChip( key: const Key('history-add-former'), | **NON VÉRIFIÉ** |
| UI-8-62 | IconButton | `lib/features/matches/presentation/history_entry_page.dart:494` | IconButton( icon: const Icon(Icons.remove_circle_outline), | **NON VÉRIFIÉ** |
| UI-8-63 | IconButton | `lib/features/matches/presentation/history_entry_page.dart:510` | IconButton( key: ValueKey('history-goals-plus-${player.key}'), | **NON VÉRIFIÉ** |
| UI-8-64 | ChoiceChip | `lib/features/matches/presentation/history_entry_page.dart:540` | ChoiceChip( key: ValueKey('history-motm-${player.key}'), | **NON VÉRIFIÉ** |
| UI-8-65 | ExpansionTile | `lib/features/matches/presentation/history_entry_page.dart:559` | child: ExpansionTile( key: const Key('history-composition'), | **NON VÉRIFIÉ** |
| UI-8-66 | DropdownButtonFormField | `lib/features/matches/presentation/history_entry_page.dart:571` | DropdownButtonFormField<String?>( key: const Key('history-formation'), | **NON VÉRIFIÉ** |
| UI-8-67 | DropdownButton | `lib/features/matches/presentation/history_entry_page.dart:617` | child: DropdownButton<HistoryPlayer?>( key: ValueKey('history-slot-${slot.label}'), | **NON VÉRIFIÉ** |
| UI-8-68 | IconButton | `lib/features/matches/presentation/history_entry_page.dart:674` | IconButton( icon: const Icon(Icons.remove_circle_outline), | **NON VÉRIFIÉ** |
| UI-8-69 | IconButton | `lib/features/matches/presentation/history_entry_page.dart:679` | IconButton( icon: const Icon(Icons.add_circle_outline), | **NON VÉRIFIÉ** |
| UI-8-70 | FilledButton.icon | `lib/features/matches/presentation/match_details_page.dart:243` | child: FilledButton.icon( onPressed: () => context.push('/matches/$matchId/finalize'), | **NON VÉRIFIÉ** |
| UI-8-71 | InkWell | `lib/features/matches/presentation/match_details_page.dart:485` | child: InkWell( onTap: onTap, | **NON VÉRIFIÉ** |

Sans constructeur détecté : 
- `lib/features/match_live/presentation/widgets/match_live_clock.dart` : NON VÉRIFIÉ
- `lib/features/match_live/presentation/widgets/substitution_salvo_frame.dart` : NON VÉRIFIÉ
- `lib/features/matches/presentation/match_encounter_route.dart` : NON VÉRIFIÉ
