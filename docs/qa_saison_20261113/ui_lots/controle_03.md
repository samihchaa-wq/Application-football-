# Contrôles Flutter — lot 3

Fichiers lus 12/12; positions 25–36/181. Occurrences 50. Contrôles sources, pas boutons rendus ; aucune interaction à l'écran : **NON VÉRIFIÉ**.

| ID | Constructeur | Fichier/ligne | Extrait | Test écran |
|---|---|---|---|---|
| UI-3-1 | IconButton.styleFrom | `lib/core/widgets/match_sheet_top_row.dart:96` | style: IconButton.styleFrom( minimumSize: const Size(width, kMinInteractiveDimension), | **NON VÉRIFIÉ** |
| UI-3-2 | DropdownButtonFormField | `lib/core/widgets/photo_crop_preview.dart:227` | DropdownButtonFormField<ClubKit>( key: const ValueKey('portrait-kit-preview'), | **NON VÉRIFIÉ** |
| UI-3-3 | TextButton | `lib/core/widgets/photo_crop_preview.dart:327` | TextButton( onPressed: _busy ? null : () => Navigator.pop(context, null), | **NON VÉRIFIÉ** |
| UI-3-4 | FilledButton | `lib/core/widgets/photo_crop_preview.dart:331` | FilledButton( onPressed: !_ready // _busy ? null : _confirm, | **NON VÉRIFIÉ** |
| UI-3-5 | InkWell | `lib/core/widgets/sticky_header_table.dart:442` | child: InkWell( onTap: onTap, | **NON VÉRIFIÉ** |
| UI-3-6 | TextButton | `lib/features/admin/presentation/admin_notification_page.dart:63` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-3-7 | FilledButton | `lib/features/admin/presentation/admin_notification_page.dart:67` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-3-8 | TextField | `lib/features/admin/presentation/admin_notification_page.dart:164` | TextField( controller: _titleController, | **NON VÉRIFIÉ** |
| UI-3-9 | TextField | `lib/features/admin/presentation/admin_notification_page.dart:176` | TextField( controller: _bodyController, | **NON VÉRIFIÉ** |
| UI-3-10 | TextButton | `lib/features/admin/presentation/admin_notification_page.dart:211` | TextButton( onPressed: _sending // profiles.isEmpty | **NON VÉRIFIÉ** |
| UI-3-11 | CheckboxListTile | `lib/features/admin/presentation/admin_notification_page.dart:240` | CheckboxListTile( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-3-12 | FilledButton.icon | `lib/features/admin/presentation/admin_notification_page.dart:261` | FilledButton.icon( onPressed: _sending ? null : () => _send(profiles), | **NON VÉRIFIÉ** |
| UI-3-13 | FilledButton | `lib/features/admin/presentation/admin_page.dart:68` | FilledButton( onPressed: () => ref.invalidate(adminDashboardProvider), | **NON VÉRIFIÉ** |
| UI-3-14 | FilledButton.tonal | `lib/features/admin/presentation/admin_page.dart:132` | child: FilledButton.tonal( onPressed: () async { | **NON VÉRIFIÉ** |
| UI-3-15 | TextButton | `lib/features/admin/presentation/admin_page.dart:217` | child: TextButton( onPressed: () => showRosterPlayerDialog( | **NON VÉRIFIÉ** |
| UI-3-16 | ListTile | `lib/features/admin/presentation/admin_page.dart:284` | child: ListTile( leading: PlayerAvatar( | **NON VÉRIFIÉ** |
| UI-3-17 | InkWell | `lib/features/admin/presentation/admin_page.dart:339` | child: InkWell( onTap: () => onSelected(items[index].$1), | **NON VÉRIFIÉ** |
| UI-3-18 | FilledButton | `lib/features/admin/presentation/admin_profile_actions.dart:19` | FilledButton( onPressed: onValidate, | **NON VÉRIFIÉ** |
| UI-3-19 | TextButton | `lib/features/admin/presentation/admin_profile_actions.dart:23` | TextButton( style: TextButton.styleFrom( | **NON VÉRIFIÉ** |
| UI-3-20 | TextButton.styleFrom | `lib/features/admin/presentation/admin_profile_actions.dart:24` | style: TextButton.styleFrom( foregroundColor: Theme.of(context).colorScheme.error, | **NON VÉRIFIÉ** |
| UI-3-21 | DropdownButtonFormField | `lib/features/admin/presentation/admin_profile_dialogs.dart:66` | DropdownButtonFormField<String>( initialValue: selectedPlayerId, | **NON VÉRIFIÉ** |
| UI-3-22 | TextButton | `lib/features/admin/presentation/admin_profile_dialogs.dart:91` | TextButton( onPressed: () => Navigator.pop(dialogContext), | **NON VÉRIFIÉ** |
| UI-3-23 | FilledButton | `lib/features/admin/presentation/admin_profile_dialogs.dart:95` | FilledButton( onPressed: () => Navigator.pop( | **NON VÉRIFIÉ** |
| UI-3-24 | TextButton.icon | `lib/features/admin/presentation/admin_profile_dialogs.dart:143` | TextButton.icon( onPressed: () async { | **NON VÉRIFIÉ** |
| UI-3-25 | FilledButton | `lib/features/admin/presentation/admin_profile_dialogs.dart:154` | FilledButton( onPressed: () => Navigator.pop(dialogContext), | **NON VÉRIFIÉ** |
| UI-3-26 | DropdownButtonFormField | `lib/features/admin/presentation/admin_profile_dialogs.dart:200` | child: DropdownButtonFormField<int?>( initialValue: selectedId, | **NON VÉRIFIÉ** |
| UI-3-27 | TextButton | `lib/features/admin/presentation/admin_profile_dialogs.dart:224` | TextButton( onPressed: () => Navigator.pop(dialogContext), | **NON VÉRIFIÉ** |
| UI-3-28 | FilledButton | `lib/features/admin/presentation/admin_profile_dialogs.dart:228` | FilledButton( onPressed: () => | **NON VÉRIFIÉ** |
| UI-3-29 | TextButton | `lib/features/admin/presentation/admin_profile_dialogs.dart:250` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-3-30 | FilledButton | `lib/features/admin/presentation/admin_profile_dialogs.dart:254` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-3-31 | FilledButton | `lib/features/admin/presentation/admin_profiles_section_v2.dart:16` | return FilledButton( style: FilledButton.styleFrom( | **NON VÉRIFIÉ** |
| UI-3-32 | FilledButton.styleFrom | `lib/features/admin/presentation/admin_profiles_section_v2.dart:17` | style: FilledButton.styleFrom( backgroundColor: const Color(0xFF1464EF), | **NON VÉRIFIÉ** |
| UI-3-33 | TextField | `lib/features/admin/presentation/admin_profiles_section_v2.dart:339` | TextField( key: ValueKey<String>( | **NON VÉRIFIÉ** |
| UI-3-34 | TextButton | `lib/features/admin/presentation/admin_profiles_section_v2.dart:378` | child: TextButton( onPressed: saveFirstName, | **NON VÉRIFIÉ** |
| UI-3-35 | FilterChip | `lib/features/admin/presentation/admin_profiles_section_v2.dart:413` | child: FilterChip( key: const ValueKey('role-effectif'), | **NON VÉRIFIÉ** |
| UI-3-36 | FilterChip | `lib/features/admin/presentation/admin_profiles_section_v2.dart:430` | child: FilterChip( key: const ValueKey('role-admin'), | **NON VÉRIFIÉ** |
| UI-3-37 | FilterChip | `lib/features/admin/presentation/admin_profiles_section_v2.dart:455` | child: FilterChip( key: const ValueKey('role-gardien'), | **NON VÉRIFIÉ** |
| UI-3-38 | FilterChip | `lib/features/admin/presentation/admin_profiles_section_v2.dart:474` | child: FilterChip( key: const ValueKey('role-coach'), | **NON VÉRIFIÉ** |
| UI-3-39 | OutlinedButton | `lib/features/admin/presentation/admin_profiles_section_v2.dart:542` | child: OutlinedButton( onPressed: archiveAccount, | **NON VÉRIFIÉ** |
| UI-3-40 | FilledButton | `lib/features/admin/presentation/admin_profiles_section_v2.dart:549` | child: FilledButton( style: FilledButton.styleFrom( | **NON VÉRIFIÉ** |
| UI-3-41 | FilledButton.styleFrom | `lib/features/admin/presentation/admin_profiles_section_v2.dart:550` | style: FilledButton.styleFrom( backgroundColor: Theme.of(context).colorScheme.error, | **NON VÉRIFIÉ** |
| UI-3-42 | ExpansionTile | `lib/features/admin/presentation/admin_profiles_section_v2.dart:626` | : ExpansionTile( key: ValueKey<String>('validated-profile-${profile.id}'), | **NON VÉRIFIÉ** |
| UI-3-43 | OutlinedButton.icon | `lib/features/admin/presentation/admin_season_section.dart:26` | child: OutlinedButton.icon( style: OutlinedButton.styleFrom( | **NON VÉRIFIÉ** |
| UI-3-44 | OutlinedButton.styleFrom | `lib/features/admin/presentation/admin_season_section.dart:27` | style: OutlinedButton.styleFrom( foregroundColor: Theme.of(context).colorScheme.error, | **NON VÉRIFIÉ** |
| UI-3-45 | FilledButton.icon | `lib/features/admin/presentation/admin_season_section.dart:61` | FilledButton.icon( onPressed: () => _createSeason(context, ref), | **NON VÉRIFIÉ** |
| UI-3-46 | TextButton | `lib/features/admin/presentation/admin_season_section.dart:92` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-3-47 | FilledButton | `lib/features/admin/presentation/admin_season_section.dart:96` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-3-48 | TextField | `lib/features/admin/presentation/admin_season_section.dart:128` | content: TextField( controller: controller, | **NON VÉRIFIÉ** |
| UI-3-49 | TextButton | `lib/features/admin/presentation/admin_season_section.dart:133` | TextButton( onPressed: () => Navigator.pop(dialogContext), | **NON VÉRIFIÉ** |
| UI-3-50 | FilledButton | `lib/features/admin/presentation/admin_season_section.dart:137` | FilledButton( onPressed: () => Navigator.pop(dialogContext, controller.text), | **NON VÉRIFIÉ** |

Sans constructeur détecté : 
- `lib/core/widgets/match_fixture.dart` : NON VÉRIFIÉ
- `lib/features/admin/presentation/admin_menu_page.dart` : NON VÉRIFIÉ
- `lib/features/admin/presentation/admin_profile_policy.dart` : NON VÉRIFIÉ
