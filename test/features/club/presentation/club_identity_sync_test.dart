import 'dart:async';

import 'package:as_grinta/core/club/club_identity.dart';
import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:as_grinta/features/auth/data/auth_repository.dart';
import 'package:as_grinta/features/auth/domain/auth_profile.dart';
import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:as_grinta/features/club/presentation/club_identity_sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Changement de compte entre deux clubs sans recharger l'application : le
/// compte B ne doit jamais voir le nom, les couleurs ou les maillots du club A,
/// ni pendant le chargement, ni après une erreur réseau, ni quand la réponse
/// du club A arrive en retard.
void main() {
  AuthProfile profile(String id) => AuthProfile(
        id: id,
        firstName: id,
        lastName: '',
        role: AuthRole.pronostiqueur,
        isGoalkeeper: false,
        isActive: true,
        mustChangePassword: false,
      );

  Club club(String id, String name, String kitLabel, String color) => Club(
        id: id,
        name: name,
        shortName: name.toUpperCase(),
        inviteCode: 'ABCDEFGH',
        primaryColor: color,
        kits: [
          for (final kit in ClubKits.defaultsFor())
            kit.copyWith(label: '$kitLabel ${kit.slot.id}').toJson(),
        ],
      );

  final clubA = club('club-a', 'Club A', 'Rouge', '#AA0000');
  final clubB = club('club-b', 'Club B', 'Vert', '#00AA00');

  late _SwitchableAuthController auth;
  late _ControlledClubRepository clubs;
  late ProviderContainer container;

  setUp(() {
    ClubIdentity.reset();
    AppTheme.resetClubColors();
    ClubKits.reset();
    auth = _SwitchableAuthController(profile('a'));
    clubs = _ControlledClubRepository(() => auth.state.profile!.id!);
    container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith((ref) => auth),
        clubRepositoryProvider.overrideWithValue(clubs),
      ],
    );
    container.listen(clubIdentitySyncProvider, (_, __) {});
  });

  tearDown(() {
    container.dispose();
    ClubIdentity.reset();
    AppTheme.resetClubColors();
    ClubKits.reset();
  });

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  void expectNeutral() {
    expect(ClubIdentity.name, ClubIdentity.defaultName);
    expect(ClubKits.usesDefaults, isTrue);
    expect(ClubKits.all.first.label, 'Domicile');
  }

  void expectClub(Club expected, String kitLabel) {
    expect(ClubIdentity.name, expected.name);
    expect(ClubKits.all.first.label, '$kitLabel france');
  }

  test('A puis B : B voit ses maillots, jamais ceux de A', () async {
    await settle();
    clubs.complete('a', clubA);
    await settle();
    expectClub(clubA, 'Rouge');

    auth.switchTo(profile('b'));
    await settle();
    // Pendant le chargement du club B : rien du club A.
    expectNeutral();

    clubs.complete('b', clubB);
    await settle();
    expectClub(clubB, 'Vert');
  });

  test('une réponse tardive du club A ne s’affiche pas chez B', () async {
    await settle();
    // La requête du club A n'a pas encore répondu quand B se connecte.
    auth.switchTo(profile('b'));
    await settle();
    clubs.complete('a', clubA);
    await settle();
    expectNeutral();

    clubs.complete('b', clubB);
    await settle();
    expectClub(clubB, 'Vert');
  });

  test('une erreur réseau chez B laisse l’affichage neutre', () async {
    await settle();
    clubs.complete('a', clubA);
    await settle();
    expectClub(clubA, 'Rouge');

    auth.switchTo(profile('b'));
    await settle();
    clubs.fail('b');
    await settle();
    expectNeutral();
  });

  test('le retour sur A recharge les maillots de A', () async {
    await settle();
    clubs.complete('a', clubA);
    await settle();
    auth.switchTo(profile('b'));
    await settle();
    clubs.complete('b', clubB);
    await settle();
    expectClub(clubB, 'Vert');

    auth.switchTo(profile('a'));
    await settle();
    expectNeutral();
    clubs.complete('a', clubA);
    await settle();
    expectClub(clubA, 'Rouge');
  });

  test('la déconnexion remet l’affichage neutre', () async {
    await settle();
    clubs.complete('a', clubA);
    await settle();
    expectClub(clubA, 'Rouge');

    auth.signOutForTest();
    await settle();
    expectNeutral();
  });
}

/// Répond aux demandes de club quand le test le décide, compte par compte.
class _ControlledClubRepository implements ClubRepository {
  _ControlledClubRepository(this._currentProfileId);

  final String Function() _currentProfileId;
  final Map<String, List<Completer<Club>>> _pending = {};

  @override
  Future<Club> fetchMyClub() {
    final completer = Completer<Club>();
    _pending.putIfAbsent(_currentProfileId(), () => []).add(completer);
    return completer.future;
  }

  void complete(String profileId, Club club) {
    for (final completer in _pending.remove(profileId) ?? const []) {
      completer.complete(club);
    }
  }

  void fail(String profileId) {
    for (final completer in _pending.remove(profileId) ?? const []) {
      completer.completeError(StateError('réseau indisponible'));
    }
  }

  @override
  String? logoUrl(Club club) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SwitchableAuthController extends AuthController {
  _SwitchableAuthController(AuthProfile profile)
      : this._(_FixedAuthRepository(profile));

  _SwitchableAuthController._(this._repository) : super(_repository) {
    switchTo(_repository.profile);
  }

  final _FixedAuthRepository _repository;

  /// Change de compte comme après une déconnexion puis une reconnexion.
  void switchTo(AuthProfile profile) {
    _repository.profile = profile;
    state = AuthState(
      isLoading: false,
      isAuthenticated: true,
      hasSession: true,
      profile: profile,
    );
  }

  void signOutForTest() {
    state = const AuthState(isLoading: false);
  }
}

class _FixedAuthRepository implements AuthRepository {
  _FixedAuthRepository(this.profile);

  AuthProfile profile;

  @override
  Stream<supabase.AuthState> get authStateChanges => const Stream.empty();

  @override
  bool get hasSession => true;

  @override
  Future<AuthProfile?> fetchProfile({bool retryAfterSignIn = false}) async =>
      profile;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
