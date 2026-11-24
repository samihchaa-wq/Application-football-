import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/matches/data/matches_repository.dart';
import 'package:petit_filet/features/matches/domain/match_model.dart';
import 'package:petit_filet/features/matches/presentation/matches_controller.dart';
import 'package:petit_filet/features/matches/presentation/matches_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Une mise à jour en direct recharge la liste partagée pour toutes les
/// saisons : l'écran « Calendrier » de l'admin, réglé sur une saison,
/// affichait alors les matchs des saisons précédentes.
void main() {
  testWidgets('seuls les matchs de la saison choisie sont listés',
      (tester) async {
    final matches = [
      _match('ancien', 'saison-1', 'Olympique Ancien', days: -200),
      _match('nouveau', 'saison-2', 'FC Nouveau', days: 2),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAdminViewProvider.overrideWithValue(false),
          matchesControllerProvider.overrideWith(
            (ref) => _StaticMatchesController(ref, matches),
          ),
        ],
        child: const MaterialApp(home: MatchesPage()),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Nouveau'), findsOneWidget);
    expect(find.textContaining('Ancien'), findsNothing);
  });
}

MatchModel _match(String id, String seasonId, String opponent,
        {required int days}) =>
    MatchModel(
      id: id,
      seasonId: seasonId,
      opponentId: 'opp-$id',
      kickoffAt: DateTime.now().add(Duration(days: days)),
      isHome: true,
      plannedDurationMinutes: 90,
      status: days < 0 ? 'termine' : 'a_venir',
      ownScore: days < 0 ? 1 : null,
      opponentScore: days < 0 ? 0 : null,
      opponentName: opponent,
    );

class _StaticMatchesController extends MatchesController {
  _StaticMatchesController(Ref ref, List<MatchModel> matches)
      : super(_UnusedMatchesRepository(), ref) {
    // Noms d'équipe insécables dans la liste : on cherche un seul mot.
    // État laissé par le rechargement « toutes saisons » de la synchro.
    state = MatchesState(
      matches: matches,
      seasons: const [
        {'id': 'saison-1', 'name': '2026-2027', 'status': 'archived'},
        {'id': 'saison-2', 'name': '2027-2028', 'status': 'open'},
      ],
      selectedSeasonId: 'saison-2',
      includesAllSeasons: true,
      isLoading: false,
    );
  }

  @override
  Future<void> load({
    String? seasonId,
    bool allSeasons = false,
    bool forceRefresh = false,
  }) async {}
}

class _UnusedMatchesRepository implements MatchesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
