import 'dart:async';
import 'dart:typed_data';

import 'package:petit_filet/core/storage/player_photo_mode.dart';
import 'package:petit_filet/features/admin/data/admin_repository.dart';
import 'package:petit_filet/features/auth/data/auth_repository.dart';
import 'package:petit_filet/features/auth/domain/auth_profile.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/feature_flags/presentation/feature_flags_controller.dart';
import 'package:petit_filet/features/more/presentation/more_page.dart';
import 'package:petit_filet/features/more/presentation/calendar_subscription_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

const _admin = AuthProfile(
  id: 'admin',
  username: 'karim.b',
  firstName: 'Karim',
  lastName: 'Benali',
  role: AuthRole.admin,
  isGoalkeeper: false,
  isActive: true,
  mustChangePassword: false,
);

const _player = AuthProfile(
  id: 'player',
  username: 'julien',
  firstName: 'Julien',
  lastName: 'Martin',
  role: AuthRole.pronostiqueur,
  isGoalkeeper: false,
  isActive: true,
  mustChangePassword: false,
);

/// Pages cibles réduites à leur chemin : le test vérifie où mène chaque
/// ligne, pas le contenu des écrans ouverts.
const _destinations = [
  '/profile',
  '/notification-settings',
  '/unavailability',
  '/waitlist',
  '/admin/waitlist',
  '/admin',
  '/admin/stadiums',
  '/admin/club',
  '/admin/history',
  '/admin/abonnement',
  '/effectif',
  '/legal/confidentialite',
  '/legal/cgu',
  '/legal/mentions',
];

