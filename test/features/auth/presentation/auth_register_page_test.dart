import 'package:petit_filet/features/auth/presentation/auth_register_page.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/legal/domain/legal_documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'MotDePasse2026';

void main() {
  late _FakeClubRepository repository;

  setUp(() => repository = _FakeClubRepository());

  Future<void> pumpPage(
    WidgetTester tester, {
    String? code,
    Size size = const Size(900, 2200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clubRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: AuthRegisterPage(initialInviteCode: code)),
      ),
    );
  }

  Future<void> giveConsent(WidgetTester tester) async {
    final age = find.byKey(const Key('register-age-15-or-more'));
    await tester.ensureVisible(age);
    await tester.pumpAndSettle();
    await tester.tap(age);
    final terms = find.byKey(const Key('register-accept-terms'));
    await tester.ensureVisible(terms);
    await tester.pumpAndSettle();
    await tester.tap(terms);
    final contract = find.byKey(const Key('register-accept-club-contract'));
    if (contract.evaluate().isNotEmpty) {
      await tester.ensureVisible(contract);
      await tester.pumpAndSettle();
      await tester.tap(contract);
    }
    await tester.pump();
  }

  Future<void> fillIdentity(
    WidgetTester tester, {
    bool consent = true,
    String email = 'karim@example.com',
  }) async {
    await tester.enterText(find.widgetWithText(TextField, 'Prénom'), 'Karim');
    await tester.enterText(find.byKey(const Key('register-email')), email);
    await tester.enterText(find.widgetWithText(TextField, 'Nom'), 'Benali');
    await tester.enterText(
      find.widgetWithText(TextField, 'Mot de passe'),
      _password,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Répète le mot de passe'),
      _password,
    );
    if (consent) await giveConsent(tester);
  }

  testWidgets('le code reçu par le lien est déjà rempli', (tester) async {
    await pumpPage(tester, code: 'abcd-efgh');

    final field = tester.widget<TextField>(
      find.byKey(const Key('register-invite-code')),
    );
    expect(field.controller!.text, 'ABCDEFGH');
  });

  testWidgets('rejoindre un club exige un code d’invitation valide', (
    tester,
  ) async {
    await pumpPage(tester);
    await fillIdentity(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
    await tester.pump();

    expect(find.textContaining('code d’invitation'), findsWidgets);
    expect(repository.joined, isNull);
  });

  testWidgets('rejoindre un club envoie le code et annonce l’attente', (
    tester,
  ) async {
    await pumpPage(tester, code: 'ABCDEFGH');
    await fillIdentity(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
    await tester.pumpAndSettle();

    expect(repository.joined, 'ABCDEFGH');
    expect(find.text('karimb'), findsOneWidget);
    expect(find.textContaining('en attente'), findsOneWidget);
    expect(find.textContaining('FC Tests'), findsOneWidget);
  });

  testWidgets('créer un club demande son nom et annonce le rôle d’admin', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Créer un club'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('register-invite-code')), findsNothing);
    await fillIdentity(tester, email: '');

    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon club'));
    await tester.pump();
    expect(find.textContaining('Le nom du club'), findsOneWidget);
    expect(repository.created, isNull);
    ScaffoldMessenger.of(tester.element(find.byType(AuthRegisterPage)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('register-club-name')),
      'FC Villeneuve',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon club'));
    await tester.pump();
    expect(find.textContaining('indique ton adresse e-mail'), findsOneWidget);
    expect(repository.created, isNull);
    ScaffoldMessenger.of(tester.element(find.byType(AuthRegisterPage)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('register-email')),
      'karim@example.com',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon club'));
    await tester.pumpAndSettle();

    expect(repository.created, 'FC Villeneuve');
    expect(repository.lastEmail, 'karim@example.com');
    expect(repository.createdContract, clubContractVersion);
    expect(find.text('Équipe créée : FC Villeneuve'), findsOneWidget);
    expect(find.textContaining('Connecte-toi, puis'), findsOneWidget);
  });

  testWidgets('code parrain : refusé s’il est mal formé, transmis sinon', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Créer un club'));
    await tester.pumpAndSettle();
    await fillIdentity(tester);
    await tester.enterText(
      find.byKey(const Key('register-club-name')),
      'FC Villeneuve',
    );
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'karim@example.com',
    );

    await tester.enterText(
      find.byKey(const Key('register-referral-code')),
      'ABC',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon club'));
    await tester.pump();
    expect(find.textContaining('Code parrain invalide'), findsOneWidget);
    expect(repository.created, isNull);
    ScaffoldMessenger.of(tester.element(find.byType(AuthRegisterPage)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('register-referral-code')),
      'pf ab-cd23',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon club'));
    await tester.pumpAndSettle();
    expect(repository.created, 'FC Villeneuve');
    expect(repository.lastReferralCode, 'PFABCD23');
  });

  testWidgets('sans code parrain, la création du club marche pareil', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Créer un club'));
    await tester.pumpAndSettle();
    await fillIdentity(tester);
    await tester.enterText(
      find.byKey(const Key('register-club-name')),
      'FC Villeneuve',
    );
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'karim@example.com',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon club'));
    await tester.pumpAndSettle();
    expect(repository.created, 'FC Villeneuve');
    expect(repository.lastReferralCode, '');
  });

  testWidgets('rejoindre un club exige une adresse e-mail', (tester) async {
    await pumpPage(tester, code: 'ABCDEFGH');
    await fillIdentity(tester, email: '');
    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
    await tester.pump();
    expect(find.textContaining('Indique ton adresse e-mail'), findsOneWidget);
    expect(repository.joined, isNull);
  });

  testWidgets('l’adresse e-mail est transmise ou refusée', (tester) async {
    await pumpPage(tester, code: 'ABCDEFGH');
    await fillIdentity(tester);
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'pas-une-adresse',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
    await tester.pump();
    expect(
      find.textContaining('adresse e-mail n’est pas valide'),
      findsOneWidget,
    );
    expect(repository.joined, isNull);
    ScaffoldMessenger.of(tester.element(find.byType(AuthRegisterPage)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('register-email')),
      'karim@example.com',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
    await tester.pumpAndSettle();
    expect(repository.lastEmail, 'karim@example.com');
  });

  testWidgets('l’inscription exige l’âge et l’acceptation des conditions', (
    tester,
  ) async {
    await pumpPage(tester, code: 'ABCDEFGH');
    await fillIdentity(tester, consent: false);

    final submit = find.widgetWithText(FilledButton, 'Créer mon compte');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    expect(submit.hitTestable(), findsOneWidget);
    await tester.tap(submit);
    await tester.pump();
    expect(find.textContaining('15 ans ou plus'), findsWidgets);
    expect(repository.joined, isNull);
    ScaffoldMessenger.of(tester.element(find.byType(AuthRegisterPage)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    await giveConsent(tester);
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    expect(submit.hitTestable(), findsOneWidget);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(repository.joined, 'ABCDEFGH');
    expect(repository.lastConsent, (
      legalVersion,
      AgeConfirmation.fifteenOrMore,
    ));
  });

  // Recette M03 : viewport logique iPhone ; aucune inscription réelle.
  // Le dépôt factice vérifie les gestes et le contrat client actuels. #160
  // doit remplacer l'ancien ageConfirmation par une naissance validée.
  testWidgets('M03 mobile : invitation et identifiant restent accessibles', (
    tester,
  ) async {
    await pumpPage(tester, code: 'abcd-efgh', size: const Size(390, 844));
    await fillIdentity(tester);
    final email = find.byKey(const Key('register-email'));
    await tester.ensureVisible(email);
    await tester.pumpAndSettle();
    await tester.enterText(email, 'karim@example.com');

    // Le champ e-mail garde le focus et ramènerait la page vers lui :
    // comme une vraie personne, on quitte le champ avant de descendre.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(FilledButton, 'Créer mon compte');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    expect(submit.hitTestable(), findsOneWidget);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(repository.joined, 'ABCDEFGH');
    expect(repository.lastEmail, 'karim@example.com');
    expect(find.text('karimb'), findsOneWidget);
    expect(find.textContaining('en attente'), findsOneWidget);
  });

  testWidgets('M03 mobile : créer une équipe reste accessible au toucher', (
    tester,
  ) async {
    await pumpPage(tester, size: const Size(390, 844));
    await tester.tap(find.text('Créer un club'));
    await tester.pumpAndSettle();
    final name = find.byKey(const Key('register-club-name'));
    await tester.ensureVisible(name);
    await tester.pumpAndSettle();
    await tester.enterText(name, 'Equipe Fictive');
    final email = find.byKey(const Key('register-email'));
    await tester.ensureVisible(email);
    await tester.pumpAndSettle();
    await tester.enterText(email, 'karim@example.com');
    await fillIdentity(tester);

    final submit = find.widgetWithText(FilledButton, 'Créer mon club');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    expect(submit.hitTestable(), findsOneWidget);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(repository.created, 'Equipe Fictive');
    expect(repository.createdContract, clubContractVersion);
    expect(find.text('Équipe créée : Equipe Fictive'), findsOneWidget);
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
  String? lastEmail;
  String? lastReferralCode;
  (String, AgeConfirmation)? lastConsent;
  String? createdContract;
  StateError? failure;

  @override
  Future<ClubRegistration> joinClub({
    required String inviteCode,
    required String firstName,
    required String lastName,
    required String password,
    required String acceptedTermsVersion,
    required AgeConfirmation ageConfirmation,
    String? email,
  }) async {
    if (failure != null) throw failure!;
    joined = inviteCode;
    lastConsent = (acceptedTermsVersion, ageConfirmation);
    lastEmail = email;
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
    required String acceptedTermsVersion,
    required String acceptedClubContractVersion,
    required AgeConfirmation ageConfirmation,
    String? email,
    String? referralCode,
  }) async {
    if (failure != null) throw failure!;
    created = clubName;
    lastReferralCode = referralCode;
    createdContract = acceptedClubContractVersion;
    lastEmail = email;
    return ClubRegistration(
      username: 'karimb',
      clubName: clubName,
      isActive: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
