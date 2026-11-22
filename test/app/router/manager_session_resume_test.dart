import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/app/router/app_router.dart';
import 'package:petit_filet/core/storage/player_photo_mode.dart';
import 'package:petit_filet/features/auth/data/auth_repository.dart';
import 'package:petit_filet/features/auth/domain/auth_profile.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Gestionnaire déjà connecté qui rouvre l'appli sur /control : il ne doit
/// jamais retomber sur l'écran de connexion.
void main() {
  for (final noClub in [true]) {
    testWidgets('retour sur /control avec session valide (sans club: $noClub)',
        (tester) async {
      final repo = _Repo(noClub: noClub);
      final container = ProviderContainer(overrides: [
        authControllerProvider.overrideWith((ref) => AuthController(repo)),
      ]);
      addTearDown(container.dispose);
      addTearDown(repo.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ));
      final seen = <String>[];
      void note() =>
          seen.add(router.routerDelegate.currentConfiguration.uri.toString());
      router.routerDelegate.addListener(note);
      router.go('/control');
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final end = router.routerDelegate.currentConfiguration.uri.toString();
      expect(end, '/control', reason: 'chemin parcouru: $seen');
      expect(seen.where((p) => p.startsWith('/auth/sign-in')), isEmpty);
    });
  }
}

class _Repo implements AuthRepository {
  _Repo({required this.noClub});
  final bool noClub;
  final _events = StreamController<supabase.AuthState>.broadcast();
  Future<void> dispose() => _events.close();

  @override
  bool get currentUserHasNoClub => noClub;
  @override
  ({String firstName, String lastName}) get suggestedNames =>
      (firstName: '', lastName: '');
  @override
  Stream<supabase.AuthState> get authStateChanges => _events.stream;
  @override
  bool get hasSession => true;
  @override
  Future<AuthProfile?> fetchProfile({bool retryAfterSignIn = false}) async =>
      noClub
          ? null
          : const AuthProfile(
              id: 'm',
              firstName: 'G',
              lastName: 'M',
              role: AuthRole.admin,
              isGoalkeeper: false,
              isActive: true,
              mustChangePassword: false,
            );
  @override
  Future<void> signInWithUsername(
      {required String username, required String password}) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> updatePassword(String password) async {}
  @override
  Future<AuthProfile> updateProfile(
          {required String firstName,
          required String lastName,
          String? surnom}) =>
      throw UnimplementedError();
  @override
  Future<AuthProfile> uploadProfilePhoto(
          {required Uint8List bytes,
          required String fileExt,
          PlayerPhotoMode mode = PlayerPhotoMode.player}) =>
      throw UnimplementedError();
  @override
  Future<String> registerAccount(
          {required String firstName,
          required String lastName,
          required String password}) async =>
      'x';
}
