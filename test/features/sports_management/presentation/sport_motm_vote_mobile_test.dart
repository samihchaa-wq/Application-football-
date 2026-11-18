import 'package:petit_filet/features/sports_management/data/sport_motm_vote_repository.dart';
import 'package:petit_filet/features/sports_management/domain/sport_motm_vote.dart';
import 'package:petit_filet/features/sports_management/presentation/sport_motm_vote_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    for (final scenario in [
      ('open', false, 'Vote de l’Homme du match ouvert'),
      ('open', true, 'Vote de l’Homme du match enregistré'),
      ('closed', false, 'Homme du match'),
      ('cancelled', false, 'Vote de l’Homme du match annulé'),
      ('draft', false, 'Vote de l’Homme du match en préparation'),
      ('error', false, 'Vote de l’Homme du match momentanément indisponible.'),
    ]) {
      testWidgets('M03 HDM ${scenario.$1}/${scenario.$2} à $width px', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sportMotmVoteProvider('match-fictif').overrideWith((ref) async {
                if (scenario.$1 == 'error') throw StateError('Erreur fictive');
                return SportMotmVote.fromJson({
                  'match_id': 'match-fictif',
                  'state': scenario.$1,
                  'has_voted': scenario.$2,
                  'is_eligible_voter': true,
                  'can_vote': true,
                  'candidates': <Map<String, dynamic>>[],
                });
              }),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: MatchMotmVoteCard(matchId: 'match-fictif'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final label = find.text(scenario.$3);
        expect(label, findsOneWidget);
        expect(tester.widget<Text>(label).overflow, isNull);
        expect(find.textContaining('Étoile du match'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
