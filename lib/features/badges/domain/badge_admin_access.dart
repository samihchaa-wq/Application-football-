import 'package:as_grinta/features/auth/domain/auth_profile.dart';
import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gestion des badges : réservée aux administrateurs actifs du club.
///
/// Ce contrôle côté Flutter sert à masquer l'entrée et à bloquer la route.
/// Les écritures restent également protégées côté Supabase.
bool canManageBadges(AuthProfile? profile) {
  return profile?.role.isAdmin == true && profile?.isActive == true;
}

final canManageBadgesProvider = Provider<bool>((ref) {
  // En « Voir l'app comme un joueur », l'entrée disparaît comme les autres
  // outils d'admin.
  if (ref.watch(playerPreviewProvider)) return false;
  return canManageBadges(ref.watch(authControllerProvider).profile);
});
