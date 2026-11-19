import 'package:petit_filet/features/admin/data/admin_repository.dart';
import 'package:petit_filet/features/admin/presentation/club_season_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Créer ou finir la saison, désormais dans les Réglages du club.
void main() {
  Future<void> pumpTile(
    WidgetTester tester,
    _FakeClubAdminRepository club,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(club),
          adminDashboardProvider.overrideWith(
            (ref) => ref.read(adminRepositoryProvider).fetchDashboard(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ClubSeasonTile()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('finir la saison demande confirmation', (tester) async {
    final club = _FakeClubAdminRepository();
    await pumpTile(tester, club);

    expect(find.text('Saison 2026-2027'), findsOneWidget);
    await tester.tap(find.text('Finir la saison'));
    await tester.pumpAndSettle();
    expect(find.text('Finir la saison ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(club.seasonStatusChanges, isEmpty);

    await tester.tap(find.text('Finir la saison'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmer'));
    await tester.pumpAndSettle();
    expect(club.seasonStatusChanges, [('s-1', 'archived')]);
    expect(find.text('Créer une saison'), findsOneWidget);
  });

  testWidgets('sans saison ouverte, on peut en créer une', (tester) async {
    final club = _FakeClubAdminRepository()..seasons = const [];
    await pumpTile(tester, club);

    await tester.tap(find.text('Créer une saison'));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle saison'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '2027-2028');
    await tester.tap(find.widgetWithText(FilledButton, 'Créer'));
    await tester.pumpAndSettle();

    expect(club.createdSeasons, ['2027-2028']);
    expect(find.text('Finir la saison'), findsOneWidget);
  });
}

class _FakeClubAdminRepository implements AdminRepository {
  List<AdminSeasonItem> seasons = const [
    AdminSeasonItem(id: 's-1', name: '2026-2027', status: 'open'),
  ];
  final seasonStatusChanges = <(String, String)>[];
  final createdSeasons = <String>[];

  @override
  Future<AdminDashboardData> fetchDashboard() async => AdminDashboardData(
        profiles: const [],
        seasons: seasons,
        openSeasonId: seasons.where((s) => s.status == 'open').firstOrNull?.id,
      );

  @override
  Future<void> setSeasonStatus(String seasonId, String status) async {
    seasonStatusChanges.add((seasonId, status));
    seasons = [
      for (final season in seasons)
        if (season.id == seasonId)
          AdminSeasonItem(id: season.id, name: season.name, status: status)
        else
          season,
    ];
  }

  @override
  Future<String> createSeason(String name) async {
    createdSeasons.add(name);
    seasons = [
      AdminSeasonItem(id: 'new', name: name, status: 'open'),
      ...seasons,
    ];
    return 'new';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
