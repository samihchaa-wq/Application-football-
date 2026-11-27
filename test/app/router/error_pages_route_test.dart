import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petit_filet/app/router/app_router.dart';
import 'package:petit_filet/app/router/not_found_page.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/features/auth/data/auth_repository.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Audit point 23 : adresse inconnue et ancienne adresse du direct.
void main() {
  late ProviderContainer container;
  late GoRouter router;

  setUp(() async {
    container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith((ref) => _TestAuthController()),
      ],
    );
    await Future<void>.delayed(Duration.zero);
    router = container.read(appRouterProvider);
  });

  tearDown(() => container.dispose());

  test('une adresse inconnue ne correspond à aucune page', () {
    final match = router.configuration.findMatch(Uri.parse('/nimportequoi'));
    expect(match.isError, isTrue);
  });

  test('/matches/<id>/live est une adresse connue, redirigée vers le direct',
      () {
    final match = router.configuration.findMatch(
      Uri.parse('/matches/abc/live'),
    );
    expect(match.isError, isFalse);
    expect(match.last.route, isA<GoRoute>());
    expect(match.last.route.redirect, isNotNull);
    expect(liveRedirectLocation('abc'), '/matches/abc/lineup?section=live');

    final target = router.configuration.findMatch(
      Uri.parse(liveRedirectLocation('abc')),
    );
    expect(target.isError, isFalse);
  });

  test('la fiche joueur et son classement sont des sous-pages de /stats', () {
    final card = router.configuration.findMatch(
      Uri.parse('/stats/joueur?profil=p-1'),
    );
    expect(card.isError, isFalse);
    // La page Statistiques reste dessous : le retour y ramène.
    final paths = <String>[];
    void collect(List<RouteMatchBase> matches) {
      for (final m in matches) {
        if (m is ShellRouteMatch) {
          collect(m.matches);
        } else if (m.route is GoRoute) {
          paths.add((m.route as GoRoute).path);
        }
      }
    }

    collect(card.matches);
    expect(paths, ['/stats', 'joueur']);

    final ranking = router.configuration.findMatch(
      Uri.parse('/stats/joueur/classement?profil=p-1&stat=buts'),
    );
    expect(ranking.isError, isFalse);
  });

  testWidgets('la page introuvable dit ce qui se passe et ramène au calendrier',
      (tester) async {
    final testRouter = GoRouter(
      initialLocation: '/nimportequoi',
      errorBuilder: (_, state) => NotFoundPage(location: state.uri.toString()),
      routes: [
        GoRoute(
          path: '/matches',
          builder: (_, __) => const Scaffold(body: Text('calendrier')),
        ),
      ],
    );
    addTearDown(testRouter.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: testRouter),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page introuvable'), findsNWidgets(2));
    expect(find.textContaining('/nimportequoi'), findsOneWidget);

    await tester.tap(find.text('Retour au calendrier'));
    await tester.pumpAndSettle();
    expect(find.text('calendrier'), findsOneWidget);
  });
}

class _TestAuthController extends AuthController {
  _TestAuthController() : super(_FakeAuthRepository());
}

class _FakeAuthRepository implements AuthRepository {
  final StreamController<supabase.AuthState> _events =
      StreamController<supabase.AuthState>.broadcast();

  @override
  Stream<supabase.AuthState> get authStateChanges => _events.stream;

  @override
  bool get hasSession => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
