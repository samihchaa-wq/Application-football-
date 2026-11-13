import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/club/match_kit_snapshot.dart';
import 'package:as_grinta/features/matches/data/match_info_repository.dart';
import 'package:as_grinta/features/matches/domain/jersey_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Le maillot de CETTE composition, et non un maillot global partagé entre
/// plusieurs matchs. Le scope évite aussi de modifier les portraits ailleurs
/// dans l'application (fiches joueurs, votes, listes de membres).
class CompositionKitScope extends InheritedWidget {
  const CompositionKitScope({
    super.key,
    required this.kit,
    required super.child,
  });

  final ClubKit kit;

  static ClubKit? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CompositionKitScope>()?.kit;

  @override
  bool updateShouldNotify(CompositionKitScope oldWidget) =>
      kit != oldWidget.kit;
}

/// Résout le maillot sélectionné dans Infos pour l'avant-match et le Live.
/// Un chargement en cours ne montre PAS un faux maillot « domicile » : les
/// avatars restent neutres jusqu'à réception de la fiche du match.
///
/// Pour un match déjà terminé, un snapshot historique doit prendre le pas sur
/// ces réglages courants : ce sera l'objet d'une migration séparée.
class MatchCompositionKitScope extends ConsumerWidget {
  const MatchCompositionKitScope({
    super.key,
    required this.matchId,
    required this.child,
  });

  final String? matchId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = matchId;
    if (id == null) return child;
    // Pour les matchs démarrés/terminés : toujours la tenue du jour J,
    // pas celle configurée aujourd'hui dans Administration.
    final snapshot = ref.watch(matchKitSnapshotProvider(id)).valueOrNull;
    if (snapshot != null) {
      return CompositionKitScope(kit: snapshot.kit, child: child);
    }
    final info = ref.watch(matchInfoProvider(id));
    if (info.isLoading || info.hasError) return child;
    final selection = JerseyOption.fromId(info.valueOrNull?.jerseyNote) ??
        JerseyOption.france;

    return ValueListenableBuilder<int>(
      valueListenable: ClubKits.revision,
      builder: (context, _, __) =>
          CompositionKitScope(kit: selection.kit, child: child),
    );
  }
}
