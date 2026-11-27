import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petit_filet/core/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Début d'activation de la double authentification : ce qu'il faut montrer
/// pour ajouter le compte dans une application d'authentification.
class TotpEnrollmentStart {
  const TotpEnrollmentStart({
    required this.factorId,
    required this.secret,
    required this.uri,
  });

  final String factorId;

  /// Clé à taper à la main si le QR code ne peut pas être scanné.
  final String secret;

  /// Adresse `otpauth://` : contenu du QR code, ouvrable directement sur le
  /// téléphone qui porte l'application d'authentification.
  final String uri;
}

/// Double authentification par code à 6 chiffres (TOTP Supabase), proposée
/// aux administrateurs (audit du 26/11/2026, point 39).
///
/// Une fois activée, le serveur exige le code pour les actions sensibles
/// (lien de nouveau mot de passe d'un membre, suppression d'un compte).
class MfaRepository {
  MfaRepository(this._auth);

  final GoTrueClient _auth;

  static const issuer = 'Petit Filet';

  /// Identifiant du code déjà activé, ou null.
  Future<String?> verifiedTotpFactorId() async {
    final factors = await _auth.mfa.listFactors();
    return factors.totp.isEmpty ? null : factors.totp.first.id;
  }

  /// Vrai si le compte a activé la double authentification mais n'a pas
  /// encore saisi de code dans cette session.
  bool needsCodeForSensitiveAction() {
    final levels = _auth.mfa.getAuthenticatorAssuranceLevel();
    return levels.nextLevel == AuthenticatorAssuranceLevels.aal2 &&
        levels.currentLevel != AuthenticatorAssuranceLevels.aal2;
  }

  /// Prépare un nouveau code. Une activation commencée puis abandonnée est
  /// d'abord retirée : Supabase refuse deux facteurs du même nom.
  Future<TotpEnrollmentStart> startEnrollment() async {
    final factors = await _auth.mfa.listFactors();
    for (final factor in factors.all) {
      if (factor.factorType == FactorType.totp &&
          factor.status == FactorStatus.unverified) {
        await _auth.mfa.unenroll(factor.id);
      }
    }
    final response = await _auth.mfa.enroll(
      factorType: FactorType.totp,
      issuer: issuer,
      friendlyName: issuer,
    );
    final totp = response.totp;
    if (totp == null) {
      throw StateError('La double authentification n’a pas pu être préparée.');
    }
    return TotpEnrollmentStart(
      factorId: response.id,
      secret: totp.secret,
      uri: totp.uri,
    );
  }

  /// Termine l'activation avec le premier code affiché par l'application.
  Future<void> confirmEnrollment({
    required String factorId,
    required String code,
  }) async {
    await _auth.mfa.challengeAndVerify(factorId: factorId, code: code.trim());
  }

  /// Saisie du code avant une action sensible : la session passe au niveau
  /// « aal2 » attendu par le serveur.
  Future<void> verifyCode(String code) async {
    final factorId = await verifiedTotpFactorId();
    if (factorId == null) {
      throw StateError('La double authentification n’est pas activée.');
    }
    await _auth.mfa.challengeAndVerify(factorId: factorId, code: code.trim());
  }

  /// Retire un code (activation abandonnée, ou désactivation après saisie
  /// d'un code valide : Supabase l'exige).
  Future<void> removeFactor(String factorId) async {
    await _auth.mfa.unenroll(factorId);
  }
}

final mfaRepositoryProvider = Provider<MfaRepository>((ref) {
  return MfaRepository(ref.watch(supabaseClientProvider).auth);
});

/// Un code TOTP : exactement 6 chiffres (espaces tolérés).
bool isValidTotpCode(String value) =>
    RegExp(r'^\d{6}$').hasMatch(value.replaceAll(' ', ''));

/// Message lisible pour une erreur de double authentification.
String mfaErrorMessage(Object error) {
  if (error is AuthException) {
    final code = error.code ?? '';
    if (code == 'mfa_verification_failed' ||
        error.message.toLowerCase().contains('invalid totp')) {
      return 'Code incorrect ou expiré. Réessaie avec le code affiché.';
    }
    if (code == 'insufficient_aal') {
      return 'Saisis d’abord un code de ton application d’authentification.';
    }
    if (code == 'mfa_totp_enroll_not_enabled' ||
        code == 'mfa_totp_verify_not_enabled') {
      return 'La double authentification n’est pas encore ouverte sur le '
          'serveur.';
    }
  }
  if (error is StateError) return error.message;
  return 'La double authentification a échoué. Réessaie.';
}
