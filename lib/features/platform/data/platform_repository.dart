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
  PlatformRepository(
    this._rpc, {
    Future<void> Function()? refreshSession,
    String? Function()? currentAccessToken,
  })  : _refreshSession = refreshSession,
        _currentAccessToken = currentAccessToken;

  /// Jeton d'accès courant. Au retour dans l'appli, le client Supabase
  /// renouvelle déjà la session de lui-même : si le jeton a changé pendant la
  /// requête, on réessaie simplement, sans second renouvellement concurrent
  /// (deux renouvellements du même jeton de session peuvent faire révoquer la
  /// session, donc déconnecter le gestionnaire).
  final String? Function()? _currentAccessToken;

  final Future<dynamic> Function(String function) _rpc;

  /// Renouvelle la session. Au retour dans l'appli, le jeton d'accès a pu
  /// expirer pendant l'absence : le serveur répond alors « jeton expiré », ce
  /// qui ne veut pas dire « compte non autorisé ».
  final Future<void> Function()? _refreshSession;

  Future<PlatformSnapshot> fetch() async {
    final tokenBefore = _currentAccessToken?.call();
    try {
      return await _fetch(canRetry: _refreshSession != null);
    } on PostgrestException catch (error) {
      final refresh = _refreshSession;
      if (refresh == null || !_isExpiredToken(error)) rethrow;
      final tokenNow = _currentAccessToken?.call();
      final alreadyRenewed = tokenBefore != null && tokenNow != tokenBefore;
      if (!alreadyRenewed) {
        try {
          await refresh();
        } catch (_) {
          throw const PlatformAccessDenied();
        }
      }
      return _fetch(canRetry: false);
    }
  }

  Future<PlatformSnapshot> _fetch({required bool canRetry}) async {
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
        if (canRetry && _isExpiredToken(error)) rethrow;
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
      if (canRetry && _isExpiredToken(error)) rethrow;
      if (_isAccessError(error)) throw const PlatformAccessDenied();
      rethrow;
    } on AuthException {
      throw const PlatformAccessDenied();
    }
  }
}

/// Jeton expiré ou illisible : se corrige en renouvelant la session.
bool _isExpiredToken(PostgrestException error) =>
    const {'PGRST301', 'PGRST302', 'PGRST303'}.contains(error.code);

bool _isAccessError(PostgrestException error) =>
    const {'42501', 'PGRST301', 'PGRST302', 'PGRST303'}.contains(error.code);

final platformRepositoryProvider = Provider<PlatformRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PlatformRepository(
    (name) async => await client.rpc(name),
    refreshSession: () async {
      await client.auth.refreshSession();
    },
    currentAccessToken: () => client.auth.currentSession?.accessToken,
  );
});

/// No disk persistence. Signed-out/session changes destroy the previous view.
final platformSnapshotProvider = FutureProvider.autoDispose<PlatformSnapshot>((
  ref,
) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.hasSession || auth.isLoading) throw const PlatformAccessDenied();
  return ref.watch(platformRepositoryProvider).fetch();
});
