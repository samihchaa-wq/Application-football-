import 'package:as_grinta/core/config/app_config.dart';
import 'package:as_grinta/core/providers/supabase_provider.dart';
import 'package:as_grinta/core/security/password_policy.dart';
import 'package:as_grinta/core/utils/app_errors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le club du compte connecté.
class Club {
  const Club({
    required this.id,
    required this.name,
    required this.shortName,
    required this.inviteCode,
  });

  factory Club.fromJson(Map<String, dynamic> json) => Club(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        shortName: json['short_name'] as String? ?? '',
        inviteCode: json['invite_code'] as String? ?? '',
      );

  final String id;
  final String name;
  final String shortName;
  final String inviteCode;

  /// Lien d'inscription à partager : il ouvre la page d'inscription avec le
  /// code du club déjà rempli.
  String get inviteLink => buildInviteLink(inviteCode);
}

String buildInviteLink(String inviteCode, {String? publicAppUrl}) {
  final base = publicAppUrl ?? AppConfig.publicAppUrl;
  final normalizedBase = base.endsWith('/') ? base : '$base/';
  return '$normalizedBase#/auth/register?code=$inviteCode';
}

/// Format d'un code d'invitation : 8 lettres ou chiffres, sans 0, 1, I ni O.
final RegExp inviteCodePattern = RegExp(r'^[A-Z2-9]{8}$');

/// Nettoie ce que la personne a tapé ou collé : espaces, tirets, minuscules.
String normalizeInviteCode(String input) =>
    input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

/// Résultat d'une inscription.
class ClubRegistration {
  const ClubRegistration({
    required this.username,
    required this.clubName,
    required this.isActive,
  });

  /// Identifiant de connexion généré par le serveur.
  final String username;
  final String clubName;

  /// Vrai pour le créateur d'un club : son compte est utilisable tout de
  /// suite. Faux pour un membre qui rejoint : il attend la validation.
  final bool isActive;
}

class ClubRepository {
  ClubRepository(this._client);

  final SupabaseClient _client;

  /// Le club du compte connecté. Les règles de la base ne laissent voir que
  /// celui-là.
  Future<Club> fetchMyClub() async {
    final row = await _client
        .from('clubs')
        .select('id,name,short_name,invite_code')
        .single();
    return Club.fromJson(row);
  }

  /// Remplace le code d'invitation du club. Réservé aux administrateurs.
  Future<String> regenerateInviteCode() async {
    final result = await _client.rpc('admin_regenerate_club_invite_code');
    if (result is! String || result.isEmpty) {
      throw StateError('Le code n’a pas pu être renouvelé.');
    }
    return result;
  }

  /// Crée un compte dans un club existant, à partir de son code d'invitation.
  Future<ClubRegistration> joinClub({
    required String inviteCode,
    required String firstName,
    required String lastName,
    required String password,
  }) {
    return _register({
      'mode': 'join',
      'inviteCode': normalizeInviteCode(inviteCode),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'password': password,
    }, password);
  }

  /// Crée un club ; le demandeur en devient le premier administrateur.
  Future<ClubRegistration> createClub({
    required String clubName,
    String? clubShortName,
    required String firstName,
    required String lastName,
    required String password,
  }) {
    return _register({
      'mode': 'create',
      'clubName': clubName.trim(),
      if (clubShortName != null && clubShortName.trim().isNotEmpty)
        'clubShortName': clubShortName.trim(),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'password': password,
    }, password);
  }

  Future<ClubRegistration> _register(
    Map<String, dynamic> body,
    String password,
  ) async {
    final passwordError = PasswordPolicy.validate(password);
    if (passwordError != null) throw ArgumentError(passwordError);

    final FunctionResponse response;
    try {
      response = await _client.functions.invoke('register-account', body: body);
    } on FunctionsHttpException catch (error) {
      throw functionHttpError(
        error,
        fallback: 'La création du compte a échoué.',
      );
    }
    final data = response.data;
    final username = data is Map ? data['username'] as String? : null;
    if (response.status != 200 || username == null || username.isEmpty) {
      final message = data is Map ? data['error'] as String? : null;
      throw StateError(message ?? 'La création du compte a échoué.');
    }
    return ClubRegistration(
      username: username,
      clubName: (data as Map)['clubName'] as String? ?? '',
      isActive: data['status'] == 'active',
    );
  }
}

final clubRepositoryProvider = Provider<ClubRepository>((ref) {
  return ClubRepository(ref.watch(supabaseClientProvider));
});
