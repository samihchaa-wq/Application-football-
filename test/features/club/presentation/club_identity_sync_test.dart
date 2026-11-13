import 'dart:async';

import 'package:as_grinta/core/club/club_identity.dart';
import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/club/club_rules.dart';
import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:as_grinta/features/auth/data/auth_repository.dart';
import 'package:as_grinta/features/auth/domain/auth_profile.dart';
import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:as_grinta/features/club/presentation/club_identity_sync.dart';
import 'package:as_grinta/features/club/presentation/club_rules_sync.dart';
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
    ClubRules.reset();
    auth = _SwitchableAuthController(profile('a'));
    clubs = _ControlledClubRepository(() => auth.state.profile!.id!);
    container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith((ref) => auth),
        clubRepositoryProvider.overrideWithValue(clubs),
      ],
    );
    container.listen(clubIdentitySyncProvider, (_, __) {});
    container.listen(clubRulesSyncProvider, (_, __) {});
    container.listen(clubModulesProvider, (_, __) {});
  });

  tearDown(() {
    container.dispose();
    ClubIdentity.reset();
    AppTheme.resetClubColors();
    ClubKits.reset();
    ClubRules.reset();
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

  test('les modules et règles de A ne restent pas dans la session B', () async {
    await settle();
    clubs.complete('a', clubA, predictions: false, openDays: 3);
    await settle();
    expect(ClubRules.featuresOpenDays, 3);
    expect(container.read(clubModuleEnabledProvider(ClubModule.predictions)),
        isFalse);

    auth.switchTo(profile('b'));
    expect(container.read(clubModuleEnabledProvider(ClubModule.predictions)),
        isFalse);
    await settle();
    expect(ClubRules.featuresOpenDays, 6);
    clubs.complete('b', clubB, predictions: true, openDays: 9);
    await settle();
    expect(ClubRules.featuresOpenDays, 9);
    expect(container.read(clubModuleEnabledProvider(ClubModule.predictions)),
        isTrue);
  });

  test('les réponses tardives des règles et modules A sont ignorées chez B',
      () async {
    await settle();
    auth.switchTo(profile('b'));
    await settle();
    clubs.complete('b', clubB, predictions: false, openDays: 10);
    await settle();
    clubs.complete('a', clubA, predictions: true, openDays: 2);
    await settle();
    expect(ClubRules.featuresOpenDays, 10);
    expect(container.read(clubModuleEnabledProvider(ClubModule.predictions)),
        isFalse);
    expectClub(clubB, 'Vert');
  });

  test('un changement distant recharge les réglages sans changer de compte',
      () async {
    await settle();
    clubs.complete('a', clubA, predictions: true, openDays: 3);
    await settle();
    expect(container.read(clubModuleEnabledProvider(ClubModule.predictions)),
        isTrue);
    refreshClubConfiguration(container.invalidate);
    expect(container.read(clubModuleEnabledProvider(ClubModule.predictions)),
        isFalse);
    await settle();
    clubs.complete('a', clubA, predictions: false, openDays: 12);
    await settle();
    expect(ClubRules.featuresOpenDays, 12);
    expect(container.read(clubModuleEnabledProvider(ClubModule.predictions)),
        isFalse);
  });

  test('une panne réseau dans B ne conserve ni règles ni autorisation de A',
      () async {
    await settle();
    clubs.complete('a', clubA, predictions: true, openDays: 2);
    await settle();
    auth.switchTo(profile('b'));
    await settle();
    clubs.fail('b');
    await settle();
    expect(ClubRules.featuresOpenDays, 6);
    expect(container.read(clubModuleEnabledProvider(ClubModule.predictions)),
        isFalse);
    expectNeutral();
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
  final Map<String, List<Completer<ClubModules>>> _pendingModules = {};
  final Map<String, List<Completer<List<ClubRule>>>> _pendingRules = {};

  @override
  Future<ClubModules> fetchModules() {
    final completer = Completer<ClubModules>();
    _pendingModules.putIfAbsent(_currentProfileId(), () => []).add(completer);
    return completer.future;
  }

  @override
  Future<List<ClubRule>> fetchRules() {
    final completer = Completer<List<ClubRule>>();
    _pendingRules.putIfAbsent(_currentProfileId(), () => []).add(completer);
    return completer.future;
  }

  @override
  Future<Club> fetchMyClub() {
    final completer = Completer<Club>();
    _pending.putIfAbsent(_currentProfileId(), () => []).add(completer);
    return completer.future;
  }

  void complete(String profileId, Club club,
      {bool predictions = true, int openDays = 6}) {
    for (final completer in _pendingModules.remove(profileId) ?? const []) {
      completer.complete(ClubModules({'predictions': predictions}));
    }
    for (final completer in _pendingRules.remove(profileId) ?? const []) {
      completer.complete([
        ClubRule(
            key: 'features_open_days',
            label: 'Ouverture',
            description: '',
            unit: 'jours',
            group: 'Avant le match',
            defaultValue: 6,
            min: 1,
            max: 21,
            value: openDays)
      ]);
    }
    for (final completer in _pending.remove(profileId) ?? const []) {
      completer.complete(club);
    }
  }

  void fail(String profileId) {
    for (final completer in _pendingModules.remove(profileId) ?? const []) {
      completer.completeError(StateError('réseau indisponible'));
    }
    for (final completer in _pendingRules.remove(profileId) ?? const []) {
      completer.completeError(StateError('réseau indisponible'));
    }
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
