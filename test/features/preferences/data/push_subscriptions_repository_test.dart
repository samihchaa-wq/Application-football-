import 'dart:convert';
import 'dart:io';

import 'package:petit_filet/features/preferences/data/push_subscriptions_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Couper les notifications retire l'abonnement côté serveur par une fonction
/// dédiée. L'ancien delete direct sur la table était refusé (le compte n'a pas
/// le droit de la lire) : le joueur voyait toujours une erreur, et son choix
/// n'était pas retenu.
void main() {
  late HttpServer server;
  late List<({String method, String path, String body})> requests;
  late supabase.SupabaseClient client;

  setUp(() async {
    requests = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      requests.add((
        method: request.method,
        path: request.uri.path,
        body: body,
      ));
      request.response
        ..headers.contentType = ContentType.json
        ..write('1');
      await request.response.close();
    });
    client = supabase.SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'test-key',
      authOptions: const supabase.AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test('désactiver appelle la fonction serveur avec le point d’envoi',
      () async {
    final repository = SupabasePushSubscriptionsRepository(
      client,
      unsubscribe: () async => jsonEncode({
        'endpoint': 'https://push.invalid/telephone',
        'keys': {'p256dh': 'k', 'auth': 'a'},
      }),
    );

    await repository.disable();

    expect(requests, hasLength(1));
    expect(requests.single.method, 'POST');
    expect(requests.single.path, '/rest/v1/rpc/unregister_push_subscription');
    expect(
      jsonDecode(requests.single.body),
      {'p_endpoint': 'https://push.invalid/telephone'},
    );
  });

  test('plus aucune suppression directe dans la table', () async {
    final repository = SupabasePushSubscriptionsRepository(
      client,
      unsubscribe: () async =>
          jsonEncode({'endpoint': 'https://push.invalid/telephone'}),
    );

    await repository.disable();

    expect(
      requests.where((r) => r.path.contains('/rest/v1/push_subscriptions')),
      isEmpty,
    );
    expect(requests.where((r) => r.method == 'DELETE'), isEmpty);
  });

  test('un navigateur déjà désabonné ne contacte pas le serveur', () async {
    final repository = SupabasePushSubscriptionsRepository(
      client,
      unsubscribe: () async => null,
    );

    await repository.disable();

    expect(requests, isEmpty);
  });
}
