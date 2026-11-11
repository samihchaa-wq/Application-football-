import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
