# Contrôles Flutter — lot 15

Fichiers lus 12/12; positions 169–180/181. Occurrences 19. Contrôles sources, pas boutons rendus ; aucune interaction à l'écran : **NON VÉRIFIÉ**.

| ID | Constructeur | Fichier/ligne | Extrait | Test écran |
|---|---|---|---|---|
| UI-15-1 | ListTile | `lib/features/sports_management/presentation/widgets/match_goal_actions_editor.dart:261` | ListTile( leading: const Icon(Icons.flag_rounded), | **NON VÉRIFIÉ** |
| UI-15-2 | ListTile | `lib/features/sports_management/presentation/widgets/match_goal_actions_editor.dart:266` | ListTile( leading: const Icon(Icons.shield_moon_outlined), | **NON VÉRIFIÉ** |
| UI-15-3 | TextField | `lib/features/sports_management/presentation/widgets/match_goal_actions_editor.dart:326` | child: TextField( controller: _controller, | **NON VÉRIFIÉ** |
| UI-15-4 | InkWell | `lib/features/sports_management/presentation/widgets/match_goal_actions_editor.dart:413` | child: InkWell( onTap: enabled ? onTap : null, | **NON VÉRIFIÉ** |
| UI-15-5 | DropdownButtonFormField | `lib/features/sports_management/presentation/widgets/match_squad_editor.dart:82` | DropdownButtonFormField<String>( key: ValueKey('squad-formation-${lineup.formationCode}'), | **NON VÉRIFIÉ** |
| UI-15-6 | TextButton | `lib/features/sports_management/presentation/widgets/match_squad_editor.dart:182` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-15-7 | FilledButton | `lib/features/sports_management/presentation/widgets/match_squad_editor.dart:186` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-15-8 | OutlinedButton.icon | `lib/features/sports_management/presentation/widgets/player_composition_video.dart:243` | child: OutlinedButton.icon( onPressed: _playing | **NON VÉRIFIÉ** |
| UI-15-9 | SegmentedButton | `lib/features/statistics/presentation/stats_hub_page.dart:84` | child: SegmentedButton<_StatsSection>( expandedInsets: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-15-10 | TextField | `lib/features/unavailability/presentation/unavailability_form_sheet.dart:147` | TextField( controller: _reason, | **NON VÉRIFIÉ** |
| UI-15-11 | TextButton | `lib/features/unavailability/presentation/unavailability_form_sheet.dart:197` | TextButton( onPressed: | **NON VÉRIFIÉ** |
| UI-15-12 | FilledButton | `lib/features/unavailability/presentation/unavailability_form_sheet.dart:203` | FilledButton( onPressed: _saving ? null : _save, | **NON VÉRIFIÉ** |
| UI-15-13 | InkWell | `lib/features/unavailability/presentation/unavailability_form_sheet.dart:229` | return InkWell( onTap: onTap, | **NON VÉRIFIÉ** |
| UI-15-14 | TextButton | `lib/features/unavailability/presentation/unavailability_page.dart:105` | TextButton( onPressed: () => Navigator.of(dialogContext).pop(false), | **NON VÉRIFIÉ** |
| UI-15-15 | FilledButton | `lib/features/unavailability/presentation/unavailability_page.dart:109` | FilledButton( onPressed: () => Navigator.of(dialogContext).pop(true), | **NON VÉRIFIÉ** |
| UI-15-16 | FilledButton.icon | `lib/features/unavailability/presentation/unavailability_page.dart:200` | child: FilledButton.icon( onPressed: () => _openForm(context, ref), | **NON VÉRIFIÉ** |
| UI-15-17 | TextButton | `lib/features/unavailability/presentation/unavailability_page.dart:266` | TextButton( onPressed: onCancel, | **NON VÉRIFIÉ** |
| UI-15-18 | TextButton | `lib/features/unavailability/presentation/unavailability_page.dart:272` | TextButton( onPressed: onEdit, | **NON VÉRIFIÉ** |
| UI-15-19 | TextButton | `lib/features/unavailability/presentation/unavailability_page.dart:471` | action: TextButton( onPressed: onRefresh, | **NON VÉRIFIÉ** |

Sans constructeur détecté : 
- `lib/features/sports_management/presentation/widgets/stadium_club_colors_web.dart` : NON VÉRIFIÉ
- `lib/features/sports_management/presentation/widgets/stadium_poster.dart` : NON VÉRIFIÉ
- `lib/features/sports_management/presentation/widgets/stadium_video.dart` : NON VÉRIFIÉ
- `lib/features/sports_management/presentation/widgets/stadium_video_stub.dart` : NON VÉRIFIÉ
- `lib/features/sports_management/presentation/widgets/stadium_video_web.dart` : NON VÉRIFIÉ
- `lib/features/statistics/presentation/team_statistics_panel.dart` : NON VÉRIFIÉ
