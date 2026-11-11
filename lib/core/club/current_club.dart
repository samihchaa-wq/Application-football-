import 'package:supabase_flutter/supabase_flutter.dart';

/// Club du compte connecté, tel qu'inscrit par le serveur dans la session
/// (`app_metadata.club_id`). Seule la clé de service peut l'écrire : un
/// utilisateur ne peut pas le modifier pour écouter un autre club.
///
/// Sert à restreindre les abonnements en direct au club de l'utilisateur :
/// sans ce filtre, chaque téléphone recevrait les changements de tous les
/// clubs, triés ensuite un par un par le serveur.
String? currentClubIdOf(SupabaseClient client) {
  final value = client.auth.currentUser?.appMetadata['club_id'];
  if (value is String && value.isNotEmpty) return value;
  return null;
}
