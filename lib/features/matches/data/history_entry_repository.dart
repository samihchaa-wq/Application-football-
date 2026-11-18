import 'package:petit_filet/core/providers/supabase_provider.dart';
import 'package:petit_filet/features/matches/domain/history_match_draft.dart';
import 'package:petit_filet/features/matches/domain/history_import_batch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Saisie de l'historique par l'administrateur : ajout et suppression d'un
/// match passé. Le serveur recalcule les statistiques après chaque geste.
class HistoryEntryRepository {
  HistoryEntryRepository(this._client);

  final SupabaseClient _client;

  Future<HistoryEntryContext> fetchContext() async {
    final response = await _client.rpc('admin_get_history_entry_context');
    return HistoryEntryContext.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  /// Enregistre le match et renvoie son identifiant.
  Future<String> addMatch(HistoryMatchDraft draft) async {
    final response = await _client.rpc(
      'admin_add_historical_match',
      params: {'p_match': draft.toPayload()},
    );
    return response.toString();
  }

  /// Une seule RPC transactionnelle : un fichier refusé ne laisse aucune
  /// insertion partielle. Rapproche uniquement les noms complets uniques.
  Future<({int imported, int skipped})> importMatches(
    HistoryImportBatch batch,
    HistoryEntryContext context,
  ) async {
    final idsByName = <String, Set<String>>{};
    for (final player in context.players) {
      if (player.playerId == null) continue;
      final normalized =
          player.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      idsByName.putIfAbsent(normalized, () => <String>{}).add(player.playerId!);
    }
    final linked = <Map<String, dynamic>>[
      for (final match in batch.matches)
        {
          ...match,
          for (final field in [
            'present',
            'starters',
            'bench',
            'scorers',
            'motm'
          ])
            if (match[field] is List)
              field: [
                for (final raw in match[field] as List)
                  {
                    ...Map<String, dynamic>.from(raw as Map),
                    if ((idsByName[(raw['name'] as String)
                                    .trim()
                                    .toLowerCase()
                                    .replaceAll(RegExp(r'\s+'), ' ')] ??
                                const <String>{})
                            .length ==
                        1)
                      'player_id': idsByName[(raw['name'] as String)
                              .trim()
                              .toLowerCase()
                              .replaceAll(RegExp(r'\s+'), ' ')]!
                          .single,
                  },
              ],
        },
    ];
    final response = await _client.rpc(
      'admin_import_historical_matches',
      params: {
        'p_document': {
          'format': 'petit-filet-historique',
          'version': 1,
          'matches': linked,
        },
      },
    );
    final result = Map<String, dynamic>.from(response as Map);
    return (
      imported: (result['imported'] as num).toInt(),
      skipped: (result['skipped'] as num).toInt(),
    );
  }

  Future<bool> deleteMatch(String matchId) async {
    final response = await _client.rpc(
      'admin_delete_historical_match',
      params: {'p_match_id': matchId},
    );
    return response == true;
  }
}

final historyEntryRepositoryProvider = Provider<HistoryEntryRepository>(
  (ref) => HistoryEntryRepository(ref.watch(supabaseClientProvider)),
);
