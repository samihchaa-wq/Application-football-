# Contrôles Flutter — lot 4

Fichiers lus 12/12; positions 37–48/181. Occurrences 95. Contrôles sources, pas boutons rendus ; aucune interaction à l'écran : **NON VÉRIFIÉ**.

| ID | Constructeur | Fichier/ligne | Extrait | Test écran |
|---|---|---|---|---|
| UI-4-1 | SwitchListTile | `lib/features/admin/presentation/club_kits_page.dart:104` | SwitchListTile( key: const ValueKey('dress-players'), | **NON VÉRIFIÉ** |
| UI-4-2 | FilledButton | `lib/features/admin/presentation/club_kits_page.dart:144` | FilledButton( key: const ValueKey('club-kits-save'), | **NON VÉRIFIÉ** |
| UI-4-3 | TextField | `lib/features/admin/presentation/club_kits_page.dart:215` | TextField( key: ValueKey('kit-label-${kit.slot.id}'), | **NON VÉRIFIÉ** |
| UI-4-4 | SwitchListTile.adaptive | `lib/features/admin/presentation/club_kits_page.dart:226` | SwitchListTile.adaptive( key: ValueKey('kit-enabled-${kit.slot.id}'), | **NON VÉRIFIÉ** |
| UI-4-5 | InkWell | `lib/features/admin/presentation/club_kits_page.dart:337` | child: InkWell( key: ValueKey('$keyPrefix-$hex'), | **NON VÉRIFIÉ** |
| UI-4-6 | DropdownButtonFormField | `lib/features/admin/presentation/club_kits_page.dart:379` | child: DropdownButtonFormField<KitPattern>( initialValue: value, | **NON VÉRIFIÉ** |
| UI-4-7 | InkWell | `lib/features/admin/presentation/club_settings_page.dart:243` | child: InkWell( key: ValueKey('$keyPrefix-$hex'), | **NON VÉRIFIÉ** |
| UI-4-8 | TextButton | `lib/features/admin/presentation/club_settings_page.dart:340` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-4-9 | FilledButton | `lib/features/admin/presentation/club_settings_page.dart:344` | FilledButton( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-4-10 | TextButton | `lib/features/admin/presentation/club_settings_page.dart:421` | TextButton( onPressed: () => Navigator.pop(dialogContext), | **NON VÉRIFIÉ** |
| UI-4-11 | IconButton | `lib/features/admin/presentation/club_settings_page.dart:431` | IconButton( key: ValueKey('club-info-$key'), | **NON VÉRIFIÉ** |
| UI-4-12 | ExpansionTile | `lib/features/admin/presentation/club_settings_page.dart:455` | child: ExpansionTile( key: ValueKey('club-section-$key'), | **NON VÉRIFIÉ** |
| UI-4-13 | SwitchListTile.adaptive | `lib/features/admin/presentation/club_settings_page.dart:563` | SwitchListTile.adaptive( key: ValueKey('club-module-${module.key}'), | **NON VÉRIFIÉ** |
| UI-4-14 | SwitchListTile.adaptive | `lib/features/admin/presentation/club_settings_page.dart:591` | Widget _boolRuleTile(ClubRule rule) => SwitchListTile.adaptive( key: ValueKey('club-rule-${rule.key} | **NON VÉRIFIÉ** |
| UI-4-15 | DropdownButton | `lib/features/admin/presentation/club_settings_page.dart:611` | DropdownButton<int>( key: ValueKey('club-rule-${rule.key}-select'), | **NON VÉRIFIÉ** |
| UI-4-16 | ListTile | `lib/features/admin/presentation/club_settings_page.dart:634` | return ListTile( key: ValueKey('club-rule-${rule.key}'), | **NON VÉRIFIÉ** |
| UI-4-17 | IconButton | `lib/features/admin/presentation/club_settings_page.dart:641` | IconButton( key: ValueKey('club-rule-${rule.key}-minus'), | **NON VÉRIFIÉ** |
| UI-4-18 | IconButton | `lib/features/admin/presentation/club_settings_page.dart:653` | IconButton( key: ValueKey('club-rule-${rule.key}-plus'), | **NON VÉRIFIÉ** |
| UI-4-19 | DropdownButton | `lib/features/admin/presentation/club_settings_page.dart:701` | DropdownButton<WaitlistMode>( key: ValueKey('club-rule-${rule.key}-select'), | **NON VÉRIFIÉ** |
| UI-4-20 | FilledButton | `lib/features/admin/presentation/club_settings_page.dart:741` | FilledButton(onPressed: _load, child: const Text('Réessayer')), ], | **NON VÉRIFIÉ** |
| UI-4-21 | TextField | `lib/features/admin/presentation/club_settings_page.dart:758` | TextField( key: const Key('club-settings-name'), | **NON VÉRIFIÉ** |
| UI-4-22 | TextField | `lib/features/admin/presentation/club_settings_page.dart:768` | TextField( key: const Key('club-settings-short-name'), | **NON VÉRIFIÉ** |
| UI-4-23 | FilledButton | `lib/features/admin/presentation/club_settings_page.dart:785` | child: FilledButton( onPressed: _savingIdentity ? null : _saveIdentity, | **NON VÉRIFIÉ** |
| UI-4-24 | FilledButton.tonalIcon | `lib/features/admin/presentation/club_settings_page.dart:807` | FilledButton.tonalIcon( key: const Key('club-logo-pick'), | **NON VÉRIFIÉ** |
| UI-4-25 | OutlinedButton | `lib/features/admin/presentation/club_settings_page.dart:815` | OutlinedButton( key: const Key('club-logo-remove'), | **NON VÉRIFIÉ** |
| UI-4-26 | ListTile | `lib/features/admin/presentation/club_settings_page.dart:846` | ListTile( key: const ValueKey('club-kits-entry'), | **NON VÉRIFIÉ** |
| UI-4-27 | ListTile | `lib/features/admin/presentation/club_settings_page.dart:863` | ListTile( key: const Key('club-usual-squad-size'), | **NON VÉRIFIÉ** |
| UI-4-28 | IconButton | `lib/features/admin/presentation/club_settings_page.dart:874` | IconButton( key: const Key('club-usual-squad-size-minus'), | **NON VÉRIFIÉ** |
| UI-4-29 | IconButton | `lib/features/admin/presentation/club_settings_page.dart:882` | IconButton( key: const Key('club-usual-squad-size-plus'), | **NON VÉRIFIÉ** |
| UI-4-30 | TextField | `lib/features/admin/presentation/club_settings_page.dart:897` | TextField( key: const Key('club-settings-home-address'), | **NON VÉRIFIÉ** |
| UI-4-31 | FilledButton | `lib/features/admin/presentation/club_settings_page.dart:916` | child: FilledButton( key: const Key('club-settings-save-home-address'), | **NON VÉRIFIÉ** |
| UI-4-32 | FilledButton.tonalIcon | `lib/features/admin/presentation/club_settings_page.dart:977` | FilledButton.tonalIcon( onPressed: _copyInviteLink, | **NON VÉRIFIÉ** |
| UI-4-33 | OutlinedButton.icon | `lib/features/admin/presentation/club_settings_page.dart:982` | OutlinedButton.icon( onPressed: _renewingCode ? null : _renewInviteCode, | **NON VÉRIFIÉ** |
| UI-4-34 | TextButton | `lib/features/admin/presentation/opponent_stadium_library_page.dart:134` | TextButton( onPressed: () => Navigator.pop(dialogContext, false), | **NON VÉRIFIÉ** |
| UI-4-35 | FilledButton.tonal | `lib/features/admin/presentation/opponent_stadium_library_page.dart:138` | FilledButton.tonal( onPressed: () => Navigator.pop(dialogContext, true), | **NON VÉRIFIÉ** |
| UI-4-36 | FloatingActionButton.extended | `lib/features/admin/presentation/opponent_stadium_library_page.dart:178` | floatingActionButton: FloatingActionButton.extended( onPressed: _saving ? null : () => _openEditor() | **NON VÉRIFIÉ** |
| UI-4-37 | TextField | `lib/features/admin/presentation/opponent_stadium_library_page.dart:189` | TextField( controller: _searchController, | **NON VÉRIFIÉ** |
| UI-4-38 | FilledButton | `lib/features/admin/presentation/opponent_stadium_library_page.dart:212` | FilledButton( onPressed: _load, | **NON VÉRIFIÉ** |
| UI-4-39 | ListTile | `lib/features/admin/presentation/opponent_stadium_library_page.dart:232` | child: ListTile( contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8), | **NON VÉRIFIÉ** |
| UI-4-40 | PopupMenuButton | `lib/features/admin/presentation/opponent_stadium_library_page.dart:271` | trailing: PopupMenuButton<String>( enabled: !_saving, | **NON VÉRIFIÉ** |
| UI-4-41 | ListTile | `lib/features/admin/presentation/opponent_stadium_library_page.dart:280` | child: ListTile( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-4-42 | ListTile | `lib/features/admin/presentation/opponent_stadium_library_page.dart:288` | child: ListTile( contentPadding: EdgeInsets.zero, | **NON VÉRIFIÉ** |
| UI-4-43 | TextFormField | `lib/features/admin/presentation/opponent_stadium_library_page.dart:362` | TextFormField( controller: _nameController, | **NON VÉRIFIÉ** |
| UI-4-44 | TextFormField | `lib/features/admin/presentation/opponent_stadium_library_page.dart:380` | TextFormField( controller: _stadiumController, | **NON VÉRIFIÉ** |
| UI-4-45 | TextFormField | `lib/features/admin/presentation/opponent_stadium_library_page.dart:391` | TextFormField( controller: _addressController, | **NON VÉRIFIÉ** |
| UI-4-46 | FilledButton.icon | `lib/features/admin/presentation/opponent_stadium_library_page.dart:406` | FilledButton.icon( onPressed: () { | **NON VÉRIFIÉ** |
| UI-4-47 | FilledButton.icon | `lib/features/auth/presentation/auth_loading_page.dart:72` | FilledButton.icon( onPressed: auth.isLoading | **NON VÉRIFIÉ** |
| UI-4-48 | TextButton | `lib/features/auth/presentation/auth_loading_page.dart:88` | TextButton( onPressed: auth.isLoading | **NON VÉRIFIÉ** |
| UI-4-49 | FilledButton.icon | `lib/features/auth/presentation/auth_loading_page.dart:143` | FilledButton.icon( onPressed: auth.isLoading | **NON VÉRIFIÉ** |
| UI-4-50 | TextButton | `lib/features/auth/presentation/auth_loading_page.dart:159` | TextButton( onPressed: auth.isLoading | **NON VÉRIFIÉ** |
| UI-4-51 | FilledButton | `lib/features/auth/presentation/auth_register_page.dart:213` | FilledButton( onPressed: () => Navigator.pop(dialogContext), | **NON VÉRIFIÉ** |
| UI-4-52 | SegmentedButton | `lib/features/auth/presentation/auth_register_page.dart:244` | SegmentedButton<RegisterMode>( segments: const [ | **NON VÉRIFIÉ** |
| UI-4-53 | TextField | `lib/features/auth/presentation/auth_register_page.dart:265` | TextField( key: const Key('register-invite-code'), | **NON VÉRIFIÉ** |
| UI-4-54 | TextField | `lib/features/auth/presentation/auth_register_page.dart:280` | TextField( key: const Key('register-club-name'), | **NON VÉRIFIÉ** |
| UI-4-55 | TextField | `lib/features/auth/presentation/auth_register_page.dart:290` | TextField( key: const Key('register-club-short-name'), | **NON VÉRIFIÉ** |
| UI-4-56 | TextField | `lib/features/auth/presentation/auth_register_page.dart:306` | TextField( controller: _firstNameController, | **NON VÉRIFIÉ** |
| UI-4-57 | TextField | `lib/features/auth/presentation/auth_register_page.dart:316` | TextField( controller: _lastNameController, | **NON VÉRIFIÉ** |
| UI-4-58 | TextField | `lib/features/auth/presentation/auth_register_page.dart:329` | TextField( controller: _emailController, | **NON VÉRIFIÉ** |
| UI-4-59 | TextField | `lib/features/auth/presentation/auth_register_page.dart:352` | TextField( controller: _passwordController, | **NON VÉRIFIÉ** |
| UI-4-60 | IconButton | `lib/features/auth/presentation/auth_register_page.dart:362` | suffixIcon: IconButton( tooltip: _obscurePassword | **NON VÉRIFIÉ** |
| UI-4-61 | TextField | `lib/features/auth/presentation/auth_register_page.dart:378` | TextField( controller: _confirmController, | **NON VÉRIFIÉ** |
| UI-4-62 | FilledButton.icon | `lib/features/auth/presentation/auth_register_page.dart:404` | FilledButton.icon( onPressed: _submitting ? null : _submit, | **NON VÉRIFIÉ** |
| UI-4-63 | TextButton | `lib/features/auth/presentation/auth_register_page.dart:422` | TextButton( onPressed: _submitting ? null : () => context.go('/auth/sign-in'), | **NON VÉRIFIÉ** |
| UI-4-64 | TextField | `lib/features/auth/presentation/auth_sign_in_page.dart:71` | TextField( controller: _usernameController, | **NON VÉRIFIÉ** |
| UI-4-65 | TextField | `lib/features/auth/presentation/auth_sign_in_page.dart:82` | TextField( controller: _passwordController, | **NON VÉRIFIÉ** |
| UI-4-66 | IconButton | `lib/features/auth/presentation/auth_sign_in_page.dart:93` | suffixIcon: IconButton( tooltip: _obscurePassword | **NON VÉRIFIÉ** |
| UI-4-67 | TextButton | `lib/features/auth/presentation/auth_sign_in_page.dart:110` | child: TextButton( onPressed: authState.isLoading ? null : _forgotPassword, | **NON VÉRIFIÉ** |
| UI-4-68 | FilledButton.icon | `lib/features/auth/presentation/auth_sign_in_page.dart:115` | FilledButton.icon( onPressed: authState.isLoading ? null : _submit, | **NON VÉRIFIÉ** |
| UI-4-69 | OutlinedButton.icon | `lib/features/auth/presentation/auth_sign_in_page.dart:126` | OutlinedButton.icon( onPressed: | **NON VÉRIFIÉ** |
| UI-4-70 | TextField | `lib/features/auth/presentation/auth_sign_in_page.dart:223` | TextField( controller: _controller, | **NON VÉRIFIÉ** |
| UI-4-71 | FilledButton | `lib/features/auth/presentation/auth_sign_in_page.dart:237` | FilledButton( onPressed: () => Navigator.pop(context), | **NON VÉRIFIÉ** |
| UI-4-72 | TextButton | `lib/features/auth/presentation/auth_sign_in_page.dart:242` | TextButton( onPressed: _sending ? null : () => Navigator.pop(context), | **NON VÉRIFIÉ** |
| UI-4-73 | FilledButton | `lib/features/auth/presentation/auth_sign_in_page.dart:246` | FilledButton( onPressed: _sending ? null : _send, | **NON VÉRIFIÉ** |
| UI-4-74 | SegmentedButton | `lib/features/auth/presentation/choose_club_page.dart:124` | SegmentedButton<RegisterMode>( segments: const [ | **NON VÉRIFIÉ** |
| UI-4-75 | TextField | `lib/features/auth/presentation/choose_club_page.dart:145` | TextField( key: const Key('choose-club-name'), | **NON VÉRIFIÉ** |
| UI-4-76 | TextField | `lib/features/auth/presentation/choose_club_page.dart:155` | TextField( controller: _clubShortNameController, | **NON VÉRIFIÉ** |
| UI-4-77 | TextField | `lib/features/auth/presentation/choose_club_page.dart:164` | TextField( key: const Key('choose-club-code'), | **NON VÉRIFIÉ** |
| UI-4-78 | TextField | `lib/features/auth/presentation/choose_club_page.dart:176` | TextField( controller: _firstNameController, | **NON VÉRIFIÉ** |
| UI-4-79 | TextField | `lib/features/auth/presentation/choose_club_page.dart:185` | TextField( controller: _lastNameController, | **NON VÉRIFIÉ** |
| UI-4-80 | FilledButton.icon | `lib/features/auth/presentation/choose_club_page.dart:213` | FilledButton.icon( onPressed: _submitting ? null : _submit, | **NON VÉRIFIÉ** |
| UI-4-81 | TextButton | `lib/features/auth/presentation/choose_club_page.dart:231` | TextButton( onPressed: _submitting | **NON VÉRIFIÉ** |
| UI-4-82 | FilledButton | `lib/features/auth/presentation/confirm_email_page.dart:101` | FilledButton(onPressed: _confirm, child: const Text('Réessayer')) else | **NON VÉRIFIÉ** |
| UI-4-83 | FilledButton | `lib/features/auth/presentation/confirm_email_page.dart:103` | FilledButton( onPressed: () => context.go('/matches'), | **NON VÉRIFIÉ** |
| UI-4-84 | RadioListTile | `lib/features/auth/presentation/consent_fields.dart:43` | RadioListTile<AgeConfirmation>( key: Key('register-age-15-or-more'), | **NON VÉRIFIÉ** |
| UI-4-85 | RadioListTile | `lib/features/auth/presentation/consent_fields.dart:49` | RadioListTile<AgeConfirmation>( key: Key('register-age-parental-consent'), | **NON VÉRIFIÉ** |
| UI-4-86 | CheckboxListTile | `lib/features/auth/presentation/consent_fields.dart:60` | CheckboxListTile( key: const Key('register-accept-terms'), | **NON VÉRIFIÉ** |
| UI-4-87 | CheckboxListTile | `lib/features/auth/presentation/consent_fields.dart:72` | CheckboxListTile( key: const Key('register-accept-club-contract'), | **NON VÉRIFIÉ** |
| UI-4-88 | TextButton | `lib/features/auth/presentation/consent_fields.dart:89` | TextButton( onPressed: () => context.push('/legal/cgu'), | **NON VÉRIFIÉ** |
| UI-4-89 | TextButton | `lib/features/auth/presentation/consent_fields.dart:93` | TextButton( onPressed: () => context.push('/legal/confidentialite'), | **NON VÉRIFIÉ** |
| UI-4-90 | TextButton | `lib/features/auth/presentation/consent_fields.dart:98` | TextButton( onPressed: () => context.push('/legal/cgv'), | **NON VÉRIFIÉ** |
| UI-4-91 | TextButton | `lib/features/auth/presentation/consent_fields.dart:102` | TextButton( onPressed: () => context.push('/legal/donnees-club'), | **NON VÉRIFIÉ** |
| UI-4-92 | TextField | `lib/features/auth/presentation/forced_password_change_page.dart:174` | TextField( controller: _passwordController, | **NON VÉRIFIÉ** |
| UI-4-93 | IconButton | `lib/features/auth/presentation/forced_password_change_page.dart:184` | suffixIcon: IconButton( tooltip: _obscure | **NON VÉRIFIÉ** |
| UI-4-94 | TextField | `lib/features/auth/presentation/forced_password_change_page.dart:199` | TextField( controller: _confirmController, | **NON VÉRIFIÉ** |
| UI-4-95 | FilledButton.icon | `lib/features/auth/presentation/forced_password_change_page.dart:214` | FilledButton.icon( onPressed: isBusy ? null : _submit, | **NON VÉRIFIÉ** |

Sans constructeur détecté : 
- `lib/features/admin/presentation/club_subscription_section.dart` : NON VÉRIFIÉ
- `lib/features/auth/presentation/auth_state.dart` : NON VÉRIFIÉ
