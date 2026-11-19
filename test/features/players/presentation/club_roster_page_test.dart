import 'package:petit_filet/features/players/data/member_contacts_repository.dart';
import 'package:petit_filet/features/players/data/roster_repository.dart';
import 'package:petit_filet/features/players/presentation/club_roster_page.dart';
import 'package:petit_filet/features/profile/data/personal_data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

RosterPlayer _player(
  String id,
  String firstName, {
  String? profileId,
  bool active = true,
}) =>
    RosterPlayer(
      id: id,
      firstName: firstName,
      lastName: '',
      isGoalkeeper: false,
      isCoach: false,
      isActive: active,
      linkedProfileId: profileId,
      linkedProfileName: null,
      linkedProfileUsername: null,
    );

/// Effectif en lecture seule : tous les membres voient téléphones et dates
/// de naissance.
void main() {
  testWidgets('affiche le téléphone et la date de naissance des joueurs', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          openSeasonIdProvider.overrideWith((ref) async => 'season-1'),
          rosterProvider('season-1').overrideWith(
            (ref) async => [
              _player('1', 'Yanis', profileId: 'p-yanis'),
              _player('2', 'Adam'),
              _player('3', 'Parti', profileId: 'p-parti', active: false),
            ],
          ),
          clubMemberContactsProvider.overrideWith(
            (ref) async => {
              'p-yanis': PrivateDetails(
                phone: '06 12 34 56 78',
                birthDate: DateTime(1995, 1, 2),
              ),
            },
          ),
        ],
        child: const MaterialApp(home: ClubRosterPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yanis'), findsOneWidget);
    expect(find.text('06 12 34 56 78'), findsOneWidget);
    expect(find.textContaining('Né(e) le 02/01/1995'), findsOneWidget);
    expect(find.byTooltip('Appeler Yanis'), findsOneWidget);
    // Joueur sans compte : pas de coordonnées.
    expect(find.text('Adam'), findsOneWidget);
    expect(find.text('Pas de coordonnées'), findsOneWidget);
    // Retiré de l'effectif : absent.
    expect(find.text('Parti'), findsNothing);
  });
}
