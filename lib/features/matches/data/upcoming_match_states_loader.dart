import 'dart:async';

import 'package:petit_filet/core/logging/app_logger.dart';
import 'package:petit_filet/core/providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Réponse groupée pour un match : chaque part n'est présente que si le
/// serveur a pu la lire sans erreur. Une part absente doit être redemandée
/// par l'appel individuel, qui rend l'erreur d'origine.
class UpcomingMatchStates {
  const UpcomingMatchStates({
    required this.availabilityRead,
    required this.availability,
    required this.liveNotificationsRead,
    required this.liveNotifications,
  });

  factory UpcomingMatchStates.fromJson(Map<String, dynamic> json) {
    return UpcomingMatchStates(
      availabilityRead: json['availability_ok'] == true,
      availability: json['availability'],
      liveNotificationsRead: json['live_notifications_ok'] == true,
      liveNotifications: json['live_notifications'],
    );
  }

  /// `true` quand [availability] est la réponse exacte du serveur (même nulle).
  final bool availabilityRead;
  final Object? availability;

  /// `true` quand [liveNotifications] est la réponse exacte du serveur.
  final bool liveNotificationsRead;
  final Object? liveNotifications;
}

/// Les deux parts d'une réponse groupée, chacune lue par un écran différent.
enum UpcomingMatchPart { availability, liveNotifications }

/// Une réponse groupée (en cours ou reçue) et les parts déjà servies.
class _SharedResponse {
  _SharedResponse(this.future);

  final Future<UpcomingMatchStates?> future;
  final Set<UpcomingMatchPart> served = {};
  DateTime? receivedAt;
}

/// Regroupe en une seule requête les lectures « ma dispo » et « cloche des
/// buts » demandées en même temps par les cartes du calendrier.
///
/// Chaque carte de match à venir lisait séparément ces deux états : environ
/// 26 requêtes à chaque affichage du calendrier, et des pastilles qui
/// apparaissaient une par une. Les demandes faites pendant une courte fenêtre
/// ([window]) partent désormais ensemble vers
/// `get_my_upcoming_match_states`, qui appelle côté serveur les deux mêmes
/// fonctions, avec les mêmes droits.
///
/// Une réponse sert au plus une fois chaque part ([UpcomingMatchPart]), et
/// seulement pendant [reuseFor] : la cloche demandée juste après « ma dispo »
/// (carte construite un peu plus tard, en défilant) profite de la même
/// réponse au lieu de relancer la requête groupée. Une relecture de la même
/// part (après une modification, un signal de synchronisation…) repart
/// toujours au serveur.
///
/// Repli : si la fonction groupée n'existe pas encore en production, ou si
/// la requête groupée échoue, [load] rend `null` et l'appelant refait son
/// appel individuel habituel. L'application et la base peuvent donc être
/// mises à jour dans n'importe quel ordre.
class UpcomingMatchStatesLoader {
  UpcomingMatchStatesLoader(
    this._client, {
    this.window = const Duration(milliseconds: 20),
    this.maxBatchSize = 50,
    this.reuseFor = const Duration(seconds: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SupabaseClient _client;
  final Duration window;

  /// Le serveur refuse au-delà de 60 matchs par appel.
  final int maxBatchSize;

  /// Durée pendant laquelle l'autre part d'une réponse reçue peut encore
  /// être servie sans nouvelle requête.
  final Duration reuseFor;
  final DateTime Function() _now;
  final Map<String, _SharedResponse> _shared = {};

  static const _rpc = 'get_my_upcoming_match_states';
  static const _timeout = Duration(seconds: 8);

  final Map<String, Completer<UpcomingMatchStates?>> _pending = {};
  Timer? _flushTimer;
  bool _unsupported = false;

  /// État groupé de [matchId], ou `null` si l'appelant doit faire son appel
  /// individuel.
  ///
  /// Avec [part], une réponse groupée en cours ou toute récente qui n'a pas
  /// encore servi cette part est réutilisée.
  Future<UpcomingMatchStates?> load(String matchId, {UpcomingMatchPart? part}) {
    if (_unsupported || matchId.isEmpty) return Future.value();
    final existing = _pending[matchId];
    if (existing != null) {
      if (part != null) _shared[matchId]?.served.add(part);
      return existing.future;
    }
    if (part != null) {
      final shared = _shared[matchId];
      final receivedAt = shared?.receivedAt;
      if (shared != null &&
          !shared.served.contains(part) &&
          (receivedAt == null || _now().difference(receivedAt) < reuseFor)) {
        shared.served.add(part);
        return shared.future;
      }
    }

    final completer = Completer<UpcomingMatchStates?>();
    _pending[matchId] = completer;
    final shared = _SharedResponse(completer.future);
    if (part != null) shared.served.add(part);
    _shared[matchId] = shared;
    if (_pending.length >= maxBatchSize) {
      _flush();
    } else {
      _flushTimer ??= Timer(window, _flush);
    }
    return completer.future;
  }

  void _flush() {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_pending.isEmpty) return;
    final batch = Map<String, Completer<UpcomingMatchStates?>>.of(_pending);
    _pending.clear();
    unawaited(_send(batch));
  }

  Future<void> _send(Map<String, Completer<UpcomingMatchStates?>> batch) async {
    Map<String, UpcomingMatchStates>? states;
    try {
      final response = await _client.rpc(
        _rpc,
        params: {'p_match_ids': batch.keys.toList(growable: false)},
      ).timeout(_timeout);
      if (response is Map) {
        states = {
          for (final entry in response.entries)
            if (entry.value is Map)
              entry.key.toString(): UpcomingMatchStates.fromJson(
                Map<String, dynamic>.from(entry.value as Map),
              ),
        };
      }
    } on PostgrestException catch (error, stackTrace) {
      if (_isMissingFunction(error)) {
        // Base pas encore à jour : on revient définitivement aux appels
        // individuels pour cette session, sans bruit dans le journal.
        _unsupported = true;
      } else {
        AppLogger.error('calendar.upcoming_states', error, stackTrace);
      }
    } catch (error, stackTrace) {
      AppLogger.error('calendar.upcoming_states', error, stackTrace);
    }

    final receivedAt = _now();
    for (final entry in batch.entries) {
      final shared = _shared[entry.key];
      if (shared != null && identical(shared.future, entry.value.future)) {
        if (states?[entry.key] == null) {
          // Rien d'utile à partager : chaque part refera son appel.
          _shared.remove(entry.key);
        } else {
          shared.receivedAt = receivedAt;
        }
      }
      if (!entry.value.isCompleted) {
        entry.value.complete(states?[entry.key]);
      }
    }
    _shared.removeWhere(
      (_, shared) {
        final at = shared.receivedAt;
        return at != null && receivedAt.difference(at) >= reuseFor;
      },
    );
  }

  static bool _isMissingFunction(PostgrestException error) {
    // PGRST202 : fonction absente du schéma exposé par l'API ;
    // 42883 : fonction inconnue de PostgreSQL.
    final code = error.code ?? '';
    return code == 'PGRST202' || code == '42883';
  }
}

final upcomingMatchStatesLoaderProvider =
    Provider<UpcomingMatchStatesLoader>((ref) {
  return UpcomingMatchStatesLoader(ref.watch(supabaseClientProvider));
});
