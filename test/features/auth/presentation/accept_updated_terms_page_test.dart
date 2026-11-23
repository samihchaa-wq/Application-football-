import 'dart:async';

import 'package:petit_filet/features/auth/data/auth_repository.dart';
import 'package:petit_filet/features/auth/domain/auth_profile.dart';
import 'package:petit_filet/features/auth/presentation/accept_updated_terms_page.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/legal/domain/legal_documents.dart';
import 'package:petit_filet/features/profile/data/personal_data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Écran « Les conditions ont changé » : l'accord n'est envoyé qu'une fois
/// l'âge confirmé et la case cochée, avec la version en vigueur.
void main() {
  late _FakePersonalData personalData;
  late _OutdatedTermsController controller;

  Future<void> pumpPage(WidgetTester tester, {String? previousAge}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    personalData = _FakePersonalData();
    controller = _OutdatedTermsController(_FakeAuthRepository(), previousAge);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => controller),
          personalDataRepositoryProvider.overrideWithValue(personalData),
        ],
        child: const MaterialApp(home: AcceptUpdatedTermsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  ButtonStyleButton acceptButton(WidgetTester tester) =>
      tester.widget<ButtonStyleButton>(
        find.byKey(const Key('accept-updated-terms')),
      );

  testWidgets('le bouton reste grisé tant que la case n’est pas cochée',
      (tester) async {
    await pumpPage(tester);
    expect(find.text('Les conditions ont changé'), findsOneWidget);
    expect(acceptButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(const Key('register-age-15-or-more')));
    await tester.pump();
    expect(acceptButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(const Key('register-accept-terms')));
    await tester.pump();
    expect(acceptButton(tester).onPressed, isNotNull);
  });

  testWidgets('accepter envoie la version en vigueur puis recharge le profil',
      (tester) async {
    await pumpPage(tester, previousAge: 'parental_consent');

    // La déclaration d'âge déjà faite est reprise : il reste à cocher.
    await tester.tap(find.byKey(const Key('register-accept-terms')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('accept-updated-terms')));
    await tester.pumpAndSettle();

    expect(personalData.accepted, [(legalVersion, 'parental_consent')]);
    expect(controller.refreshes, 1);
  });

  testWidgets('on peut refuser en se déconnectant', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const Key('updated-terms-sign-out')));
    await tester.pumpAndSettle();
    expect(controller.signOuts, 1);
    expect(personalData.accepted, isEmpty);
  });
}

class _OutdatedTermsController extends AuthController {
  _OutdatedTermsController(super.repository, String? previousAge) {
    state = AuthState(
      isLoading: false,
      isAuthenticated: true,
      hasSession: true,
      profile: AuthProfile(
        id: 'member-1',
        firstName: 'Léa',
        lastName: 'Test',
        role: AuthRole.pronostiqueur,
        isGoalkeeper: false,
        isActive: true,
        mustChangePassword: false,
        termsVersion: '2000-01-01',
        ageConfirmation: previousAge,
      ),
    );
  }

  int refreshes = 0;
  int signOuts = 0;

  @override
  Future<void> refreshProfile() async => refreshes += 1;

  @override
  Future<void> signOut() async => signOuts += 1;
}

class _FakePersonalData implements PersonalDataRepository {
  final accepted = <(String, String)>[];

  @override
  Future<void> acceptTerms({
    required String version,
    required String ageConfirmation,
  }) async {
    accepted.add((version, ageConfirmation));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  final _events = StreamController<supabase.AuthState>.broadcast();

  @override
  Stream<supabase.AuthState> get authStateChanges => _events.stream;

  @override
  bool get hasSession => true;

  @override
  bool get currentUserHasNoClub => false;

  @override
  Future<bool> isPlatformOperator() async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
