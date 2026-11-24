import 'package:petit_filet/features/admin/data/admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';

AdminSeasonItem _season(String name) =>
    AdminSeasonItem(id: name, name: name, status: 'archived');

void main() {
  test('saison finie en novembre : la suivante, pas la même', () {
    expect(
      suggestedNewSeasonName(
        [_season('2025-2026'), _season('2026-2027')],
        DateTime(2026, 11, 24),
      ),
      '2027-2028',
    );
  });

  test('fin de saison en juin : l’année en cours, comme avant', () {
    expect(
      suggestedNewSeasonName([_season('2026-2027')], DateTime(2027, 6, 20)),
      '2027-2028',
    );
  });

  test('premier club sans saison : l’année en cours', () {
    expect(suggestedNewSeasonName(const [], DateTime(2026, 9, 1)), '2026-2027');
  });

  test('un nom hors format est ignoré', () {
    expect(
      suggestedNewSeasonName([_season('Saison test')], DateTime(2026, 9, 1)),
      '2026-2027',
    );
  });
}