Future<_FakeAuthRepository> _pumpMorePage(
  WidgetTester tester, {
  required AuthProfile profile,
  required bool sportsEnabled,
  _FakeClubAdminRepository? clubRepository,
  List<String>? regenerations,
}) async {
  final repository = _FakeAuthRepository(profile);
  final club = clubRepository ?? _FakeClubAdminRepository();
  final router = GoRouter(
    initialLocation: '/more',
    routes: [
      GoRoute(path: '/more', builder: (_, __) => const MorePage()),
      for (final path in _destinations)
        GoRoute(
          path: path,
          builder: (_, __) => Scaffold(body: Text('page $path')),
        ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => AuthController(repository),
        ),
        sportsManagementEnabledProvider.overrideWithValue(sportsEnabled),
        adminRepositoryProvider.overrideWithValue(club),
        calendarSubscriptionLinkProvider.overrideWithValue(
          () async => Uri.parse(
            'https://example.supabase.co/functions/v1/calendar-feed?token=00000000-0000-4000-8000-000000000001',
          ),
        ),
        calendarSubscriptionRegenerateProvider.overrideWithValue(() async {
          regenerations?.add('regenerate');
          return Uri.parse(
            'https://example.supabase.co/functions/v1/calendar-feed?token=00000000-0000-4000-8000-000000000002',
          );
        }),
        adminDashboardProvider.overrideWith(
          (ref) => ref.read(adminRepositoryProvider).fetchDashboard(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets(
    'chacun trouve dans Paramètres comment installer l’appli, iPhone ou '
    'Android',
    (tester) async {
      await _pumpMorePage(tester, profile: _player, sportsEnabled: false);

      await tester.tap(find.byKey(const Key('more-install-app')));
      await tester.pumpAndSettle();

      expect(find.text('Installer l’appli sur ton téléphone'), findsOneWidget);
      expect(find.text('iPhone'), findsOneWidget);
      expect(find.text('Android'), findsOneWidget);
    },
  );

  testWidgets('an admin sees the account card and both setting groups', (
    tester,
  ) async {
    // Grand écran de téléphone : avec les réglages du club, la page dépasse
    // la petite fenêtre de test par défaut.
    tester.view
      ..physicalSize = const Size(1170, 3300)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await _pumpMorePage(tester, profile: _admin, sportsEnabled: true);

    expect(find.text('Karim Benali'), findsOneWidget);
    expect(find.text('@karim.b · Admin'), findsOneWidget);
    // La carte du compte remplace l'ancienne ligne « Profil ».
    expect(find.text('Profil'), findsNothing);

    expect(find.text('MON COMPTE'), findsOneWidget);
    expect(find.text('Apple Calendrier, Google Agenda, Outlook'), findsNothing);
    expect(find.text('CLUB · ADMIN'), findsOneWidget);
    // Les réglages de notifications ont leur ligne ici ; l'historique reste
    // derrière la cloche de l'en-tête.
    expect(find.text('Notifications'), findsOneWidget);
    for (final title in [
      'Synchroniser mon calendrier',
      'Indisponibilité',
      'Liste d’attente',
      'Effectif',
      'Équipes & stades',
      'Réglages du club',
      'Ajouter des matchs passés',
      'Abonnement',
      'Confidentialité',
      'Conditions d’utilisation',
      'Mentions légales',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    expect(find.text('Administration'), findsNothing);
    expect(find.text('Saisons'), findsNothing);
    // Finir la saison est rangé dans les Réglages du club.
    expect(find.text('Finir la saison'), findsNothing);
    expect(find.text('INFORMATIONS LÉGALES'), findsOneWidget);
    // Le bouton de déconnexion reste présent, après un défilement sur
    // téléphone.
    await tester.scrollUntilVisible(
      find.text('Se déconnecter'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Se déconnecter'), findsOneWidget);

    // Les deux groupes sont chacun une seule carte.
    expect(
      find.ancestor(
          of: find.text('Indisponibilité'), matching: find.byType(Card)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Indisponibilité'),
          matching: find.byType(Card),
        ),
        matching: find.text('Liste d’attente'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('an admin opens the stadiums directly from Paramètres', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await _pumpMorePage(tester, profile: _admin, sportsEnabled: true);

    expect(find.text('Réglages'), findsNothing);
    expect(find.text('Équipes & stades'), findsOneWidget);
    await tester.ensureVisible(find.text('Équipes & stades'));
    await tester.tap(find.text('Équipes & stades'));
    await tester.pumpAndSettle();
    expect(find.text('page /admin/stadiums'), findsOneWidget);
  });

  testWidgets('an admin opens the subscription from Paramètres', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1170, 3000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await _pumpMorePage(tester, profile: _admin, sportsEnabled: true);

    await tester.ensureVisible(find.text('Abonnement'));
    await tester.tap(find.text('Abonnement'));
    await tester.pumpAndSettle();
    expect(find.text('page /admin/abonnement'), findsOneWidget);
  });

  testWidgets('a player opens the read-only roster from Paramètres', (
    tester,
  ) async {
    await _pumpMorePage(tester, profile: _player, sportsEnabled: false);

    await tester.tap(find.text('Effectif'));
    await tester.pumpAndSettle();
    expect(find.text('page /effectif'), findsOneWidget);
  });

  testWidgets('a player opens the legal texts from Paramètres', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1170, 3000)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await _pumpMorePage(tester, profile: _player, sportsEnabled: false);

    await tester.ensureVisible(find.text('Mentions légales'));
    await tester.tap(find.text('Mentions légales'));
    await tester.pumpAndSettle();
    expect(find.text('page /legal/mentions'), findsOneWidget);
  });

  testWidgets('a player without sports management only sees their account', (
    tester,
  ) async {
    // Écran haut : toute la liste est construite, « Se déconnecter » compris
    // (l'entrée « Installer l'appli » l'a poussé sous le bas d'un 800×600).
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpMorePage(tester, profile: _player, sportsEnabled: false);

    expect(find.text('Julien Martin'), findsOneWidget);
    expect(find.text('@julien · Utilisateur'), findsOneWidget);
    // L'abonnement aux matchs reste disponible même sans gestion sportive.
    expect(find.text('MON COMPTE'), findsOneWidget);
    expect(find.text('Synchroniser mon calendrier'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Se déconnecter'), findsOneWidget);

    expect(find.text('CLUB · ADMIN'), findsNothing);
    // Effectif en lecture seule, ouvert à tous les membres.
    expect(find.text('Effectif'), findsOneWidget);
    expect(find.text('Réglages du club'), findsNothing);
    expect(find.text('Équipes & stades'), findsNothing);
    expect(find.text('Finir la saison'), findsNothing);
    expect(find.text('Abonnement'), findsNothing);
    expect(find.text('Indisponibilité'), findsNothing);
    expect(find.text('Liste d’attente'), findsNothing);
  });

  testWidgets(
    'un joueur peut ouvrir les choix de calendrier depuis les paramètres',
    (tester) async {
      await _pumpMorePage(tester, profile: _player, sportsEnabled: false);

      await tester.tap(find.text('Synchroniser mon calendrier'));
      await tester.pumpAndSettle();
      expect(find.text('S’abonner au calendrier'), findsOneWidget);
      expect(find.text('Apple Calendrier'), findsOneWidget);
      expect(find.text('Google Agenda'), findsOneWidget);
      expect(find.text('Outlook'), findsOneWidget);
      expect(find.text('Copier le lien du calendrier'), findsOneWidget);
    },
  );

  testWidgets(
    'changer le lien du calendrier demande confirmation, puis rouvre les choix',
    (tester) async {
      tester.view
        ..physicalSize = const Size(1170, 3000)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final regenerations = <String>[];
      await _pumpMorePage(
        tester,
        profile: _player,
        sportsEnabled: false,
        regenerations: regenerations,
      );

      await tester.tap(find.text('Synchroniser mon calendrier'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('calendar-subscription-regenerate')),
      );
      await tester.pumpAndSettle();

      // Annuler ne change rien.
      expect(find.text('Changer le lien du calendrier ?'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(regenerations, isEmpty);

      await tester.tap(find.text('Synchroniser mon calendrier'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('calendar-subscription-regenerate')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('calendar-subscription-regenerate-confirm')),
      );
      await tester.pumpAndSettle();

      expect(regenerations, ['regenerate']);
      expect(
        find.text('Nouveau lien créé. L’ancien ne fonctionne plus.'),
        findsOneWidget,
      );
      expect(find.text('S’abonner au calendrier'), findsOneWidget);
    },
  );

  testWidgets('the account card is announced as a single button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpMorePage(tester, profile: _admin, sportsEnabled: true);

    expect(
      tester.getSemantics(find.text('Karim Benali')),
      isSemantics(
        label: 'Karim Benali\n@karim.b · Admin',
        hint: 'Ouvrir le profil',
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('MON COMPTE')),
      isSemantics(label: 'Mon compte', isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('the account card opens the profile', (tester) async {
    await _pumpMorePage(tester, profile: _player, sportsEnabled: true);

    await tester.tap(find.text('Julien Martin'));
    await tester.pumpAndSettle();

    expect(find.text('page /profile'), findsOneWidget);
  });

  testWidgets('a player opens the read-only waitlist', (tester) async {
    await _pumpMorePage(tester, profile: _player, sportsEnabled: true);

    await tester.tap(find.text('Liste d’attente'));
    await tester.pumpAndSettle();

    expect(find.text('page /waitlist'), findsOneWidget);
  });

  testWidgets('an admin opens the editable waitlist', (tester) async {
    await _pumpMorePage(tester, profile: _admin, sportsEnabled: true);

    await tester.tap(find.text('Liste d’attente'));
    await tester.pumpAndSettle();

    expect(find.text('page /admin/waitlist'), findsOneWidget);
  });

  testWidgets('sign out asks for confirmation before disconnecting', (
    tester,
  ) async {
    final repository = await _pumpMorePage(
      tester,
      profile: _player,
      sportsEnabled: true,
    );

    // Les informations légales poussent le bouton sous le bas de l'écran.
    await tester.scrollUntilVisible(
      find.text('Se déconnecter'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(find.text('Se déconnecter\u00A0?'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(repository.signOutCalls, 0);

    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Se déconnecter'),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.signOutCalls, 1);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  bool get currentUserHasNoClub => false;

  @override
  Future<bool> isPlatformOperator() async => false;

  @override
  ({String firstName, String lastName}) get suggestedNames =>
      (firstName: '', lastName: '');

  _FakeAuthRepository(this.profile);

  final AuthProfile profile;
  int signOutCalls = 0;
  final StreamController<supabase.AuthState> _events =
      StreamController<supabase.AuthState>.broadcast();

  @override
  Stream<supabase.AuthState> get authStateChanges => _events.stream;

  @override
  bool get hasSession => true;

  @override
  Future<AuthProfile?> fetchProfile({bool retryAfterSignIn = false}) async =>
      profile;

  @override
  Future<void> signInWithUsername({
    required String username,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async => signOutCalls += 1;

  @override
  Future<void> updatePassword(String password) async {}

  @override
  Future<AuthProfile> updateProfile({
    required String firstName,
    required String lastName,
    String? surnom,
  }) async =>
      profile;

  @override
  Future<AuthProfile> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileExt,
    PlayerPhotoMode mode = PlayerPhotoMode.player,
  }) async =>
      profile;

  @override
  Future<String> registerAccount({
    required String firstName,
    required String lastName,
    required String password,
  }) async =>
      'test-user';
}

class _FakeClubAdminRepository implements AdminRepository {
  List<AdminSeasonItem> seasons = const [
    AdminSeasonItem(id: 's-1', name: '2026-2027', status: 'open'),
  ];
  final seasonStatusChanges = <(String, String)>[];
  final createdSeasons = <String>[];

  @override
  Future<AdminDashboardData> fetchDashboard() async => AdminDashboardData(
        profiles: const [],
        seasons: seasons,
        openSeasonId: seasons.where((s) => s.status == 'open').firstOrNull?.id,
      );

  @override
  Future<void> setSeasonStatus(String seasonId, String status) async {
    seasonStatusChanges.add((seasonId, status));
    seasons = [
      for (final season in seasons)
        if (season.id == seasonId)
          AdminSeasonItem(id: season.id, name: season.name, status: status)
        else
          season,
    ];
  }

  @override
  Future<String> createSeason(String name) async {
    createdSeasons.add(name);
    seasons = [
      AdminSeasonItem(id: 'new', name: name, status: 'open'),
      ...seasons,
    ];
    return 'new';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
