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
  // L'authentification peut rester vraie lors d'un changement de compte.
  // Suivre aussi l'identité du profil pour recharger les données du bon club.
  final identity = ref.watch(
    authControllerProvider.select(
      (state) => (
        authenticated: state.isAuthenticated,
        profileId: state.profile?.id,
      ),
    ),
  );
  var disposed = false;
  ref.onDispose(() => disposed = true);

  // Jamais pendant la construction d'un écran : le changement de nom
  // redessine l'application.
  unawaited(
    Future<void>.microtask(() async {
      if (disposed) return;
      // Neutraliser immédiatement l'ancien club, même si la session suivante
      // est authentifiée. Un échec réseau ne doit pas conserver ses maillots.
      ClubIdentity.reset();
      AppTheme.resetClubColors();
      ClubKits.reset();
      if (!identity.authenticated) return;
      try {
        final club = await ref.read(clubRepositoryProvider).fetchMyClub();
        if (disposed) return;
        // Une réponse réseau d'une ancienne session ne doit jamais remettre
        // les couleurs ou les maillots du compte précédent après connexion B.
        final latest = ref.read(authControllerProvider);
        if (!latest.isAuthenticated ||
            latest.profile?.id != identity.profileId) {
          return;
        }
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
