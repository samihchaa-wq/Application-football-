import 'package:petit_filet/core/utils/name_validation.dart';
import 'package:petit_filet/features/legal/domain/legal_documents.dart';

enum AuthRole { pronostiqueur, admin }

extension AuthRoleX on AuthRole {
  String get label {
    switch (this) {
      case AuthRole.admin:
        return 'Admin';
      case AuthRole.pronostiqueur:
        return 'Utilisateur';
    }
  }

  bool get isPronostiqueur => this == AuthRole.pronostiqueur;
  bool get isAdmin => this == AuthRole.admin;
  bool get isStaff => isAdmin;
}

class AuthProfile {
  const AuthProfile({
    this.id,
    this.username,
    required this.firstName,
    required this.lastName,
    this.surnom = '',
    this.photoUrl,
    required this.role,
    required this.isGoalkeeper,
    required this.isActive,
    this.status = 'active',
    required this.mustChangePassword,
    this.createdAt,
    this.updatedAt,
    this.contactEmail,
    this.pendingContactEmail,
    this.termsVersion = legalVersion,
    this.ageConfirmation,
  });

  final String? id;
  final String? username;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final String surnom;
  final AuthRole role;
  final bool isGoalkeeper;
  final bool isActive;
  final String status;
  final bool mustChangePassword;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Adresse e-mail confirmée du compte, s'il y en a une.
  final String? contactEmail;

  /// Adresse saisie mais dont le lien de confirmation n'a pas encore été ouvert.
  final String? pendingContactEmail;

  /// Version des CGU et de la politique de confidentialité acceptée par ce
  /// compte. `null` : compte créé avant l'enregistrement de l'accord.
  final String? termsVersion;

  /// Déclaration d'âge faite avec l'accord (`15_or_more` ou
  /// `parental_consent`), si elle existe.
  final String? ageConfirmation;

  bool get isPending => status == 'pending';

  /// Les textes ont changé depuis l'accord de ce compte : il doit accepter la
  /// nouvelle version pour continuer.
  bool get needsTermsAcceptance => termsVersion != legalVersion;

  String get fullName =>
      capitalizePersonName('${capitalizePersonName(firstName)} $lastName');

  String get displayName {
    final nick = capitalizePersonName(surnom);
    if (nick.isNotEmpty) return nick;
    final first = capitalizePersonName(firstName);
    if (first.isNotEmpty) return first;
    return fullName.isEmpty ? 'Utilisateur' : fullName;
  }

  factory AuthProfile.fromJson(Map<String, dynamic> json) {
    final roleValue =
        (json['role'] ?? 'pronostiqueur').toString().toLowerCase();
    // Compatibilité de transition : un ancien profil « moderateur » est traité
    // comme admin côté client jusqu'à la migration de production.
    final role = switch (roleValue) {
      'admin' || 'moderateur' || 'moderator' => AuthRole.admin,
      _ => AuthRole.pronostiqueur,
    };

    final statusValue = (json['status'] ?? 'active').toString().toLowerCase();

    return AuthProfile(
      id: json['id']?.toString(),
      username: json['username']?.toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      surnom: (json['surnom'] ?? '').toString(),
      photoUrl: (json['photo_url']?.toString().trim().isNotEmpty ?? false)
          ? json['photo_url'].toString()
          : null,
      role: role,
      isGoalkeeper: json['is_goalkeeper'] == true,
      isActive: statusValue == 'active',
      status: statusValue,
      mustChangePassword: json['must_change_password'] == true,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
      contactEmail: _nonEmpty(json['contact_email']),
      pendingContactEmail: _nonEmpty(json['pending_contact_email']),
      termsVersion: _nonEmpty(json['terms_version']),
      ageConfirmation: _nonEmpty(json['age_confirmation']),
    );
  }
}

String? _nonEmpty(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
