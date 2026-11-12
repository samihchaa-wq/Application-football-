import 'dart:typed_data';

import 'package:as_grinta/core/club/club_kits.dart';
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
    this.primaryColor,
    this.secondaryColor,
    this.logoPath,
    this.kits,
  });

  factory Club.fromJson(Map<String, dynamic> json) => Club(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        shortName: json['short_name'] as String? ?? '',
        inviteCode: json['invite_code'] as String? ?? '',
        primaryColor: json['primary_color'] as String?,
        secondaryColor: json['secondary_color'] as String?,
        logoPath: json['logo_path'] as String?,
        kits: json['kits'],
      );

  final String id;
  final String name;
  final String shortName;
  final String inviteCode;

  /// Couleurs du club au format « #RRGGBB » (null : couleurs par défaut).
  final String? primaryColor;
  final String? secondaryColor;

  /// Chemin du logo dans l'espace d'images (null : écusson neutre).
  final String? logoPath;

  /// Maillots réglés par le club (null : maillots par défaut). Voir
  /// [ClubKits.parse].
  final Object? kits;

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

/// Une fonctionnalité que l'administrateur peut activer ou non pour son club.
enum ClubModule {
  predictions(
    'predictions',
    'Pronostics et classement',
    'Les pronostics des membres avant chaque match et leur classement.',
  ),
  statistics(
    'statistics',
    'Statistiques',
    'L’onglet Statistiques : classements, stats de l’équipe et des joueurs.',
  ),
  manOfTheMatch(
    'man_of_the_match',
    'Étoile du match',
    'Le vote de l’Étoile du match après chaque rencontre.',
  ),
  liveMode(
    'live_mode',
    'Mode live',
    'Le suivi du match en direct (score, buteurs) et les alertes de but.',
  ),
  badges(
    'badges',
    'Badges',
    'Récompenses débloquées par les joueurs et leur armoire à badges.',
  ),
  seasonWrapped(
    'season_wrapped',
    'Bilan de fin de saison',
    'Le récapitulatif personnel proposé à chaque joueur en fin de saison.',
  ),
  weather(
    'weather',
    'Météo du match',
    'La météo prévue au coup d’envoi, sur la fiche du match.',
  );

  const ClubModule(this.key, this.label, this.description);

  /// Nom de la fonctionnalité côté serveur.
  final String key;
  final String label;
  final String description;
}

/// État des fonctionnalités du club. Une fonctionnalité inconnue ou non
/// renseignée est considérée comme activée : rien ne disparaît par erreur.
class ClubModules {
  const ClubModules(this._enabled);

  const ClubModules.allEnabled() : _enabled = const {};

  factory ClubModules.fromJson(Object? json) {
    if (json is! Map) return const ClubModules.allEnabled();
    return ClubModules({
      for (final entry in json.entries)
        if (entry.value is bool) '${entry.key}': entry.value as bool,
    });
  }

  final Map<String, bool> _enabled;

  bool isEnabled(ClubModule module) => _enabled[module.key] ?? true;
}

/// Une règle du club réglable par l'administrateur (délai, heure…).
class ClubRule {
  const ClubRule({
    required this.key,
    required this.label,
    required this.description,
    required this.unit,
    required this.group,
    required this.defaultValue,
    required this.min,
    required this.max,
    required this.value,
  });

  factory ClubRule.fromJson(Map<String, dynamic> json) => ClubRule(
        key: json['key'] as String,
        label: json['label'] as String? ?? '',
        description: json['description'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        group: json['group'] as String? ?? '',
        defaultValue: (json['default'] as num).toInt(),
        min: (json['min'] as num).toInt(),
        max: (json['max'] as num).toInt(),
        value: (json['value'] as num).toInt(),
      );

  final String key;
  final String label;
  final String description;
  final String unit;
  final String group;
  final int defaultValue;
  final int min;
  final int max;
  final int value;
}

/// Déclaration d'âge faite à l'inscription. En France, un mineur de moins de
/// 15 ans ne peut s'inscrire qu'avec l'accord d'un parent.
enum AgeConfirmation {
  fifteenOrMore('15_or_more'),
  parentalConsent('parental_consent');

  const AgeConfirmation(this.serverValue);

  final String serverValue;
}

/// Résultat d'une inscription.
class ClubRegistration {
  const ClubRegistration({
    required this.username,
    required this.clubName,
    required this.isActive,
    this.emailConfirmationSent = false,
  });

  /// Identifiant de connexion généré par le serveur.
  final String username;
  final String clubName;

