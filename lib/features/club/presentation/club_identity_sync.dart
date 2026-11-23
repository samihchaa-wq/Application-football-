import 'dart:async';

import 'package:petit_filet/core/club/club_identity.dart';
import 'package:petit_filet/core/club/club_kits.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Étend la garde d'identité multiclub déjà présente dans Petit Filet, avec
/// le provider du club : les changements distants peuvent aussi la relancer.
final clubIdentitySyncProvider = Provider<void>((ref) {
  ref.watch(clubSessionIdentityProvider);
  var disposed = false;
  var generation = 0;
  ref.onDispose(() => disposed = true);

  void reset() {
    ClubIdentity.reset();
    AppTheme.resetClubColors();
    ClubKits.reset();
  }

  // Le changement de session efface l'identité précédente avant le prochain
  // rendu. Les réponses de l'ancien provider ne sont plus écoutées.
  unawaited(
    Future<void>.microtask(() {
      if (!disposed) reset();
    }),
  );

  ref.listen<AsyncValue<Club>>(myClubProvider, (_, next) {
    final currentGeneration = ++generation;
    if (next.isLoading) return;
    unawaited(
      Future<void>.microtask(() {
        if (disposed || currentGeneration != generation) return;
        final club = next.valueOrNull;
        if (next.hasError || club == null) {
          reset();
          return;
        }
        ClubIdentity.set(name: club.name, shortName: club.shortName);
        applyClubColors(club);
        ClubKits.setFromJson(club.kits);
        ClubIdentity.setLogoUrl(ref.read(clubRepositoryProvider).logoUrl(club));
      }),
    );
  }, fireImmediately: true);
});

/// Tous les clubs partagent les mêmes couleurs : celles de Petit Filet.
/// Les couleurs enregistrées en base ne sont plus appliquées.
void applyClubColors(Club club) {
  AppTheme.resetClubColors();
  ClubKits.setClubColors();
}
