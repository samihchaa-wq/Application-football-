# Contrôles Flutter — lot 12

Fichiers lus 12/12; positions 133–144/181. Occurrences 57. Contrôles sources, pas boutons rendus ; aucune interaction à l'écran : **NON VÉRIFIÉ**.

| ID | Constructeur | Fichier/ligne | Extrait | Test écran |
|---|---|---|---|---|
| UI-12-1 | InkWell | `lib/features/predictions/presentation/widgets/match_history_card.dart:85` | : InkWell( onTap: () => context.push('/matches/${match.id}'), | **NON VÉRIFIÉ** |
| UI-12-2 | OutlinedButton.icon | `lib/features/profile/presentation/my_data_section.dart:90` | OutlinedButton.icon( key: const Key('profile-export-data'), | **NON VÉRIFIÉ** |
| UI-12-3 | TextButton | `lib/features/profile/presentation/my_data_section.dart:98` | TextButton( onPressed: () => context.push('/legal/confidentialite'), | **NON VÉRIFIÉ** |
| UI-12-4 | TextButton | `lib/features/profile/presentation/my_data_section.dart:102` | TextButton( onPressed: () => context.push('/legal/cgu'), | **NON VÉRIFIÉ** |
| UI-12-5 | TextButton | `lib/features/profile/presentation/my_data_section.dart:106` | TextButton( onPressed: () => context.push('/legal/mentions'), | **NON VÉRIFIÉ** |
| UI-12-6 | TextButton.icon | `lib/features/profile/presentation/my_data_section.dart:113` | TextButton.icon( key: const Key('profile-delete-account'), | **NON VÉRIFIÉ** |
| UI-12-7 | TextButton.styleFrom | `lib/features/profile/presentation/my_data_section.dart:115` | style: TextButton.styleFrom( foregroundColor: theme.colorScheme.error, | **NON VÉRIFIÉ** |
| UI-12-8 | TextField | `lib/features/profile/presentation/my_data_section.dart:161` | TextField( key: const Key('delete-account-confirmation'), | **NON VÉRIFIÉ** |
| UI-12-9 | TextButton | `lib/features/profile/presentation/my_data_section.dart:172` | TextButton( onPressed: () => Navigator.pop(context, false), | **NON VÉRIFIÉ** |
| UI-12-10 | FilledButton | `lib/features/profile/presentation/my_data_section.dart:176` | FilledButton( key: const Key('delete-account-confirm'), | **NON VÉRIFIÉ** |
| UI-12-11 | InkWell | `lib/features/profile/presentation/profile_page.dart:123` | child: InkWell( customBorder: const CircleBorder(), | **NON VÉRIFIÉ** |
| UI-12-12 | TextField | `lib/features/profile/presentation/profile_page.dart:189` | TextField( controller: _firstNameController, | **NON VÉRIFIÉ** |
| UI-12-13 | TextField | `lib/features/profile/presentation/profile_page.dart:200` | TextField( controller: _lastNameController, | **NON VÉRIFIÉ** |
| UI-12-14 | TextField | `lib/features/profile/presentation/profile_page.dart:211` | TextField( controller: _surnomController, | **NON VÉRIFIÉ** |
| UI-12-15 | OutlinedButton.icon | `lib/features/profile/presentation/profile_page.dart:226` | OutlinedButton.icon( onPressed: busy ? null : () => _changePassword(context), | **NON VÉRIFIÉ** |
| UI-12-16 | OutlinedButton.icon | `lib/features/profile/presentation/profile_page.dart:232` | OutlinedButton.icon( onPressed: busy ? null : () => _editEmail(context, profile), | **NON VÉRIFIÉ** |
| UI-12-17 | FilledButton.icon | `lib/features/profile/presentation/profile_page.dart:238` | FilledButton.icon( onPressed: busy ? null : _saveProfile, | **NON VÉRIFIÉ** |
| UI-12-18 | TextField | `lib/features/profile/presentation/profile_page.dart:400` | TextField( controller: passwordController, | **NON VÉRIFIÉ** |
| UI-12-19 | TextField | `lib/features/profile/presentation/profile_page.dart:411` | TextField( controller: confirmationController, | **NON VÉRIFIÉ** |
| UI-12-20 | TextButton | `lib/features/profile/presentation/profile_page.dart:433` | TextButton( onPressed: () => Navigator.pop(dialogContext), | **NON VÉRIFIÉ** |
| UI-12-21 | FilledButton | `lib/features/profile/presentation/profile_page.dart:437` | FilledButton( onPressed: () { | **NON VÉRIFIÉ** |
| UI-12-22 | TextField | `lib/features/profile/presentation/profile_page.dart:576` | TextField( controller: _controller, | **NON VÉRIFIÉ** |
| UI-12-23 | FilledButton | `lib/features/profile/presentation/profile_page.dart:589` | FilledButton( onPressed: () => Navigator.pop(context), | **NON VÉRIFIÉ** |
| UI-12-24 | TextButton | `lib/features/profile/presentation/profile_page.dart:594` | TextButton( onPressed: _sending ? null : () => Navigator.pop(context), | **NON VÉRIFIÉ** |
| UI-12-25 | FilledButton | `lib/features/profile/presentation/profile_page.dart:598` | FilledButton( onPressed: _sending ? null : _send, | **NON VÉRIFIÉ** |
| UI-12-26 | IconButton | `lib/features/season_wrapped/presentation/season_wrapped_button.dart:30` | return IconButton( key: const ValueKey('season-wrapped-button'), | **NON VÉRIFIÉ** |
| UI-12-27 | IconButton.styleFrom | `lib/features/season_wrapped/presentation/season_wrapped_button.dart:36` | style: IconButton.styleFrom( foregroundColor: AppTheme.accent, | **NON VÉRIFIÉ** |
| UI-12-28 | IconButton | `lib/features/season_wrapped/presentation/season_wrapped_page.dart:149` | child: IconButton( tooltip: 'Fermer', | **NON VÉRIFIÉ** |
| UI-12-29 | ListTile | `lib/features/season_wrapped/presentation/season_wrapped_page.dart:354` | ListTile( title: Text( | **NON VÉRIFIÉ** |
| UI-12-30 | GestureDetector | `lib/features/season_wrapped/presentation/season_wrapped_page.dart:472` | child: GestureDetector( behavior: HitTestBehavior.translucent, | **NON VÉRIFIÉ** |
| UI-12-31 | GestureDetector | `lib/features/season_wrapped/presentation/season_wrapped_page.dart:482` | child: GestureDetector( behavior: HitTestBehavior.translucent, | **NON VÉRIFIÉ** |
| UI-12-32 | IconButton | `lib/features/season_wrapped/presentation/season_wrapped_page.dart:608` | IconButton( key: const ValueKey('wrapped-mute-button'), | **NON VÉRIFIÉ** |
| UI-12-33 | IconButton | `lib/features/season_wrapped/presentation/season_wrapped_page.dart:616` | IconButton( key: const ValueKey('wrapped-close-button'), | **NON VÉRIFIÉ** |
| UI-12-34 | FilledButton.icon | `lib/features/season_wrapped/presentation/wrapped_slides.dart:887` | FilledButton.icon( onPressed: onShare, | **NON VÉRIFIÉ** |
| UI-12-35 | FilledButton.styleFrom | `lib/features/season_wrapped/presentation/wrapped_slides.dart:889` | style: FilledButton.styleFrom( backgroundColor: skin.badge, | **NON VÉRIFIÉ** |
| UI-12-36 | TextButton | `lib/features/season_wrapped/presentation/wrapped_slides.dart:902` | TextButton( onPressed: onShareByTheme, | **NON VÉRIFIÉ** |
| UI-12-37 | TextButton.styleFrom | `lib/features/season_wrapped/presentation/wrapped_slides.dart:904` | style: TextButton.styleFrom(foregroundColor: skin.muted), child: Text( | **NON VÉRIFIÉ** |
| UI-12-38 | TextField | `lib/features/sports_management/presentation/admin_guests_page.dart:132` | TextField( controller: firstName, | **NON VÉRIFIÉ** |
| UI-12-39 | TextField | `lib/features/sports_management/presentation/admin_guests_page.dart:144` | TextField( controller: lastName, | **NON VÉRIFIÉ** |
| UI-12-40 | SwitchListTile | `lib/features/sports_management/presentation/admin_guests_page.dart:153` | SwitchListTile( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-12-41 | TextButton | `lib/features/sports_management/presentation/admin_guests_page.dart:168` | TextButton( onPressed: () => Navigator.pop(dialogContext), | **NON VÉRIFIÉ** |
| UI-12-42 | FilledButton | `lib/features/sports_management/presentation/admin_guests_page.dart:172` | FilledButton( onPressed: () { | **NON VÉRIFIÉ** |
| UI-12-43 | TextButton | `lib/features/sports_management/presentation/admin_guests_page.dart:239` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-12-44 | FilledButton | `lib/features/sports_management/presentation/admin_guests_page.dart:243` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-12-45 | IconButton | `lib/features/sports_management/presentation/admin_guests_page.dart:348` | IconButton( tooltip: 'Actualiser', | **NON VÉRIFIÉ** |
| UI-12-46 | FilledButton | `lib/features/sports_management/presentation/admin_guests_page.dart:367` | FilledButton(onPressed: _loadMatches, child: const Text('Réessayer')), ], | **NON VÉRIFIÉ** |
| UI-12-47 | DropdownButtonFormField | `lib/features/sports_management/presentation/admin_guests_page.dart:386` | DropdownButtonFormField<String>( initialValue: _selectedMatchId, | **NON VÉRIFIÉ** |
| UI-12-48 | ListTile | `lib/features/sports_management/presentation/admin_guests_page.dart:440` | ListTile( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-12-49 | IconButton | `lib/features/sports_management/presentation/admin_guests_page.dart:457` | trailing: IconButton( tooltip: 'Retirer du match', | **NON VÉRIFIÉ** |
| UI-12-50 | FilledButton.icon | `lib/features/sports_management/presentation/admin_guests_page.dart:464` | FilledButton.icon( onPressed: _busy ? null : _createAndAdd, | **NON VÉRIFIÉ** |
| UI-12-51 | OutlinedButton.icon | `lib/features/sports_management/presentation/admin_guests_page.dart:470` | OutlinedButton.icon( // Le match choisi ici doit suivre : sans lui, l'écran de | **NON VÉRIFIÉ** |
| UI-12-52 | SwitchListTile | `lib/features/sports_management/presentation/admin_guests_page.dart:493` | SwitchListTile( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-12-53 | ListTile | `lib/features/sports_management/presentation/admin_guests_page.dart:512` | ListTile( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-12-54 | IconButton | `lib/features/sports_management/presentation/admin_guests_page.dart:533` | IconButton( tooltip: 'Changer la photo', | **NON VÉRIFIÉ** |
| UI-12-55 | IconButton | `lib/features/sports_management/presentation/admin_guests_page.dart:542` | IconButton( tooltip: assignedIds.contains(guest.id) | **NON VÉRIFIÉ** |
| UI-12-56 | IconButton | `lib/features/sports_management/presentation/admin_guests_page.dart:552` | IconButton( tooltip: 'Archiver', | **NON VÉRIFIÉ** |
| UI-12-57 | IconButton | `lib/features/sports_management/presentation/admin_guests_page.dart:561` | : IconButton( tooltip: 'Restaurer', | **NON VÉRIFIÉ** |

Sans constructeur détecté : 
- `lib/features/season_wrapped/presentation/season_wrapped_entry_button.dart` : NON VÉRIFIÉ
- `lib/features/season_wrapped/presentation/season_wrapped_share_sheet.dart` : NON VÉRIFIÉ
- `lib/features/season_wrapped/presentation/wrapped_ink_pitch.dart` : NON VÉRIFIÉ
- `lib/features/season_wrapped/presentation/wrapped_motion.dart` : NON VÉRIFIÉ
- `lib/features/season_wrapped/presentation/wrapped_theme.dart` : NON VÉRIFIÉ
