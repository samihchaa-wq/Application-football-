import 'package:as_grinta/core/club/current_club.dart';
import 'package:as_grinta/core/logging/app_logger.dart';
import 'package:as_grinta/core/providers/supabase_provider.dart';
import 'package:as_grinta/features/feature_flags/domain/feature_flags.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureFlagChangeSignal {
  const FeatureFlagChangeSignal({
    required this.revision,
    required this.updatedAt,
    this.key = 'sports_management',
  });

  factory FeatureFlagChangeSignal.fromRow(Map<String, dynamic> row) {
    final revisionValue = row['revision'];
    final updatedAtValue = row['updated_at'];
    if (revisionValue is! num || updatedAtValue is! String) {
      throw const FormatException('Invalid feature flag change signal.');
    }
    return FeatureFlagChangeSignal(
      revision: revisionValue.toInt(),
      updatedAt: DateTime.parse(updatedAtValue).toUtc(),
      key: row['key'] as String? ?? 'sports_management',
    );
  }

  final int revision;
  final DateTime updatedAt;
  final String key;
}

abstract interface class FeatureFlagsRepository {
  Future<FeatureFlagsSnapshot> fetchFeatureFlags();

  Stream<FeatureFlagChangeSignal> watchSportsManagementChanges();
}

class SupabaseFeatureFlagsRepository implements FeatureFlagsRepository {
  SupabaseFeatureFlagsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<FeatureFlagsSnapshot> fetchFeatureFlags() async {
    try {
      final response = await _client.rpc('get_public_feature_flags');
      return FeatureFlagsSnapshot.fromRpc(response);
    } catch (error, stackTrace) {
      AppLogger.error('feature_flags.fetch', error, stackTrace);
      return const FeatureFlagsSnapshot.permanentSportsFallback();
    }
  }

  @override
  Stream<FeatureFlagChangeSignal> watchSportsManagementChanges() {
    final clubId = currentClubIdOf(_client);
    final rows = clubId == null
        ? _client
            .from('feature_flag_change_signals')
            .stream(primaryKey: ['club_id', 'key'])
        : _client
            .from('feature_flag_change_signals')
            .stream(primaryKey: ['club_id', 'key']).eq('club_id', clubId);
    // Le flux hérité est étendu aux révisions de configuration ; aucun
    // paramètre privé n'est transporté, seules les révisions de notre club.
    return rows.expand(
      (rows) => rows
          .where(
            (row) =>
                row['key'] == 'sports_management' ||
                row['key'] == 'club_configuration',
          )
          .map(FeatureFlagChangeSignal.fromRow),
    );
  }
}

final featureFlagsRepositoryProvider = Provider<FeatureFlagsRepository>((ref) {
  return SupabaseFeatureFlagsRepository(ref.watch(supabaseClientProvider));
});
