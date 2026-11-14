import 'package:as_grinta/core/storage/player_photo_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le mode survit aux chemins de saison et aux URLs signées', () {
    for (final prefix in [
      'profile/',
      'season/player/',
      'https://example.test/storage/v1/object/sign/profile-photos/profile/'
    ]) {
      for (final mode in PlayerPhotoMode.values) {
        final path = '$prefix${mode.filename(123, 'png')}';
        expect(PlayerPhotoMode.fromPhotoUrl(path), mode);
        expect(PlayerPhotoMode.fromPhotoUrl('$path?token=abc'), mode);
      }
    }
  });
  test('les portraits existants gardent le mode joueur', () {
    for (final path in [
      null,
      '',
      'profile/avatar_123.png',
      'https://example.test/old.png'
    ]) {
      expect(PlayerPhotoMode.fromPhotoUrl(path), PlayerPhotoMode.player);
    }
    // Un mot dans le dossier ou le jeton ne doit pas changer le mode.
    expect(
        PlayerPhotoMode.fromPhotoUrl(
            'avatar_other_123.png/avatar_1.png?mode=other'),
        PlayerPhotoMode.player);
  });
}
