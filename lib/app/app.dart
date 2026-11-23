import 'dart:async';

import 'package:petit_filet/app/router/app_router.dart';
import 'package:petit_filet/core/club/club_identity.dart';
import 'package:petit_filet/core/club/club_rules.dart';
import 'package:petit_filet/core/l10n/french_localizations.dart';
import 'package:petit_filet/core/network/connectivity_service.dart';
import 'package:petit_filet/core/push/push_client.dart';
import 'package:petit_filet/core/sync/resume_refresh_policy.dart';
import 'package:petit_filet/core/sync/shared_data_sync.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/widgets/pf_accessibility_scope.dart';
import 'package:petit_filet/core/widgets/pf_status_banner.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/club/presentation/club_configuration_status_banner.dart';
import 'package:petit_filet/features/club/presentation/club_identity_sync.dart';
import 'package:petit_filet/features/club/presentation/club_rules_sync.dart';
import 'package:petit_filet/features/feature_flags/presentation/feature_flags_controller.dart';
import 'package:petit_filet/features/notifications/data/notification_inbox_repository.dart';
import 'package:petit_filet/features/notifications/presentation/push_device_banner.dart';
import 'package:petit_filet/features/preferences/data/push_subscriptions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PetitFiletApp extends ConsumerStatefulWidget {
  const PetitFiletApp({super.key});

  @override
  ConsumerState<PetitFiletApp> createState() => _PetitFiletAppState();
}

