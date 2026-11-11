import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:as_grinta/features/predictions/presentation/widgets/inline_match_prediction_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pronostics désactivés : la carte de pronostic disparaît',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubModulesProvider.overrideWith(
            (ref) async => const ClubModules({'predictions': false}),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: InlineMatchPredictionCard(matchId: 'm1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Card), findsNothing);
  });
}
