import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fonctionnalités reçues du serveur', () {
    test('une réponse absente, partielle ou mal typée est refusée', () {
      for (final value in <Object?>[
        null,
        [],
        {},
        {'badges': true},
        {for (final module in ClubModule.values) module.key: 'true'},
      ]) {
        expect(() => ClubModules.fromJson(value), throwsFormatException);
      }
    });

    test('les sept réglages sont lus sans réactiver ceux coupés', () {
      final values = {
        for (final module in ClubModule.values)
          module.key: module != ClubModule.predictions,
      };
      final modules = ClubModules.fromJson(values);
      expect(modules.isEnabled(ClubModule.predictions), isFalse);
      expect(modules.isEnabled(ClubModule.badges), isTrue);
    });

    test('l’état de remplacement ne rend aucune option disponible', () {
      const modules = ClubModules.allDisabled();
      for (final module in ClubModule.values) {
        expect(modules.isEnabled(module), isFalse);
      }
    });
  });
  group('code d’invitation', () {
    test('les espaces, tirets et minuscules sont tolérés à la saisie', () {
      expect(normalizeInviteCode(' abcd-efgh '), 'ABCDEFGH');
      expect(normalizeInviteCode('ab cd ef gh'), 'ABCDEFGH');
    });

    test('seuls 8 caractères sans 0, 1, I ni O sont acceptés', () {
      expect(inviteCodePattern.hasMatch('ABCDEFGH'), isTrue);
      expect(inviteCodePattern.hasMatch('AB23CD45'), isTrue);
      expect(inviteCodePattern.hasMatch('ABCDEFG'), isFalse);
      expect(inviteCodePattern.hasMatch('ABCDEFG0'), isFalse);
      expect(inviteCodePattern.hasMatch('ABCDEFG1'), isFalse);
    });
  });

  group('lien d’inscription', () {
    test('il ouvre la page d’inscription avec le code du club', () {
      expect(
        buildInviteLink('ABCDEFGH', publicAppUrl: 'https://exemple.test/app/'),
        'https://exemple.test/app/#/auth/register?code=ABCDEFGH',
      );
    });

    test('une adresse sans barre finale donne le même lien', () {
      expect(
        buildInviteLink('ABCDEFGH', publicAppUrl: 'https://exemple.test/app'),
        'https://exemple.test/app/#/auth/register?code=ABCDEFGH',
      );
    });
  });
}
