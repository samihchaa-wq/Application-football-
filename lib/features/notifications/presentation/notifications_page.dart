import 'package:petit_filet/core/providers/supabase_provider.dart';
import 'package:petit_filet/core/theme/app_spacing.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/widgets/pf_app_bar.dart';
import 'package:petit_filet/core/widgets/pf_loader.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/match_live/presentation/widgets/match_live_notification_bell.dart';
import 'package:petit_filet/features/notifications/presentation/notification_history_view.dart';
import 'package:petit_filet/features/preferences/data/preferences_repository.dart';
import 'package:petit_filet/features/preferences/data/push_subscriptions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Onglets de l'écran Notifications.
enum NotificationsTab { history, settings }

/// Écran ouvert par la cloche de l'en-tête : l'historique des notifications
/// reçues, et leurs réglages.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    this.initialTab = NotificationsTab.history,
  });

  final NotificationsTab initialTab;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late NotificationsTab _tab = widget.initialTab;

  /// Les réglages interrogent le téléphone et le serveur : ils ne sont
  /// construits qu'à la première visite de leur onglet, puis gardés.
  late bool _settingsBuilt = _tab == NotificationsTab.settings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PfAppBar(title: const Text('Notifications')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenGutter,
              AppSpacing.contentGap,
              AppSpacing.screenGutter,
              AppSpacing.contentGap,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<NotificationsTab>(
                expandedInsets: EdgeInsets.zero,
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: NotificationsTab.history,
                    label: Text('Historique'),
                  ),
                  ButtonSegment(
                    value: NotificationsTab.settings,
                    label: Text('Paramètres'),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (value) {
                  setState(() {
                    _tab = value.first;
                    if (_tab == NotificationsTab.settings) {
                      _settingsBuilt = true;
                    }
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab.index,
              children: [
                const NotificationHistoryView(),
                _settingsBuilt
                    ? const NotificationSettingsView()
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Réglages des notifications (onglet Paramètres).
class NotificationSettingsView extends ConsumerWidget {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(pushStatusProvider)
          ..invalidate(appPreferencesProvider)
          ..invalidate(adminAvailabilityChangeNotificationProvider);
        await Future.wait([
          ref.read(pushStatusProvider.future),
          ref.read(appPreferencesProvider.future),
        ]);
        if (ref.read(isAdminViewProvider)) {
          await ref.read(adminAvailabilityChangeNotificationProvider.future);
        }
      },
      // Même taille de texte partout : celle des lignes de la liste des
      // notifications essentielles.
      child: ListTileTheme(
        data: ListTileThemeData(
          titleTextStyle: Theme.of(context).textTheme.bodyMedium,
        ),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: const [
            _EssentialNotificationsCard(),
            SizedBox(height: 12),
            _OptionalNotificationsCard(),
            _NotificationActionsRow(),
            _AdminResumeNotificationsCard(),
          ],
        ),
      ),
    );
  }
}

/// Ce que cet appareil peut recevoir, d'après la cloche du haut.
enum _DeviceReception { unknown, receives, switchedOff, unavailable }

/// Les réglages ci-dessous valent pour le compte, mais rien n'arrive sur un
/// appareil désabonné ou qui ne sait pas recevoir de notifications. Les
/// laisser verts ferait croire le contraire.
final _deviceReceptionProvider = Provider.autoDispose<_DeviceReception>((ref) {
  final statusAsync = ref.watch(pushStatusProvider);
  if (statusAsync.hasError) return _DeviceReception.unavailable;
  final status = statusAsync.valueOrNull;
  if (status == null) return _DeviceReception.unknown;
  if (!status.supported) return _DeviceReception.unavailable;
  return status.subscribed
      ? _DeviceReception.receives
      : _DeviceReception.switchedOff;
});

class _OptionalNotificationsCard extends ConsumerWidget {
  const _OptionalNotificationsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(appPreferencesProvider);
    // Une fonctionnalité coupée par le club n'envoie plus rien : sa cloche
    // disparaît aussi.
    final predictionsEnabled =
        ref.watch(clubModuleEnabledProvider(ClubModule.predictions));
    final motmEnabled =
        ref.watch(clubModuleEnabledProvider(ClubModule.manOfTheMatch));
    final badgesEnabled =
        ref.watch(clubModuleEnabledProvider(ClubModule.badges));
    // Un appareil qui ne sait pas recevoir est déjà signalé par l'encadré du
    // haut : seules les cloches passent en gris ici.
    final deviceNote =
        ref.watch(_deviceReceptionProvider) == _DeviceReception.switchedOff
            ? 'Coupées sur cet appareil'
            : null;

    return Card(
      child: Padding(
        // Mêmes marges que l'encadré du haut : les cloches s'alignent.
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (deviceNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  deviceNote,
                  style: const TextStyle(color: AppTheme.textFaint),
                ),
              ),
            preferencesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: PfProgressIndicator()),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Impossible de charger tes préférences.'),
              ),
              data: (preferences) => Column(
                children: [
                  if (predictionsEnabled)
                    _BellToggleTile(
                      title: 'Rappel pronostic',
                      value: preferences.predictionNotifications,
                      onChanged: (value) => _update(
                        context,
                        ref,
                        preferences.copyWith(predictionNotifications: value),
                      ),
                    ),
                  if (motmEnabled)
                    _BellToggleTile(
                      title: 'Vote de l’Homme du match',
                      value: preferences.motmVoteNotifications,
                      onChanged: (value) => _update(
                        context,
                        ref,
                        preferences.copyWith(motmVoteNotifications: value),
                      ),
                    ),
                  _BellToggleTile(
                    title: 'Composition en ligne',
                    value: preferences.compositionNotifications,
                    onChanged: (value) => _update(
                      context,
                      ref,
                      preferences.copyWith(compositionNotifications: value),
                    ),
                  ),
                  if (badgesEnabled)
                    _BellToggleTile(
                      title: 'Badge débloqué',
                      value: preferences.badgeNotifications,
                      onChanged: (value) => _updateBadges(context, ref, value),
                    ),
                ],
              ),
            ),
            // Réglage réservé aux administrateurs : invisible pour les autres.
            const _AdminAvailabilityNotificationTile(),
          ],
        ),
      ),
    );
  }

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    AppPreferences preferences,
  ) async {
    try {
      await ref.read(preferencesRepositoryProvider).update(preferences);
      ref.invalidate(appPreferencesProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’enregistrer ce réglage.')),
        );
      }
    }
  }

  Future<void> _updateBadges(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    try {
      await ref
          .read(preferencesRepositoryProvider)
          .updateBadgeNotifications(enabled);
      ref.invalidate(appPreferencesProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’enregistrer ce réglage.')),
        );
      }
    }
  }
}

