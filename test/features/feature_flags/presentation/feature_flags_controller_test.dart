import 'dart:async';

import 'package:as_grinta/core/logging/app_logger.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:as_grinta/features/feature_flags/data/feature_flags_repository.dart';
import 'package:as_grinta/features/feature_flags/domain/feature_flags.dart';
import 'package:as_grinta/features/feature_flags/presentation/feature_flags_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppLogger.sink = null);

  test('does not call the server before authentication', () async {
    final repository = _FakeFeatureFlagsRepository();
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        featureFlagsRepositoryProvider.overrideWithValue(repository),
        featureFlagsSessionReadyProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    final snapshot = await container.read(
      featureFlagsControllerProvider.future,
    );

    expect(repository.fetchCount, 0);
    expect(repository.watchCount, 0);
    expect(snapshot.sourceAvailable, isFalse);
    expect(snapshot.sportsManagement.enabled, isFalse);
  });

  test('fails closed when the server flag cannot be loaded', () async {
    final repository = _FakeFeatureFlagsRepository(throwOnFetch: true);
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        featureFlagsRepositoryProvider.overrideWithValue(repository),
        featureFlagsSessionReadyProvider.overrideWithValue(true),
        clubSessionIdentityProvider.overrideWithValue('test-session'),
      ],
    );
    addTearDown(container.dispose);

    final snapshot = await container.read(
      featureFlagsControllerProvider.future,
    );

    expect(snapshot.sourceAvailable, isFalse);
    expect(snapshot.sportsManagement.enabled, isFalse);
    expect(repository.watchCount, 1);
    expect(container.read(sportsManagementEnabledProvider), isFalse);
  });

  test('refreshes a running session when the server flag changes', () async {
    final repository = _FakeFeatureFlagsRepository();
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        featureFlagsRepositoryProvider.overrideWithValue(repository),
        featureFlagsSessionReadyProvider.overrideWithValue(true),
        clubSessionIdentityProvider.overrideWithValue('test-session'),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(featureFlagsControllerProvider.future);
    expect(initial.sportsManagement.enabled, isFalse);
    expect(repository.fetchCount, 1);

    repository.publishChange(
      revision: 2,
      enabled: true,
      updatedAt: DateTime.utc(2026, 7, 20, 13),
    );
    await pumpEventQueue();

    expect(repository.fetchCount, 2);
    expect(container.read(sportsManagementEnabledProvider), isTrue);
  });

  test('ignores stale and duplicate realtime signals', () async {
    final repository = _FakeFeatureFlagsRepository();
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        featureFlagsRepositoryProvider.overrideWithValue(repository),
        featureFlagsSessionReadyProvider.overrideWithValue(true),
        clubSessionIdentityProvider.overrideWithValue('test-session'),
      ],
    );
    addTearDown(container.dispose);

    await container.read(featureFlagsControllerProvider.future);

    repository.publishSignal(
      revision: 1,
      updatedAt: DateTime.utc(2026, 7, 20, 11),
    );
    repository.publishSignal(
      revision: 1,
      updatedAt: DateTime.utc(2026, 7, 20, 13),
    );
    await pumpEventQueue();

    expect(repository.fetchCount, 1);
    expect(container.read(sportsManagementEnabledProvider), isFalse);
  });

  test(
    'only reports a sustained watcher outage after three failures',
    () async {
      final repository = _FakeFeatureFlagsRepository();
      addTearDown(repository.dispose);
      final incidents = <AppIncident>[];
      AppLogger.sink = incidents.add;

      final container = ProviderContainer(
        overrides: [
          featureFlagsRepositoryProvider.overrideWithValue(repository),
          featureFlagsSessionReadyProvider.overrideWithValue(true),
          clubSessionIdentityProvider.overrideWithValue('test-session'),
          featureFlagsWatchRetryDelayProvider.overrideWithValue(
            (_) => Duration.zero,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(featureFlagsControllerProvider.future);
      expect(repository.watchCount, 1);

      repository.publishWatchError();
      await pumpEventQueue(times: 20);
      expect(repository.watchCount, greaterThan(1));
      expect(
        incidents.where(
          (incident) => incident.operation == 'feature_flags.watch',
        ),
        isEmpty,
      );

      repository.publishWatchError();
      await pumpEventQueue(times: 20);
      expect(repository.watchCount, greaterThan(2));
      expect(
        incidents.where(
          (incident) => incident.operation == 'feature_flags.watch',
        ),
        isEmpty,
      );

      repository.publishWatchError();
      await pumpEventQueue(times: 20);
      expect(repository.watchCount, greaterThan(3));
      expect(
        incidents.where(
          (incident) => incident.operation == 'feature_flags.watch',
        ),
        hasLength(1),
      );

      repository.publishWatchError();
      await pumpEventQueue(times: 20);
      expect(
        incidents.where(
          (incident) => incident.operation == 'feature_flags.watch',
        ),
        hasLength(1),
      );

      repository.publishChange(
        revision: 2,
        enabled: true,
        updatedAt: DateTime.utc(2026, 7, 20, 13),
      );
      await pumpEventQueue(times: 20);

      expect(repository.fetchCount, 2);
      expect(container.read(sportsManagementEnabledProvider), isTrue);
    },
  );
  test('les révisions de configuration sont séparées et regroupées', () async {
    final repository = _FakeFeatureFlagsRepository();
    addTearDown(repository.dispose);
    var refreshes = 0;
    final container = ProviderContainer(overrides: [
      featureFlagsRepositoryProvider.overrideWithValue(repository),
      featureFlagsSessionReadyProvider.overrideWithValue(true),
      clubSessionIdentityProvider.overrideWithValue('a'),
      featureFlagsConfigurationRefreshProvider
          .overrideWithValue(() => refreshes++),
      featureFlagsConfigurationDebounceProvider
          .overrideWithValue(Duration.zero),
    ]);
    addTearDown(container.dispose);
    await container.read(featureFlagsControllerProvider.future);
    for (final revision in [1, 2, 2, 1]) {
      repository.publishSignal(
          key: 'club_configuration',
          revision: revision,
          updatedAt: DateTime.utc(2026, 7, 20, 13));
    }
    await pumpEventQueue();
    expect(refreshes, 1);
    // Même numéro dans un autre flux : le changement sportif n'est pas perdu.
    repository.publishChange(
        revision: 2, enabled: true, updatedAt: DateTime.utc(2026, 7, 20, 14));
    await pumpEventQueue();
    expect(container.read(sportsManagementEnabledProvider), isTrue);
    repository.publishSignal(
        key: 'club_configuration',
        revision: 3,
        updatedAt: DateTime.utc(2026, 7, 20, 15));
    await pumpEventQueue();
    expect(refreshes, 2);
  });

  test(
      'la première révision rattrape les réglages modifiés pendant le chargement',
      () async {
    final repository = _FakeFeatureFlagsRepository();
    addTearDown(repository.dispose);
    var refreshes = 0;
    final container = ProviderContainer(overrides: [
      featureFlagsRepositoryProvider.overrideWithValue(repository),
      featureFlagsSessionReadyProvider.overrideWithValue(true),
      clubSessionIdentityProvider.overrideWithValue('a'),
      featureFlagsConfigurationRefreshProvider
          .overrideWithValue(() => refreshes++),
      featureFlagsConfigurationDebounceProvider
          .overrideWithValue(Duration.zero),
    ]);
    addTearDown(container.dispose);
    await container.read(featureFlagsControllerProvider.future);
    repository.publishSignal(
        key: 'club_configuration',
        revision: 8,
        updatedAt: DateTime.utc(2026, 7, 20, 12));
    await pumpEventQueue();
    expect(refreshes, 1);
    repository.publishSignal(
        key: 'club_configuration',
        revision: 8,
        updatedAt: DateTime.utc(2026, 7, 20, 13));
    await pumpEventQueue();
    expect(refreshes, 1);
  });

  test('une réponse de chargement A ne remplace jamais les flags de B',
      () async {
    final session = StateProvider<String?>((ref) => 'a');
    final repository = _PendingFeatureFlagsRepository();
    final container = ProviderContainer(overrides: [
      featureFlagsRepositoryProvider.overrideWithValue(repository),
      featureFlagsSessionReadyProvider.overrideWithValue(true),
      clubSessionIdentityProvider.overrideWith((ref) => ref.watch(session)),
    ]);
    addTearDown(container.dispose);
    final subscription =
        container.listen(featureFlagsControllerProvider, (_, __) {});
    addTearDown(subscription.close);
    await pumpEventQueue();
    expect(repository.pending, hasLength(1));
    container.read(session.notifier).state = 'b';
    await pumpEventQueue();
    expect(repository.pending, hasLength(2));
    repository.pending[1]
        .complete(_snapshot(enabled: false, updatedAt: DateTime.utc(2026)));
    await pumpEventQueue();
    repository.pending[0]
        .complete(_snapshot(enabled: true, updatedAt: DateTime.utc(2027)));
    await pumpEventQueue();
    expect(container.read(sportsManagementEnabledProvider), isFalse);
    expect(repository.watchCount, 1);
  });

  test('une réponse A dans la même boucle que la connexion B est écartée',
      () async {
    final session = StateProvider<String?>((ref) => 'a');
    final repository = _PendingFeatureFlagsRepository();
    final seenByB = <bool>[];
    final container = ProviderContainer(overrides: [
      featureFlagsRepositoryProvider.overrideWithValue(repository),
      featureFlagsSessionReadyProvider.overrideWithValue(true),
      clubSessionIdentityProvider.overrideWith((ref) => ref.watch(session)),
    ]);
    addTearDown(container.dispose);
    final subscription =
        container.listen(featureFlagsControllerProvider, (_, next) {
      if (container.read(session) == 'b' &&
          !next.isLoading &&
          next.valueOrNull?.sourceAvailable == true) {
        seenByB.add(next.valueOrNull!.sportsManagement.enabled);
      }
    });
    addTearDown(subscription.close);
    await pumpEventQueue();
    repository.pending[0]
        .complete(_snapshot(enabled: true, updatedAt: DateTime.utc(2026)));
    await pumpEventQueue();
    final refreshA =
        container.read(featureFlagsControllerProvider.notifier).refresh();
    await pumpEventQueue();

    container.read(session.notifier).state = 'b';
    // Pas d'attente ici : la réponse arrive avant la reconstruction différée
    // des providers. Le changement de compte est déjà effectif.
    repository.pending[1]
        .complete(_snapshot(enabled: true, updatedAt: DateTime.utc(2027)));
    await pumpEventQueue();
    repository.pending[2]
        .complete(_snapshot(enabled: false, updatedAt: DateTime.utc(2026)));
    await refreshA;
    await pumpEventQueue();
    expect(seenByB, [false]);
  });

  test('une actualisation A en vol ne réactive pas les flags chez B', () async {
    final session = StateProvider<String?>((ref) => 'a');
    final repository = _PendingFeatureFlagsRepository();
    final container = ProviderContainer(overrides: [
      featureFlagsRepositoryProvider.overrideWithValue(repository),
      featureFlagsSessionReadyProvider.overrideWithValue(true),
      clubSessionIdentityProvider.overrideWith((ref) => ref.watch(session)),
    ]);
    addTearDown(container.dispose);
    final subscription =
        container.listen(featureFlagsControllerProvider, (_, __) {});
    addTearDown(subscription.close);
    await pumpEventQueue();
    repository.pending[0]
        .complete(_snapshot(enabled: true, updatedAt: DateTime.utc(2026)));
    await pumpEventQueue();
    final refreshA =
        container.read(featureFlagsControllerProvider.notifier).refresh();
    await pumpEventQueue();
    container.read(session.notifier).state = 'b';
    await pumpEventQueue();
    repository.pending[2]
        .complete(_snapshot(enabled: false, updatedAt: DateTime.utc(2026)));
    await pumpEventQueue();
    repository.pending[1]
        .complete(_snapshot(enabled: true, updatedAt: DateTime.utc(2027)));
    await refreshA;
    await pumpEventQueue();
    expect(container.read(sportsManagementEnabledProvider), isFalse);
  });
}

class _FakeFeatureFlagsRepository implements FeatureFlagsRepository {
  _FakeFeatureFlagsRepository({this.throwOnFetch = false});

  final bool throwOnFetch;
  final StreamController<FeatureFlagChangeSignal> _changes =
      StreamController<FeatureFlagChangeSignal>.broadcast(sync: true);

  int fetchCount = 0;
  int watchCount = 0;
  bool enabled = false;
  DateTime updatedAt = DateTime.utc(2026, 7, 20, 12);

  Future<void> dispose() => _changes.close();

  void publishChange({
    required int revision,
    required bool enabled,
    required DateTime updatedAt,
  }) {
    this.enabled = enabled;
    this.updatedAt = updatedAt;
    publishSignal(revision: revision, updatedAt: updatedAt);
  }

  void publishSignal({
    String key = 'sports_management',
    required int revision,
    required DateTime updatedAt,
  }) {
    _changes.add(
      FeatureFlagChangeSignal(
          key: key, revision: revision, updatedAt: updatedAt),
    );
  }

  void publishWatchError() {
    _changes.addError(
      StateError('realtime unavailable'),
      StackTrace.current,
    );
  }

  @override
  Future<FeatureFlagsSnapshot> fetchFeatureFlags() async {
    fetchCount += 1;
    if (throwOnFetch) throw StateError('unavailable');
    return _snapshot(enabled: enabled, updatedAt: updatedAt);
  }

  @override
  Stream<FeatureFlagChangeSignal> watchSportsManagementChanges() {
    watchCount += 1;
    return _changes.stream;
  }
}

FeatureFlagsSnapshot _snapshot({
  required bool enabled,
  required DateTime updatedAt,
}) {
  return FeatureFlagsSnapshot(
    sourceAvailable: true,
    sportsManagement: SportsManagementFeature(
      enabled: enabled,
      availabilityOpenHoursBefore: 144,
      reminderHoursBefore: const [72, 24],
      usualSquadSize: 14,
      voteDurationHours: 24,
      timezone: 'Europe/Paris',
      updatedAt: updatedAt,
    ),
  );
}

class _PendingFeatureFlagsRepository implements FeatureFlagsRepository {
  final pending = <Completer<FeatureFlagsSnapshot>>[];
  int watchCount = 0;

  @override
  Future<FeatureFlagsSnapshot> fetchFeatureFlags() {
    final completer = Completer<FeatureFlagsSnapshot>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Stream<FeatureFlagChangeSignal> watchSportsManagementChanges() {
    watchCount += 1;
    return const Stream.empty();
  }
}
