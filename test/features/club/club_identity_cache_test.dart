import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/core/club/club_identity.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/features/club/data/club_identity_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ClubIdentity.reset();
    AppTheme.resetClubColors();
    ClubIdentityCache.restoredUserId = null;
  });

  test('restaure nom et couleurs du compte avant le premier rendu', () async {
    await ClubIdentityCache.save(
      'u1',
      name: 'FC Test',
      shortName: 'FCT',
      primaryHex: '#1A4AC0',
      secondaryHex: '#FFD700',
    );
    expect(ClubIdentity.name, ClubIdentity.defaultName);
    await ClubIdentityCache.restore('u1');
    expect(ClubIdentity.name, 'FC Test');
    expect(AppTheme.primary, isNot(AppTheme.defaultPrimary));
    expect(ClubIdentityCache.restoredUserId, 'u1');
  });

  test('un autre compte ne lit jamais la copie', () async {
    await ClubIdentityCache.save('u1', name: 'FC Test', shortName: 'FCT');
    await ClubIdentityCache.restore('u2');
    expect(ClubIdentity.name, ClubIdentity.defaultName);
    expect(ClubIdentityCache.restoredUserId, isNull);
  });
}
