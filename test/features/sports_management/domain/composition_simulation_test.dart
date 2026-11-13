import 'position_profiles_fixture.dart';
import 'package:as_grinta/features/sports_management/domain/composition_simulation.dart';
import 'package:as_grinta/features/sports_management/domain/football_formation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Identités fictives de l'effectif d'essai, telles que le fichier de postes
/// anonymisé les connaît.
const String gardienTitulaire = '00000000-0000-4000-8000-000000000033';
const String joueurB = '00000000-0000-4000-8000-000000000034';
const String joueurC = '00000000-0000-4000-8000-000000000037';
const String joueurD = '00000000-0000-4000-8000-000000000019';
const String joueurE = '00000000-0000-4000-8000-000000000029';
const String joueurF = '00000000-0000-4000-8000-000000000004';
const String joueurG = '00000000-0000-4000-8000-000000000020';
const String joueurH = '00000000-0000-4000-8000-000000000031';
const String joueurI = '00000000-0000-4000-8000-000000000013';
const String joueurJ = '00000000-0000-4000-8000-000000000022';
const String joueurK = '00000000-0000-4000-8000-000000000003';
const String joueurL = '00000000-0000-4000-8000-000000000028';
const String joueurM = '00000000-0000-4000-8000-000000000026';
const String joueurN = '00000000-0000-4000-8000-000000000018';
const String joueurO = '00000000-0000-4000-8000-000000000036';
const String joueurP = '00000000-0000-4000-8000-000000000002';
const String joueurQ = '00000000-0000-4000-8000-000000000005';
const String joueurR = '00000000-0000-4000-8000-000000000015';

SimulationCandidate candidate(
  String name, {
  String? playerId,
  int benchCount = 0,
  bool isGuest = false,
  bool isGoalkeeper = false,
  bool benchedLastTime = false,
}) {
  return SimulationCandidate(
    participantId: name,
    displayName: name,
    benchCount: benchCount,
    profile: playerId == null ? null : kTestPositionProfiles[playerId],
    isGuest: isGuest,
    isGoalkeeper: isGoalkeeper,
    benchedLastTime: benchedLastTime,
  );
}

/// Le poste occupé par un joueur, ou null s'il n'est pas sur le terrain.
String? slotOf(SimulatedComposition simulation, String name) {
  for (final placement in simulation.placements) {
    if (placement.candidate.participantId == name) return placement.slot.label;
  }
  return null;
}

SimulatedPlacementReason? reasonOf(
  SimulatedComposition simulation,
  String name,
) {
  for (final placement in simulation.placements) {
    if (placement.candidate.participantId == name) return placement.reason;
  }
  return null;
}

List<String> benchOf(SimulatedComposition simulation) =>
    simulation.bench.map((entry) => entry.displayName).toList();

