import 'dart:async';

import 'package:as_grinta/core/club/club_identity.dart';
import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renseigne le nom du club affiché partout dès qu'un compte est connecté, et
/// revient au libellé neutre à la déconnexion.
final clubIdentitySyncProvider = Provider<void>((ref) {
  final authenticated = ref.watch(
    authControllerProvider.select((state) => state.isAuthenticated),
  );
  var disposed = false;
  ref.onDispose(() => disposed = true);

  // Jamais pendant la construction d'un écran : le changement de nom
  // redessine l'application.
  unawaited(
    Future<void>.microtask(() async {
      if (disposed) return;
      if (!authenticated) {
        ClubIdentity.reset();
        AppTheme.resetClubColors();
        ClubKits.reset();
        return;
      }
      try {
        final club = await ref.read(clubRepositoryProvider).fetchMyClub();
        if (disposed) return;
        ClubIdentity.set(name: club.name, shortName: club.shortName);
        applyClubColors(club);
        ClubKits.setFromJson(club.kits);
        ClubIdentity.setLogoUrl(ref.read(clubRepositoryProvider).logoUrl(club));
      } catch (_) {
        // Le libellé neutre reste affiché ; la prochaine connexion réessaie.
      }
    }),
  );
});

/// Habille l'application aux couleurs du club.
void applyClubColors(Club club) {
  final primary = AppTheme.parseHex(club.primaryColor);
  final secondary = AppTheme.parseHex(club.secondaryColor);
  AppTheme.applyClubColors(primary: primary, secondary: secondary);
  // Les maillots par défaut reprennent les couleurs du club.
  ClubKits.setClubColors(primary: primary, secondary: secondary);
}
