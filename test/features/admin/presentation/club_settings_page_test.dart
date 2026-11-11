import 'package:as_grinta/core/club/club_rules.dart';
import 'package:as_grinta/features/admin/presentation/club_settings_page.dart';
import 'package:as_grinta/features/badges/data/badge_inbox_repository.dart';
import 'package:as_grinta/features/badges/presentation/badge_trophy_button.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:as_grinta/features/club/data/club_subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeClubRepository repository;

  setUp(() {
    repository = _FakeClubRepository();
    ClubRules.reset();
  });
  tearDown(ClubRules.reset);

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubRepositoryProvider.overrideWithValue(repository),
          hasUnseenBadgeProvider.overrideWith((ref) => false),
          clubSubscriptionProvider.overrideWith(
            (ref) async => const ClubSubscription(
              state: ClubSubscriptionState.trialEnding,
              trialEndsAt: null,
              trialDaysLeft: 5,
              currentPeriodEnd: null,
              billablePlayers: 24,
              pricePerPlayerCents: 1000,
              basePriceCents: 0,
              yearlyAmountCents: 24000,
            ),
          ),
          clubStorageUsageProvider.overrideWith(
            (ref) async => const ClubStorageUsage(
              usedBytes: 50 * 1024 * 1024,
              quotaBytes: 200 * 1024 * 1024,
            ),
          ),
        ],
        child: const MaterialApp(home: ClubSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la page montre le nom, le code et les fonctionnalités',
      (tester) async {
    await pumpPage(tester);

    expect(find.widgetWithText(TextField, 'Nom du club'), findsOneWidget);
    expect(find.text('ABCDEFGH'), findsOneWidget);
    for (final module in ClubModule.values) {
      expect(find.text(module.label), findsOneWidget);
    }
  });

  testWidgets('l’admin voit son essai, ses joueurs facturés et son espace',
      (tester) async {
    await pumpPage(tester);

    expect(find.text('Essai gratuit : encore 5 jours'), findsOneWidget);
    expect(find.textContaining('24 joueurs'), findsOneWidget);
    expect(find.text('Total annuel : 240\u00a0€'), findsOneWidget);
    expect(find.text('50\u00a0Mo utilisés sur 200\u00a0Mo.'), findsOneWidget);
  });

  testWidgets('désactiver une fonctionnalité l’enregistre côté serveur',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('club-module-weather')));
    await tester.pumpAndSettle();

    expect(repository.modules['weather'], isFalse);
    final tile = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('club-module-weather')),
    );
    expect(tile.value, isFalse);
  });

  testWidgets('le nom du club est enregistré', (tester) async {
    await pumpPage(tester);

    await tester.enterText(
      find.byKey(const Key('club-settings-name')),
      'FC Renommé',
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(repository.club.name, 'FC Renommé');
    expect(find.text('Nom du club enregistré.'), findsOneWidget);
  });

  testWidgets('un nom trop court est refusé sans appel au serveur',
      (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('club-settings-name')), 'X');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();

    expect(repository.identityUpdates, 0);
    expect(find.textContaining('entre 2 et 80'), findsOneWidget);
  });

  testWidgets('changer le code demande confirmation puis affiche le nouveau',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Changer le code'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ne fonctionneront plus'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Changer le code'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const Key('club-settings-invite-code')),
          )
          .data,
      'NEWCODE2',
    );
  });

  testWidgets('le bouton des badges disparaît quand le club les désactive',
      (tester) async {
    repository.modules['badges'] = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubRepositoryProvider.overrideWithValue(repository),
          hasUnseenBadgeProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(home: Scaffold(body: BadgeTrophyButton())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('la page affiche les règles du club et enregistre un changement',
      (tester) async {
    await pumpPage(tester);

    expect(find.text('Règles du club'), findsOneWidget);
    expect(find.text('Fermeture des pronostics'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('club-rule-prediction_close_minutes-plus')),
    );
    await tester.tap(
      find.byKey(const ValueKey('club-rule-prediction_close_minutes-plus')),
    );
    await tester.pumpAndSettle();

    expect(repository.ruleValues['prediction_close_minutes'], 16);
    expect(find.text('16 min'), findsOneWidget);
    expect(ClubRules.predictionCloseBeforeKickoff, const Duration(minutes: 16));
  });

  testWidgets('le bouton des badges reste visible par défaut', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubRepositoryProvider.overrideWithValue(repository),
          hasUnseenBadgeProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(home: Scaffold(body: BadgeTrophyButton())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(IconButton), findsOneWidget);
  });
}

class _FakeClubRepository implements ClubRepository {
  Club club = const Club(
    id: 'club-1',
    name: 'FC Tests',
    shortName: 'FCT',
    inviteCode: 'ABCDEFGH',
  );
  final Map<String, bool> modules = {};
  int identityUpdates = 0;
  final Map<String, int> ruleValues = {'prediction_close_minutes': 15};

  List<ClubRule> _rules() => [
        for (final entry in ruleValues.entries)
          ClubRule(
            key: entry.key,
            label: 'Fermeture des pronostics',
            description: 'Minutes avant le coup d’envoi.',
            unit: 'min',
            group: 'Pronostics',
            defaultValue: 15,
            min: 0,
            max: 240,
            value: entry.value,
          ),
      ];

  @override
  Future<List<ClubRule>> fetchRules() async => _rules();

  @override
  Future<List<ClubRule>> setRule(String key, int? value) async {
    ruleValues[key] = value ?? 15;
    return _rules();
  }

  @override
  Future<Club> fetchMyClub() async => club;

  @override
  Future<ClubModules> fetchModules() async => ClubModules(Map.of(modules));

  @override
  Future<ClubModules> setModule(
    ClubModule module, {
    required bool enabled,
  }) async {
    modules[module.key] = enabled;
    return ClubModules(Map.of(modules));
  }

  @override
  Future<Club> updateIdentity({
    required String name,
    required String shortName,
  }) async {
    identityUpdates += 1;
    club = Club(
      id: club.id,
      name: name,
      shortName: shortName,
      inviteCode: club.inviteCode,
    );
    return club;
  }

  @override
  Future<String> regenerateInviteCode() async => 'NEWCODE2';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
