import 'dart:async';

import 'package:as_grinta/core/club/club_identity.dart';
import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
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

/// Habille l'application aux couleurs du club.
void applyClubColors(Club club) {
  final primary = AppTheme.parseHex(club.primaryColor);
  final secondary = AppTheme.parseHex(club.secondaryColor);
  AppTheme.applyClubColors(primary: primary, secondary: secondary);
  // Les maillots par défaut reprennent les couleurs du club.
  ClubKits.setClubColors(primary: primary, secondary: secondary);
}
