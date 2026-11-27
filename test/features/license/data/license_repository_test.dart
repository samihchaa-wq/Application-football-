import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/features/license/data/license_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

typedef _Request = ({
  String method,
  String path,
  Map<String, String> query,
  String prefer,
  Object? body,
});

/// L'espace Licence parle directement aux tables (le serveur réserve tout aux
/// administrateurs du club). Ces tests fixent la forme exacte des requêtes :
/// une erreur ici écrirait sur la mauvaise ligne ou sur toute la table.
void main() {
  late HttpServer server;
  late List<_Request> requests;
  late Map<String, Object> responses;
  late supabase.SupabaseClient client;
  late LicenseRepository repository;

  setUp(() async {
    requests = [];
    responses = {};
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final raw = await utf8.decoder.bind(request).join();
      final path = request.uri.path.replaceFirst('/rest/v1/', '');
      requests.add((
        method: request.method,
        path: path,
        query: request.uri.queryParameters,
        prefer: request.headers.value('prefer') ?? '',
        body: raw.isEmpty ? null : jsonDecode(raw),
      ));
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(responses[path] ?? const []));
      await request.response.close();
    });
    client = supabase.SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'test-key',
      authOptions: const supabase.AuthClientOptions(autoRefreshToken: false),
    );
    repository = LicenseRepository(client);
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  group('dépenses du club', () {
    // `.order('created_at')` sans précision trie du plus récent au plus ancien
    // (valeur par défaut de supabase-dart) : comportement actuel, figé ici.
    test('la liste est lue de la plus récente à la plus ancienne', () async {
      responses['club_license_expenses'] = [
        {'id': 'e1', 'label': 'Survêtement'},
        {'id': 'e2', 'label': null},
      ];

      final expenses = await repository.fetchExpenses('s1');

      expect(requests.single.method, 'GET');
      expect(requests.single.query['select'], 'id,label');
      expect(requests.single.query['season_id'], 'eq.s1',
          reason: 'chaque saison a ses propres dépenses');
      expect(requests.single.query['order'], 'created_at.desc.nullslast');
      expect(expenses.map((e) => e.id), ['e1', 'e2']);
      expect(expenses.first.label, 'Survêtement');
      expect(expenses.last.label, '', reason: 'un nom absent reste lisible');
    });

    test('ajouter envoie la saison et le nom sans espaces, sans club',
        () async {
      await repository.addExpense('s1', '  Survêtement  ');

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.path, 'club_license_expenses');
      // Le club est fixé par le serveur (valeur par défaut), jamais par l'appli.
      expect(request.body, {'season_id': 's1', 'label': 'Survêtement'});
    });

    test('renommer ne touche que la dépense visée', () async {
      await repository.renameExpense('e1', ' Maillot ');

      final request = requests.single;
      expect(request.method, 'PATCH');
      expect(request.query['id'], 'eq.e1');
      expect(request.body, {'label': 'Maillot'});
    });

    test('supprimer ne touche que la dépense visée', () async {
      await repository.deleteExpense('e1');

      final request = requests.single;
      expect(request.method, 'DELETE');
      expect(request.path, 'club_license_expenses');
      expect(request.query['id'], 'eq.e1');
    });
  });

  group('paiements d’une saison', () {
    test('seules les lignes de la saison demandée sont lues', () async {
      responses['season_player_licenses'] = [
        {'season_player_id': 'p1', 'license_paid': true},
        {'season_player_id': 'p2', 'license_paid': false},
      ];
      responses['season_player_expense_payments'] = [
        {'expense_id': 'e1', 'season_player_id': 'p1'},
        {'expense_id': 'e1', 'season_player_id': 'p2'},
        {'expense_id': 'e2', 'season_player_id': 'p2'},
      ];

      final season = await repository.fetchSeason('s1');

      expect(requests, hasLength(2));
      for (final request in requests) {
        expect(request.query['season_players.season_id'], 'eq.s1');
      }
      expect(season.licensePaid, {'p1'});
      expect(season.hasPaidLicense('p2'), isFalse);
      expect(season.hasPaidExpense('e1', 'p1'), isTrue);
      expect(season.hasPaidExpense('e2', 'p1'), isFalse);
      expect(season.hasPaidExpense('e2', 'p2'), isTrue);
      expect(season.hasPaidExpense('inconnue', 'p1'), isFalse);
    });

    test('cocher la licence met à jour la ligne existante du joueur', () async {
      await repository.setLicensePaid('p1', true);

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.path, 'season_player_licenses');
      expect(request.query['on_conflict'], 'season_player_id');
      expect(request.prefer, contains('resolution=merge-duplicates'));
      final body = request.body! as Map;
      expect(body['season_player_id'], 'p1');
      expect(body['license_paid'], isTrue);
      expect(body.containsKey('club_id'), isFalse);
    });

    test('cocher une dépense ajoute un paiement sans doublon', () async {
      await repository.setExpensePaid('e1', 'p1', true);

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.path, 'season_player_expense_payments');
      expect(request.query['on_conflict'], 'expense_id,season_player_id');
      expect(request.body, {'expense_id': 'e1', 'season_player_id': 'p1'});
    });

    test('décocher une dépense efface ce seul paiement', () async {
      await repository.setExpensePaid('e1', 'p1', false);

      final request = requests.single;
      expect(request.method, 'DELETE');
      expect(request.path, 'season_player_expense_payments');
      expect(request.query['expense_id'], 'eq.e1');
      expect(request.query['season_player_id'], 'eq.p1');
    });
  });
}
