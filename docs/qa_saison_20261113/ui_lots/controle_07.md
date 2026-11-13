# Contrôles Flutter — lot 7

Fichiers lus 12/12; positions 73–84/181. Occurrences 48. Contrôles sources, pas boutons rendus ; aucune interaction à l'écran : **NON VÉRIFIÉ**.

| ID | Constructeur | Fichier/ligne | Extrait | Test écran |
|---|---|---|---|---|
| UI-7-1 | InkWell | `lib/features/home/presentation/home_next_match_card.dart:131` | InkWell( onTap: () => showMatchAddressSheet(context, address), | **NON VÉRIFIÉ** |
| UI-7-2 | InkWell | `lib/features/home/presentation/home_next_match_card.dart:174` | child: InkWell( onTap: () => context.push( | **NON VÉRIFIÉ** |
| UI-7-3 | FilledButton.icon | `lib/features/match_live/presentation/match_live_pre_kickoff_page.dart:100` | FilledButton.icon( onPressed: _openWorkspaceIfNeeded, | **NON VÉRIFIÉ** |
| UI-7-4 | FilledButton.icon | `lib/features/match_live/presentation/match_live_pre_kickoff_page.dart:169` | FilledButton.icon( onPressed: _busy ? null : _confirmAndStart, | **NON VÉRIFIÉ** |
| UI-7-5 | IconButton.outlined | `lib/features/match_live/presentation/match_live_pre_kickoff_page.dart:196` | IconButton.outlined( tooltip: tooltip, | **NON VÉRIFIÉ** |
| UI-7-6 | TextField | `lib/features/match_live/presentation/match_live_pre_kickoff_page.dart:208` | child: TextField( controller: _durationController, | **NON VÉRIFIÉ** |
| UI-7-7 | DropdownButtonFormField | `lib/features/match_live/presentation/match_live_pre_kickoff_page.dart:217` | child: DropdownButtonFormField<String>( key: ValueKey('squad-formation-${lineup.formationCode}'), | **NON VÉRIFIÉ** |
| UI-7-8 | TextButton | `lib/features/match_live/presentation/match_live_pre_kickoff_page.dart:356` | TextButton( onPressed: () => Navigator.of(context).pop(false), | **NON VÉRIFIÉ** |
| UI-7-9 | FilledButton | `lib/features/match_live/presentation/match_live_pre_kickoff_page.dart:360` | FilledButton( onPressed: () => Navigator.of(context).pop(true), | **NON VÉRIFIÉ** |
| UI-7-10 | InkWell | `lib/features/match_live/presentation/match_live_running_journal.dart:48` | InkWell( borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), | **NON VÉRIFIÉ** |
| UI-7-11 | PopupMenuButton | `lib/features/match_live/presentation/match_live_running_journal.dart:225` | Widget actions() => PopupMenuButton<_JournalAction>( tooltip: 'Corriger', | **NON VÉRIFIÉ** |
| UI-7-12 | InkWell | `lib/features/match_live/presentation/match_live_running_journal.dart:331` | child: InkWell( borderRadius: BorderRadius.circular(6), | **NON VÉRIFIÉ** |
| UI-7-13 | DropdownButtonFormField | `lib/features/match_live/presentation/match_live_running_page.dart:263` | child: DropdownButtonFormField<String>( key: ValueKey('live-formation-${lineup.formationCode}'), | **NON VÉRIFIÉ** |
| UI-7-14 | OutlinedButton | `lib/features/match_live/presentation/match_live_running_page.dart:296` | child: OutlinedButton( onPressed: setupControlsDisabled | **NON VÉRIFIÉ** |
| UI-7-15 | OutlinedButton.styleFrom | `lib/features/match_live/presentation/match_live_running_page.dart:304` | style: OutlinedButton.styleFrom( padding: const EdgeInsets.symmetric(horizontal: 8), | **NON VÉRIFIÉ** |
| UI-7-16 | TextButton | `lib/features/match_live/presentation/match_live_running_page.dart:947` | TextButton( onPressed: () => Navigator.of(dialogContext).pop(false), | **NON VÉRIFIÉ** |
| UI-7-17 | FilledButton | `lib/features/match_live/presentation/match_live_running_page.dart:951` | FilledButton( onPressed: () => Navigator.of(dialogContext).pop(true), | **NON VÉRIFIÉ** |
| UI-7-18 | TextButton | `lib/features/match_live/presentation/match_live_running_page.dart:972` | TextButton( onPressed: () => Navigator.of(dialogContext).pop(false), | **NON VÉRIFIÉ** |
| UI-7-19 | FilledButton | `lib/features/match_live/presentation/match_live_running_page.dart:976` | FilledButton( onPressed: () => Navigator.of(dialogContext).pop(true), | **NON VÉRIFIÉ** |
| UI-7-20 | TextButton | `lib/features/match_live/presentation/match_live_running_page.dart:997` | TextButton( onPressed: () => Navigator.of(context).pop(false), | **NON VÉRIFIÉ** |
| UI-7-21 | FilledButton | `lib/features/match_live/presentation/match_live_running_page.dart:1001` | FilledButton( onPressed: () => Navigator.of(context).pop(true), | **NON VÉRIFIÉ** |
| UI-7-22 | TextButton | `lib/features/match_live/presentation/match_live_running_page.dart:1022` | TextButton( onPressed: () => Navigator.of(dialogContext).pop(false), | **NON VÉRIFIÉ** |
| UI-7-23 | FilledButton | `lib/features/match_live/presentation/match_live_running_page.dart:1026` | FilledButton( onPressed: () => Navigator.of(dialogContext).pop(true), | **NON VÉRIFIÉ** |
| UI-7-24 | FilledButton.styleFrom | `lib/features/match_live/presentation/match_live_running_page.dart:1028` | style: FilledButton.styleFrom( backgroundColor: Theme.of(dialogContext).colorScheme.error, | **NON VÉRIFIÉ** |
| UI-7-25 | IconButton.filled | `lib/features/match_live/presentation/match_live_running_widgets.dart:102` | ? IconButton.filled( tooltip: tooltip, | **NON VÉRIFIÉ** |
| UI-7-26 | IconButton.outlined | `lib/features/match_live/presentation/match_live_running_widgets.dart:110` | : IconButton.outlined( tooltip: tooltip, | **NON VÉRIFIÉ** |
| UI-7-27 | InkWell | `lib/features/match_live/presentation/match_live_running_widgets.dart:255` | child: InkWell( onTap: onPressed, | **NON VÉRIFIÉ** |
| UI-7-28 | FilledButton | `lib/features/match_live/presentation/match_live_running_widgets.dart:313` | FilledButton(onPressed: onChoose, child: const Text('Choisir')), ], | **NON VÉRIFIÉ** |
| UI-7-29 | InkWell | `lib/features/match_live/presentation/match_live_running_widgets.dart:343` | child: InkWell( onTap: onPressed, | **NON VÉRIFIÉ** |
| UI-7-30 | IconButton | `lib/features/match_live/presentation/match_live_running_widgets.dart:450` | IconButton( tooltip: 'Retirer un but à $fullName', | **NON VÉRIFIÉ** |
| UI-7-31 | IconButton | `lib/features/match_live/presentation/match_live_running_widgets.dart:472` | IconButton( tooltip: 'Ajouter un but à $fullName', | **NON VÉRIFIÉ** |
| UI-7-32 | IconButton | `lib/features/match_live/presentation/match_live_running_widgets.dart:652` | IconButton( tooltip: 'Annuler ce changement', | **NON VÉRIFIÉ** |
| UI-7-33 | OutlinedButton | `lib/features/match_live/presentation/match_live_running_widgets.dart:664` | child: OutlinedButton( onPressed: busy ? null : onClear, | **NON VÉRIFIÉ** |
| UI-7-34 | FilledButton.icon | `lib/features/match_live/presentation/match_live_running_widgets.dart:672` | child: FilledButton.icon( onPressed: busy ? null : onValidate, | **NON VÉRIFIÉ** |
| UI-7-35 | FilledButton | `lib/features/match_live/presentation/match_live_tab.dart:224` | FilledButton( onPressed: () => unawaited(onClaim()), | **NON VÉRIFIÉ** |
| UI-7-36 | OutlinedButton | `lib/features/match_live/presentation/match_live_tab.dart:252` | OutlinedButton( onPressed: () async { | **NON VÉRIFIÉ** |
| UI-7-37 | TextButton | `lib/features/match_live/presentation/match_live_tab.dart:259` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-7-38 | FilledButton | `lib/features/match_live/presentation/match_live_tab.dart:263` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-7-39 | InkWell | `lib/features/match_live/presentation/widgets/live_bench_tile.dart:108` | : InkWell( borderRadius: BorderRadius.circular(12), | **NON VÉRIFIÉ** |
| UI-7-40 | InkWell | `lib/features/match_live/presentation/widgets/live_bench_tile.dart:180` | : InkWell( borderRadius: BorderRadius.circular(12), | **NON VÉRIFIÉ** |
| UI-7-41 | IconButton | `lib/features/match_live/presentation/widgets/match_live_add_player_sheet.dart:100` | IconButton( tooltip: 'Fermer', | **NON VÉRIFIÉ** |
| UI-7-42 | SegmentedButton | `lib/features/match_live/presentation/widgets/match_live_add_player_sheet.dart:114` | SegmentedButton<int>( segments: const [ | **NON VÉRIFIÉ** |
| UI-7-43 | FilledButton.icon | `lib/features/match_live/presentation/widgets/match_live_add_player_sheet.dart:206` | FilledButton.icon( onPressed: _busy ? null : _submit, | **NON VÉRIFIÉ** |
| UI-7-44 | TextField | `lib/features/match_live/presentation/widgets/match_live_add_player_sheet.dart:375` | TextField( controller: firstNameController, | **NON VÉRIFIÉ** |
| UI-7-45 | TextField | `lib/features/match_live/presentation/widgets/match_live_add_player_sheet.dart:386` | TextField( controller: lastNameController, | **NON VÉRIFIÉ** |
| UI-7-46 | SwitchListTile.adaptive | `lib/features/match_live/presentation/widgets/match_live_add_player_sheet.dart:396` | SwitchListTile.adaptive( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-7-47 | CheckboxListTile | `lib/features/match_live/presentation/widgets/match_live_add_player_sheet.dart:422` | return CheckboxListTile( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-7-48 | TextButton.icon | `lib/features/match_live/presentation/widgets/match_live_add_player_sheet.dart:488` | TextButton.icon( onPressed: onRetry, | **NON VÉRIFIÉ** |

Sans constructeur détecté : 
- `lib/features/match_live/presentation/match_live_pilot.dart` : NON VÉRIFIÉ
- `lib/features/match_live/presentation/match_live_providers.dart` : NON VÉRIFIÉ
- `lib/features/match_live/presentation/widgets/live_substitution_line.dart` : NON VÉRIFIÉ
- `lib/features/match_live/presentation/widgets/match_faits_du_match_card.dart` : NON VÉRIFIÉ
