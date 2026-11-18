import 'package:petit_filet/core/widgets/match_date_column.dart';
import 'package:petit_filet/core/widgets/calendar_scoreline.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/home/presentation/home_next_match_card.dart';
import 'package:petit_filet/features/match_live/data/match_live_notification_repository.dart';
import 'package:petit_filet/features/matches/domain/match_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now();
  final kickoff = DateTime(
    now.year,
    now.month,
    now.day + 5,
    15,
  );
  final match = MatchModel(
    id: 'upcoming-test',
    seasonId: 'season',
    opponentId: 'opponent',
    kickoffAt: kickoff,
    isHome: false,
    plannedDurationMinutes: 90,
    status: 'a_venir',
    ownScore: null,
    opponentScore: null,
    opponentName: 'Adversaire Fictif A',
    matchType: 'amical',
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    required bool isAdmin,
    bool eligible = true,
    double width = 375,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        clubModulesProvider.overrideWith(
          (ref) async => const ClubModules.allEnabled(),
        ),
        matchLiveNotificationStatusProvider.overrideWith(
          (ref, matchId) async => MatchLiveNotificationStatus(
            eligible: eligible,
            subscribed: false,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Charger la famille avant le premier rendu : la position des actions
    // ne doit pas dépendre de l'ordonnancement du FutureProvider.
    final status = matchLiveNotificationStatusProvider(match.id);
    final subscription = container.listen(status, (_, __) {});
    addTearDown(subscription.close);
    final resolved = await container.read(status.future);
    await container.read(clubModulesProvider.future);
    expect(resolved.eligible, eligible);
    expect(
      container.read(clubModuleEnabledProvider(ClubModule.liveMode)),
      isTrue,
    );
    expect(match.isFinished, isFalse);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: HomeNextMatchCard(
              match: match,
              isAdmin: isAdmin,
              showAvailability: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('les deux équipes encadrent le VS dans le calendrier',
      (tester) async {
    await pumpCard(tester, isAdmin: false, eligible: false);
    expect(find.byType(CalendarScoreline), findsOneWidget);
    final names = find.byType(CalendarTeamName);
    expect(names, findsNWidgets(2));
    final left = tester.getCenter(names.at(0)).dx;
    final middle = tester.getCenter(find.text('VS')).dx;
    final right = tester.getCenter(names.at(1)).dx;
    expect(left, lessThan(middle));
    expect(right, greaterThan(middle));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cloche et crayon au niveau de la date, pas des équipes', (
    tester,
  ) async {
    await pumpCard(tester, isAdmin: true);

    final date = tester.getRect(
      find
          .descendant(
            of: find.byType(MatchDateHeader),
            matching: find.byType(Text),
          )
          .first,
    );
    final bell = tester.getRect(
      find.byIcon(Icons.notifications_none_rounded),
    );
    final edit = tester.getRect(find.byIcon(Icons.edit_outlined));
    final arrow = tester.getRect(
      find.byIcon(Icons.arrow_forward_ios_rounded),
    );

    expect((bell.center.dy - date.center.dy).abs(), lessThan(18));
    expect((edit.center.dy - date.center.dy).abs(), lessThan(18));
    expect(bell.center.dy, lessThan(arrow.center.dy));
    expect(edit.center.dy, lessThan(arrow.center.dy));
    expect(edit.center.dx, greaterThan(bell.center.dx));
    expect(tester.takeException(), isNull);

    // Le menu administrateur reste actionnable, sans ouvrir la fiche.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Modifier'), findsOneWidget);
  });

  testWidgets('sur petit écran, les boutons ne chevauchent pas la date', (
    tester,
  ) async {
    await pumpCard(tester, isAdmin: true, width: 320);
    final date = tester.getRect(
      find
          .descendant(
            of: find.byType(MatchDateHeader),
            matching: find.byType(Text),
          )
          .first,
    );
    final bell = tester.getRect(find.byIcon(Icons.notifications_none_rounded));
    expect(date.right, lessThanOrEqualTo(bell.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sans autorisation ni alertes, aucun bouton superflu', (
    tester,
  ) async {
    await pumpCard(tester, isAdmin: false, eligible: false);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
    final fixture = tester.widget<CalendarScoreline>(
      find.byType(CalendarScoreline),
    );
    expect(fixture.homeName, 'Adversaire Fictif A');
    expect(fixture.ownIsHome, isFalse);
    expect(find.text('VS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
