import 'dart:convert';

import 'package:as_grinta/core/providers/supabase_provider.dart';
import 'package:as_grinta/core/utils/app_errors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Droits du membre sur ses données : les télécharger, supprimer son compte.
class PersonalDataRepository {
  PersonalDataRepository(this._client);

  final SupabaseClient _client;

  /// Toutes les données du membre connecté, en JSON lisible.
  Future<String> exportMyData() async {
    final result = await _client.rpc('export_my_data');
    return const JsonEncoder.withIndent('  ').convert(result);
  }

  /// Supprime définitivement le compte du membre connecté.
  Future<void> deleteMyAccount() async {
    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'manage-user',
        body: {'action': 'delete-self'},
      );
    } on FunctionsHttpException catch (error) {
      throw functionHttpError(
        error,
        fallback: 'La suppression du compte a échoué.',
      );
    }
    final data = response.data;
    if (response.status < 200 ||
        response.status >= 300 ||
        data is! Map ||
        data['deleted'] != true) {
      final message = data is Map ? data['error'] as String? : null;
      throw StateError(message ?? 'La suppression du compte a échoué.');
    }
  }
}

final personalDataRepositoryProvider = Provider<PersonalDataRepository>((ref) {
  return PersonalDataRepository(ref.watch(supabaseClientProvider));
});
