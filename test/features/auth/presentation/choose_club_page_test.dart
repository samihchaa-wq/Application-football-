import 'package:as_grinta/features/auth/data/auth_repository.dart';
import 'package:as_grinta/features/auth/domain/auth_profile.dart';
import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:as_grinta/features/auth/presentation/choose_club_page.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class _FakeClubRepository implements ClubRepository {
  Map<String, Object?>? claimed;
  StateError? failure;

  @override
  Future<ClubRegistration> claimClub({
    required bool create,
    String? inviteCode,
    String? clubName,
    String? clubShortName,
    required String firstName,
    required String lastName,
  }) async {
    if (failure != null) throw failure!;
    claimed = {
      'create': create,
      'code': inviteCode,
      'club': clubName,
      'first': firstName,
      'last': lastName,
    };
    return const ClubRegistration(
      username: 'fabr',
      clubName: 'FC Tests',
      isActive: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthController extends AuthController {
  _FakeAuthController() : super(_NoRepository());

  int refreshes = 0;

  @override
  ({String firstName, String lastName}) get suggestedNames =>
      (firstName: 'Fab', lastName: 'Roy');

  @override
  Future<void> refreshProfile() async => refreshes++;
}

class _NoRepository implements AuthRepository {
  @override
  Stream<supabase.AuthState> get authStateChanges => const Stream.empty();

  @override
  bool get hasSession => false;

  @override
  Future<AuthProfile?> fetchProfile({bool retryAfterSignIn = false}) async =>
      null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late _FakeClubRepository clubs;
  late _FakeAuthController auth;

  setUp(() {
    clubs = _FakeClubRepository();
    auth = _FakeAuthController();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubRepositoryProvider.overrideWithValue(clubs),
          authControllerProvider.overrideWith((ref) => auth),
        ],
        child: const MaterialApp(home: ChooseClubPage()),
      ),
    );
  }

  testWidgets('le nom connu de Facebook est prérempli', (tester) async {
    await pumpPage(tester);

    expect(find.widgetWithText(TextField, 'Fab'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Roy'), findsOneWidget);
  });

  testWidgets('rejoindre exige un code valide', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Rejoindre le club'));
    await tester.pump();

    expect(find.textContaining('code d’invitation'), findsWidgets);
    expect(clubs.claimed, isNull);
  });

  testWidgets('rejoindre envoie le code puis recharge le profil',
      (tester) async {
    await pumpPage(tester);
    await tester.enterText(
      find.byKey(const Key('choose-club-code')),
      'abcd-efgh',
    );
    await tester.tap(find.text('Rejoindre le club'));
    await tester.pumpAndSettle();

    expect(clubs.claimed?['create'], false);
    expect(clubs.claimed?['code'], 'ABCDEFGH');
    expect(auth.refreshes, 1);
  });

  testWidgets('créer un club envoie son nom', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Créer un club'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('choose-club-name')),
      'FC Villeneuve',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon club'));
    await tester.pumpAndSettle();

    expect(clubs.claimed?['create'], true);
    expect(clubs.claimed?['club'], 'FC Villeneuve');
    expect(auth.refreshes, 1);
  });

  testWidgets('le refus du serveur est affiché', (tester) async {
    clubs.failure = StateError('Code d’invitation inconnu.');
    await pumpPage(tester);
    await tester.enterText(
      find.byKey(const Key('choose-club-code')),
      'ABCDEFGH',
    );
    await tester.tap(find.text('Rejoindre le club'));
    await tester.pumpAndSettle();

    expect(find.text('Code d’invitation inconnu.'), findsOneWidget);
    expect(auth.refreshes, 0);
  });
}
