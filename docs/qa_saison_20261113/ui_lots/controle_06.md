# Contrôles Flutter — lot 6

Fichiers lus 12/12; positions 61–72/181. Occurrences 12. Contrôles sources, pas boutons rendus ; aucune interaction à l'écran : **NON VÉRIFIÉ**.

| ID | Constructeur | Fichier/ligne | Extrait | Test écran |
|---|---|---|---|---|
| UI-6-1 | OutlinedButton | `lib/features/badges/presentation/badge_text_editor.dart:20` | return OutlinedButton( onPressed: () => showDialog<void>( | **NON VÉRIFIÉ** |
| UI-6-2 | TextField | `lib/features/badges/presentation/badge_text_editor.dart:107` | TextField( controller: _name, | **NON VÉRIFIÉ** |
| UI-6-3 | TextField | `lib/features/badges/presentation/badge_text_editor.dart:116` | TextField( controller: _description, | **NON VÉRIFIÉ** |
| UI-6-4 | TextButton | `lib/features/badges/presentation/badge_text_editor.dart:129` | TextButton( onPressed: _saving ? null : () => Navigator.of(context).pop(), | **NON VÉRIFIÉ** |
| UI-6-5 | FilledButton.icon | `lib/features/badges/presentation/badge_text_editor.dart:133` | FilledButton.icon( onPressed: _canSave ? _save : null, | **NON VÉRIFIÉ** |
| UI-6-6 | OutlinedButton | `lib/features/badges/presentation/badge_threshold_editor.dart:19` | return OutlinedButton( key: const Key('badge-threshold-edit'), | **NON VÉRIFIÉ** |
| UI-6-7 | TextField | `lib/features/badges/presentation/badge_threshold_editor.dart:114` | TextField( key: const Key('badge-threshold-field'), | **NON VÉRIFIÉ** |
| UI-6-8 | TextButton | `lib/features/badges/presentation/badge_threshold_editor.dart:126` | TextButton( onPressed: _saving ? null : () => Navigator.of(context).pop(), | **NON VÉRIFIÉ** |
| UI-6-9 | FilledButton.icon | `lib/features/badges/presentation/badge_threshold_editor.dart:130` | FilledButton.icon( key: const Key('badge-threshold-save'), | **NON VÉRIFIÉ** |
| UI-6-10 | IconButton | `lib/features/badges/presentation/badge_trophy_button.dart:19` | return IconButton( tooltip: 'Armoire à badges', | **NON VÉRIFIÉ** |
| UI-6-11 | IconButton.styleFrom | `lib/features/badges/presentation/badge_trophy_button.dart:24` | style: IconButton.styleFrom( foregroundColor: AppTheme.reward, | **NON VÉRIFIÉ** |
| UI-6-12 | TextButton | `lib/features/club/presentation/club_configuration_status_banner.dart:38` | TextButton( onPressed: () { | **NON VÉRIFIÉ** |

Sans constructeur détecté : 
- `lib/features/badges/presentation/badge_image_picker_stub.dart` : NON VÉRIFIÉ
- `lib/features/badges/presentation/badge_image_picker_web.dart` : NON VÉRIFIÉ
- `lib/features/badges/presentation/locked_badge_emblem.dart` : NON VÉRIFIÉ
- `lib/features/badges/presentation/name_with_badges.dart` : NON VÉRIFIÉ
- `lib/features/club/presentation/club_identity_sync.dart` : NON VÉRIFIÉ
- `lib/features/club/presentation/club_rules_sync.dart` : NON VÉRIFIÉ
- `lib/features/club/presentation/club_suspended_page.dart` : NON VÉRIFIÉ
- `lib/features/feature_flags/presentation/feature_flags_controller.dart` : NON VÉRIFIÉ
