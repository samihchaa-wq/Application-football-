# Contrôles Flutter — lot 5

Fichiers lus 12/12; positions 49–60/181. Occurrences 28. Contrôles sources, pas boutons rendus ; aucune interaction à l'écran : **NON VÉRIFIÉ**.

| ID | Constructeur | Fichier/ligne | Extrait | Test écran |
|---|---|---|---|---|
| UI-5-1 | TextButton | `lib/features/auth/presentation/legal_document_page.dart:53` | TextButton( onPressed: () => context.go('/legal/${other.slug}'), | **NON VÉRIFIÉ** |
| UI-5-2 | TextButton | `lib/features/auth/presentation/sign_out_confirmation.dart:19` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-5-3 | FilledButton | `lib/features/auth/presentation/sign_out_confirmation.dart:23` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-5-4 | IconButton | `lib/features/badges/presentation/armoire_page.dart:59` | IconButton( tooltip: 'Gérer les badges', | **NON VÉRIFIÉ** |
| UI-5-5 | GestureDetector | `lib/features/badges/presentation/armoire_page.dart:291` | child: GestureDetector( onTap: () => showBadgeDetailSheet( | **NON VÉRIFIÉ** |
| UI-5-6 | GestureDetector | `lib/features/badges/presentation/armoire_page.dart:367` | GestureDetector( onTap: () { | **NON VÉRIFIÉ** |
| UI-5-7 | GestureDetector | `lib/features/badges/presentation/armoire_page.dart:562` | return GestureDetector( onTap: () => showBadgeDetailSheet(context, badge.def), | **NON VÉRIFIÉ** |
| UI-5-8 | InkWell | `lib/features/badges/presentation/badge_admin_page.dart:151` | child: InkWell( onTap: () => showBadgeDetailSheet( | **NON VÉRIFIÉ** |
| UI-5-9 | InkWell | `lib/features/badges/presentation/badge_admin_page.dart:317` | child: InkWell( onTap: selected ? null : () => onChanged(value), | **NON VÉRIFIÉ** |
| UI-5-10 | FilledButton.tonalIcon | `lib/features/badges/presentation/badge_admin_page.dart:412` | child: FilledButton.tonalIcon( onPressed: creating ? null : onEditImage, | **NON VÉRIFIÉ** |
| UI-5-11 | TextField | `lib/features/badges/presentation/badge_admin_page.dart:427` | TextField( controller: nameController, | **NON VÉRIFIÉ** |
| UI-5-12 | TextField | `lib/features/badges/presentation/badge_admin_page.dart:436` | TextField( controller: descController, | **NON VÉRIFIÉ** |
| UI-5-13 | FilledButton.icon | `lib/features/badges/presentation/badge_admin_page.dart:447` | child: FilledButton.icon( onPressed: creating // !hasImage ? null : onCreate, | **NON VÉRIFIÉ** |
| UI-5-14 | TextButton | `lib/features/badges/presentation/badge_admin_page.dart:523` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-5-15 | FilledButton | `lib/features/badges/presentation/badge_admin_page.dart:527` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-5-16 | TextField | `lib/features/badges/presentation/badge_admin_page.dart:618` | TextField( decoration: InputDecoration( | **NON VÉRIFIÉ** |
| UI-5-17 | ListTile | `lib/features/badges/presentation/badge_admin_page.dart:657` | ListTile( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-5-18 | FilledButton.tonal | `lib/features/badges/presentation/badge_admin_page.dart:668` | : FilledButton.tonal( onPressed: | **NON VÉRIFIÉ** |
| UI-5-19 | OutlinedButton.icon | `lib/features/badges/presentation/badge_detail_sheet.dart:240` | ? OutlinedButton.icon( onPressed: () { | **NON VÉRIFIÉ** |
| UI-5-20 | FilledButton.icon | `lib/features/badges/presentation/badge_detail_sheet.dart:248` | : FilledButton.icon( onPressed: () { | **NON VÉRIFIÉ** |
| UI-5-21 | OutlinedButton.icon | `lib/features/badges/presentation/badge_detail_sheet.dart:262` | child: OutlinedButton.icon( onPressed: onAward, | **NON VÉRIFIÉ** |
| UI-5-22 | IconButton.filledTonal | `lib/features/badges/presentation/badge_image_editor.dart:132` | return IconButton.filledTonal( tooltip: tooltip, | **NON VÉRIFIÉ** |
| UI-5-23 | FilledButton.tonal | `lib/features/badges/presentation/badge_image_editor.dart:139` | return FilledButton.tonal( onPressed: _busy ? null : _editImage, | **NON VÉRIFIÉ** |
| UI-5-24 | FilledButton.icon | `lib/features/badges/presentation/badge_image_editor.dart:327` | child: FilledButton.icon( onPressed: _pickImage, | **NON VÉRIFIÉ** |
| UI-5-25 | TextButton.icon | `lib/features/badges/presentation/badge_image_editor.dart:395` | TextButton.icon( onPressed: _saving ? null : _pickImage, | **NON VÉRIFIÉ** |
| UI-5-26 | TextButton.icon | `lib/features/badges/presentation/badge_image_editor.dart:400` | TextButton.icon( onPressed: _saving ? null : _reset, | **NON VÉRIFIÉ** |
| UI-5-27 | TextButton | `lib/features/badges/presentation/badge_image_editor.dart:410` | TextButton( onPressed: _saving ? null : () => Navigator.of(context).pop(), | **NON VÉRIFIÉ** |
| UI-5-28 | FilledButton.icon | `lib/features/badges/presentation/badge_image_editor.dart:414` | FilledButton.icon( onPressed: | **NON VÉRIFIÉ** |

Sans constructeur détecté : 
- `lib/features/badges/presentation/badge_descriptor.dart` : NON VÉRIFIÉ
- `lib/features/badges/presentation/badge_display_scope.dart` : NON VÉRIFIÉ
- `lib/features/badges/presentation/badge_emblem.dart` : NON VÉRIFIÉ
- `lib/features/badges/presentation/badge_emblem_body.dart` : NON VÉRIFIÉ
- `lib/features/badges/presentation/badge_image_delivery.dart` : NON VÉRIFIÉ
- `lib/features/badges/presentation/badge_image_picker.dart` : NON VÉRIFIÉ
