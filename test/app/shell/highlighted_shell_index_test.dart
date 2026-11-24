import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/app/shell/app_shell.dart';

void main() {
  test('Calendrier allumé seulement sur le calendrier et ses matchs', () {
    expect(highlightedShellIndex(branchIndex: 0, locationPath: '/matches'), 0);
    expect(
      highlightedShellIndex(branchIndex: 0, locationPath: '/matches/42/vote'),
      0,
    );
    expect(highlightedShellIndex(branchIndex: 0, locationPath: '/more'), null);
    expect(highlightedShellIndex(branchIndex: 0, locationPath: '/admin'), null);
    expect(
      highlightedShellIndex(branchIndex: 0, locationPath: '/profile'),
      null,
    );
    expect(highlightedShellIndex(branchIndex: 1, locationPath: '/stats'), 1);
  });
}
