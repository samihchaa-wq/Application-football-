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
    );
  }

  final int revision;
  final DateTime updatedAt;
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
    if (clubId == null) {
      return _client
          .from('feature_flag_change_signals')
          .stream(primaryKey: ['key'])
          .eq('key', 'sports_management')
          .where((rows) => rows.isNotEmpty)
          .map((rows) => FeatureFlagChangeSignal.fromRow(rows.first));
    }
    // Filtré par club côté serveur : le téléphone n'écoute que son club.
    return _client
        .from('feature_flag_change_signals')
        .stream(primaryKey: ['club_id', 'key'])
        .eq('club_id', clubId)
        .map(
          (rows) =>
              rows.where((row) => row['key'] == 'sports_management').toList(),
        )
        .where((rows) => rows.isNotEmpty)
        .map((rows) => FeatureFlagChangeSignal.fromRow(rows.first));
  }
}

final featureFlagsRepositoryProvider = Provider<FeatureFlagsRepository>((ref) {
  return SupabaseFeatureFlagsRepository(ref.watch(supabaseClientProvider));
});
