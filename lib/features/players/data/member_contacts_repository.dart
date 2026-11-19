import 'package:petit_filet/core/providers/supabase_provider.dart';
import 'package:petit_filet/features/profile/data/personal_data_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Téléphone et date de naissance des membres du club, affichés dans
/// l'Effectif. Tous les membres actifs les voient ; le membre modifie les
/// siens depuis son Profil, un administrateur ceux de n'importe quel membre.
class MemberContactsRepository {
  MemberContactsRepository(this._client);

  final SupabaseClient _client;

  /// Coordonnées des membres actifs du club, par identifiant de compte.
  Future<Map<String, PrivateDetails>> fetchClubContacts() async {
    final result = await _client.rpc('get_club_member_contacts');
    if (result is! List) return const {};
    return {
      for (final item in result.whereType<Map>())
        if (item['profile_id'] is String)
          item['profile_id'] as String:
              PrivateDetails.fromJson(Map<String, dynamic>.from(item)),
    };
  }

  /// Saisie par un administrateur. Le serveur vérifie le rôle, le format et
  /// que le membre appartient bien au club.
  Future<PrivateDetails> saveForMember(
    String profileId,
    PrivateDetails details,
  ) async {
    final result = await _client.rpc(
      'admin_set_member_private_details',
      params: {
        'p_profile_id': profileId,
        'p_phone': details.phone,
        'p_birth_date':
            details.birthDate == null ? null : isoDay(details.birthDate!),
      },
    );
    if (result is! Map) {
      throw StateError('Les coordonnées n’ont pas pu être enregistrées.');
    }
    return PrivateDetails.fromJson(Map<String, dynamic>.from(result));
  }
}

final memberContactsRepositoryProvider =
    Provider<MemberContactsRepository>((ref) {
  return MemberContactsRepository(ref.watch(supabaseClientProvider));
});

final clubMemberContactsProvider =
    FutureProvider.autoDispose<Map<String, PrivateDetails>>((ref) {
  return ref.watch(memberContactsRepositoryProvider).fetchClubContacts();
});
