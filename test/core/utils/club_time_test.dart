import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/core/utils/app_formats.dart';
import 'package:petit_filet/core/utils/club_time.dart';
import 'package:petit_filet/features/matches/domain/convocation_launch.dart';
import 'package:petit_filet/features/matches/domain/match_model.dart';

/// Le match de l'audit : lundi 30/11/2026 à 20:45, heure de Paris.
final _kickoffUtc = DateTime.utc(2026, 11, 30, 19, 45);

/// Décalage fixe d'un téléphone simulé.
Duration Function(DateTime) _device(Duration offset) => (_) => offset;

void main() {
  final realDeviceOffset = ClubTime.deviceOffset;

  tearDown(() {
    ClubTime.reset();
    ClubTime.deviceOffset = realDeviceOffset;
  });

  group('affichage à l\'heure du club', () {
    test('un club parisien voit lundi 30/11 20:45, quel que soit le téléphone',
        () {
      ClubTime.use('Europe/Paris');
      // Le résultat ne dépend pas du fuseau du téléphone : on simule New York
      // puis Tokyo pour la mention, l'heure affichée reste la même.
      for (final phone in [
        const Duration(hours: -5), // New York
        const Duration(hours: 9), // Tokyo
        Duration.zero, // UTC
      ]) {
        ClubTime.deviceOffset = _device(phone);
        final club = _kickoffUtc.toClub();
        expect(club.weekday, DateTime.monday);
        expect(AppFormats.date(_kickoffUtc), '30/11/26');
        expect(AppFormats.hourMinute(_kickoffUtc), '20:45');
        expect(AppFormats.time(_kickoffUtc), '20h45');
        expect(AppFormats.weekdayLong(_kickoffUtc), 'Lundi');
      }
    });

    test('le même instant suit le fuseau du club, pas celui du téléphone', () {
      ClubTime.use('America/New_York');
      expect(AppFormats.hourMinute(_kickoffUtc), '14:45');
      expect(AppFormats.weekdayLong(_kickoffUtc), 'Lundi');

      ClubTime.use('Asia/Tokyo');
      expect(AppFormats.hourMinute(_kickoffUtc), '04:45');
      expect(AppFormats.weekdayLong(_kickoffUtc), 'Mardi');
      expect(AppFormats.date(_kickoffUtc), '01/12/26');
    });

    test('une date lue du serveur (texte ISO) passe à l\'heure du club', () {
      ClubTime.use('Europe/Paris');
      final match = MatchModel.fromJson({
        'id': 'm1',
        'season_id': 's1',
        'opponent_id': 'o1',
        'kickoff_at': '2026-11-30T19:45:00+00:00',
        'location': 'domicile',
        'status': 'scheduled',
      });
      expect(match.kickoffAt.hour, 20);
      expect(match.kickoffAt.minute, 45);
      expect(match.kickoffAt.isAtSameMomentAs(_kickoffUtc), isTrue);
    });

    test('heure d\'été : 20:45 à Paris en juin = 18:45 UTC', () {
      ClubTime.use('Europe/Paris');
      expect(AppFormats.hourMinute(DateTime.utc(2026, 6, 15, 18, 45)), '20:45');
    });

    test('un fuseau vide ou inconnu retombe sur Paris', () {
      ClubTime.use('Mars/Olympus');
      expect(ClubTime.timezoneName, 'Europe/Paris');
      ClubTime.use('  ');
      expect(ClubTime.timezoneName, 'Europe/Paris');
      ClubTime.use(null);
      expect(ClubTime.timezoneName, 'Europe/Paris');
    });
  });

  group('saisie à l\'heure du club', () {
    test('20:45 saisi devient 19:45 UTC en hiver, 18:45 UTC en été', () {
      ClubTime.use('Europe/Paris');
      expect(
        ClubTime.wallClock(2026, 11, 30, 20, 45).toUtc(),
        DateTime.utc(2026, 11, 30, 19, 45),
      );
      expect(
        ClubTime.fromWallClock(DateTime(2026, 6, 15, 20, 45)).toUtc(),
        DateTime.utc(2026, 6, 15, 18, 45),
      );
    });

    test('la saisie ne dépend pas du fuseau du téléphone', () {
      ClubTime.use('Europe/Paris');
      // Une date « au mur » simple : seuls ses champs comptent.
      final wall = DateTime(2026, 11, 30, 20, 45);
      expect(ClubTime.fromWallClock(wall).toUtc(), _kickoffUtc);
      // Une valeur déjà à l'heure du club reste inchangée.
      final club = _kickoffUtc.toClub();
      expect(ClubTime.fromWallClock(club).isAtSameMomentAs(club), isTrue);
    });

    test('ouverture J-6 à 12 h du club, même avec un changement d\'heure', () {
      ClubTime.use('Europe/Paris');
      // Match le dimanche 1er novembre 2026 ; passage à l'heure d'hiver le
      // dimanche 25 octobre, entre l'ouverture et le match.
      final kickoff = ClubTime.wallClock(2026, 11, 1, 15);
      final opens = defaultConvocationLaunchAt(kickoff).toClub();
      expect(opens.day, 26);
      expect(opens.month, 10);
      expect(opens.hour, 12);
      expect(opens.minute, 0);
    });
  });

  group('mention du fuseau', () {
    test('rien si le téléphone est à l\'heure du club', () {
      ClubTime.use('Europe/Paris');
      ClubTime.deviceOffset = (instant) => instant.toClub().timeZoneOffset;
      expect(ClubTime.suffix, '');
      expect(
        AppFormats.calendarDateTimeLong(_kickoffUtc),
        'Lun. 30 nov. 2026 • 20:45',
      );
    });

    test('« heure de Paris » si le téléphone est à New York ou Tokyo', () {
      ClubTime.use('Europe/Paris');
      for (final phone in [
        const Duration(hours: -5),
        const Duration(hours: 9),
      ]) {
        ClubTime.deviceOffset = _device(phone);
        expect(ClubTime.suffix, ' (heure de Paris)');
        expect(
          AppFormats.calendarDateTimeLong(_kickoffUtc),
          'Lun. 30 nov. 2026 • 20:45 (heure de Paris)',
        );
      }
    });

    test('pas de mention quand l\'heure n\'est pas affichée', () {
      ClubTime.use('Europe/Paris');
      ClubTime.deviceOffset = _device(const Duration(hours: 9));
      expect(
        AppFormats.calendarDateTimeLong(_kickoffUtc, includeTime: false),
        'Lun. 30 nov. 2026',
      );
    });

    test('nom de ville avec espace', () {
      ClubTime.use('America/New_York');
      expect(ClubTime.label, 'heure de New York');
    });
  });
}
