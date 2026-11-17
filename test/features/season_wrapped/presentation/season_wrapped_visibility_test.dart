import 'package:as_grinta/app/router/auth_redirect.dart';
import 'package:as_grinta/core/sync/shared_data_sync.dart';
import 'package:as_grinta/features/auth/domain/auth_profile.dart';
import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:as_grinta/features/season_wrapped/data/season_wrapped_repository.dart';
import 'package:as_grinta/features/season_wrapped/presentation/season_wrapped_entry_button.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

void main() {
  testWidgets(
    'un admin ne voit plus Wrapped pendant une saison ouverte',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clubModulesProvider.overrideWith(
              (ref) async => const ClubModules.allEnabled(),
            ),
            seasonWrappedStateProvider.overrideWith(
              (ref) async => const SeasonWrappedState.unavailable(),
            ),
            isAdminViewProvider.overrideWithValue(true),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SeasonWrappedEntryButton()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('season-wrapped-button')),
        findsNothing,
      );
    },
  );

  testWidgets('Wrapped réapparaît lorsqu’un vrai bilan est disponible',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubModulesProvider.overrideWith(
            (ref) async => const ClubModules.allEnabled(),
          ),
          seasonWrappedStateProvider.overrideWith(
            (ref) async => const SeasonWrappedState(
              available: true,
              seasonName: '2026-2027',
            ),
          ),
          isAdminViewProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SeasonWrappedEntryButton()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('season-wrapped-button')),
      findsOneWidget,
    );
  });

  testWidgets('la synchronisation fait apparaître la vidéo après la clôture', (
    tester,
  ) async {
    final repository = _WrappedRepository();
    final container = ProviderContainer(
      overrides: [
        clubModulesProvider.overrideWith(
          (ref) async => const ClubModules.allEnabled(),
        ),
        seasonWrappedRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: SeasonWrappedEntryButton()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await container.read(mySeasonWrappedProvider.future);
    expect(find.byKey(const ValueKey('season-wrapped-button')), findsNothing);

    repository.available = true;
    container
        .read(sharedDataRefreshCoordinatorProvider)
        .invalidateForSessionChange();
    await tester.pumpAndSettle();
    await container.read(mySeasonWrappedProvider.future);
    expect(find.byKey(const ValueKey('season-wrapped-button')), findsOneWidget);
    expect(repository.mineReads, 2);

    repository.available = false; // Ouverture de la saison suivante.
    container
        .read(sharedDataRefreshCoordinatorProvider)
        .invalidateForSessionChange();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('season-wrapped-button')), findsNothing);
  });

  test('le lien d’aperçu Wrapped est bloqué même pour un admin', () {
    const state = AuthState(
      isLoading: false,
      isAuthenticated: true,
      hasSession: true,
      profile: _adminProfile,
    );

    expect(
      resolveAuthRedirect(
        authState: state,
        uri: Uri.parse('/wrapped?apercu=1'),
        matchedLocation: '/wrapped',
      ),
      '/matches',
    );

    // La vraie route reste disponible : son contenu est ensuite servi par les
    // RPC uniquement lorsque le bilan d’intersaison existe réellement.
    expect(
      resolveAuthRedirect(
        authState: state,
        uri: Uri.parse('/wrapped'),
        matchedLocation: '/wrapped',
      ),
      isNull,
    );
  });
}

const _adminProfile = AuthProfile(
  id: 'admin',
  firstName: 'Admin',
  lastName: 'One',
  role: AuthRole.admin,
  isGoalkeeper: false,
  isActive: true,
  mustChangePassword: false,
);

class _WrappedRepository extends SeasonWrappedRepository {
  _WrappedRepository()
      : super(SupabaseClient('https://example.invalid', 'test-key'));

  bool available = false;
  int mineReads = 0;

  @override
  Future<SeasonWrappedState> fetchState() async => SeasonWrappedState(
        available: available,
        seasonName: available ? '2026-2027' : null,
      );

  @override
  Future<SeasonWrapped?> fetchMine() async {
    mineReads++;
    return available ? demoSeasonWrapped('2026-2027') : null;
  }
}