  /// Vrai pour le créateur d'un club : son compte est utilisable tout de
  /// suite. Faux pour un membre qui rejoint : il attend la validation.
  final bool isActive;

  /// Vrai si un e-mail de confirmation a été envoyé à l'adresse indiquée.
  final bool emailConfirmationSent;
}

class ClubRepository {
  ClubRepository(this._client);

  final SupabaseClient _client;

  /// Le club du compte connecté. Les règles de la base ne laissent voir que
  /// celui-là.
  Future<Club> fetchMyClub() async {
    final row = await _client
        .from('clubs')
        .select(
            'id,name,short_name,invite_code,primary_color,secondary_color,logo_path,kits')
        .single();
    return Club.fromJson(row);
  }

  /// Enregistre les trois maillots du club. Réservé aux administrateurs.
  Future<List<ClubKit>> updateKits(List<ClubKit> kits) async {
    final result = await _client.rpc(
      'admin_update_club_kits',
      params: {
        'p_kits': [for (final kit in kits) kit.toJson()],
      },
    );
    final saved = ClubKits.parse(result);
    if (saved == null) throw StateError('Les maillots n’ont pas pu changer.');
    return saved;
  }

  /// Remplace le code d'invitation du club. Réservé aux administrateurs.
  Future<String> regenerateInviteCode() async {
    final result = await _client.rpc('admin_regenerate_club_invite_code');
    if (result is! String || result.isEmpty) {
      throw StateError('Le code n’a pas pu être renouvelé.');
    }
    return result;
  }

  /// Change le nom et le nom court du club. Réservé aux administrateurs.
  Future<Club> updateIdentity({
    required String name,
    required String shortName,
  }) async {
    final result = await _client.rpc(
      'admin_update_club_identity',
      params: {'p_name': name.trim(), 'p_short_name': shortName.trim()},
    );
    if (result is! Map) throw StateError('Le club n’a pas pu être modifié.');
    return Club.fromJson(Map<String, dynamic>.from(result));
  }

  /// Change les deux couleurs du club (« #RRGGBB »). Réservé aux
  /// administrateurs.
  Future<Club> updateColors({
    required String primary,
    required String secondary,
  }) async {
    final result = await _client.rpc(
      'admin_update_club_colors',
      params: {'p_primary': primary, 'p_secondary': secondary},
    );
    if (result is! Map) throw StateError('Les couleurs n’ont pas pu changer.');
    return Club.fromJson(Map<String, dynamic>.from(result));
  }

  /// Adresse publique du logo du club, ou null.
  String? logoUrl(Club club) {
    final path = club.logoPath;
    if (path == null || path.isEmpty) return null;
    return _client.storage.from('badge-images').getPublicUrl(path);
  }

