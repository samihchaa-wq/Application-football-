import 'dart:async';

import 'package:as_grinta/core/club/club_rules.dart';
import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Charge les règles du club (ouverture des pronostics, fermeture…) dès qu'un
/// compte est connecté, et revient aux valeurs par défaut à la déconnexion.
final clubRulesSyncProvider = Provider<void>((ref) {
  ref.watch(clubSessionIdentityProvider);
  var disposed = false;
  var generation = 0;
  ref.onDispose(() => disposed = true);
  unawaited(
    Future<void>.microtask(() {
      // Le mode live appartient à clubLiveModeSyncProvider : une panne de
      // lecture des règles ne doit jamais le réactiver par défaut.
      if (!disposed) ClubRules.set(const {});
    }),
  );
  ref.listen<AsyncValue<List<ClubRule>>>(clubRulesProvider, (_, next) {
    final currentGeneration = ++generation;
    if (next.isLoading) return;
    unawaited(
      Future<void>.microtask(() {
        if (disposed || currentGeneration != generation) return;
        if (next.hasError) {
          ClubRules.set(const {});
        } else {
          applyClubRules(next.valueOrNull ?? const []);
        }
      }),
    );
  }, fireImmediately: true);
});

/// Transmet au reste de l'application les règles reçues du serveur.
void applyClubRules(List<ClubRule> rules) {
  ClubRules.set({for (final rule in rules) rule.key: rule.value});
}

/// Applique le réglage « mode live » du club aux horaires et aux écrans.
final clubLiveModeSyncProvider = Provider<void>((ref) {
  // Hors connexion, aucune question au serveur : le live reste « activé ».
  final authenticated = ref.watch(
    authControllerProvider.select((state) => state.isAuthenticated),
  );
  final enabled = !authenticated ||
      ref.watch(clubModuleEnabledProvider(ClubModule.liveMode));
  var disposed = false;
  ref.onDispose(() => disposed = true);
  unawaited(
    Future<void>.microtask(() {
      if (!disposed) ClubRules.setLiveEnabled(enabled);
    }),
  );
});
