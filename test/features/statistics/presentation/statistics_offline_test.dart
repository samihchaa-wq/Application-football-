import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/core/network/connectivity_service.dart';
import 'package:petit_filet/features/statistics/data/statistics_repository.dart';
import 'package:petit_filet/features/statistics/presentation/team_statistics_panel.dart';

/// Statistiques ouvertes sans réseau : « Hors ligne » au lieu d'un écran
/// vide, puis nouvelle lecture au retour du réseau.
void main() {
  testWidgets('hors ligne, l’équipe affiche un message puis se relit',
      (tester) async {
    final online = StreamController<bool>();
    addTearDown(online.close);
    var reads = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onlineStatusProvider.overrideWith((ref) => online.stream),
          teamStatisticsPeriodProvider.overrideWith((ref, period) {
            reads++;
            // Demande en attente, comme sans réseau.
            return Completer<TeamStatistics>().future;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TeamStatisticsPanel(period: StatisticsPeriod.current),
          ),
        ),
      ),
    );

    online.add(false);
    await tester.pump();
    expect(find.textContaining('Hors ligne'), findsOneWidget);
    expect(reads, 1);

    online.add(true);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Hors ligne'), findsNothing);
    expect(reads, 2);
  });
}
