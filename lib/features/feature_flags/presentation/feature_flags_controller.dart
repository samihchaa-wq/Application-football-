import 'dart:async';

import 'package:as_grinta/core/logging/app_logger.dart';
import 'package:as_grinta/core/sync/shared_data_sync.dart';
import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:as_grinta/features/feature_flags/data/feature_flags_repository.dart';
import 'package:as_grinta/features/feature_flags/domain/feature_flags.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final featureFlagsSessionReadyProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return !authState.isLoading && authState.isAuthenticated;
});

typedef FeatureFlagsWatchRetryDelay = Duration Function(int attempt);

final featureFlagsWatchRetryDelayProvider =
    Provider<FeatureFlagsWatchRetryDelay>((ref) {
  return (attempt) {
    if (attempt <= 1) return const Duration(seconds: 5);
    if (attempt == 2) return const Duration(seconds: 15);
    return const Duration(minutes: 1);
  };
});

/// Réutilise le coordinateur de caches d'AS Grinta : un changement de règle
/// peut aussi modifier un classement ou les fenêtres d'accès d'un match.
final featureFlagsConfigurationRefreshProvider = Provider<void Function()>((
  ref,
) {
  return () {
    refreshClubConfiguration(ref.invalidate);
    unawaited(
      ref
          .read(sharedDataRefreshCoordinatorProvider)
          .refreshAll(refreshProfile: false),
    );
  };
});

final featureFlagsConfigurationDebounceProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 350),
);

class FeatureFlagsController extends AsyncNotifier<FeatureFlagsSnapshot> {
  static const int _watchIncidentThreshold = 3;

  StreamSubscription<FeatureFlagChangeSignal>? _changeSubscription;
  Timer? _watchRetryTimer;
  Timer? _configurationTimer;
  final Map<String, int> _lastRevisions = {};
  bool _signalRefreshInProgress = false;
  bool _signalRefreshRequested = false;
  bool _watchErrorLogged = false;
  bool _disposed = false;
  int _watchFailureCount = 0;
  int _generation = 0;
  bool _sessionReady = false;
  String? _sessionIdentity;

  bool _isCurrent(int generation) =>
      !_disposed &&
      generation == _generation &&
      (!_sessionReady ||
          ref.read(clubSessionIdentityProvider) == _sessionIdentity);

  @override
  Future<FeatureFlagsSnapshot> build() async {
    final generation = ++_generation;
    _disposed = false;
    final sessionReady = ref.watch(featureFlagsSessionReadyProvider);
    _sessionReady = sessionReady;
    // Le booléen peut rester vrai pendant A → B. Cette dépendance annule
    // aussi les abonnements et réponses tardives de l'ancien compte.
    _sessionIdentity =
        sessionReady ? ref.watch(clubSessionIdentityProvider) : null;
    _watchRetryTimer?.cancel();
    _configurationTimer?.cancel();
    _watchRetryTimer = null;
    _lastRevisions.clear();
    _watchFailureCount = 0;
    _watchErrorLogged = false;
    _signalRefreshInProgress = false;
    _signalRefreshRequested = false;
    final oldSubscription = _changeSubscription;
    _changeSubscription = null;

    ref.onDispose(() {
      _disposed = true;
      _watchRetryTimer?.cancel();
      _configurationTimer?.cancel();
      unawaited(_changeSubscription?.cancel() ?? Future<void>.value());
    });
    await oldSubscription?.cancel();
    if (!_isCurrent(generation) || !sessionReady) {
      return const FeatureFlagsSnapshot.unavailable();
    }

    final snapshot = await _loadFailClosed();
    if (_isCurrent(generation)) _watchServerChanges(generation);
    return snapshot;
  }

  void _watchServerChanges(int generation) {
    if (!_isCurrent(generation)) return;
    try {
      _changeSubscription = ref
          .read(featureFlagsRepositoryProvider)
          .watchSportsManagementChanges()
          .listen(
        (signal) {
          if (!_isCurrent(generation)) return;
          _watchFailureCount = 0;
          _watchErrorLogged = false;
          _handleServerSignal(signal, generation);
        },
        onError: (Object error, StackTrace stackTrace) =>
            _handleWatchError(error, stackTrace, generation),
        onDone: () => _scheduleWatchRestart(generation),
        cancelOnError: true,
      );
    } catch (error, stackTrace) {
      _handleWatchError(error, stackTrace, generation);
    }
  }