/// Une notification réglable : son nom et une cloche, verte quand elle est
/// activée, grise sinon — comme celle des notifications essentielles. Quand
/// cet appareil ne reçoit rien, la cloche est grise et inactive : le réglage
/// du compte est conservé et réapparaît dès que l'appareil est réabonné.
class _BellToggleTile extends ConsumerStatefulWidget {
  const _BellToggleTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;

  /// `null` désactive la cloche.
  final Future<void> Function(bool value)? onChanged;

  @override
  ConsumerState<_BellToggleTile> createState() => _BellToggleTileState();
}

class _BellToggleTileState extends ConsumerState<_BellToggleTile> {
  bool _busy = false;

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      await widget.onChanged!(!widget.value);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reception = ref.watch(_deviceReceptionProvider);
    final deviceOff = reception == _DeviceReception.switchedOff ||
        reception == _DeviceReception.unavailable;
    final onChanged = deviceOff ? null : widget.onChanged;
    final active = widget.value && !deviceOff;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(widget.title)),
          SizedBox.square(
            dimension: 40,
            child: NotificationBellButton(
              active: active,
              busy: _busy,
              onPressed: onChanged == null ? null : _toggle,
              label: deviceOff
                  ? '« ${widget.title} » : coupée sur cet appareil'
                  : active
                      ? 'Désactiver « ${widget.title} »'
                      : 'Activer « ${widget.title} »',
            ),
          ),
        ],
      ),
    );
  }
}

final adminAvailabilityChangeNotificationProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final response = await ref.read(supabaseClientProvider).rpc('get_my_profile');
  if (response is! Map) return true;
  final profile = Map<String, dynamic>.from(response);
  return profile['notify_admin_availability_change'] != false;
});

class _AdminAvailabilityNotificationTile extends ConsumerStatefulWidget {
  const _AdminAvailabilityNotificationTile();

  @override
  ConsumerState<_AdminAvailabilityNotificationTile> createState() =>
      _AdminAvailabilityNotificationTileState();
}

