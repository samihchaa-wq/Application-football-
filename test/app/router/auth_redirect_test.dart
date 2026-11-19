import 'package:petit_filet/app/router/auth_redirect.dart';
import 'package:petit_filet/features/auth/domain/auth_profile.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAuthRedirect', () {
    test('sends loading states to the loading route without looping', () {
      const state = AuthState(isLoading: true);

      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/matches'),
          matchedLocation: '/matches',
        ),
        '/auth/loading?redirect=%2Fmatches',
      );
      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/auth/loading'),
          matchedLocation: '/auth/loading',
        ),
        isNull,
      );
    });

    test(
      'keeps sign-in mounted while an authentication request is loading',
      () {
        const state = AuthState(isLoading: true);

        expect(
          resolveAuthRedirect(
            authState: state,
            uri: Uri.parse('/auth/sign-in'),
            matchedLocation: '/auth/sign-in',
          ),
          isNull,
        );
        expect(
          resolveAuthRedirect(
            authState: state,
            uri: Uri.parse('/auth/sign-in?redirect=%2Fstats'),
            matchedLocation: '/auth/sign-in',
          ),
          isNull,
        );
      },
    );

    test('keeps a signed-in account without a club on the club step', () {
      const state = AuthState(
        isLoading: false,
        hasSession: true,
        needsClub: true,
      );

      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/matches'),
          matchedLocation: '/matches',
        ),
        '/auth/choose-club',
      );
      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/auth/choose-club'),
          matchedLocation: '/auth/choose-club',
        ),
        isNull,
      );
    });

    test('preserves invitations for a connected account without a club', () {
      const state = AuthState(
        isLoading: false,
        hasSession: true,
        needsClub: true,
      );
      for (final path in [
        '/auth/register?code=ABCDEFGH',
        '/auth/loading?redirect=%2Fauth%2Fregister%3Fcode%3DABCDEFGH',
      ]) {
        final uri = Uri.parse(path);
        expect(
          resolveAuthRedirect(
            authState: state,
            uri: uri,
            matchedLocation: uri.path,
          ),
          '/auth/choose-club?code=ABCDEFGH',
        );
      }
    });

    test('retains a club invitation through cold startup without a loop', () {
      final uri = Uri.parse('/auth/choose-club?code=ABCDEFGH');
      final loading = resolveAuthRedirect(
        authState: const AuthState(),
        uri: uri,
        matchedLocation: uri.path,
      )!;
      final ready = resolveAuthRedirect(
        authState: const AuthState(
          isLoading: false,
          hasSession: true,
          needsClub: true,
        ),
        uri: Uri.parse(loading),
        matchedLocation: '/auth/loading',
      );
      expect(ready, '/auth/choose-club?code=ABCDEFGH');
      expect(
        resolveAuthRedirect(
          authState: const AuthState(
            isLoading: false,
            hasSession: true,
            needsClub: true,
          ),
          uri: Uri.parse(ready!),
          matchedLocation: '/auth/choose-club',
        ),
        isNull,
      );
    });

    test(
      'ignores invitation codes from unrelated or external destinations',
      () {
        const state = AuthState(
          isLoading: false,
          hasSession: true,
          needsClub: true,
        );
        for (final target in [
          '/matches?code=ABCDEFGH',
          'https://evil.test/auth/register?code=ABCDEFGH',
          '//evil.test/auth/register?code=ABCDEFGH',
        ]) {
          final uri = Uri(
            path: '/auth/loading',
            queryParameters: {'redirect': target},
          );
          expect(
            resolveAuthRedirect(
              authState: state,
              uri: uri,
              matchedLocation: uri.path,
            ),
            '/auth/choose-club',
          );
        }
      },
    );

    test('lets the e-mail confirmation link open while signed out', () {
      const state = AuthState(isLoading: false);

      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/auth/confirm-email?token=abc'),
          matchedLocation: '/auth/confirm-email',
        ),
        isNull,
      );
    });

    test('lets the legal texts open signed out, loading or signed in', () {
      for (final state in const [
        AuthState(isLoading: false),
        AuthState(isLoading: true),
      ]) {
        expect(
          resolveAuthRedirect(
            authState: state,
            uri: Uri.parse('/legal/cgu'),
            matchedLocation: '/legal/cgu',
          ),
          isNull,
        );
      }
    });

    test('carries the recovery destination through the loading route', () {
      const loading = AuthState(isLoading: true);

      expect(
        resolveAuthRedirect(
          authState: loading,
          uri: Uri.parse('/auth/new-password?recovery=1'),
          matchedLocation: '/auth/new-password',
        ),
        '/auth/loading?redirect=%2Fauth%2Fnew-password%3Frecovery%3D1',
      );

      const resolved = AuthState(isLoading: false);

      expect(
        resolveAuthRedirect(
          authState: resolved,
          uri: Uri.parse(
            '/auth/loading?redirect=%2Fauth%2Fnew-password%3Frecovery%3D1',
          ),
          matchedLocation: '/auth/loading',
        ),
        '/auth/new-password?recovery=1',
      );
    });

    test('carries registration through the initial loading route', () {
      const loading = AuthState(isLoading: true);

      expect(
        resolveAuthRedirect(
          authState: loading,
          uri: Uri.parse('/auth/register'),
          matchedLocation: '/auth/register',
        ),
        '/auth/loading?redirect=%2Fauth%2Fregister',
      );

      const signedOut = AuthState(isLoading: false);

      expect(
        resolveAuthRedirect(
          authState: signedOut,
          uri: Uri.parse('/auth/loading?redirect=%2Fauth%2Fregister'),
          matchedLocation: '/auth/loading',
        ),
        '/auth/register',
      );

      const authenticated = AuthState(
        isLoading: false,
        isAuthenticated: true,
        hasSession: true,
        profile: _userProfile,
      );

      expect(
        resolveAuthRedirect(
          authState: authenticated,
          uri: Uri.parse('/auth/loading?redirect=%2Fauth%2Fregister'),
          matchedLocation: '/auth/loading',
        ),
        '/matches',
      );
    });

    test('restores a non-auth destination after signing in', () {
      const state = AuthState(isLoading: false);

      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/auth/loading?redirect=%2Fmatches%2Fabc'),
          matchedLocation: '/auth/loading',
        ),
        '/auth/sign-in?redirect=%2Fmatches%2Fabc',
      );
    });

    test(
      'leaves the loading route once loading finishes without a session',
      () {
        const state = AuthState(isLoading: false);

        expect(
          resolveAuthRedirect(
            authState: state,
            uri: Uri.parse('/auth/loading'),
            matchedLocation: '/auth/loading',
          ),
          '/auth/sign-in',
        );
      },
    );

    test(
      'keeps a valid session on loading while the profile is unavailable',
      () {
        const state = AuthState(
          isLoading: false,
          hasSession: true,
          error: 'Connexion temporairement indisponible.',
        );

        expect(
          resolveAuthRedirect(
            authState: state,
            uri: Uri.parse('/matches'),
            matchedLocation: '/matches',
          ),
          '/auth/loading?redirect=%2Fmatches',
        );
        expect(
          resolveAuthRedirect(
            authState: state,
            uri: Uri.parse('/auth/loading'),
            matchedLocation: '/auth/loading',
          ),
          isNull,
        );
      },
    );

    test('preserves the requested local path for signed-out users', () {
      const state = AuthState(isLoading: false);

      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/matches/abc?tab=stats'),
          matchedLocation: '/matches/abc',
        ),
        '/auth/sign-in?redirect=%2Fmatches%2Fabc%3Ftab%3Dstats',
      );
    });

    test('allows signed-out users to remain on auth routes', () {
      const state = AuthState(isLoading: false);

      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/auth/register'),
          matchedLocation: '/auth/register',
        ),
        isNull,
      );
    });

    test('forces password renewal before all other authenticated routes', () {
      const state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        hasSession: true,
        profile: _passwordChangeProfile,
      );

      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/matches'),
          matchedLocation: '/matches',
        ),
        '/auth/new-password',
      );
      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/auth/new-password'),
          matchedLocation: '/auth/new-password',
        ),
        isNull,
      );
    });

    test('redirects authenticated users away from auth routes', () {
      const state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        hasSession: true,
        profile: _userProfile,
      );

      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/auth/sign-in?redirect=%2Fprofile'),
          matchedLocation: '/auth/sign-in',
        ),
        '/profile',
      );
    });

    test('rejects external and auth redirect targets', () {
      const state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        hasSession: true,
        profile: _userProfile,
      );

      for (final target in <String>[
        'https://example.com',
        '//example.com/path',
        '/auth/register',
      ]) {
        final uri = Uri(
          path: '/auth/sign-in',
          queryParameters: {'redirect': target},
        );
        expect(
          resolveAuthRedirect(
            authState: state,
            uri: uri,
            matchedLocation: '/auth/sign-in',
          ),
          '/matches',
        );
      }
    });

    test('blocks privileged routes for regular users', () {
      const state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        hasSession: true,
        profile: _userProfile,
      );

      for (final route in <String>[
        '/admin',
        '/admin/administration',
        '/admin/matches',
        '/players',
        '/matches/abc/finalize',
      ]) {
        expect(
          resolveAuthRedirect(
            authState: state,
            uri: Uri.parse(route),
            matchedLocation: route,
          ),
          '/matches',
          reason: route,
        );
      }
    });

    test('blocks badge administration for regular users', () {
      const state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        hasSession: true,
        profile: _userProfile,
      );

      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/admin/badges'),
          matchedLocation: '/admin/badges',
        ),
        '/matches',
      );
    });

    test('allows the other privileged routes for administrators', () {
      const state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        hasSession: true,
        profile: _adminProfile,
      );

      for (final route in <String>[
        '/admin',
        '/admin/administration',
        '/admin/matches',
        '/players',
        '/matches/abc/finalize',
      ]) {
        expect(
          resolveAuthRedirect(
            authState: state,
            uri: Uri.parse(route),
            matchedLocation: route,
          ),
          isNull,
          reason: route,
        );
      }
    });

    test('blocks badge administration for a simple member', () {
      const state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        hasSession: true,
        profile: _userProfile,
      );

      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/admin/badges'),
          matchedLocation: '/admin/badges',
        ),
        '/matches',
      );
    });

    test('allows badge administration for any club administrator', () {
      const state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        hasSession: true,
        profile: _adminProfile,
      );

      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/admin/badges'),
          matchedLocation: '/admin/badges',
        ),
        isNull,
      );
    });

    test('normalizes root and former home aliases to Matchs', () {
      const state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        hasSession: true,
        profile: _userProfile,
      );

      for (final route in <String>['/', '/home', '/accueil']) {
        expect(
          resolveAuthRedirect(
            authState: state,
            uri: Uri.parse(route),
            matchedLocation: route,
          ),
          '/matches',
        );
      }
    });

    test('asks for the new terms before anything else in the app', () {
      const state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        hasSession: true,
        profile: _outdatedTermsProfile,
      );

      for (final route in <String>['/matches', '/stats', '/admin', '/']) {
        expect(
          resolveAuthRedirect(
            authState: state,
            uri: Uri.parse(route),
            matchedLocation: route,
          ),
          '/auth/accept-terms',
          reason: route,
        );
      }
      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/auth/accept-terms'),
          matchedLocation: '/auth/accept-terms',
        ),
        isNull,
      );
      // Les textes restent lisibles pour pouvoir les accepter.
      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/legal/cgu'),
          matchedLocation: '/legal/cgu',
        ),
        isNull,
      );
    });

    test('an account that never accepted the terms is asked too', () {
      const state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        hasSession: true,
        profile: _noTermsProfile,
      );
      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/matches'),
          matchedLocation: '/matches',
        ),
        '/auth/accept-terms',
      );
    });

    test('a temporary password is changed before the new terms', () {
      const state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        hasSession: true,
        profile: _passwordAndTermsProfile,
      );
      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/matches'),
          matchedLocation: '/matches',
        ),
        '/auth/new-password',
      );
    });

    test('leaves the terms page once the current version is accepted', () {
      const state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        hasSession: true,
        profile: _userProfile,
      );
      expect(
        resolveAuthRedirect(
          authState: state,
          uri: Uri.parse('/auth/accept-terms'),
          matchedLocation: '/auth/accept-terms',
        ),
        '/matches',
      );
      expect(
        resolveAuthRedirect(
          authState: const AuthState(isLoading: false),
          uri: Uri.parse('/auth/accept-terms'),
          matchedLocation: '/auth/accept-terms',
        ),
        '/auth/sign-in',
      );
    });
  });
}