class _PetitFiletAppState extends ConsumerState<PetitFiletApp>
    with WidgetsBindingObserver {
  /// Moment où l'application est passée en arrière-plan, `null` au premier
  /// plan.
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Nouvelles couleurs de club : le thème est recalculé.
    AppTheme.colorsRevision.addListener(_onClubColorsChanged);
    // Session restaurée au lancement ou nouvelle connexion : l'abonnement
    // aux notifications de cet appareil est recollé au compte connecté.
    ref.listenManual<bool>(
      authControllerProvider.select((state) => state.isAuthenticated),
      (previous, next) {
        if (next && previous != true) unawaited(_resyncPushSubscription());
      },
      fireImmediately: true,
    );
    // Notification reçue pendant que l'application est ouverte : la cloche
    // se met à jour sans attendre le prochain retour au premier plan.
    pushListenReceived(() {
      if (mounted) ref.invalidate(unreadNotificationCountProvider);
    });
    // L'icône de l'application porte le même chiffre que la cloche (zéro
    // hors connexion : la pastille du compte précédent disparaît).
    ref.listenManual<AsyncValue<int>>(unreadNotificationCountProvider, (
      _,
      next,
    ) {
      final count = next.valueOrNull;
      if (count != null) unawaited(pushSetAppBadge(count));
    }, fireImmediately: true);
  }

  /// La cloche des notifications reflète l'abonnement du navigateur, que le
  /// serveur peut avoir perdu (autre compte connecté sur ce téléphone, appareil
  /// remplacé…). Le réenregistrer à chaque ouverture évite qu'elle reste verte
  /// alors que plus rien n'arrive. Sans abonnement, rien n'est demandé.
  Future<void> _resyncPushSubscription() async {
    try {
      await ref.read(pushSubscriptionsRepositoryProvider).resync();
    } catch (_) {
      // Au mieux : l'échec ne change rien pour l'utilisateur, le prochain
      // lancement réessaiera.
    }
  }

  void _onClubColorsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppTheme.colorsRevision.removeListener(_onClubColorsChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _backgroundedAt ??= DateTime.now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    final awayFor = backgroundedAt == null
        ? null
        : DateTime.now().difference(backgroundedAt);

    // Reconnecte le signal Realtime : un iPhone peut suspendre le websocket
    // pendant l'arrière-plan. La reconnexion relit la révision courante ; si
    // elle a bougé pendant l'absence, le rafraîchissement ciblé habituel se
    // déclenche (sharedDataSyncListenerProvider). Rien n'a changé : rien
    // n'est rechargé.
    ref.invalidate(sharedDataSignalProvider);
    // Les préférences de club peuvent avoir changé pendant la suspension du
    // websocket iOS, même après une courte absence.
    refreshClubConfiguration(ref.invalidate);
    ref.invalidate(featureFlagsControllerProvider);
    // La cloche peut avoir reçu des notifications pendant l'absence.
    ref.invalidate(unreadNotificationCountProvider);
    // Le joueur revient peut-être des réglages du téléphone.
    ref.invalidate(pushStatusProvider);

    if (!shouldFullyRefreshOnResume(awayFor)) return;

    // Longue absence : une application installée sur iPhone reprend souvent
    // sans relancer, ce retour compte alors comme une ouverture.
    unawaited(ref.read(sharedDataRefreshCoordinatorProvider).refreshAll());
    if (ref.read(authControllerProvider).isAuthenticated) {
      unawaited(_resyncPushSubscription());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Maintient l'abonnement global tant que l'application est montée.
    ref.watch(sharedDataSyncListenerProvider);
    // Tient à jour le nom du club affiché dans toute l'application.
    ref.watch(clubIdentitySyncProvider);
    // Idem pour les règles horaires du club.
    ref.watch(clubRulesSyncProvider);
    ref.watch(clubLiveModeSyncProvider);

    ref.listen<bool>(
      authControllerProvider.select((state) => state.isAuthenticated),
      (previous, next) {
        if (previous != next) {
          ref.invalidate(featureFlagsControllerProvider);
        }
      },
    );

    final router = ref.watch(appRouterProvider);
    final onlineAsync = ref.watch(onlineStatusProvider);
    final isOnline = onlineAsync.valueOrNull ?? true;
    final isAuthenticated = ref.watch(
      authControllerProvider.select((state) => state.isAuthenticated),
    );
    final baseTheme = AppTheme.light;

    return MaterialApp.router(
      title: ClubIdentity.appName,
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: frenchLocalizationsDelegates,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: AppTheme.background,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
      ),
      routerConfig: router,
      builder: (context, child) {
        // Le réglage d'accessibilité du système / du navigateur doit être
        // respecté : un facteur fixe l'écrasait purement et simplement, et
        // « très grand texte » ne changeait pas un pixel (échec WCAG 1.4.4).
        // On garde le confort de lecture de base en plancher, et un plafond
        // pour ne pas casser les mises en page denses.
        final systemScale = MediaQuery.textScalerOf(context).scale(1);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              (systemScale * 1.10).clamp(1.10, 1.60),
            ),
          ),
          child: PfAccessibilityScope(
            child: ColoredBox(
              color: AppTheme.background,
              child: Column(
                children: [
                  if (!isOnline)
                    Material(
                      color: Theme.of(context).colorScheme.surface,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                          child: PfStatusBanner(
                            title: 'Connexion perdue',
                            message:
                                'Les données affichées peuvent être obsolètes.',
                            tone: PfStatusTone.warning,
                            compact: true,
                            action: TextButton(
                              onPressed: () =>
                                  ref.invalidate(onlineStatusProvider),
                              child: const Text('Réessayer'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (isAuthenticated) const ClubConfigurationStatusBanner(),
                  if (isAuthenticated)
                    PushDeviceBanner(
                      navigatorContext: () =>
                          router.routerDelegate.navigatorKey.currentContext,
                    ),
                  Expanded(
                    // Quand le nom du club arrive ou change, les écrans déjà
                    // affichés sont redessinés avec le bon nom.
                    child: ListenableBuilder(
                      listenable: Listenable.merge([
                        ClubIdentity.revision,
                        ClubRules.revision,
                        AppTheme.colorsRevision,
                      ]),
                      builder: (context, _) => KeyedSubtree(
                        key: ValueKey(
                          'club-identity-${ClubIdentity.revision.value}-'
                          '${ClubRules.revision.value}-'
                          '${AppTheme.colorsRevision.value}',
                        ),
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
