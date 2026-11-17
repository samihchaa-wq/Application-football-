import 'package:as_grinta/features/season_wrapped/data/season_wrapped_repository.dart';
import 'package:as_grinta/features/season_wrapped/domain/wrapped_stat_selection.dart';
import 'package:as_grinta/features/season_wrapped/presentation/wrapped_slides.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final wrapped = demoSeasonWrapped('2026-2027');

  test('toutes les statistiques restent affichées par défaut', () {
    expect(wrappedSlideSkins(WrappedStatOption.allMask), hasLength(11));
    expect(wrapped.sheetsForMask(WrappedStatOption.allMask), hasLength(3));
    expect(wrapped.statsForMask(WrappedStatOption.allMask), hasLength(10));
  });

  test('le réglage buts garde uniquement la page et le partage concernés', () {
    const mask = 8;
    expect(wrappedSlideSkins(mask), hasLength(3));
    expect(wrapped.statsForMask(mask).map((stat) => stat.label), ['Buts']);
    final sheets = wrapped.sheetsForMask(mask);
    expect(sheets, hasLength(1));
    expect(sheets.single.title, 'Mon apport');
    expect(sheets.single.stats.single.label, 'Buts');
  });

  test('postes et polyvalence restent groupés dans un choix unique', () {
    const mask = 64;
    expect(wrappedSlideSkins(mask), hasLength(3));
    expect(wrapped.statsForMask(mask).map((stat) => stat.label),
        ['Poste le plus joué', 'Polyvalence']);
  });

  test('masquer les badges masque aussi leur total dans les partages', () {
    const mask = WrappedStatOption.allMask ^ 256;
    expect(wrappedSlideSkins(mask), hasLength(10));
    expect(
      wrapped
          .statsForMask(mask)
          .any((stat) => stat.label == 'Badges décrochés'),
      isFalse,
    );
  });
}
