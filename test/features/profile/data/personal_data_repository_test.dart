import 'package:petit_filet/features/profile/data/personal_data_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('âge révolu, avant et après l’anniversaire', () {
    final birth = DateTime(1990, 5, 12);
    expect(ageOn(birth, DateTime(2026, 5, 11)), 35);
    expect(ageOn(birth, DateTime(2026, 5, 12)), 36);
  });

  test('résumé des coordonnées d’un membre', () {
    expect(describeContact(null), isNull);
    expect(describeContact(const PrivateDetails()), isNull);
    expect(
      describeContact(
        PrivateDetails(phone: '0611223344', birthDate: DateTime(1990, 5, 12)),
        today: DateTime(2026, 11, 19),
      ),
      '0611223344 · 12/05/1990 (36 ans)',
    );
  });

  test('lit la réponse du serveur', () {
    final details = PrivateDetails.fromJson(
      {'phone': ' 0611 ', 'birth_date': '1990-05-12'},
    );
    expect(details.phone, '0611');
    expect(details.birthDate, DateTime(1990, 5, 12));
    expect(isoDay(DateTime(2001, 3, 4)), '2001-03-04');
  });
}
