# Contrôles Flutter — lot 10

Fichiers lus 12/12; positions 109–120/181. Occurrences 34. Contrôles sources, pas boutons rendus ; aucune interaction à l'écran : **NON VÉRIFIÉ**.

| ID | Constructeur | Fichier/ligne | Extrait | Test écran |
|---|---|---|---|---|
| UI-10-1 | InkWell | `lib/features/matches/presentation/widgets/match_form_section.dart:109` | child: InkWell( onTap: enabled ? onTap : null, | **NON VÉRIFIÉ** |
| UI-10-2 | InkWell | `lib/features/matches/presentation/widgets/match_info_tab.dart:266` | child: InkWell( onTap: () => context.push(route), | **NON VÉRIFIÉ** |
| UI-10-3 | FilledButton | `lib/features/matches/presentation/widgets/match_meeting_time_picker.dart:130` | return FilledButton( style: FilledButton.styleFrom( | **NON VÉRIFIÉ** |
| UI-10-4 | FilledButton.styleFrom | `lib/features/matches/presentation/widgets/match_meeting_time_picker.dart:131` | style: FilledButton.styleFrom( foregroundColor: Theme.of(context).colorScheme.secondary, | **NON VÉRIFIÉ** |
| UI-10-5 | OutlinedButton | `lib/features/matches/presentation/widgets/match_meeting_time_picker.dart:138` | return OutlinedButton( onPressed: enabled ? onPressed : null, | **NON VÉRIFIÉ** |
| UI-10-6 | InkWell | `lib/features/matches/presentation/widgets/match_result_score_chip.dart:69` | child: InkWell( onTap: onTap, | **NON VÉRIFIÉ** |
| UI-10-7 | TextButton | `lib/features/matches/presentation/widgets/match_wheel_picker.dart:251` | TextButton(onPressed: onCancel, child: const Text('Annuler')), Expanded( | **NON VÉRIFIÉ** |
| UI-10-8 | FilledButton | `lib/features/matches/presentation/widgets/match_wheel_picker.dart:262` | FilledButton(onPressed: onDone, child: const Text('Valider')), ], | **NON VÉRIFIÉ** |
| UI-10-9 | TextButton.icon | `lib/features/more/presentation/more_page.dart:105` | child: TextButton.icon( onPressed: authState.isBusy | **NON VÉRIFIÉ** |
| UI-10-10 | TextButton.styleFrom | `lib/features/more/presentation/more_page.dart:111` | style: TextButton.styleFrom(foregroundColor: AppTheme.error), ), | **NON VÉRIFIÉ** |
| UI-10-11 | ListTile | `lib/features/more/presentation/more_page.dart:135` | loading: () => const ListTile( leading: Icon(Icons.flag_outlined), | **NON VÉRIFIÉ** |
| UI-10-12 | ListTile | `lib/features/more/presentation/more_page.dart:140` | error: (_, __) => ListTile( leading: const Icon(Icons.refresh), | **NON VÉRIFIÉ** |
| UI-10-13 | ListTile | `lib/features/more/presentation/more_page.dart:156` | return ListTile( leading: const Icon(Icons.add_circle_outline), | **NON VÉRIFIÉ** |
| UI-10-14 | ListTile | `lib/features/more/presentation/more_page.dart:162` | return ListTile( leading: Icon(Icons.flag_outlined, color: AppTheme.error), | **NON VÉRIFIÉ** |
| UI-10-15 | TextButton | `lib/features/more/presentation/more_page.dart:190` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-10-16 | FilledButton | `lib/features/more/presentation/more_page.dart:194` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-10-17 | TextFormField | `lib/features/more/presentation/more_page.dart:225` | content: TextFormField( initialValue: enteredName, | **NON VÉRIFIÉ** |
| UI-10-18 | TextButton | `lib/features/more/presentation/more_page.dart:231` | TextButton( onPressed: () => Navigator.pop(dialogContext), | **NON VÉRIFIÉ** |
| UI-10-19 | FilledButton | `lib/features/more/presentation/more_page.dart:235` | FilledButton( onPressed: () => Navigator.pop(dialogContext, enteredName), | **NON VÉRIFIÉ** |
| UI-10-20 | InkWell | `lib/features/more/presentation/more_page.dart:283` | child: InkWell( onTap: onTap, | **NON VÉRIFIÉ** |
| UI-10-21 | ListTile | `lib/features/more/presentation/more_page.dart:396` | return ListTile( leading: Icon(icon, color: AppTheme.primaryBright), | **NON VÉRIFIÉ** |
| UI-10-22 | InkWell | `lib/features/notifications/presentation/notification_history_view.dart:242` | child: InkWell( onTap: onTap, | **NON VÉRIFIÉ** |
| UI-10-23 | OutlinedButton | `lib/features/notifications/presentation/notification_history_view.dart:333` | OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')), ], | **NON VÉRIFIÉ** |
| UI-10-24 | IconButton | `lib/features/notifications/presentation/notification_inbox_button.dart:23` | child: IconButton( key: const ValueKey('notification-inbox-button'), | **NON VÉRIFIÉ** |
| UI-10-25 | IconButton.styleFrom | `lib/features/notifications/presentation/notification_inbox_button.dart:29` | style: IconButton.styleFrom( foregroundColor: AppTheme.primaryBright, | **NON VÉRIFIÉ** |
| UI-10-26 | SegmentedButton | `lib/features/notifications/presentation/notifications_page.dart:55` | child: SegmentedButton<NotificationsTab>( expandedInsets: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-10-27 | OutlinedButton | `lib/features/notifications/presentation/notifications_page.dart:432` | child: OutlinedButton( onPressed: () => context.push('/admin/notification'), | **NON VÉRIFIÉ** |
| UI-10-28 | PopupMenuButton | `lib/features/notifications/presentation/notifications_page.dart:540` | return PopupMenuButton<_TestNotificationOption>( enabled: !_sending, | **NON VÉRIFIÉ** |
| UI-10-29 | OutlinedButton | `lib/features/notifications/presentation/notifications_page.dart:554` | child: OutlinedButton( onPressed: _sending ? null : () {}, | **NON VÉRIFIÉ** |
| UI-10-30 | TextButton | `lib/features/notifications/presentation/notifications_page.dart:644` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-10-31 | FilledButton | `lib/features/notifications/presentation/notifications_page.dart:648` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-10-32 | SwitchListTile.adaptive | `lib/features/notifications/presentation/notifications_page.dart:668` | child: SwitchListTile.adaptive( contentPadding: const EdgeInsets.symmetric(horizontal: 16), | **NON VÉRIFIÉ** |
| UI-10-33 | TextButton | `lib/features/notifications/presentation/push_device_banner.dart:91` | TextButton( onPressed: _busy ? null : (blocked ? _recheck : _enable), | **NON VÉRIFIÉ** |
| UI-10-34 | TextButton | `lib/features/notifications/presentation/push_device_banner.dart:95` | TextButton( onPressed: _busy ? null : _decline, | **NON VÉRIFIÉ** |

Sans constructeur détecté : 
- `lib/features/matches/presentation/widgets/upcoming_match_fixture_header.dart` : NON VÉRIFIÉ
- `lib/features/players/presentation/hero_photo_margin.dart` : NON VÉRIFIÉ
