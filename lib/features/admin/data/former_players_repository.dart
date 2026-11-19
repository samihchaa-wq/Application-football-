import 'package:petit_filet/core/providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Joueur du club qui n'a plus de compte actif (ancien membre ou invité).
class FormerPlayer {
  const FormerPlayer({required this.id, required this.displayName});

  final String id;
  final String displayName;
}

/// Ce que devient le nom dans l'historique des matchs.
enum FormerPlayerRename {
  /// « Yves Dujardin » devient « Yves D. ».
  shorten('short'),

  /// « Yves Dujardin » devient « Ancien joueur ».
  anonymize('anonymous');

  const FormerPlayerRename(this.serverValue);

  final String serverValue;
}

/// Raccourcir ou remplacer le nom d'un ancien joueur dans tout l'historique
/// du club, à sa demande (politique de confidentialité).
class FormerPlayersRepository {
  FormerPlayersRepository(this._client);

  final SupabaseClient _client;

  Future<List<FormerPlayer>> list() async {
    final rows = await _client.rpc('admin_list_former_players') as List;
    return [
      for (final row in rows.cast<Map<String, dynamic>>())
        FormerPlayer(
          id: row['player_id'].toString(),
          displayName: (row['display_name'] ?? '').toString(),
        ),
    ];
  }

  /// Renvoie le nouveau nom.
  Future<String> rename(String playerId, FormerPlayerRename mode) async {
    final result = await _client.rpc(
      'admin_rename_former_player',
      params: {'p_player_id': playerId, 'p_mode': mode.serverValue},
    );
    return (result as Map)['display_name'].toString();
  }
}

final formerPlayersRepositoryProvider = Provider<FormerPlayersRepository>(
  (ref) => FormerPlayersRepository(ref.watch(supabaseClientProvider)),
);
