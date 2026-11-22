import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/features/auth/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Retour dans l'appli : un jeton expiré ou un réseau lent au réveil ne doit
/// pas faire échouer le chargement du profil (écran « Connexion
/// temporairement indisponible »).
void main() {
  late HttpServer server;
  var profileCalls = 0;
  var refreshCalls = 0;
  late int Function(int call) profileStatus;

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await request.drain<void>();
      final path = request.uri.path;
      Object body = <String, Object?>{};
      var status = 200;
      if (path == '/rest/v1/rpc/get_my_profile') {
        profileCalls += 1;
        status = profileStatus(profileCalls);
        body = status == 200
            ? {
                'id': 'user-1',
                'first_name': 'Karim',
                'last_name': 'Test',
                'role': 'pronostiqueur',
                'is_goalkeeper': false,
                'is_active': true,
              }
            : {'code': 'PGRST301', 'message': 'JWT expired'};
      } else if (path == '/auth/v1/token') {
        refreshCalls += 1;
        body = _session();
      }
      request.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(body));
      await request.response.close();
    });
    await supabase.Supabase.initialize(
      url: 'http://127.0.0.1:${server.port}',
      publishableKey: 'test-key',
      authOptions: const supabase.FlutterAuthClientOptions(
        localStorage: supabase.EmptyLocalStorage(),
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
    );
    await supabase.Supabase.instance.client.auth
        .recoverSession(jsonEncode(_session()));
  });

  tearDownAll(() => server.close(force: true));

  setUp(() {
    profileCalls = 0;
    refreshCalls = 0;
  });

  test('jeton expiré : la session est renouvelée puis le profil chargé',
      () async {
    profileStatus = (call) => call == 1 ? 401 : 200;
    final repository = AuthRepository(supabase.Supabase.instance.client);

    final profile = await repository.fetchProfile();

    expect(profile?.firstName, 'Karim');
    expect(refreshCalls, 1);
    expect(profileCalls, 2);
  });

  test('réseau lent au réveil : nouvelle tentative sans erreur', () async {
    profileStatus = (call) => call == 1 ? 503 : 200;
    final repository = AuthRepository(supabase.Supabase.instance.client);

    final profile = await repository.fetchProfile();

    expect(profile?.firstName, 'Karim');
    expect(profileCalls, 2);
  });
}

Map<String, Object?> _session() {
  final expiresAt =
      DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch ~/
          1000;
  String enc(Object o) => base64Url.encode(utf8.encode(jsonEncode(o)));
  final token = [
    enc({'alg': 'HS256', 'typ': 'JWT'}),
    enc({
      'sub': 'user-1',
      'exp': expiresAt,
      'role': 'authenticated',
      'aud': 'authenticated',
    }),
    'signature',
  ].join('.');
  return {
    'access_token': token,
    'token_type': 'bearer',
    'expires_in': 86400,
    'expires_at': expiresAt,
    'refresh_token': 'refresh-user-1',
    'user': {
      'id': 'user-1',
      'aud': 'authenticated',
      'role': 'authenticated',
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'created_at': '2026-01-01T00:00:00Z',
    },
  };
}
