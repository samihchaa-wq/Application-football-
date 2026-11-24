import 'package:petit_filet/features/matches/data/match_details_repository.dart';
import 'package:petit_filet/features/predictions/data/predictions_repository.dart';
import 'package:petit_filet/features/predictions/presentation/widgets/inline_match_prediction_card.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _matchId = 'match-1';
const _outcomeUnknownMessage =
    'Connexion interrompue : ton pronostic a peut-être été enregistré. '
    'Actualise la page avant de réessayer.';

/// Une coupure pendant l'enregistrement laisse l'issue inconnue : la carte doit
/// le dire, et non annoncer un échec qui pousserait à ressaisir un pronostic
/// peut-être déjà enregistré.
void main() {
  testWidgets('une coupure pendant l’enregistrement le dit sans parler d’échec',
      (tester) async {
    final repository = _FakePredictionsRepository(
      saveError: const PredictionWriteOutcomeUnknown(),
    );
    await _pump(tester, repository);

    await _tapSave(tester);

    expect(repository.saveCalls, 1);
    expect(find.text(_outcomeUnknownMessage), findsOneWidget);
    await _dismissSnackBar(tester);
  });

  testWidgets('un refus du serveur reste annoncé comme un échec', (
    tester,
  ) async {
    final repository = _FakePredictionsRepository(
      saveError: StateError('Le pronostic n’a pas pu être enregistré.'),
    );
    await _pump(tester, repository);

    await _tapSave(tester);

    expect(
      find.text('Le pronostic n’a pas pu être enregistré.'),
      findsOneWidget,
    );
    expect(find.text(_outcomeUnknownMessage), findsNothing);
    await _dismissSnackBar(tester);
  });

  testWidgets('match fini : le pronostic fermé ne parle pas du Live', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakePredictionsRepository(
        saveError: StateError('inutile'),
        status: 'termine',
        untilKickoff: const Duration(hours: -5),
      ),
    );

    expect(find.text('Pronostic fermé : match terminé.'), findsOneWidget);
    expect(find.textContaining('Live'), findsNothing);
  });

  testWidgets('match annulé : la raison est donnée', (tester) async {
    await _pump(
      tester,
      _FakePredictionsRepository(
        saveError: StateError('inutile'),
        status: 'annule',
        untilKickoff: const Duration(hours: -1),
      ),
    );

    expect(find.text('Pronostic fermé : match annulé.'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  _FakePredictionsRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clubModulesProvider.overrideWith(
          (ref) async => const ClubModules.allEnabled(),
        ),
        predictionsRepositoryProvider.overrideWithValue(repository),
        matchDetailsProvider(_matchId).overrideWith(
          (ref) => Future<MatchDetailsData>.error(StateError('indisponible')),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InlineMatchPredictionCard(matchId: _matchId),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  final save = find.text('Enregistrer');
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}

/// Laisse le message se refermer pour ne pas finir le test sur une minuterie
/// encore active.
Future<void> _dismissSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
}

class _FakePredictionsRepository implements PredictionsRepository {
  _FakePredictionsRepository({
    required this.saveError,
    this.status = 'a_venir',
    this.untilKickoff = const Duration(days: 3),
  });

  final Object saveError;
  final String status;
  final Duration untilKickoff;
  int saveCalls = 0;

  @override
  Future<MatchPredictionItem?> fetchMatchPrediction(String matchId) async {
    return MatchPredictionItem(
      matchId: matchId,
      opponentName: 'Olympique Test',
      kickoffAt: DateTime.now().add(untilKickoff),
      status: status,
      scoreOwn: 2,
      scoreOpponent: 1,
      isFilled: false,
      oddsWin: 2,
      oddsDraw: 3,
      oddsLoss: 4,
      actualScoreOwn: null,
      actualScoreOpponent: null,
    );
  }

  @override
  Future<void> savePrediction({
    required String matchId,
    required int scoreOwn,
    required int scoreOpponent,
  }) async {
    saveCalls += 1;
    throw saveError;
  }
}
