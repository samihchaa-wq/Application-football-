import 'package:as_grinta/core/providers/supabase_provider.dart';
import 'package:as_grinta/core/utils/app_errors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Adresse e-mail d'un compte : confirmer l'adresse, et retrouver son compte
/// par e-mail en cas de mot de passe perdu. Tout passe par le serveur, qui
/// envoie les messages.
class AccountEmailRepository {
  AccountEmailRepository(this._client);

  final SupabaseClient _client;

  /// Demande un lien de récupération pour l'adresse confirmée d'un compte. La
  /// réponse est la même que l'adresse soit connue ou non.
  Future<void> requestPasswordReset(String email) async {
    await _invoke(
      {'action': 'request-reset', 'email': email.trim()},
      fallback: 'La demande n’a pas pu être envoyée.',
    );
  }

  /// Envoie un lien de confirmation à [email] pour le compte connecté.
  Future<void> requestConfirmation(String email) async {
    await _invoke(
      {'action': 'request-confirmation', 'email': email.trim()},
      fallback: 'Le lien de confirmation n’a pas pu être envoyé.',
    );
  }

  /// Valide le lien reçu par e-mail. Vrai si l'adresse est confirmée.
  Future<bool> confirm(String token) async {
    final data = await _invoke(
      {'action': 'confirm', 'token': token.trim()},
      fallback: 'La confirmation a échoué.',
    );
    return data is Map && data['confirmed'] == true;
  }

  Future<Object?> _invoke(
    Map<String, dynamic> body, {
    required String fallback,
  }) async {
    final FunctionResponse response;
    try {
      response = await _client.functions.invoke('account-email', body: body);
    } on FunctionsHttpException catch (error) {
      throw functionHttpError(error, fallback: fallback);
    }
    if (response.status != 200) {
      final data = response.data;
      final message = data is Map ? data['error'] as String? : null;
      throw StateError(message ?? fallback);
    }
    return response.data;
  }
}

final accountEmailRepositoryProvider = Provider<AccountEmailRepository>((ref) {
  return AccountEmailRepository(ref.watch(supabaseClientProvider));
});

/// Une adresse e-mail plausible : quelque chose, un @, un domaine avec un
/// point. La vraie vérification est le lien envoyé à l'adresse.
bool looksLikeEmail(String value) {
  final email = value.trim();
  return email.length <= 254 &&
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
}
