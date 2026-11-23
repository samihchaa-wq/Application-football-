import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/feature_flags/data/feature_flags_repository.dart';
import 'package:petit_filet/features/feature_flags/domain/feature_flags.dart';
import 'package:petit_filet/features/feature_flags/presentation/feature_flags_controller.dart';

const _enabled = FeatureFlagsSnapshot(
  sportsManagement: SportsManagementFeature.permanentFallback(),
  sourceAvailable: true,
);

const _disabled = FeatureFlagsSnapshot(
  sportsManagement: SportsManagementFeature.disabled(),
  sourceAvailable: true,
);

/// Ce que la fiche d'un match à venir montre, d'après les deux états lus
/// (même ordre de décision que la page). Écouté comme un provider : chaque
/// valeur relevée est celle qu'un écran aurait réellement reçue.
final _displayProvider = Provider<String>((ref) {
  if (ref.watch(sportsManagementEnabledProvider)) return 'modules';
  if (ref.watch(sportsManagementRoutingStateProvider) == null) {
    return 'attente';
  }
  return 'indisponible';
});

String _display(ProviderContainer container) =>
    container.read(_displayProvider);

/// Session connectée dont le compte peut changer, avec un serveur qui ne
/// répond que quand le test le décide.
class _Harness {
  _Harness() {
    container = ProviderContainer(
      overrides: [
        featureFlagsRepositoryProvider.overrideWithValue(repository),
        clubSessionIdentityProvider.overrideWith((ref) => ref.watch(account)),
        featureFlagsSessionReadyProvider.overrideWithValue(true),
      ],
    );
    container.listen(_displayProvider, (_, next) => seen.add(next));
  }

  final repository = _QueuedRepository();
  final account = StateProvider<String?>((ref) => 'joueur-a');
  final seen = <String>[];
  late final ProviderContainer container;

  Future<void> answer(FeatureFlagsSnapshot snapshot) async {
    await pumpEventQueue();
    repository.answerPending(snapshot);
    await pumpEventQueue();
  }
}

void main() {
  late _Harness harness;

  setUp(() async {
    harness = _Harness();
    await harness.answer(_enabled);
    expect(_display(harness.container), 'modules');
    harness.seen.clear();
  });

  tearDown(() => harness.container.dispose());

  test(
      'retour dans l’application ou ouverture depuis une notification : la '
      'relecture ne montre jamais « Gestion sportive indisponible »', () async {
    // L'application invalide les réglages à chaque reprise.
    harness.container.invalidate(featureFlagsControllerProvider);
    await pumpEventQueue();
    expect(_display(harness.container), 'modules');

    await harness.answer(_enabled);
    expect(_display(harness.container), 'modules');
    expect(harness.seen, isNot(contains('indisponible')));
  });

  test('tirer pour actualiser garde les blocs du match affichés', () async {
    final refresh = harness.container
        .read(featureFlagsControllerProvider.notifier)
        .refresh();
    await pumpEventQueue();
    expect(_display(harness.container), 'modules');

    await harness.answer(_enabled);
    await refresh;
    expect(_display(harness.container), 'modules');
    expect(harness.seen, isNot(contains('indisponible')));
  });

  test('la relecture applique une coupure décidée entre-temps', () async {
    harness.container.invalidate(featureFlagsControllerProvider);
    await harness.answer(_disabled);
    expect(_display(harness.container), 'indisponible');
  });

  test(
      'changement de compte : la valeur de l’ancien compte n’est jamais '
      'reprise pendant la lecture du nouveau', () async {
    harness.container.read(harness.account.notifier).state = 'joueur-b';
    await pumpEventQueue();
    expect(harness.container.read(sportsManagementEnabledProvider), isFalse);
    expect(_display(harness.container), 'attente');

    await harness.answer(_disabled);
    expect(_display(harness.container), 'indisponible');
    expect(harness.seen, isNot(contains('modules')));
  });
}

class _QueuedRepository implements FeatureFlagsRepository {
  final _pending = <Completer<FeatureFlagsSnapshot>>[];

  void answerPending(FeatureFlagsSnapshot snapshot) {
    for (final request in _pending) {
      if (!request.isCompleted) request.complete(snapshot);
    }
  }

  @override
  Future<FeatureFlagsSnapshot> fetchFeatureFlags() {
    final request = Completer<FeatureFlagsSnapshot>();
    _pending.add(request);
    return request.future;
  }

  @override
  Stream<FeatureFlagChangeSignal> watchSportsManagementChanges() =>
      const Stream<FeatureFlagChangeSignal>.empty();
}
