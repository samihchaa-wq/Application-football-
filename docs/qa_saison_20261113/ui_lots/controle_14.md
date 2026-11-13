# Contrôles Flutter — lot 14

Fichiers lus 12/12; positions 157–168/181. Occurrences 39. Contrôles sources, pas boutons rendus ; aucune interaction à l'écran : **NON VÉRIFIÉ**.

| ID | Constructeur | Fichier/ligne | Extrait | Test écran |
|---|---|---|---|---|
| UI-14-1 | ActionChip | `lib/features/sports_management/presentation/widgets/composition_pitch.dart:347` | final chip = ActionChip( avatar: PlayerAvatar( | **NON VÉRIFIÉ** |
| UI-14-2 | GestureDetector | `lib/features/sports_management/presentation/widgets/composition_pitch.dart:486` | return GestureDetector( onTap: onTap, | **NON VÉRIFIÉ** |
| UI-14-3 | IconButton | `lib/features/sports_management/presentation/widgets/composition_presentation.dart:692` | IconButton( tooltip: 'Fermer', | **NON VÉRIFIÉ** |
| UI-14-4 | GestureDetector | `lib/features/sports_management/presentation/widgets/composition_presentation.dart:701` | : GestureDetector( onTap: _videoStatus == null ? null : _showVideoStatus, | **NON VÉRIFIÉ** |
| UI-14-5 | FilledButton.tonalIcon | `lib/features/sports_management/presentation/widgets/composition_presentation.dart:729` | FilledButton.tonalIcon( onPressed: _replay, | **NON VÉRIFIÉ** |
| UI-14-6 | TextButton | `lib/features/sports_management/presentation/widgets/composition_presentation.dart:751` | TextButton( onPressed: () => Navigator.of(context).pop(), | **NON VÉRIFIÉ** |
| UI-14-7 | InkWell | `lib/features/sports_management/presentation/widgets/composition_presentation_elements.dart:54` | child: InkWell( customBorder: const StadiumBorder(), | **NON VÉRIFIÉ** |
| UI-14-8 | InkWell | `lib/features/sports_management/presentation/widgets/effectif_avatar_grid.dart:168` | child: InkWell( onTap: onTap, | **NON VÉRIFIÉ** |
| UI-14-9 | InkWell | `lib/features/sports_management/presentation/widgets/formation_pitch_editor.dart:551` | child: InkWell( onTap: widget.editable ? () => _tapEmptySlot(slot) : null, | **NON VÉRIFIÉ** |
| UI-14-10 | InkWell | `lib/features/sports_management/presentation/widgets/formation_pitch_editor.dart:609` | child: InkWell( onTap: | **NON VÉRIFIÉ** |
| UI-14-11 | TextButton | `lib/features/sports_management/presentation/widgets/internal_team_composition_view.dart:379` | TextButton( onPressed: () => Navigator.of(dialogContext).pop(false), | **NON VÉRIFIÉ** |
| UI-14-12 | FilledButton | `lib/features/sports_management/presentation/widgets/internal_team_composition_view.dart:383` | FilledButton( onPressed: () => Navigator.of(dialogContext).pop(true), | **NON VÉRIFIÉ** |
| UI-14-13 | TextButton | `lib/features/sports_management/presentation/widgets/internal_team_composition_view.dart:441` | TextButton( onPressed: () => Navigator.of(dialogContext).pop(false), | **NON VÉRIFIÉ** |
| UI-14-14 | FilledButton | `lib/features/sports_management/presentation/widgets/internal_team_composition_view.dart:445` | FilledButton( onPressed: () => Navigator.of(dialogContext).pop(true), | **NON VÉRIFIÉ** |
| UI-14-15 | SegmentedButton | `lib/features/sports_management/presentation/widgets/internal_team_composition_view.dart:706` | SegmentedButton<int>( segments: const [ | **NON VÉRIFIÉ** |
| UI-14-16 | SegmentedButton | `lib/features/sports_management/presentation/widgets/internal_team_composition_view.dart:770` | SegmentedButton<int>( segments: [ | **NON VÉRIFIÉ** |
| UI-14-17 | OutlinedButton.icon | `lib/features/sports_management/presentation/widgets/internal_team_composition_view.dart:824` | OutlinedButton.icon( onPressed: _saving ? null : _resetComposition, | **NON VÉRIFIÉ** |
| UI-14-18 | FilledButton.icon | `lib/features/sports_management/presentation/widgets/internal_team_composition_view.dart:830` | FilledButton.icon( onPressed: _saving | **NON VÉRIFIÉ** |
| UI-14-19 | TextField | `lib/features/sports_management/presentation/widgets/internal_team_composition_widgets.dart:148` | child: TextField( controller: controller, | **NON VÉRIFIÉ** |
| UI-14-20 | InkWell | `lib/features/sports_management/presentation/widgets/internal_team_composition_widgets.dart:256` | child: InkWell( onTap: assignmentEnabled ? onTap : null, | **NON VÉRIFIÉ** |
| UI-14-21 | PopupMenuButton | `lib/features/sports_management/presentation/widgets/internal_team_composition_widgets.dart:293` | child: PopupMenuButton<JerseyOption>( tooltip: 'Choisir le maillot', | **NON VÉRIFIÉ** |
| UI-14-22 | TextField | `lib/features/sports_management/presentation/widgets/internal_team_composition_widgets.dart:425` | ? TextField( controller: controller, | **NON VÉRIFIÉ** |
| UI-14-23 | InkWell | `lib/features/sports_management/presentation/widgets/internal_team_composition_widgets.dart:601` | child: InkWell( borderRadius: BorderRadius.circular(12), | **NON VÉRIFIÉ** |
| UI-14-24 | PopupMenuButton | `lib/features/sports_management/presentation/widgets/internal_team_composition_widgets.dart:627` | child: PopupMenuButton<JerseyOption>( tooltip: 'Choisir le maillot', | **NON VÉRIFIÉ** |
| UI-14-25 | GestureDetector | `lib/features/sports_management/presentation/widgets/internal_team_composition_widgets.dart:708` | return GestureDetector( key: const ValueKey('internal-unassigned-pool'), | **NON VÉRIFIÉ** |
| UI-14-26 | GestureDetector | `lib/features/sports_management/presentation/widgets/internal_team_composition_widgets.dart:761` | return GestureDetector( behavior: HitTestBehavior.opaque, | **NON VÉRIFIÉ** |
| UI-14-27 | InkWell | `lib/features/sports_management/presentation/widgets/internal_team_composition_widgets.dart:847` | child: InkWell( borderRadius: BorderRadius.circular(10), | **NON VÉRIFIÉ** |
| UI-14-28 | TextButton | `lib/features/sports_management/presentation/widgets/match_availability_selector.dart:155` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-14-29 | FilledButton | `lib/features/sports_management/presentation/widgets/match_availability_selector.dart:159` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-14-30 | FilledButton.icon | `lib/features/sports_management/presentation/widgets/match_availability_selector.dart:295` | ? FilledButton.icon( onPressed: saving ? null : onAvailable, | **NON VÉRIFIÉ** |
| UI-14-31 | FilledButton.styleFrom | `lib/features/sports_management/presentation/widgets/match_availability_selector.dart:299` | style: FilledButton.styleFrom( backgroundColor: const Color(0xFF168A52), | **NON VÉRIFIÉ** |
| UI-14-32 | OutlinedButton.icon | `lib/features/sports_management/presentation/widgets/match_availability_selector.dart:303` | : OutlinedButton.icon( onPressed: saving ? null : onAvailable, | **NON VÉRIFIÉ** |
| UI-14-33 | FilledButton.icon | `lib/features/sports_management/presentation/widgets/match_availability_selector.dart:312` | ? FilledButton.icon( onPressed: saving ? null : onAbsent, | **NON VÉRIFIÉ** |
| UI-14-34 | FilledButton.styleFrom | `lib/features/sports_management/presentation/widgets/match_availability_selector.dart:316` | style: FilledButton.styleFrom( backgroundColor: const Color(0xFFB33A3A), | **NON VÉRIFIÉ** |
| UI-14-35 | OutlinedButton.icon | `lib/features/sports_management/presentation/widgets/match_availability_selector.dart:320` | : OutlinedButton.icon( onPressed: saving ? null : onAbsent, | **NON VÉRIFIÉ** |
| UI-14-36 | OutlinedButton.icon | `lib/features/sports_management/presentation/widgets/match_availability_selector.dart:357` | child: OutlinedButton.icon( onPressed: onOpenEffectif, | **NON VÉRIFIÉ** |
| UI-14-37 | OutlinedButton.styleFrom | `lib/features/sports_management/presentation/widgets/match_availability_selector.dart:362` | ? OutlinedButton.styleFrom( foregroundColor: Colors.white, | **NON VÉRIFIÉ** |
| UI-14-38 | OutlinedButton.icon | `lib/features/sports_management/presentation/widgets/match_availability_selector.dart:371` | child: OutlinedButton.icon( onPressed: onOpenComposition, | **NON VÉRIFIÉ** |
| UI-14-39 | OutlinedButton.styleFrom | `lib/features/sports_management/presentation/widgets/match_availability_selector.dart:376` | ? OutlinedButton.styleFrom( foregroundColor: Colors.white, | **NON VÉRIFIÉ** |

Sans constructeur détecté : 
- `lib/features/sports_management/presentation/widgets/composition_presentation_camera.dart` : NON VÉRIFIÉ
- `lib/features/sports_management/presentation/widgets/composition_presentation_stage.dart` : NON VÉRIFIÉ
- `lib/features/sports_management/presentation/widgets/football_pitch.dart` : NON VÉRIFIÉ
- `lib/features/sports_management/presentation/widgets/match_availability_board_card.dart` : NON VÉRIFIÉ
