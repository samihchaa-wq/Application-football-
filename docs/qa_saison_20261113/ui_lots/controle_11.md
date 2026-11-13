# Contrôles Flutter — lot 11

Fichiers lus 12/12; positions 121–132/181. Occurrences 32. Contrôles sources, pas boutons rendus ; aucune interaction à l'écran : **NON VÉRIFIÉ**.

| ID | Constructeur | Fichier/ligne | Extrait | Test écran |
|---|---|---|---|---|
| UI-11-1 | InkWell | `lib/features/players/presentation/player_card_link.dart:76` | child: InkWell( onTap: () => context.push(playerCardLocation(playerKey)), | **NON VÉRIFIÉ** |
| UI-11-2 | InkWell | `lib/features/players/presentation/player_card_matches.dart:101` | child: InkWell( onTap: () => context.push('/matches/${match.matchId}'), | **NON VÉRIFIÉ** |
| UI-11-3 | GestureDetector | `lib/features/players/presentation/player_card_page.dart:500` | child: GestureDetector( behavior: HitTestBehavior.opaque, | **NON VÉRIFIÉ** |
| UI-11-4 | InkWell | `lib/features/players/presentation/player_card_stats.dart:192` | child: InkWell(onTap: onTap, child: box()), ), | **NON VÉRIFIÉ** |
| UI-11-5 | InkWell | `lib/features/players/presentation/player_card_stats.dart:394` | child: InkWell( onTap: onTap, | **NON VÉRIFIÉ** |
| UI-11-6 | FilledButton.icon | `lib/features/players/presentation/players_registry_page.dart:70` | child: FilledButton.icon( onPressed: () => | **NON VÉRIFIÉ** |
| UI-11-7 | ListTile | `lib/features/players/presentation/players_registry_page.dart:93` | child: ListTile( leading: PlayerAvatar( | **NON VÉRIFIÉ** |
| UI-11-8 | PopupMenuButton | `lib/features/players/presentation/players_registry_page.dart:117` | trailing: PopupMenuButton<String>( onSelected: (action) async { | **NON VÉRIFIÉ** |
| UI-11-9 | DropdownButtonFormField | `lib/features/players/presentation/players_registry_page.dart:401` | DropdownButtonFormField<String>( initialValue: selectedProfileId, | **NON VÉRIFIÉ** |
| UI-11-10 | TextButton | `lib/features/players/presentation/players_registry_page.dart:446` | TextButton( onPressed: saving ? null : () => Navigator.pop(dialogContext), | **NON VÉRIFIÉ** |
| UI-11-11 | FilledButton | `lib/features/players/presentation/players_registry_page.dart:450` | FilledButton( onPressed: saving // profiles.isEmpty | **NON VÉRIFIÉ** |
| UI-11-12 | TextButton | `lib/features/players/presentation/players_registry_page.dart:515` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-11-13 | FilledButton | `lib/features/players/presentation/players_registry_page.dart:519` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-11-14 | TextButton | `lib/features/players/presentation/players_registry_page.dart:541` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-11-15 | FilledButton | `lib/features/players/presentation/players_registry_page.dart:545` | FilledButton( style: FilledButton.styleFrom( | **NON VÉRIFIÉ** |
| UI-11-16 | FilledButton.styleFrom | `lib/features/players/presentation/players_registry_page.dart:546` | style: FilledButton.styleFrom( backgroundColor: Theme.of(dialogContext).colorScheme.error, | **NON VÉRIFIÉ** |
| UI-11-17 | TextField | `lib/features/players/presentation/players_registry_page.dart:579` | TextField( controller: firstName, | **NON VÉRIFIÉ** |
| UI-11-18 | SwitchListTile.adaptive | `lib/features/players/presentation/players_registry_page.dart:584` | SwitchListTile.adaptive( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-11-19 | SwitchListTile.adaptive | `lib/features/players/presentation/players_registry_page.dart:592` | SwitchListTile.adaptive( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-11-20 | TextButton | `lib/features/players/presentation/players_registry_page.dart:622` | TextButton( onPressed: saving ? null : () => Navigator.pop(dialogContext), | **NON VÉRIFIÉ** |
| UI-11-21 | FilledButton | `lib/features/players/presentation/players_registry_page.dart:626` | FilledButton( onPressed: saving | **NON VÉRIFIÉ** |
| UI-11-22 | PopupMenuButton | `lib/features/players/presentation/players_registry_page.dart:695` | return PopupMenuButton<String>( tooltip: 'Modifier le joueur', | **NON VÉRIFIÉ** |
| UI-11-23 | InkWell | `lib/features/predictions/presentation/merged_matches_view.dart:800` | : InkWell(onTap: () => context.push(detailsRoute), child: content), ), | **NON VÉRIFIÉ** |
| UI-11-24 | IconButton | `lib/features/predictions/presentation/pronos_hub_history_section.dart:100` | IconButton( tooltip: '👑 Ajouter un match', | **NON VÉRIFIÉ** |
| UI-11-25 | InkWell | `lib/features/predictions/presentation/pronos_hub_history_section.dart:279` | child: InkWell( onTap: () => context.push( | **NON VÉRIFIÉ** |
| UI-11-26 | TextButton | `lib/features/predictions/presentation/pronos_hub_history_section.dart:319` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-11-27 | FilledButton | `lib/features/predictions/presentation/pronos_hub_history_section.dart:323` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-11-28 | PopupMenuButton | `lib/features/predictions/presentation/pronos_hub_history_section.dart:352` | PopupMenuButton<String>( tooltip: 'Options du match', | **NON VÉRIFIÉ** |
| UI-11-29 | FilledButton.icon | `lib/features/predictions/presentation/widgets/inline_match_prediction_card.dart:208` | child: FilledButton.icon( style: FilledButton.styleFrom( | **NON VÉRIFIÉ** |
| UI-11-30 | FilledButton.styleFrom | `lib/features/predictions/presentation/widgets/inline_match_prediction_card.dart:209` | style: FilledButton.styleFrom( minimumSize: const Size.fromHeight(44), | **NON VÉRIFIÉ** |
| UI-11-31 | IconButton | `lib/features/predictions/presentation/widgets/inline_match_prediction_card.dart:422` | IconButton( tooltip: 'Retirer un but pour $label', | **NON VÉRIFIÉ** |
| UI-11-32 | IconButton | `lib/features/predictions/presentation/widgets/inline_match_prediction_card.dart:437` | IconButton( tooltip: 'Ajouter un but pour $label', | **NON VÉRIFIÉ** |

Sans constructeur détecté : 
- `lib/features/players/presentation/player_stat_ranking_page.dart` : NON VÉRIFIÉ
- `lib/features/predictions/presentation/pronos_hub_components.dart` : NON VÉRIFIÉ
- `lib/features/predictions/presentation/pronos_hub_page.dart` : NON VÉRIFIÉ
- `lib/features/predictions/presentation/pronos_hub_ranking_sections.dart` : NON VÉRIFIÉ