  void _handleWatchError(Object error, StackTrace stackTrace, int generation) {
    if (!_isCurrent(generation)) return;
    _watchFailureCount += 1;
    if (_watchFailureCount >= _watchIncidentThreshold && !_watchErrorLogged) {
      _watchErrorLogged = true;
      AppLogger.error('feature_flags.watch', error, stackTrace);
    }
    _scheduleWatchRestart(generation);
  }

  void _scheduleWatchRestart(int generation) {
    if (!_isCurrent(generation) || _watchRetryTimer != null) return;
    final attempt = _watchFailureCount <= 0 ? 1 : _watchFailureCount;
    final delay = ref.read(featureFlagsWatchRetryDelayProvider)(attempt);
    _watchRetryTimer = Timer(delay, () async {
      if (!_isCurrent(generation)) return;
      _watchRetryTimer = null;
      final subscription = _changeSubscription;
      _changeSubscription = null;
      await subscription?.cancel();
      if (_isCurrent(generation)) _watchServerChanges(generation);
    });
  }

  void _handleServerSignal(FeatureFlagChangeSignal signal, int generation) {
    final previous = _lastRevisions[signal.key];
    if (previous != null && signal.revision <= previous) return;
    _lastRevisions[signal.key] = signal.revision;

    if (signal.key == 'club_configuration') {
      // La première révision rattrape aussi une modification survenue entre
      // les lectures initiales et la connexion de l'abonnement Realtime.
      _configurationTimer?.cancel();
      _configurationTimer = Timer(
        ref.read(featureFlagsConfigurationDebounceProvider),
        () {
          if (_isCurrent(generation)) {
            ref.read(featureFlagsConfigurationRefreshProvider)();
          }
        },
      );
      return;
    }
    if (signal.key != 'sports_management') return;
    final currentUpdatedAt =
        state.valueOrNull?.sportsManagement.updatedAt?.toUtc();
    if (currentUpdatedAt != null &&
        !signal.updatedAt.isAfter(currentUpdatedAt)) {
      return;
    }
    _signalRefreshRequested = true;
    if (!_signalRefreshInProgress) unawaited(_refreshFromSignals(generation));
  }

  Future<void> _refreshFromSignals(int generation) async {
    _signalRefreshInProgress = true;
    try {
      while (_isCurrent(generation) && _signalRefreshRequested) {
        _signalRefreshRequested = false;
        final next = await _loadFailClosed();
        if (!_isCurrent(generation)) return;
        state = AsyncData(next);
      }
    } finally {
      if (_isCurrent(generation)) _signalRefreshInProgress = false;
    }
  }

  Future<FeatureFlagsSnapshot> _loadFailClosed() async {
    try {
      return await ref.read(featureFlagsRepositoryProvider).fetchFeatureFlags();
    } catch (error, stackTrace) {
      AppLogger.error('feature_flags.fetch', error, stackTrace);
      return const FeatureFlagsSnapshot.unavailable();
    }
  }

  Future<void> refresh() async {
    final generation = _generation;
    if (!_isCurrent(generation)) return;
    if (!ref.read(featureFlagsSessionReadyProvider)) {
      state = const AsyncData(FeatureFlagsSnapshot.unavailable());
      return;
    }
    state = const AsyncLoading();
    final next = await _loadFailClosed();
    if (_isCurrent(generation)) state = AsyncData(next);
  }
}

final featureFlagsControllerProvider =
    AsyncNotifierProvider<FeatureFlagsController, FeatureFlagsSnapshot>(
  FeatureFlagsController.new,
);

final sportsManagementEnabledProvider = Provider<bool>((ref) {
  final flags = ref.watch(featureFlagsControllerProvider);
  if (flags.isLoading || flags.hasError) return false;
  return flags.valueOrNull?.sportsManagement.enabled ?? false;
});

/// État de la gestion sportive pour le routeur : `null` tant que les réglages
/// du club ne sont pas connus.
///
/// Pendant ce chargement, [sportsManagementEnabledProvider] vaut `false`, comme
/// si la gestion sportive était coupée : le routeur renvoyait alors la page
/// Effectif d'un match vers ses pronos, et la destination était perdue. Un
/// rechargement qui part d'une valeur réellement lue garde cette valeur ; la
/// valeur de remplacement posée avant la connexion, elle, ne compte pas.
final sportsManagementRoutingStateProvider = Provider<bool?>((ref) {
  final flags = ref.watch(featureFlagsControllerProvider);
  final snapshot = flags.valueOrNull;
  if (flags.isLoading) {
    if (flags.isReloading) return null;
    if (snapshot != null && snapshot.sourceAvailable) {
      return snapshot.sportsManagement.enabled;
    }
    return null;
  }
  return snapshot?.sportsManagement.enabled ?? false;
});
