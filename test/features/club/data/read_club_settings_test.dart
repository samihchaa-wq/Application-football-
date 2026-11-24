import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const expired = PostgrestException(message: 'JWT expired', code: 'PGRST303');

  test('jeton expiré au lancement : session renouvelée puis relue', () async {
    var token = 'ancien';
    var calls = 0;
    var refreshes = 0;
    final value = await readClubSettings(
      () async {
        calls++;
        if (token == 'ancien') throw expired;
        return 'réglages';
      },
      currentAccessToken: () => token,
      refreshSession: () async {
        refreshes++;
        token = 'nouveau';
      },
    );
    expect(value, 'réglages');
    expect(calls, 2);
    expect(refreshes, 1);
  });

  test('jeton déjà renouvelé pendant la requête : pas de second renouvellement',
      () async {
    var token = 'ancien';
    var refreshes = 0;
    final value = await readClubSettings(
      () async {
        if (token == 'ancien') {
          token = 'nouveau';
          throw expired;
        }
        return 'réglages';
      },
      currentAccessToken: () => token,
      refreshSession: () async => refreshes++,
    );
    expect(value, 'réglages');
    expect(refreshes, 0);
  });

  test('réseau lent au réveil : un second essai', () async {
    var calls = 0;
    final value = await readClubSettings(
      () async {
        if (calls++ == 0) throw Exception('connexion coupée');
        return 'réglages';
      },
      currentAccessToken: () => 't',
      refreshSession: () async {},
      retryDelay: Duration.zero,
    );
    expect(value, 'réglages');
    expect(calls, 2);
  });

  test('refus réel (droits) : aucune nouvelle tentative', () async {
    var calls = 0;
    await expectLater(
      readClubSettings(
        () async {
          calls++;
          throw const PostgrestException(message: 'denied', code: '42501');
        },
        currentAccessToken: () => 't',
        refreshSession: () async {},
      ),
      throwsA(isA<PostgrestException>()),
    );
    expect(calls, 1);
  });

  test('renouvellement refusé : l’erreur d’origine remonte', () async {
    await expectLater(
      readClubSettings<String>(
        () async => throw expired,
        currentAccessToken: () => 't',
        refreshSession: () async => throw const AuthException('révoquée'),
      ),
      throwsA(isA<PostgrestException>()),
    );
  });
}
