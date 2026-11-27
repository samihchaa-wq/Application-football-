import 'package:petit_filet/app/router/auth_redirect.dart';
import 'package:petit_filet/features/auth/domain/auth_profile.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('blocks sports routes while the module is disabled', () {
    for (final route in <String>[
      '/admin/composition',
      '/admin/guests',
      '/admin/motm',
    ]) {
      expect(
        resolveAuthRedirect(
          authState: _adminState,
          uri: Uri.parse(route),
          matchedLocation: route,
          sportsManagementEnabled: false,
        ),
        '/matches',
      );
    }
  });

  test('a match sheet falls back to its prono while the module is disabled',
      () {
    expect(
      resolveAuthRedirect(
        authState: _adminState,
        uri: Uri.parse('/matches/match-1/lineup'),
        matchedLocation: '/matches/match-1/lineup',
        sportsManagementEnabled: false,
      ),
      '/matches/match-1/prediction',
    );
  });

  test('allows sports routes for an administrator when enabled', () {
    for (final route in <String>[
      '/admin/composition',
      '/admin/guests',
      '/admin/motm',
      '/matches/match-1/lineup',
    ]) {
      expect(
        resolveAuthRedirect(
          authState: _adminState,
          uri: Uri.parse(route),
          matchedLocation: route,
          sportsManagementEnabled: true,
        ),
        isNull,
      );
    }
  });

  test('still blocks sports admin routes for a regular player', () {
    for (final route in <String>[
      '/admin/composition',
      '/admin/guests',
      '/admin/motm',
    ]) {
      expect(
        resolveAuthRedirect(
          authState: _playerState,
          uri: Uri.parse(route),
          matchedLocation: route,
          sportsManagementEnabled: true,
        ),
        '/matches',
      );
    }
  });

  test('un joueur qui ouvre la compo d’admin voit la fiche joueur', () {
    expect(
      resolveAuthRedirect(
        authState: _playerState,
        uri: Uri.parse('/matches/match-1/composition?step=composition'),
        matchedLocation: '/matches/match-1/composition',
        sportsManagementEnabled: true,
      ),
      '/matches/match-1/lineup?section=composition',
    );
    expect(
      resolveAuthRedirect(
        authState: _playerState,
        uri: Uri.parse('/matches/match-1/composition?step=live'),
        matchedLocation: '/matches/match-1/composition',
        sportsManagementEnabled: true,
      ),
      '/matches/match-1/lineup?section=live',
    );
  });

  test('après connexion, la destination d’admin est aussi refusée au joueur',
      () {
    const target = '/matches/match-1/composition?step=composition';
    final uri = Uri.parse(
      '/auth/loading?redirect=${Uri.encodeComponent(target)}',
    );
    expect(
      resolveAuthRedirect(
        authState: _playerState,
        uri: uri,
        matchedLocation: '/auth/loading',
        sportsManagementEnabled: true,
      ),
      '/matches/match-1/lineup?section=composition',
    );
    final adminUri = Uri.parse(
      '/auth/sign-in?redirect=${Uri.encodeComponent('/admin/composition')}',
    );
    expect(
      resolveAuthRedirect(
        authState: _playerState,
        uri: adminUri,
        matchedLocation: '/auth/sign-in',
        sportsManagementEnabled: true,
      ),
      '/matches',
    );
  });
}

const _adminState = AuthState(
  isLoading: false,
  isAuthenticated: true,
  profile: AuthProfile(
    id: 'admin',
    firstName: 'Admin',
    lastName: 'One',
    role: AuthRole.admin,
    isGoalkeeper: false,
    isActive: true,
    mustChangePassword: false,
  ),
);

const _playerState = AuthState(
  isLoading: false,
  isAuthenticated: true,
  profile: AuthProfile(
    id: 'player',
    firstName: 'Player',
    lastName: 'One',
    role: AuthRole.pronostiqueur,
    isGoalkeeper: false,
    isActive: true,
    mustChangePassword: false,
  ),
);
