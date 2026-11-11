import 'dart:async';

import 'package:as_grinta/core/club/club_rules.dart';
import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Charge les règles du club (ouverture des pronostics, fermeture…) dès qu'un
/// compte est connecté, et revient aux valeurs par défaut à la déconnexion.
final clubRulesSyncProvider = Provider<void>((ref) {
  final authenticated = ref.watch(
    authControllerProvider.select((state) => state.isAuthenticated),
  );
  var disposed = false;
  ref.onDispose(() => disposed = true);

  unawaited(
    Future<void>.microtask(() async {
      if (disposed) return;
      if (!authenticated) {
        ClubRules.reset();
        return;
      }
      try {
        final rules = await ref.read(clubRepositoryProvider).fetchRules();
        if (disposed) return;
        applyClubRules(rules);
      } catch (_) {
        // Les valeurs par défaut restent en place ; la prochaine connexion
        // réessaie.
      }
    }),
  );
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
