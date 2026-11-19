import 'dart:convert';

import 'package:petit_filet/core/providers/supabase_provider.dart';
import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Téléphone et date de naissance du membre. Visibles par lui seul : ni les
/// autres membres ni les administrateurs du club ne les voient.
class PrivateDetails {
  const PrivateDetails({this.phone, this.birthDate});

  factory PrivateDetails.fromJson(Map<String, dynamic> json) {
    final phone = json['phone']?.toString().trim() ?? '';
    final birth = json['birth_date'];
    return PrivateDetails(
      phone: phone.isEmpty ? null : phone,
      birthDate: birth is String ? DateTime.tryParse(birth) : null,
    );
  }

  final String? phone;
  final DateTime? birthDate;
}

/// Format accepté pour un numéro de téléphone (le serveur fait le même
/// contrôle) : chiffres, espaces, points, tirets, parenthèses, « + » initial.
final RegExp phoneNumberPattern = RegExp(r'^\+?[0-9][0-9 .()-]{5,24}$');

/// Date au format attendu par la base : AAAA-MM-JJ.
String isoDay(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Droits du membre sur ses données : les télécharger, supprimer son compte.
class PersonalDataRepository {
  PersonalDataRepository(this._client);

  final SupabaseClient _client;

  /// Téléphone et date de naissance du membre connecté.
  Future<PrivateDetails> fetchPrivateDetails() async {
    final result = await _client.rpc('get_my_private_details');
    if (result is! Map) return const PrivateDetails();
    return PrivateDetails.fromJson(Map<String, dynamic>.from(result));
  }

  /// Enregistre (ou efface, avec des valeurs vides) le téléphone et la date
  /// de naissance du membre connecté.
  Future<PrivateDetails> savePrivateDetails(PrivateDetails details) async {
    final result = await _client.rpc(
      'set_my_private_details',
      params: {
        'p_phone': details.phone,
        'p_birth_date':
            details.birthDate == null ? null : isoDay(details.birthDate!),
      },
    );
    if (result is! Map) {
      throw StateError('Le téléphone et la date de naissance n’ont pas pu '
          'être enregistrés.');
    }
    return PrivateDetails.fromJson(Map<String, dynamic>.from(result));
  }

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
