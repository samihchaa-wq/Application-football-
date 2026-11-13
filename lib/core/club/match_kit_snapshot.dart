import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/providers/supabase_provider.dart';
import 'package:as_grinta/features/matches/domain/jersey_option.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Photographie des couleurs de maillot au coup d'envoi / à la clôture.
@immutable
class MatchKitSnapshot {
  const MatchKitSnapshot({
    required this.matchId,
    required this.clubId,
    required this.jerseyId,
    required this.kit,
    required this.allKits,
    required this.capturedAt,
    this.team1Kit,
    this.team2Kit,
  });

  final String matchId;
  final String clubId;
  final JerseyOption jerseyId;
  final ClubKit kit;
  final List<ClubKit> allKits;
  final ClubKit? team1Kit;
  final ClubKit? team2Kit;
  final DateTime capturedAt;

  /// Le JSON conserve les couleurs exactes ; ne jamais reconstruire un
  /// historique à partir de [ClubKits.all] qui évolue avec le club.
  static MatchKitSnapshot? fromJson(Map<String, dynamic> json) {
    final matchId = json['match_id']?.toString();
    final clubId = json['club_id']?.toString();
    final slot = JerseyOption.fromId(json['jersey_id']?.toString());
    final kits = ClubKits.parse(json['kits']);
    final capturedAt = DateTime.tryParse(json['captured_at']?.toString() ?? '');
    if (matchId == null ||
        matchId.isEmpty ||
        clubId == null ||
        clubId.isEmpty ||
        slot == null ||
        kits == null ||
        capturedAt == null) {
      return null;
    }

    ClubKit? fromSnapshot(Object? value) {
      if (value == null) return null;
      if (value is! Map) return null;
      final id = JerseyOption.fromId(value['slot']?.toString());
      if (id == null) return null;
      return kits.firstWhere((kit) => kit.slot == id);
    }

    return MatchKitSnapshot(
      matchId: matchId,
      clubId: clubId,
      jerseyId: slot,
      kit: kits.firstWhere((kit) => kit.slot == slot),
      allKits: List<ClubKit>.unmodifiable(kits),
      team1Kit: fromSnapshot(json['team1_kit']),
      team2Kit: fromSnapshot(json['team2_kit']),
      capturedAt: capturedAt,
    );
  }
}

/// Lecture seule sous RLS. Un résultat nul signifie que le match n'a pas
/// encore débuté (ou que la migration n'est pas appliquée).
///
/// Ne jamais modifier la table depuis le client : seul le serveur saisit les
/// couleurs au démarrage du Live / à la validation du résultat.
final matchKitSnapshotProvider =
    FutureProvider.autoDispose.family<MatchKitSnapshot?, String>(
  (ref, matchId) async {
    final row = await ref
        .watch(supabaseClientProvider)
        .from('match_kit_snapshots')
        .select(
          'match_id,club_id,jersey_id,kit,kits,team1_kit,team2_kit,captured_at',
        )
        .eq('match_id', matchId)
        .maybeSingle();
    return row == null ? null : MatchKitSnapshot.fromJson(row);
  },
);
