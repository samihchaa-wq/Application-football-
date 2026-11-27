import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petit_filet/core/providers/supabase_provider.dart';
import 'package:petit_filet/features/license/domain/license_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lecture et écriture des licences. Tout est réservé aux administrateurs du
/// club : le serveur refuse les autres comptes.
class LicenseRepository {
  LicenseRepository(this._client);

  final SupabaseClient _client;

  /// Dépenses de la saison : chaque saison a les siennes.
  Future<List<LicenseExpense>> fetchExpenses(String seasonId) async {
    final rows = await _client
        .from('club_license_expenses')
        .select('id, label')
        .eq('season_id', seasonId)
        .order('created_at');
    return [
      for (final row in rows)
        LicenseExpense.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  Future<void> addExpense(String seasonId, String label) async {
    await _client
        .from('club_license_expenses')
        .insert({'season_id': seasonId, 'label': label.trim()});
  }

  Future<void> renameExpense(String id, String label) async {
    await _client
        .from('club_license_expenses')
        .update({'label': label.trim()}).eq('id', id);
  }

  Future<void> deleteExpense(String id) async {
    await _client.from('club_license_expenses').delete().eq('id', id);
  }

  Future<SeasonLicenses> fetchSeason(String seasonId) async {
    final licenses = await _client
        .from('season_player_licenses')
        .select(
            'season_player_id, license_paid, season_players!inner(season_id)')
        .eq('season_players.season_id', seasonId);
    final payments = await _client
        .from('season_player_expense_payments')
        .select('expense_id, season_player_id, season_players!inner(season_id)')
        .eq('season_players.season_id', seasonId);
    final expensePaid = <String, Set<String>>{};
    for (final row in payments) {
      expensePaid
          .putIfAbsent(row['expense_id'].toString(), () => <String>{})
          .add(row['season_player_id'].toString());
    }
    return SeasonLicenses(
      licensePaid: {
        for (final row in licenses)
          if (row['license_paid'] == true) row['season_player_id'].toString(),
      },
      expensePaid: expensePaid,
    );
  }

  Future<void> setLicensePaid(String playerId, bool paid) async {
    await _client.from('season_player_licenses').upsert({
      'season_player_id': playerId,
      'license_paid': paid,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'season_player_id');
  }

  Future<void> setExpensePaid(
    String expenseId,
    String playerId,
    bool paid,
  ) async {
    final table = _client.from('season_player_expense_payments');
    if (paid) {
      await table.upsert({
        'expense_id': expenseId,
        'season_player_id': playerId,
      }, onConflict: 'expense_id,season_player_id');
    } else {
      await table
          .delete()
          .eq('expense_id', expenseId)
          .eq('season_player_id', playerId);
    }
  }
}

final licenseRepositoryProvider = Provider<LicenseRepository>(
  (ref) => LicenseRepository(ref.watch(supabaseClientProvider)),
);

final licenseExpensesProvider =
    FutureProvider.autoDispose.family<List<LicenseExpense>, String>(
  (ref, seasonId) =>
      ref.watch(licenseRepositoryProvider).fetchExpenses(seasonId),
);

final seasonLicensesProvider =
    FutureProvider.autoDispose.family<SeasonLicenses, String>(
  (ref, seasonId) => ref.watch(licenseRepositoryProvider).fetchSeason(seasonId),
);
