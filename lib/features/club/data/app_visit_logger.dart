import 'package:petit_filet/core/providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Note qu'un membre a ouvert l'appli aujourd'hui (une fois par jour au plus,
/// le serveur ignore les doublons). Sert à la moyenne de visites du poste de
/// contrôle de l'éditeur ; aucune autre information n'est envoyée.
class AppVisitLogger {
  AppVisitLogger(this._rpc, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final Future<void> Function() _rpc;
  final DateTime Function() _clock;
  DateTime? _loggedDay;

  Future<void> log() async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    if (_loggedDay == today) return;
    _loggedDay = today;
    try {
      await _rpc().timeout(const Duration(seconds: 10));
    } catch (_) {
      // Une visite non comptée ne doit jamais gêner l'utilisateur ; on
      // réessaiera au prochain retour dans l'appli.
      _loggedDay = null;
    }
  }
}

final appVisitLoggerProvider = Provider<AppVisitLogger>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AppVisitLogger(() async => await client.rpc('log_app_visit'));
});
