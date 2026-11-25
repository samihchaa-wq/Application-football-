import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petit_filet/core/providers/supabase_provider.dart';
import 'package:petit_filet/features/license/domain/license_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lecture et écriture des licences. Tout est réservé aux administrateurs du
/// club : le serveur refuse les autres comptes.
class LicenseRepository {
  LicenseRepository(this._client);

  final SupabaseClient _client;

  Future<LicenseSettings> fetchSettings() async {
    final row =
        await _client.from('club_license_settings').select().maybeSingle();
    return LicenseSettings.fromJson(row);
  }

  Future<void> saveSettings(LicenseSettings settings) async {
    await _client
        .from('club_license_settings')
        .upsert(settings.toJson(), onConflict: 'club_id');
  }

  Future<Map<String, PlayerLicense>> fetchLicenses(String seasonId) async {
    final rows = await _client
        .from('season_player_licenses')
        .select('*, season_players!inner(season_id)')
        .eq('season_players.season_id', seasonId);
    return {
      for (final row in rows)
        row['season_player_id'].toString():
            PlayerLicense.fromJson(Map<String, dynamic>.from(row)),
    };
  }

  Future<void> saveLicense(PlayerLicense license) async {
    await _client
        .from('season_player_licenses')
        .upsert(license.toJson(), onConflict: 'season_player_id');
  }

  Future<String> seasonName(String seasonId) async {
    final row = await _client
        .from('seasons')
        .select('name')
        .eq('id', seasonId)
        .maybeSingle();
    return (row?['name'] ?? '').toString();
  }

  /// Adresse postale et e-mail du club (réglages du club, déjà lisibles).
  Future<({String address, String email})> clubContact() async {
    final row = await _client
        .from('club_settings')
        .select('postal_address, contact_email')
        .maybeSingle();
    return (
      address: (row?['postal_address'] ?? '').toString(),
      email: (row?['contact_email'] ?? '').toString(),
    );
  }
}

final licenseRepositoryProvider = Provider<LicenseRepository>(
  (ref) => LicenseRepository(ref.watch(supabaseClientProvider)),
);

final licenseSettingsProvider = FutureProvider.autoDispose<LicenseSettings>(
  (ref) => ref.watch(licenseRepositoryProvider).fetchSettings(),
);

final seasonLicensesProvider =
    FutureProvider.autoDispose.family<Map<String, PlayerLicense>, String>(
  (ref, seasonId) =>
      ref.watch(licenseRepositoryProvider).fetchLicenses(seasonId),
);
