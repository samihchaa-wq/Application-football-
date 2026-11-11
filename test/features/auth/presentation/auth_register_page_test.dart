import 'package:as_grinta/features/auth/presentation/auth_register_page.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'MotDePasse2026';

void main() {
  late _FakeClubRepository repository;

  setUp(() => repository = _FakeClubRepository());

  Future<void> pumpPage(WidgetTester tester, {String? code}) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clubRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: AuthRegisterPage(initialInviteCode: code)),
      ),
    );
  }

  Future<void> fillIdentity(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextField, 'Prénom'), 'Karim');
    await tester.enterText(find.widgetWithText(TextField, 'Nom'), 'Benali');
    await tester.enterText(
      find.widgetWithText(TextField, 'Mot de passe'),
      _password,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirme ton mot de passe'),
      _password,
    );
  }

  testWidgets('le code reçu par le lien est déjà rempli', (tester) async {
    await pumpPage(tester, code: 'abcd-efgh');

    final field = tester.widget<TextField>(
      find.byKey(const Key('register-invite-code')),
    );
    expect(field.controller!.text, 'ABCDEFGH');
  });

  testWidgets('rejoindre un club exige un code d’invitation valide',
      (tester) async {
    await pumpPage(tester);
    await fillIdentity(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
    await tester.pump();

    expect(find.textContaining('code d’invitation'), findsWidgets);
    expect(repository.joined, isNull);
  });

  testWidgets('rejoindre un club envoie le code et annonce l’attente',
      (tester) async {
    await pumpPage(tester, code: 'ABCDEFGH');
    await fillIdentity(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
    await tester.pumpAndSettle();

    expect(repository.joined, 'ABCDEFGH');
    expect(find.text('karimb'), findsOneWidget);
    expect(find.textContaining('en attente'), findsOneWidget);
    expect(find.textContaining('FC Tests'), findsOneWidget);
  });

  testWidgets('créer un club demande son nom et annonce le rôle d’admin',
      (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Créer un club'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('register-invite-code')), findsNothing);
    await fillIdentity(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon club'));
    await tester.pump();
    expect(find.textContaining('nom du club'), findsOneWidget);
    expect(repository.created, isNull);
    ScaffoldMessenger.of(tester.element(find.byType(AuthRegisterPage)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('register-club-name')),
      'FC Villeneuve',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon club'));
    await tester.pumpAndSettle();

    expect(repository.created, 'FC Villeneuve');
    expect(find.text('Club créé : FC Villeneuve'), findsOneWidget);
    expect(find.textContaining('Connecte-toi, puis'), findsOneWidget);
  });

  testWidgets('le refus du serveur est affiché tel quel', (tester) async {
    repository.failure = StateError('Code d’invitation inconnu.');
    await pumpPage(tester, code: 'ABCDEFGH');
    await fillIdentity(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text('Code d’invitation inconnu.'), findsOneWidget);
  });
}

class _FakeClubRepository implements ClubRepository {
  String? joined;
  String? created;
  StateError? failure;

  @override
  Future<ClubRegistration> joinClub({
    required String inviteCode,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    if (failure != null) throw failure!;
    joined = inviteCode;
    return const ClubRegistration(
      username: 'karimb',
      clubName: 'FC Tests',
      isActive: false,
    );
  }

  @override
  Future<ClubRegistration> createClub({
    required String clubName,
    String? clubShortName,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    if (failure != null) throw failure!;
    created = clubName;
    return ClubRegistration(
      username: 'karimb',
      clubName: clubName,
      isActive: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
