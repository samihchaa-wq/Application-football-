import 'package:as_grinta/app/router/auth_redirect.dart';
import 'package:as_grinta/features/auth/domain/auth_profile.dart';
import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

String? redirect(AuthState state, String path) => resolveAuthRedirect(
      authState: state,
      uri: Uri.parse(path),
      matchedLocation: Uri.parse(path).path,
    );

void main() {
  test('cold console URL survives loading and sign-in', () {
    expect(
      redirect(const AuthState(), '/control'),
      '/auth/loading?redirect=%2Fcontrol',
    );
    expect(
      redirect(
        const AuthState(isLoading: false),
        '/auth/loading?redirect=%2Fcontrol',
      ),
      '/auth/sign-in?redirect=%2Fcontrol',
    );
    expect(
      redirect(
        const AuthState(isLoading: false),
        '/auth/sign-in?redirect=%2Fcontrol',
      ),
      isNull,
    );
  });

  test(
      'a teamless session reaches the operator gate without joining an unrelated team',
      () {
    const auth = AuthState(isLoading: false, hasSession: true, needsClub: true);
    expect(redirect(auth, '/control'), isNull);
    expect(redirect(auth, '/auth/sign-in?redirect=%2Fcontrol'), '/control');
    expect(redirect(auth, '/auth/loading?redirect=%2Fcontrol'), '/control');
    expect(redirect(auth, '/matches'), '/auth/choose-club');
  });

  test('signed-out users cannot remain on the console', () {
    expect(
      redirect(const AuthState(isLoading: false), '/control'),
      '/auth/sign-in?redirect=%2Fcontrol',
    );
  });

  test(
    'console route preserves forced password change and inactive restrictions',
    () {
      const profile = AuthProfile(
        firstName: 'Test',
        lastName: '',
        role: AuthRole.admin,
        isGoalkeeper: false,
        isActive: true,
        mustChangePassword: true,
      );
      expect(
        redirect(
          const AuthState(isLoading: false, hasSession: true, profile: profile),
          '/control',
        ),
        '/auth/new-password',
      );
      const pending = AuthProfile(
        firstName: 'Test',
        lastName: '',
        role: AuthRole.admin,
        isGoalkeeper: false,
        isActive: false,
        status: 'pending',
        mustChangePassword: false,
      );
      expect(
        redirect(
          const AuthState(isLoading: false, hasSession: true, profile: pending),
          '/control',
        ),
        '/auth/loading',
      );
    },
  );

  test(
    'only the exact local console destination gets the teamless exception',
    () {
      const auth = AuthState(
        isLoading: false,
        hasSession: true,
        needsClub: true,
      );
      for (final path in [
        '/auth/sign-in?redirect=https://evil.invalid/control',
        '/auth/sign-in?redirect=%2F%2Fevil.invalid%2Fcontrol',
        '/control-other',
        '/control/team',
      ]) {
        expect(redirect(auth, path), '/auth/choose-club');
      }
    },
  );
}
