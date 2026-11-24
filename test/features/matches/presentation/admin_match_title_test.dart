import 'package:petit_filet/features/matches/domain/match_model.dart';
import 'package:petit_filet/features/matches/presentation/matches_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match({
  required String status,
  required bool isHome,
  int? own,
  int? opponent,
  String opponentName = 'AS Pantin',
}) =>
    MatchModel(
      id: 'm1',
      seasonId: 's1',
      opponentId: 'o1',
      kickoffAt: DateTime(2026, 9, 20, 15),
      isHome: isHome,
      plannedDurationMinutes: 90,
      status: status,
      ownScore: own,
      opponentScore: opponent,
      opponentName: opponentName,
    );

void main() {
  test('un nom d’équipe et son score ne se séparent jamais', () {
    final title = adminMatchTitle(
      _match(status: 'termine', isHome: false, own: 2, opponent: 2),
    );

    expect(title, 'AS Pantin 2 - 2 AS Grinta');
    // Seules coupures possibles : autour du tiret central.
    expect(' '.allMatches(title).length, 2);
  });

  test('un match à venir garde aussi ses noms d’équipe entiers', () {
    final title = adminMatchTitle(_match(status: 'a_venir', isHome: true));

    expect(title, 'AS Grinta – AS Pantin');
  });

  testWidgets('sur une ligne trop courte, la coupure tombe sur le tiret',
      (tester) async {
    final title = adminMatchTitle(
      _match(status: 'termine', isHome: false, own: 2, opponent: 2),
    );
    final painter = TextPainter(
      text: TextSpan(text: title, style: const TextStyle(fontSize: 18)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 300);

    final lines = painter.computeLineMetrics();
    expect(lines.length, greaterThan(1));
    final firstLineEnd =
        painter.getLineBoundary(const TextPosition(offset: 0)).end;
    expect(title.substring(0, firstLineEnd).trim(), 'AS Pantin 2 -');
  });

  test('un nom trop long peut se couper entre ses mots', () {
    // Rendu insécable, « Olympique des Coteaux » ne tenait pas sur une ligne
    // de téléphone et le navigateur le coupait au milieu d'un mot
    // (« Coteau » puis « x »). Les tests ne reproduisent pas ce découpage :
    // on vérifie donc les espaces eux-mêmes.
    final title = adminMatchTitle(
      _match(
        status: 'termine',
        isHome: true,
        own: 1,
        opponent: 2,
        opponentName: 'Olympique des Coteaux',
      ),
    );

    expect(title, contains('Olympique des Coteaux'));
    // Le score reste collé au nom voisin, le nom court reste entier.
    expect(title, contains('2\u00A0Olympique'));
    expect(title, startsWith('AS\u00A0Grinta\u00A01'));
  });
}