void main() {
  final formation = formationForCode('4-2-1-3');

  group('Fichier des postes de référence', () {
    test('chaque poste cité existe sur la feuille de match', () {
      for (final profile in kTestPositionProfiles.values) {
        for (final share in profile.samples) {
          expect(
            matchSheetSlotPositions.containsKey(share.slotLabel),
            isTrue,
            reason: '${profile.displayName} : poste inconnu '
                '${share.slotLabel}',
          );
        }
      }
    });

    test('les postes sont triés du plus fréquent au moins fréquent', () {
      for (final profile in kTestPositionProfiles.values) {
        expect(profile.samples, isNotEmpty);
        for (var index = 1; index < profile.samples.length; index += 1) {
          expect(
            profile.samples[index - 1].weight,
            greaterThanOrEqualTo(profile.samples[index].weight),
            reason: profile.displayName,
          );
        }
      }
    });

    test('les couteaux suisses sont ceux sans poste dominant', () {
      expect(kTestPositionProfiles[joueurN]!.isVersatile, isTrue);
      expect(kTestPositionProfiles[joueurO]!.isVersatile, isTrue);
      expect(kTestPositionProfiles[joueurM]!.isVersatile, isFalse);
      expect(kTestPositionProfiles[gardienTitulaire]!.mainSlotLabel, 'GB');
    });
  });

  group('Placement au poste de référence', () {
    test('un effectif type se range à ses postes habituels', () {
      final simulation = simulateComposition(
        slots: formation.slots,
        candidates: [
          candidate('Sacha', playerId: gardienTitulaire, isGoalkeeper: true),
          candidate('Anouar', playerId: joueurF),
          candidate('Jérôme', playerId: joueurD),
          candidate('Octave', playerId: joueurE),
          candidate('Jules', playerId: joueurG),
          candidate('Rémi', playerId: joueurH),
          candidate('Fab', playerId: joueurI),
          candidate('Lino', playerId: joueurJ),
          candidate('Noé', playerId: joueurL),
          candidate('Marius', playerId: joueurM),
          candidate('Arno', playerId: joueurK),
        ],
      );

      expect(simulation.emptySlots, isEmpty);
      expect(slotOf(simulation, 'Sacha'), 'GB');
      expect(slotOf(simulation, 'Anouar'), 'DG');
      expect(slotOf(simulation, 'Jules'), 'DD');
      expect(slotOf(simulation, 'Marius'), 'BU');
      expect(slotOf(simulation, 'Arno'), 'AD');
      expect(slotOf(simulation, 'Noé'), 'AG');
      // Joueur C absent : les deux axiaux sont Jérôme et Octave.
      expect(slotOf(simulation, 'Jérôme'), 'DCG');
      expect(slotOf(simulation, 'Octave'), 'DCD');
      // Les trois milieux se partagent les trois postes du milieu.
      expect(
        {
          slotOf(simulation, 'Rémi'),
          slotOf(simulation, 'Fab'),
          slotOf(simulation, 'Lino'),
        },
        {'MDG', 'MDD', 'MOC'},
      );
      expect(simulation.stretchedPlacements, isEmpty);
    });

    test('deux axiaux pour la même charnière se la partagent', () {
      final simulation = simulateComposition(
        slots: formation.slots,
        candidates: [
          candidate('Sébastien', playerId: joueurC),
          candidate('Octave', playerId: joueurE),
        ],
      );

      expect(
        {slotOf(simulation, 'Sébastien'), slotOf(simulation, 'Octave')},
        {'DCG', 'DCD'},
      );
      // Chacun à un poste qu'il a réellement tenu.
      expect(
        reasonOf(simulation, 'Sébastien'),
        isNot(SimulatedPlacementReason.nearbyPosition),
      );
      expect(
        reasonOf(simulation, 'Octave'),
        isNot(SimulatedPlacementReason.nearbyPosition),
      );
    });

    test('un défenseur en surnombre ne prend pas la place d’un milieu', () {
      // Le défaut de l'ancienne simulation, sur chaque match de la saison :
      // le troisième axial filait en sentinelle pendant qu'un vrai milieu
      // restait sur le banc.
      final simulation = simulateComposition(
        slots: formation.slots,
        candidates: [
          candidate('Sacha', playerId: gardienTitulaire, isGoalkeeper: true),
          candidate('Ilan', playerId: joueurQ),
          candidate('Jérôme', playerId: joueurD),
          candidate('Sébastien', playerId: joueurC),
          candidate('Octave', playerId: joueurE),
          candidate('Sylvain', playerId: joueurB),
          candidate('Fab', playerId: joueurI),
          candidate('Rémi', playerId: joueurH),
          candidate('Lino', playerId: joueurJ),
          candidate('Abel', playerId: joueurP),
          candidate('Fabrice', playerId: joueurR),
          candidate('Marius', playerId: joueurM),
          candidate('Arno', playerId: joueurK),
        ],
      );

      for (final defender in ['Jérôme', 'Sébastien', 'Octave']) {
        expect(
          ['MDG', 'MDD', 'MOC'],
          isNot(contains(slotOf(simulation, defender))),
          reason: '$defender ne joue pas au milieu',
        );
      }
      expect(slotOf(simulation, 'Abel'), 'MOC');
      expect(slotOf(simulation, 'Marius'), 'BU');
      expect(simulation.stretchedPlacements, isEmpty);
    });

    test('un couteau suisse comble un poste laissé libre', () {
      final simulation = simulateComposition(
        slots: formationForCode('4-4-2 à plat').slots,
        candidates: [
          candidate('Sébastien', playerId: joueurC),
          candidate('Jérôme', playerId: joueurD),
          candidate('Hugo', playerId: joueurN),
        ],
      );

      expect(slotOf(simulation, 'Sébastien'), 'DCD');
      expect(slotOf(simulation, 'Jérôme'), 'DCG');
      expect(slotOf(simulation, 'Hugo'), isNotNull);
      expect(simulation.stretchedPlacements, isEmpty);
    });

    test('un poste sans candidat naturel revient au joueur le plus proche', () {
      // Aucun buteur convoqué : le dispositif garde ses trois postes
      // offensifs, comblés par glissement plutôt que laissés vides.
      final simulation = simulateComposition(
        slots: formation.slots,
        candidates: [
          candidate('Noé', playerId: joueurL),
          candidate('Arno', playerId: joueurK),
          candidate('Lino', playerId: joueurJ),
        ],
      );

      expect(slotOf(simulation, 'Noé'), 'AG');
      expect(slotOf(simulation, 'Arno'), 'AD');
      expect(slotOf(simulation, 'Lino'), isNotNull);
      expect(simulation.bench, isEmpty);
    });

    test('personne n’est envoyé hors de ses habitudes sans nécessité', () {
      // Un buteur remplaçant la dernière fois n'a pas sa place dans une
      // charnière déjà tenue par deux axiaux : il reste sur le banc.
      final simulation = simulateComposition(
        slots: <FootballFormationSlot>[
          const FootballFormationSlot(label: 'DCG', position: Offset(.32, .70)),
          const FootballFormationSlot(label: 'DCD', position: Offset(.68, .70)),
        ],
        candidates: [
          candidate('Jérôme', playerId: joueurD),
          candidate('Sébastien', playerId: joueurC),
          candidate('Marius', playerId: joueurM, benchedLastTime: true),
        ],
      );

      expect(slotOf(simulation, 'Marius'), isNull);
      expect(simulation.keptOnBench.map((entry) => entry.displayName), [
        'Marius',
      ]);
    });

    test('hors de ses habitudes, mais seulement pour ne pas laisser de trou',
        () {
      final simulation = simulateComposition(
        slots: <FootballFormationSlot>[
          const FootballFormationSlot(label: 'BU', position: Offset(.50, .08)),
        ],
        candidates: [candidate('Jérôme', playerId: joueurD)],
      );

      expect(slotOf(simulation, 'Jérôme'), 'BU');
      expect(
        reasonOf(simulation, 'Jérôme'),
        SimulatedPlacementReason.outOfPosition,
      );
      expect(simulation.stretchedPlacements, hasLength(1));
    });
  });

  group('Rotation', () {
    test('les remplaçants de leur dernier match commencent celui-ci', () {
      // Convocation réelle du 27 octobre 2026 : Hakim et Luka étaient
      // remplaçants le 12 octobre, Simon le 21 septembre, la dernière fois
      // qu'il a joué.
      final simulation = simulateComposition(
        slots: formation.slots,
        candidates: [
          candidate('Sacha', playerId: gardienTitulaire, isGoalkeeper: true),
          candidate('Abel', playerId: joueurP),
          candidate('Arno', playerId: joueurK),
          candidate('Ilan', playerId: joueurQ, benchCount: 1),
          candidate('Fab', playerId: joueurI),
          candidate(
            'Hugo',
            playerId: joueurN,
            benchCount: 2,
            benchedLastTime: true,
          ),
          candidate('Jérôme', playerId: joueurD, benchCount: 1),
          candidate(
            'Lino',
            playerId: joueurJ,
            benchCount: 1,
            benchedLastTime: true,
          ),
          candidate('Marius', playerId: joueurM),
          candidate('Noé', playerId: joueurL, benchCount: 1),
          candidate('Octave', playerId: joueurE, benchCount: 1),
          candidate('Rémi', playerId: joueurH, benchCount: 1),
          candidate(
            'Sami',
            playerId: joueurO,
            benchCount: 1,
            benchedLastTime: true,
          ),
          candidate('Sébastien', playerId: joueurC, benchCount: 1),
        ],
      );

      expect(slotOf(simulation, 'Hugo'), isNotNull);
      expect(slotOf(simulation, 'Lino'), isNotNull);
      expect(
        simulation.promotedFromBench.map((p) => p.candidate.displayName),
        unorderedEquals(['Hugo', 'Lino', 'Sami']),
      );
      expect(simulation.keptOnBench, isEmpty);
      // Les titulaires qui n'ont pas de concurrent à leur poste restent.
      expect(slotOf(simulation, 'Marius'), 'BU');
      expect(slotOf(simulation, 'Arno'), 'AD');
      expect(slotOf(simulation, 'Sacha'), 'GB');
      expect(simulation.stretchedPlacements, isEmpty);
      expect(simulation.bench, hasLength(3));
    });

    test('à poste égal, le plus souvent remplaçant est titularisé', () {
      final simulation = simulateComposition(
        slots: <FootballFormationSlot>[
          const FootballFormationSlot(label: 'DG', position: Offset(.10, .65)),
        ],
        candidates: [
          candidate('Anouar', playerId: joueurF, benchCount: 1),
          candidate('Anouar bis', playerId: joueurF, benchCount: 7),
        ],
      );

      expect(slotOf(simulation, 'Anouar bis'), 'DG');
      expect(benchOf(simulation), ['Anouar']);
    });

    test('le banc est ordonné du plus attendu au moins attendu', () {
      final simulation = simulateComposition(
        slots: <FootballFormationSlot>[
          const FootballFormationSlot(label: 'BU', position: Offset(.50, .08)),
        ],
        candidates: [
          candidate('Peu', playerId: joueurL, benchCount: 1),
          candidate('Beaucoup', playerId: joueurJ, benchCount: 9),
          candidate('Moyen', playerId: joueurK, benchCount: 4),
          candidate(
            'Remplaçant la dernière fois',
            playerId: joueurD,
            benchedLastTime: true,
          ),
          candidate('Titulaire', playerId: joueurM, benchCount: 12),
        ],
      );

      expect(slotOf(simulation, 'Titulaire'), 'BU');
      // Le remplaçant de son dernier match passe en tête, puis le compteur
      // banc.
      expect(
        benchOf(simulation),
        ['Remplaçant la dernière fois', 'Beaucoup', 'Moyen', 'Peu'],
      );
    });

    test('une même convocation redonne toujours la même équipe', () {
      List<SimulationCandidate> squad() => [
            candidate('Sacha', playerId: gardienTitulaire, isGoalkeeper: true),
            candidate('Axel', benchCount: 2),
            candidate('Hugo', playerId: joueurN, benchCount: 2),
            candidate('Sami', playerId: joueurO, benchCount: 2),
            candidate('Fab', playerId: joueurI, benchCount: 2),
          ];
      String lineup(SimulatedComposition simulation) => simulation.placements
          .map((p) => '${p.slot.label}:${p.candidate.displayName}')
          .join(' ');

      final first = simulateComposition(
        slots: formation.slots,
        candidates: squad(),
      );
      final second = simulateComposition(
        slots: formation.slots,
        candidates: squad().reversed.toList(),
      );

      expect(lineup(second), lineup(first));
      expect(benchOf(second), benchOf(first));
    });
  });

  group('Gardien', () {
    test('le gardien déclaré prend les buts', () {
      final simulation = simulateComposition(
        slots: formation.slots,
        candidates: [
          candidate('Sacha', playerId: gardienTitulaire, isGoalkeeper: true),
          candidate('Sébastien', playerId: joueurC, benchCount: 9),
        ],
      );

      expect(slotOf(simulation, 'Sacha'), 'GB');
      expect(
        reasonOf(simulation, 'Sacha'),
        SimulatedPlacementReason.goalkeeper,
      );
    });

    test('sans gardien convoqué, les buts restent vides', () {
      final simulation = simulateComposition(
        slots: formation.slots,
        candidates: [
          // Guerin a déjà gardé les buts, mais il n'est pas gardien déclaré.
          candidate('Sylvain', playerId: joueurB, benchCount: 9),
          candidate('Sébastien', playerId: joueurC, benchCount: 9),
        ],
      );

      expect(simulation.emptySlots.map((slot) => slot.label), contains('GB'));
      expect(slotOf(simulation, 'Sylvain'), isNot('GB'));
      expect(slotOf(simulation, 'Sébastien'), isNot('GB'));
    });

    test('le second gardien va sur le banc, jamais en défense', () {
      final simulation = simulateComposition(
        slots: formation.slots,
        candidates: [
          candidate('Habituel', playerId: gardienTitulaire, isGoalkeeper: true),
          candidate(
            'Doublure',
            playerId: gardienTitulaire,
            isGoalkeeper: true,
            benchCount: 8,
          ),
        ],
      );

      // La rotation vaut aussi pour les gants : celui qui a le plus attendu
      // prend les buts.
      expect(slotOf(simulation, 'Doublure'), 'GB');
      // L'autre reste gardien : il ne dépanne pas à un poste de champ.
      expect(slotOf(simulation, 'Habituel'), isNull);
      expect(benchOf(simulation), contains('Habituel'));
    });

    test('le gardien remplaçant la dernière fois prend les buts', () {
      final simulation = simulateComposition(
        slots: formation.slots,
        candidates: [
          candidate(
            'Habituel',
            playerId: gardienTitulaire,
            isGoalkeeper: true,
            benchCount: 8,
          ),
          candidate(
            'Doublure',
            playerId: gardienTitulaire,
            isGoalkeeper: true,
            benchedLastTime: true,
          ),
        ],
      );

      expect(slotOf(simulation, 'Doublure'), 'GB');
      expect(benchOf(simulation), ['Habituel']);
    });
  });

  group('Invités et joueurs sans profil', () {
    test('un invité complète un terrain incomplet', () {
      final simulation = simulateComposition(
        slots: formation.slots,
        candidates: [
          candidate('Invité', isGuest: true),
          candidate('Marius', playerId: joueurM),
        ],
      );

      expect(slotOf(simulation, 'Marius'), 'BU');
      expect(slotOf(simulation, 'Invité'), isNotNull);
      expect(
        reasonOf(simulation, 'Invité'),
        SimulatedPlacementReason.unknownPosition,
      );
      expect(simulation.bench, isEmpty);
    });

    test('un invité ne prend jamais la place d’un joueur de l’effectif', () {
      final simulation = simulateComposition(
        slots: <FootballFormationSlot>[
          const FootballFormationSlot(label: 'BU', position: Offset(.50, .08)),
        ],
        candidates: [
          candidate(
            'Invité',
            isGuest: true,
            benchCount: 12,
            benchedLastTime: true,
          ),
          // Même un défenseur hors de ses habitudes passe avant l'invité.
          candidate('Jérôme', playerId: joueurD),
        ],
      );

      expect(slotOf(simulation, 'Jérôme'), 'BU');
      expect(benchOf(simulation), ['Invité']);
      expect(simulation.keptOnBench, isEmpty);
    });

    test('un joueur sans profil ne sert qu’à combler un poste vide', () {
      final simulation = simulateComposition(
        slots: <FootballFormationSlot>[
          const FootballFormationSlot(label: 'BU', position: Offset(.50, .08)),
          const FootballFormationSlot(label: 'DC', position: Offset(.50, .72)),
        ],
        candidates: [
          candidate('Recrue', benchCount: 12),
          candidate('Marius', playerId: joueurM, benchCount: 0),
        ],
      );

      // Malgré son compteur banc, la recrue ne prend pas la pointe à Marius :
      // elle hérite du poste que personne ne revendique, à confirmer.
      expect(slotOf(simulation, 'Marius'), 'BU');
      expect(slotOf(simulation, 'Recrue'), 'DC');
      expect(
        reasonOf(simulation, 'Recrue'),
        SimulatedPlacementReason.unknownPosition,
      );
      expect(simulation.unknownPlacements, hasLength(1));
    });

    test('une recrue remplaçante la dernière fois a sa chance', () {
      final simulation = simulateComposition(
        slots: formation.slots,
        candidates: [
          candidate('Sacha', playerId: gardienTitulaire, isGoalkeeper: true),
          candidate('Anouar', playerId: joueurF),
          candidate('Jérôme', playerId: joueurD),
          candidate('Octave', playerId: joueurE),
          candidate('Jules', playerId: joueurG),
          candidate('Rémi', playerId: joueurH),
          candidate('Fab', playerId: joueurI),
          candidate('Lino', playerId: joueurJ),
          candidate('Noé', playerId: joueurL),
          candidate('Marius', playerId: joueurM),
          candidate('Arno', playerId: joueurK),
          candidate('Recrue', benchedLastTime: true),
        ],
      );

      expect(
        reasonOf(simulation, 'Recrue'),
        SimulatedPlacementReason.unknownPosition,
      );
      // Elle prend la place qui dérange le moins l'équipe, pas celle d'un
      // titulaire sans concurrent.
      expect(slotOf(simulation, 'Marius'), 'BU');
      expect(slotOf(simulation, 'Sacha'), 'GB');
      expect(simulation.bench, hasLength(1));
    });

    test('aucun convoqué ne donne ni titulaire ni remplaçant', () {
      final simulation = simulateComposition(
        slots: formation.slots,
        candidates: const [],
      );

      expect(simulation.placements, isEmpty);
      expect(simulation.bench, isEmpty);
      expect(simulation.emptySlots, hasLength(formation.slotLabels.length));
    });
  });

  test('vingt convoqués se répartissent sans attente perceptible', () {
    final profiles = kTestPositionProfiles.entries.take(20).toList();
    final stopwatch = Stopwatch()..start();
    final simulation = simulateComposition(
      slots: formation.slots,
      candidates: [
        for (var index = 0; index < profiles.length; index += 1)
          candidate(
            'Joueur $index',
            playerId: profiles[index].key,
            benchCount: index % 3,
            benchedLastTime: index.isEven,
          ),
      ],
    );
    stopwatch.stop();

    expect(simulation.placements.length + simulation.bench.length, 20);
    expect(stopwatch.elapsedMilliseconds, lessThan(1000));
  });
}
