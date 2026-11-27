import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/features/auth/data/auth_repository.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/feature_flags/presentation/feature_flags_controller.dart';
import 'package:petit_filet/features/matches/data/match_details_repository.dart';
import 'package:petit_filet/features/matches/presentation/match_details_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Audit point 22 : lien vers un match qui n'existe pas.
void main() {
  group('isMatchNotFoundError', () {
    test('reconnaît « introuvable » du serveur, avant et après la migration',
        () {
      for (final code in ['PT404', 'P0002', '22P02']) {
        expect(
          isMatchNotFoundError(
            supabase.PostgrestException(message: 'Match not found', code: code),
          ),
          isTrue,
          reason: code,
        );
      }
    });

    test('ne confond pas une panne avec un match introuvable', () {
      expect(
        isMatchNotFoundError(
          const supabase.PostgrestException(message: 'boom', code: '500'),
        ),
        isFalse,
      );
      expect(isMatchNotFoundError(StateError('réseau')), isFalse);
    });
  });

  Future<void> pump(WidgetTester tester, Object error) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubModulesProvider.overrideWith(
            (ref) async => const ClubModules.allEnabled(),
          ),
          matchDetailsProvider('absent').overrideWith((ref) async {
            throw error;
          }),
          authControllerProvider.overrideWith(
            (ref) => AuthController(_FakeAuthRepository()),
          ),
          sportsManagementEnabledProvider.overrideWithValue(false),
          isAdminViewProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(home: MatchDetailsPage(matchId: 'absent')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('un match introuvable le dit, sans bouton Réessayer',
      (tester) async {
    await pump(tester, const MatchNotFoundException());

    expect(find.byKey(const Key('match-not-found')), findsOneWidget);
    expect(find.text('Ce match n’existe plus.'), findsOneWidget);
    expect(find.text('Retour au calendrier'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('une panne garde le bouton Réessayer', (tester) async {
    await pump(tester, StateError('Connexion au serveur impossible.'));

    expect(find.byKey(const Key('match-not-found')), findsNothing);
    expect(find.text('Réessayer'), findsOneWidget);
  });
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
