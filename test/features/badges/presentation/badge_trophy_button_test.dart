import 'dart:async';

import 'package:as_grinta/features/badges/data/badge_inbox_repository.dart';
import 'package:as_grinta/features/badges/presentation/badge_trophy_button.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('le bouton attend les modules sans lire les badges',
      (tester) async {
    final modules = Completer<ClubModules>();
    var badgeReads = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        clubModulesProvider.overrideWith((ref) => modules.future),
        hasUnseenBadgeProvider.overrideWith((ref) async {
          badgeReads += 1;
          return true;
        }),
      ],
      child: const MaterialApp(home: Scaffold(body: BadgeTrophyButton())),
    ));
    await tester.pump();
    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
    expect(badgeReads, 0);

    modules.complete(const ClubModules.allEnabled());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    expect(badgeReads, 1);
  });

  testWidgets('une erreur de réglages ne révèle pas le bouton ni les badges',
      (tester) async {
    var badgeReads = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        clubModulesProvider.overrideWith((ref) async {
          throw StateError('réglages indisponibles');
        }),
        hasUnseenBadgeProvider.overrideWith((ref) async {
          badgeReads += 1;
          return true;
        }),
      ],
      child: const MaterialApp(home: Scaffold(body: BadgeTrophyButton())),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
    expect(badgeReads, 0);
  });

  testWidgets(
    'affiche un indicateur lorsqu’un badge est nouveau',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clubModulesProvider.overrideWith(
              (ref) async => const ClubModules.allEnabled(),
            ),
            hasUnseenBadgeProvider.overrideWith((ref) async => true),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BadgeTrophyButton()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
      expect(
        find.byKey(const ValueKey('badge-unseen-indicator')),
        findsOneWidget,
      );
    },
  );

  testWidgets('masque l’indicateur lorsque tout est vu', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubModulesProvider.overrideWith(
            (ref) async => const ClubModules.allEnabled(),
          ),
          hasUnseenBadgeProvider.overrideWith((ref) async => false),
        ],
        child: const MaterialApp(
          home: Scaffold(body: BadgeTrophyButton()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey('badge-unseen-indicator')), findsNothing);
  });
}
