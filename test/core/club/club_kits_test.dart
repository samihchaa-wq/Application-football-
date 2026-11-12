import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/features/matches/domain/jersey_option.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(ClubKits.reset);

  List<Map<String, Object>> savedJson({bool thirdEnabled = false}) => [
        {
          'slot': 'blue',
          'label': 'Troisième',
          'body': '#111111',
          'trim': '#AA0000',
          'enabled': thirdEnabled,
        },
        {
          'slot': 'france',
          'label': 'Rouge',
          'body': '#AA0000',
          'trim': '#FFFFFF',
          'enabled': true,
        },
        {
          'slot': 'orange',
          'label': 'Blanc',
          'body': '#FFFFFF',
          'trim': '#AA0000',
          'enabled': true,
        },
      ];

  test('sans réglage, les maillots par défaut suivent les couleurs du club',
      () {
    ClubKits.setClubColors(
      primary: const Color(0xFFAA0000),
      secondary: const Color(0xFF00AA00),
    );
    expect(ClubKits.usesDefaults, isTrue);
    expect(ClubKits.all.map((kit) => kit.slot), JerseyOption.values);
    expect(ClubKits.of(JerseyOption.france).body, const Color(0xFFAA0000));
    expect(ClubKits.of(JerseyOption.france).trim, const Color(0xFF00AA00));
    expect(JerseyOption.france.label, 'Domicile');
    expect(ClubKits.enabled, hasLength(3));
  });

  test('les maillots enregistrés remplacent les maillots par défaut', () {
    ClubKits.setFromJson(savedJson());
    expect(ClubKits.usesDefaults, isFalse);
    // Rangés dans l'ordre des emplacements, quel que soit l'ordre reçu.
    expect(ClubKits.all.map((kit) => kit.slot), JerseyOption.values);
    expect(JerseyOption.france.label, 'Rouge');
    expect(JerseyOption.orange.kit.body, const Color(0xFFFFFFFF));
    expect(ClubKits.enabled.map((kit) => kit.slot),
        [JerseyOption.france, JerseyOption.orange]);
  });

  test('un match entre nous garde au moins deux maillots au choix', () {
    final json = savedJson();
    json[2]['enabled'] = false;
    ClubKits.setFromJson(json);
    expect(ClubKits.enabled, hasLength(1));
    expect(ClubKits.forInternalMatch, hasLength(3));
  });

  test('une valeur illisible ramène aux maillots par défaut', () {
    expect(ClubKits.parse(null), isNull);
    expect(ClubKits.parse('x'), isNull);
    expect(ClubKits.parse(savedJson().sublist(0, 2)), isNull);
    final badColor = savedJson();
    badColor[0]['body'] = 'rouge';
    expect(ClubKits.parse(badColor), isNull);
    final duplicate = savedJson();
    duplicate[0]['slot'] = 'france';
    expect(ClubKits.parse(duplicate), isNull);
  });

  test('changement de compte : aucun maillot de l’ancien club ne persiste',
      () {
    ClubKits.setClubColors(primary: const Color(0xFFAA0000));
    ClubKits.setFromJson(savedJson());
    expect(ClubKits.of(JerseyOption.france).label, 'Rouge');
    expect(ClubKits.of(JerseyOption.france).body, const Color(0xFFAA0000));

    // La couche de synchronisation appelle reset dès que l'identité change,
    // avant de charger le club suivant. Même en cas d'échec réseau, les
    // maillots mémorisés du club A ne doivent pas apparaître sur B.
    ClubKits.reset();
    expect(ClubKits.usesDefaults, isTrue);
    expect(ClubKits.of(JerseyOption.france).label, 'Domicile');

    ClubKits.setClubColors(primary: const Color(0xFF0055CC));
    expect(ClubKits.of(JerseyOption.france).body, const Color(0xFF0055CC));
    expect(ClubKits.of(JerseyOption.france).label, 'Domicile');
  });

  test('toJson produit ce que le serveur attend', () {
    final kit = ClubKits.parse(savedJson())!.first;
    expect(kit.toJson(), {
      'slot': 'france',
      'label': 'Rouge',
      'body': '#AA0000',
      'trim': '#FFFFFF',
      'enabled': true,
    });
  });
}
