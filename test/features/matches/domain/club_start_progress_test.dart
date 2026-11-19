import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/features/matches/domain/club_start_progress.dart';

void main() {
  test('un club qui vient d’être créé n’a fait aucune étape', () {
    const progress = ClubStartProgress(
      hasLogo: false,
      hasOpenSeason: false,
      hasMatches: false,
      activeMembers: 1,
    );
    expect(progress.doneCount, 0);
    expect(progress.complete, isFalse);
  });

  test('le guide se termine sans logo dès que le club joue avec ses joueurs',
      () {
    const progress = ClubStartProgress(
      hasLogo: false,
      hasOpenSeason: true,
      hasMatches: true,
      activeMembers: 12,
    );
    expect(progress.doneCount, 3);
    expect(progress.complete, isTrue);
  });

  test('un administrateur seul n’a pas encore invité ses joueurs', () {
    const progress = ClubStartProgress(
      hasLogo: true,
      hasOpenSeason: true,
      hasMatches: true,
      activeMembers: 1,
    );
    expect(progress.playersDone, isFalse);
    expect(progress.complete, isFalse);
  });
}
