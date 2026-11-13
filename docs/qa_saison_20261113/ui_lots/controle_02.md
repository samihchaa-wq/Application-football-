# Contrôles Flutter — lot 2

Fichiers inspectés : 12/12 (positions 13–24/181). 7 contrôles repérés dans le code. Aucune interaction réelle testée ; chaque ligne vaut **NON VÉRIFIÉ**. Les contrôles dynamiques ne sont pas prouvés exhaustifs.

| ID | Type | Fichier / ligne | Extrait | Résultat UI |
|---|---|---|---|---|
| 2-1 | SegmentedButton | `lib/core/widgets/grinta_secondary_tabs.dart:41` | child: SegmentedButton<T>( expandedInsets: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| 2-2 | FilledButton.icon | `lib/core/widgets/incident_error_view.dart:55` | FilledButton.icon( onPressed: onRetry, | **NON VÉRIFIÉ** |
| 2-3 | ListTile | `lib/core/widgets/match_address_sheet.dart:99` | (app) => ListTile( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| 2-4 | FilledButton.icon | `lib/core/widgets/match_address_sheet.dart:182` | FilledButton.icon( onPressed: () => openMaps(sheetContext), | **NON VÉRIFIÉ** |
| 2-5 | OutlinedButton.icon | `lib/core/widgets/match_address_sheet.dart:188` | OutlinedButton.icon( onPressed: () => copy(sheetContext), | **NON VÉRIFIÉ** |
| 2-6 | OutlinedButton.icon | `lib/core/widgets/match_address_sheet.dart:194` | OutlinedButton.icon( onPressed: () => share(sheetContext), | **NON VÉRIFIÉ** |
| 2-7 | InkWell | `lib/core/widgets/match_detail_header_card.dart:141` | InkWell( onTap: onMotmTap, | **NON VÉRIFIÉ** |

Fichiers sans constructeur standard détecté :
- `lib/core/widgets/grinta_empty_state.dart` : **NON VÉRIFIÉ**.
- `lib/core/widgets/grinta_loader.dart` : **NON VÉRIFIÉ**.
- `lib/core/widgets/grinta_skeleton.dart` : **NON VÉRIFIÉ**.
- `lib/core/widgets/grinta_status_banner.dart` : **NON VÉRIFIÉ**.
- `lib/core/widgets/kit_pattern_paint.dart` : **NON VÉRIFIÉ**.
- `lib/core/widgets/kit_portrait.dart` : **NON VÉRIFIÉ**.
- `lib/core/widgets/match_contribution_icons.dart` : **NON VÉRIFIÉ**.
- `lib/core/widgets/match_date_column.dart` : **NON VÉRIFIÉ**.