class _AdminAvailabilityNotificationTileState
    extends ConsumerState<_AdminAvailabilityNotificationTile> {
  bool _updating = false;

  Future<void> _toggle(bool enabled) async {
    setState(() => _updating = true);
    var message = enabled
        ? 'Notification de changement de disponibilité activée.'
        : 'Notification de changement de disponibilité désactivée.';
    try {
      final result = await ref.read(supabaseClientProvider).rpc(
        'update_my_admin_availability_notification',
        params: {'p_enabled': enabled},
      );
      if (result != true) {
        throw StateError('Preference not saved');
      }
      ref.invalidate(adminAvailabilityChangeNotificationProvider);
    } catch (_) {
      message = 'Impossible d’enregistrer ce réglage.';
    }
    if (!mounted) return;
    setState(() => _updating = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(isAdminViewProvider)) return const SizedBox.shrink();
    final preferenceAsync =
        ref.watch(adminAvailabilityChangeNotificationProvider);

    return preferenceAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: PfProgressIndicator()),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Impossible de charger le réglage administrateur.'),
      ),
      data: (enabled) => _BellToggleTile(
        title: 'Changement de disponibilité d’un joueur',
        value: enabled,
        onChanged: _updating ? null : _toggle,
      ),
    );
  }
}

class _NotificationActionsRow extends ConsumerWidget {
  const _NotificationActionsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminViewProvider);

    // Deux boutons l'un sous l'autre : côte à côte, « Envoyer une
    // notification » était coupé en « Envoyer une noti… ».
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TestPushButton(),
          if (isAdmin) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.push('/admin/notification'),
              child: const Text('Envoyer une notification'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TestNotificationOption {
  const _TestNotificationOption(
    this.kind,
    this.label, {
    this.adminOnly = false,
  });

  final String kind;
  final String label;
  final bool adminOnly;
}

const _testNotificationOptions = <_TestNotificationOption>[
  _TestNotificationOption('test', 'Test technique'),
  _TestNotificationOption('availability_open', 'Disponibilités ouvertes'),
  _TestNotificationOption('availability_manual', 'Relance disponibilité'),
  _TestNotificationOption('convocation_promoted', 'Passage en convoqué'),
  _TestNotificationOption(
    'convocation_demoted',
    'Passage en liste d’attente',
  ),
  _TestNotificationOption('composition_published', 'Composition en ligne'),
  _TestNotificationOption('prediction_j5', 'Pronostic'),
  _TestNotificationOption('match_cancelled', 'Match annulé'),
  _TestNotificationOption('match_rescheduled_date', 'Match reporté'),
  _TestNotificationOption('match_rescheduled_time', 'Horaire modifié'),
  _TestNotificationOption('motm_open', 'Vote de l’Homme du match'),
  _TestNotificationOption(
      'motm_result_general', 'Résultat de l’Homme du match'),
  _TestNotificationOption('motm_result_winner', 'Tu es l’Homme du match'),
  _TestNotificationOption('badge_unlocked', 'Badge débloqué'),
  _TestNotificationOption('badges_unlocked', 'Plusieurs badges débloqués'),
  _TestNotificationOption(
    'admin_pending_signup',
    'Nouveau compte en attente',
    adminOnly: true,
  ),
  _TestNotificationOption(
    'admin_availability_change',
    'Changement de disponibilité',
    adminOnly: true,
  ),
];

class _TestPushButton extends ConsumerStatefulWidget {
  const _TestPushButton();

  @override
  ConsumerState<_TestPushButton> createState() => _TestPushButtonState();
}

class _TestPushButtonState extends ConsumerState<_TestPushButton> {
  bool _sending = false;

  Future<void> _send(_TestNotificationOption option) async {
    setState(() => _sending = true);
    var message =
        'Test « ${option.label} » envoyé — regarde tes notifications.';
    try {
      final result = await ref
          .read(supabaseClientProvider)
          .rpc('send_test_push_kind', params: {'p_kind': option.kind});
      final data = result is Map ? Map<String, dynamic>.from(result) : null;
      if (data != null && data['sent'] != true) {
        message = switch (data['reason']?.toString()) {
          'no_subscription' =>
            'Aucun appareil abonné : active les notifications sur cet appareil.',
          'notifications_paused' =>
            'Les notifications du club sont en pause : rien n’a été envoyé.',
          'not_configured' => 'Les notifications push ne sont pas configurées.',
          'rate_limited' =>
            'Trop de tests rapprochés : réessaie dans quelques minutes.',
          _ => 'Impossible d’envoyer le test.',
        };
      }
    } catch (_) {
      message = 'Impossible d’envoyer le test.';
    }
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminViewProvider);
    final options = [
      for (final option in _testNotificationOptions)
        if (!option.adminOnly || isAdmin) option,
    ];

    return PopupMenuButton<_TestNotificationOption>(
      enabled: !_sending,
      tooltip: 'Choisir une notification à tester',
      onSelected: _send,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<_TestNotificationOption>(
            value: option,
            child: Text(option.label),
          ),
      ],
      child: IgnorePointer(
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _sending ? null : () {},
            child: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: PfProgressIndicator(strokeWidth: 2),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Test'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down_outlined, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Conserve une porte de sortie pour un club dont les notifications étaient
/// déjà en pause, sans réintroduire la commande permettant de tout couper.
final notificationsPausedProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final response = await ref
      .read(supabaseClientProvider)
      .rpc('admin_get_notifications_paused');
  final data = Map<String, dynamic>.from(response as Map);
  final flag = Map<String, dynamic>.from(
    data['notifications_paused'] as Map? ?? const {},
  );
  return flag['enabled'] == true;
});

final setNotificationsPausedProvider =
    Provider<Future<void> Function(bool)>((ref) => (enabled) async {
          await ref.read(supabaseClientProvider).rpc(
            'admin_set_notifications_paused',
            params: {'p_enabled': enabled},
          );
        });

class _AdminResumeNotificationsCard extends ConsumerStatefulWidget {
  const _AdminResumeNotificationsCard();

  @override
  ConsumerState<_AdminResumeNotificationsCard> createState() =>
      _AdminResumeNotificationsCardState();
}

class _AdminResumeNotificationsCardState
    extends ConsumerState<_AdminResumeNotificationsCard> {
  bool _busy = false;

  Future<void> _resume() async {
    setState(() => _busy = true);
    try {
      await ref.read(setNotificationsPausedProvider)(false);
      ref.invalidate(notificationsPausedProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications du club réactivées.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Impossible de réactiver les notifications.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(isAdminViewProvider)) return const SizedBox.shrink();
    final paused = ref.watch(notificationsPausedProvider).valueOrNull;
    if (paused != true) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Les notifications du club sont en pause.'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _resume,
              child: const Text('Réactiver les notifications du club'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encadré unique : état des notifications sur cet appareil (cloche) et
/// liste des notifications essentielles, toujours envoyées.
class _EssentialNotificationsCard extends ConsumerStatefulWidget {
  const _EssentialNotificationsCard();

  @override
  ConsumerState<_EssentialNotificationsCard> createState() =>
      _EssentialNotificationsCardState();
}

class _EssentialNotificationsCardState
    extends ConsumerState<_EssentialNotificationsCard> {
  bool _busy = false;

  Future<void> _toggle(bool currentlySubscribed) async {
    setState(() => _busy = true);
    String message;
    if (currentlySubscribed) {
      message = 'Notifications désactivées sur cet appareil.';
      try {
        await ref.read(pushSubscriptionsRepositoryProvider).disable();
        // Choix du joueur : le bandeau du haut ne doit pas le contredire.
        await writePushOptOut(true);
      } catch (_) {
        message = 'Impossible de désactiver les notifications.';
      }
    } else {
      message = 'Notifications activées sur cet appareil.';
      try {
        final enabled =
            await ref.read(pushSubscriptionsRepositoryProvider).enable();
        if (!enabled) {
          message = 'Notifications bloquées sur ce téléphone : autorise-les '
              'dans ses réglages, puis réessaie.';
        }
      } catch (_) {
        message = 'Impossible d’activer les notifications.';
      }
    }
    ref.invalidate(pushStatusProvider);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(pushStatusProvider);
    final status = statusAsync.valueOrNull;
    final supported = status?.supported ?? false;
    final subscribed = supported && status!.subscribed;
    final unavailable = statusAsync.hasError || (status != null && !supported);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notifications essentielles',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                ),
                SizedBox.square(
                  dimension: 40,
                  child: NotificationBellButton(
                    active: subscribed,
                    busy: _busy || statusAsync.isLoading,
                    onPressed: supported ? () => _toggle(subscribed) : null,
                    label: subscribed
                        ? 'Désactiver les notifications sur cet appareil'
                        : 'Activer les notifications sur cet appareil',
                  ),
                ),
              ],
            ),
            if (unavailable)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Indisponibles sur cet appareil',
                  style: TextStyle(color: AppTheme.textFaint),
                ),
              ),
            const SizedBox(height: 4),
            for (final title in const [
              'Ouverture des disponibilités',
              'Passage en convoqué ou en liste d’attente',
              'Match annulé, reporté ou modifié',
            ])
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 12),
                child: Text(title),
              ),
          ],
        ),
      ),
    );
  }
}
