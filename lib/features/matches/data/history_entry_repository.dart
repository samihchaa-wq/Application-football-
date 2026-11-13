import 'package:as_grinta/core/providers/supabase_provider.dart';
import 'package:as_grinta/features/matches/domain/history_match_draft.dart';
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