const _userProfile = AuthProfile(
  id: 'user',
  firstName: 'User',
  lastName: 'One',
  role: AuthRole.pronostiqueur,
  isGoalkeeper: false,
  isActive: true,
  mustChangePassword: false,
);

const _adminProfile = AuthProfile(
  id: 'admin',
  firstName: 'Admin',
  lastName: 'One',
  role: AuthRole.admin,
  isGoalkeeper: false,
  isActive: true,
  mustChangePassword: false,
);

const _passwordChangeProfile = AuthProfile(
  id: 'password-change',
  firstName: 'Password',
  lastName: 'Change',
  role: AuthRole.pronostiqueur,
  isGoalkeeper: false,
  isActive: true,
  mustChangePassword: true,
);

const _outdatedTermsProfile = AuthProfile(
  id: 'outdated-terms',
  firstName: 'Old',
  lastName: 'Terms',
  role: AuthRole.pronostiqueur,
  isGoalkeeper: false,
  isActive: true,
  mustChangePassword: false,
  termsVersion: '2000-01-01',
);

const _noTermsProfile = AuthProfile(
  id: 'no-terms',
  firstName: 'No',
  lastName: 'Terms',
  role: AuthRole.pronostiqueur,
  isGoalkeeper: false,
  isActive: true,
  mustChangePassword: false,
  termsVersion: null,
);

const _passwordAndTermsProfile = AuthProfile(
  id: 'password-and-terms',
  firstName: 'Both',
  lastName: 'Pending',
  role: AuthRole.pronostiqueur,
  isGoalkeeper: false,
  isActive: true,
  mustChangePassword: true,
  termsVersion: null,
);
