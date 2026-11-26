import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/app/router/auth_redirect.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';

// Adresses piégées : le routeur ne doit jamais planter ni renvoyer vers un
// autre site.
const _hostile = <String>[
  '//evil.com',
  '///evil.com',
  r'/\evil.com',
  r'\\evil.com',
  'https://evil.com',
  'javascript:alert(1)',
  'data:text/html,<script>alert(1)</script>',
  '%zz',
  '/%',
  '/%E0%A4%A',
  '/a b',
  '/\u0000',
  '/..%2f..%2fauth',
  '/matches?redirect=//evil.com',
  '/auth/loading?redirect=/auth/loading',
  '',
  '/',
  ':::',
  'http://[::1',
];

void main() {
  test('adresses hostiles : jamais d exception, jamais de sortie du site', () {
    final states = <AuthState>[
      const AuthState(isLoading: true),
      const AuthState(isLoading: false),
      const AuthState(isLoading: false, hasSession: true),
      const AuthState(
          isLoading: false, isAuthenticated: true, hasSession: true),
      const AuthState(isLoading: false, hasSession: true, needsClub: true),
      const AuthState(
        isLoading: false,
        isAuthenticated: true,
        hasSession: true,
        isPlatformOperator: true,
      ),
    ];
    final paths = [
      '/auth/sign-in',
      '/auth/loading',
      '/auth/register',
      '/matches',
      '/control',
      '/auth/choose-club'
    ];
    var runs = 0;
    for (final state in states) {
      for (final bad in _hostile) {
        for (final path in paths) {
          final uris = <Uri?>[
            Uri.tryParse('$path?redirect=${Uri.encodeComponent(bad)}'),
            Uri.tryParse('$path?redirect=$bad'),
            Uri.tryParse('$path?code=${Uri.encodeComponent(bad)}'),
          ];
          for (final uri in uris) {
            if (uri == null) continue;
            runs++;
            for (final sports in [null, true, false]) {
              final out = resolveAuthRedirect(
                authState: state,
                uri: uri,
                matchedLocation: path,
                sportsManagementEnabled: sports,
              );
              if (out != null) {
                final parsed = Uri.tryParse(out);
                expect(parsed, isNotNull, reason: '$state $uri -> $out');
                expect(parsed!.hasScheme || parsed.hasAuthority, isFalse,
                    reason: '$state $uri -> $out');
                expect(out.startsWith('//'), isFalse, reason: '$uri -> $out');
              }
            }
          }
        }
      }
    }
    expect(runs, greaterThan(500));
  });
}
