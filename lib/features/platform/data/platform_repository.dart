import 'package:petit_filet/core/providers/supabase_provider.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/platform/domain/platform_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlatformAccessDenied implements Exception {
  const PlatformAccessDenied();
}

/// Only guarded, read-only RPCs. No elevated key or client-side role grant.
class PlatformRepository {
  PlatformRepository(this._rpc);

  final Future<dynamic> Function(String function) _rpc;

  Future<PlatformSnapshot> fetch() async {
    try {
      // This RPC checks private.platform_operators before returning any club.
      final response = await _rpc('platform_control_overview')
          .timeout(const Duration(seconds: 15));
      if (response is! Map) throw const FormatException('Invalid overview');
      final rows = response['clubs'];
      if (rows is! List) throw const FormatException('Invalid team list');
      final teams = rows.map((row) {
        if (row is! Map) throw const FormatException('Invalid team');
        return PlatformTeam.fromJson(Map<String, dynamic>.from(row));
      }).toList();
      if (teams.map((team) => team.id).toSet().length != teams.length) {
        throw const FormatException('Duplicate team identifiers');
      }
      final totalsJson = response['totals'];
      final totals = totalsJson is Map
          ? PlatformTotals.fromJson(Map<String, dynamic>.from(totalsJson))
          : const PlatformTotals();
      final dailyVisits = <PlatformDailyVisits>[];
      final dailyJson = response['daily_visits'];
      if (dailyJson is List) {
        for (final point in dailyJson) {
          if (point is! Map) continue;
          final day = measuredDate(point['day']);
          final visits = measuredCount(point['visits']);
          if (day != null && visits != null) {
            dailyVisits.add(PlatformDailyVisits(day, visits));
          }
        }
      }

      PlatformHealth? health;
      try {
        final response =
            await _rpc('platform_health').timeout(const Duration(seconds: 15));
        if (response is! Map) throw const FormatException('Invalid health');
        health = PlatformHealth.fromJson(Map<String, dynamic>.from(response));
      } on PostgrestException catch (error) {
        // A revoked operator must lose the entire snapshot, not only health.
        if (_isAccessError(error)) throw const PlatformAccessDenied();
      } on AuthException {
        throw const PlatformAccessDenied();
      } catch (_) {
        // Observability unavailable is never translated to zero failures.
      }
      return PlatformSnapshot(
        teams: teams,
        fetchedAt: DateTime.now().toUtc(),
        health: health,
        totals: totals,
        dailyVisits: dailyVisits,
      );
    } on PostgrestException catch (error) {
      if (_isAccessError(error)) throw const PlatformAccessDenied();
      rethrow;
    } on AuthException {
      throw const PlatformAccessDenied();
    }
  }
}

bool _isAccessError(PostgrestException error) =>
    const {'42501', 'PGRST301', 'PGRST302', 'PGRST303'}.contains(error.code);

final platformRepositoryProvider = Provider<PlatformRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PlatformRepository((name) async => await client.rpc(name));
});

/// No disk persistence. Signed-out/session changes destroy the previous view.
final platformSnapshotProvider = FutureProvider.autoDispose<PlatformSnapshot>((
  ref,
) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.hasSession || auth.isLoading) throw const PlatformAccessDenied();
  return ref.watch(platformRepositoryProvider).fetch();
});