  /// Envoie l'image comme logo du club. Réservé aux administrateurs.
  Future<Club> uploadLogo(
      Uint8List bytes, String fileExt, String clubId) async {
    final ext = fileExt.isEmpty ? 'png' : fileExt.toLowerCase();
    // Chaque envoi prend un nouveau nom : le navigateur peut garder l'image
    // un an sans jamais afficher l'ancienne.
    final path =
        'club-logos/$clubId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from('badge-images').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: ext == 'jpg' || ext == 'jpeg'
                ? 'image/jpeg'
                : ext == 'webp'
                    ? 'image/webp'
                    : 'image/png',
            cacheControl: '31536000',
            upsert: false,
          ),
        );
    return _setLogoPath(path);
  }

  /// Retire le logo : l'écusson neutre revient.
  Future<Club> removeLogo() => _setLogoPath(null);

  Future<Club> _setLogoPath(String? path) async {
    final result =
        await _client.rpc('admin_set_club_logo', params: {'p_path': path});
    if (result is! Map) throw StateError('Le logo n’a pas pu être changé.');
    return Club.fromJson(Map<String, dynamic>.from(result));
  }

  /// Les fonctionnalités activées pour le club du compte connecté.
  Future<ClubModules> fetchModules() async {
    return ClubModules.fromJson(await _client.rpc('get_club_modules'));
  }

  /// Active ou désactive une fonctionnalité. Réservé aux administrateurs.
  Future<ClubModules> setModule(ClubModule module,
      {required bool enabled}) async {
    return ClubModules.fromJson(
      await _client.rpc(
        'admin_set_club_module',
        params: {'p_key': module.key, 'p_enabled': enabled},
      ),
    );
  }

  /// Les règles du club avec leur valeur actuelle.
  Future<List<ClubRule>> fetchRules() async {
    final result = await _client.rpc('get_club_rules');
    if (result is! List) return const [];
    return [
      for (final row in result)
        if (row is Map) ClubRule.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  /// Change une règle ; [value] à null rétablit la valeur par défaut.
  /// Réservé aux administrateurs.
  Future<List<ClubRule>> setRule(String key, int? value) async {
    final result = await _client.rpc(
      'admin_set_club_rule',
      params: {'p_key': key, 'p_value': value},
    );
    if (result is List) {
      return [
        for (final row in result)
          if (row is Map) ClubRule.fromJson(Map<String, dynamic>.from(row)),
      ];
    }
    return fetchRules();
  }

  /// Crée un compte dans un club existant, à partir de son code d'invitation.
  Future<ClubRegistration> joinClub({
    required String inviteCode,
    required String firstName,
    required String lastName,
    required String password,
    required String acceptedTermsVersion,
    required AgeConfirmation ageConfirmation,
    String? email,
  }) {
    return _register({
      'mode': 'join',
      'acceptedTermsVersion': acceptedTermsVersion,
      'ageConfirmation': ageConfirmation.serverValue,
      'inviteCode': normalizeInviteCode(inviteCode),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'password': password,
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    }, password);
  }

  /// Crée un club ; le demandeur en devient le premier administrateur.
  Future<ClubRegistration> createClub({
    required String clubName,
    String? clubShortName,
    required String firstName,
    required String lastName,
    required String password,
    required String acceptedTermsVersion,
    required AgeConfirmation ageConfirmation,
    String? email,
  }) {
    return _register({
      'mode': 'create',
      'acceptedTermsVersion': acceptedTermsVersion,
      'ageConfirmation': ageConfirmation.serverValue,
      'clubName': clubName.trim(),
      if (clubShortName != null && clubShortName.trim().isNotEmpty)
        'clubShortName': clubShortName.trim(),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'password': password,
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    }, password);
  }

  /// Rattache le compte connecté (sans club) à un club : rejoindre avec un
  /// code d'invitation, ou en créer un.
  Future<ClubRegistration> claimClub({
    required bool create,
    String? inviteCode,
    String? clubName,
    String? clubShortName,
    required String firstName,
    required String lastName,
    required String acceptedTermsVersion,
    required AgeConfirmation ageConfirmation,
  }) async {
    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'claim-club',
        body: {
          'mode': create ? 'create' : 'join',
          if (!create) 'inviteCode': normalizeInviteCode(inviteCode ?? ''),
          if (create) 'clubName': (clubName ?? '').trim(),
          if (create && (clubShortName ?? '').trim().isNotEmpty)
            'clubShortName': clubShortName!.trim(),
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'acceptedTermsVersion': acceptedTermsVersion,
          'ageConfirmation': ageConfirmation.serverValue,
        },
      );
    } on FunctionsHttpException catch (error) {
      throw functionHttpError(
        error,
        fallback: 'Le rattachement au club a échoué.',
      );
    }
    final data = response.data;
    if (response.status != 200 || data is! Map || data['username'] == null) {
      final message = data is Map ? data['error'] as String? : null;
      throw StateError(message ?? 'Le rattachement au club a échoué.');
    }
    // Le club vient d'être inscrit dans le compte : on renouvelle la session
    // pour que l'application le voie.
    await _client.auth.refreshSession();
    return ClubRegistration(
      username: data['username'] as String,
      clubName: data['clubName'] as String? ?? '',
      isActive: data['status'] == 'active',
    );
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
      emailConfirmationSent: data['emailConfirmationSent'] == true,
    );
  }
}

final clubRepositoryProvider = Provider<ClubRepository>((ref) {
  return ClubRepository(ref.watch(supabaseClientProvider));
});

/// Le club du compte connecté.
final myClubProvider = FutureProvider.autoDispose<Club>((ref) {
  return ref.watch(clubRepositoryProvider).fetchMyClub();
});

/// Les fonctionnalités du club. Tant que la réponse n'est pas arrivée, ou si
/// elle échoue, les écrans se comportent comme si tout était activé.
final clubModulesProvider = FutureProvider<ClubModules>((ref) {
  return ref.watch(clubRepositoryProvider).fetchModules();
});

/// Vrai si [module] est activé pour le club (ou pas encore connu).
final clubModuleEnabledProvider =
    Provider.family<bool, ClubModule>((ref, module) {
  return ref.watch(clubModulesProvider).valueOrNull?.isEnabled(module) ?? true;
});
