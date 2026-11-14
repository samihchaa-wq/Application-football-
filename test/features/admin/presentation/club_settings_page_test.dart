import 'package:as_grinta/core/club/club_identity.dart';
import 'package:as_grinta/core/club/club_rules.dart';
import 'package:as_grinta/core/theme/app_theme.dart';
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
  tearDown(() {
    ClubIdentity.reset();
    ClubRules.reset();
    AppTheme.resetClubColors();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubModulesProvider.overrideWith(
            (ref) async => const ClubModules.allEnabled(),
          ),
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

  Future<void> openSection(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey('club-section-$key'));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('la page montre le nom, le code et les fonctionnalités', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.widgetWithText(TextField, 'Nom du club'), findsOneWidget);
    await openSection(tester, 'members');
    expect(find.text('ABCDEFGH'), findsOneWidget);
    await openSection(tester, 'matches');
    await openSection(tester, 'predictions');
    await openSection(tester, 'rewards');
    await openSection(tester, 'live');
    for (final module in ClubModule.values) {
      expect(find.text(module.label), findsOneWidget);
    }
  });

  testWidgets('l’admin voit son essai, ses joueurs facturés et son espace', (
    tester,
  ) async {
    await pumpPage(tester);

    await openSection(tester, 'subscription');
    expect(find.text('Essai gratuit : encore 5 jours'), findsOneWidget);
    expect(find.textContaining('24 joueurs'), findsOneWidget);
    expect(find.text('Total annuel : 240\u00a0€'), findsOneWidget);
    expect(find.text('50\u00a0Mo utilisés sur 200\u00a0Mo.'), findsOneWidget);
  });

  testWidgets('désactiver une fonctionnalité l’enregistre côté serveur', (
    tester,
  ) async {
    await pumpPage(tester);

    await openSection(tester, 'matches');
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

  testWidgets('un nom trop court est refusé sans appel au serveur', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('club-settings-name')), 'X');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();

    expect(repository.identityUpdates, 0);
    expect(find.textContaining('entre 2 et 80'), findsOneWidget);
  });

  testWidgets('adresse du terrain propre au club et effaçable', (tester) async {
    repository.homeAddress = 'Rue du Stade, Toulouse';
    await pumpPage(tester);
    await openSection(tester, 'matches');

    final field = find.byKey(const Key('club-settings-home-address'));
    expect(
      tester.widget<TextField>(field).controller!.text,
      'Rue du Stade, Toulouse',
    );

    await tester.ensureVisible(field);
    await tester.enterText(field, '  12 avenue des Sports, Lille  ');
    final save = find.byKey(const Key('club-settings-save-home-address'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repository.homeAddress, '12 avenue des Sports, Lille');

    await tester.enterText(field, '');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repository.homeAddress, isNull);
    expect(find.text('Adresse du terrain effacée.'), findsOneWidget);
  });

  testWidgets('le quota habituel est réglable de 1 à 30', (tester) async {
    await pumpPage(tester);
    await openSection(tester, 'squad');
    final plus = find.byKey(const Key('club-usual-squad-size-plus'));
    await tester.ensureVisible(plus);
    expect(find.text('14'), findsOneWidget);

    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(repository.usualSquadSize, 15);
    expect(find.text('15'), findsOneWidget);

    final minus = find.byKey(const Key('club-usual-squad-size-minus'));
    await tester.tap(minus);
    await tester.pumpAndSettle();
    expect(repository.usualSquadSize, 14);
  });

  testWidgets('changer le code demande confirmation puis affiche le nouveau', (
    tester,
  ) async {
    await pumpPage(tester);
    await openSection(tester, 'members');

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

  testWidgets('le bouton des badges disparaît quand le club les désactive', (
    tester,
  ) async {
    repository.modules['badges'] = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubModulesProvider.overrideWith((ref) => repository.fetchModules()),
          clubRepositoryProvider.overrideWithValue(repository),
          hasUnseenBadgeProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(home: Scaffold(body: BadgeTrophyButton())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets(
    'la page affiche les règles du club et enregistre un changement',
    (tester) async {
      await pumpPage(tester);

      await openSection(tester, 'predictions');
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
      expect(
        ClubRules.predictionCloseBeforeKickoff,
        const Duration(minutes: 16),
      );
    },
  );

  testWidgets('le mode de liste d’attente se choisit parmi trois options', (
    tester,
  ) async {
    repository.ruleValues['waitlist_mode'] = 0;
    await pumpPage(tester);
    await openSection(tester, 'squad');

    expect(find.text('Par présence l’an dernier'), findsOneWidget);
    // Pas de compteur +/- pour ce réglage.
    expect(
      find.byKey(const ValueKey('club-rule-waitlist_mode-plus')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('club-rule-waitlist_mode-select')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Par choix'), findsOneWidget);
    await tester.tap(find.text('Ordre d’arrivée').last);
    await tester.pumpAndSettle();

    expect(repository.ruleValues['waitlist_mode'], 1);
    expect(ClubRules.waitlistMode, WaitlistMode.arrivalOrder);
  });

  testWidgets('les +1 sont manuels et les anciens créneaux sont masqués', (
    tester,
  ) async {
    repository.ruleValues.addAll({
      'waitlist_mode': 0,
      'waitlist_cutoff_days': 1,
      'waitlist_cutoff_hour': 12,
    });
    await pumpPage(tester);
    await openSection(tester, 'squad');

    expect(find.textContaining('Seuls les administrateurs'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('club-info-rule-waitlist_mode')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Seuls les administrateurs'), findsOneWidget);
    expect(find.textContaining('Au coup d’envoi'), findsNothing);
    expect(
      find.byKey(const ValueKey('club-rule-waitlist_cutoff_days')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('club-rule-waitlist_cutoff_hour')),
      findsNothing,
    );
    // Les trois règles de convocation restent disponibles.
    await tester.tap(find.text('Fermer'));
    expect(
      find.byKey(const ValueKey('club-rule-waitlist_mode-select')),
      findsOneWidget,
    );
  });

  testWidgets('l’aide d’une fonction apparaît uniquement après appui sur i', (
    tester,
  ) async {
    await pumpPage(tester);
    await openSection(tester, 'matches');
    expect(find.text(ClubModule.weather.description), findsNothing);
    await tester.tap(find.byKey(const ValueKey('club-info-module-weather')));
    await tester.pumpAndSettle();
    expect(
      find.text(ClubModule.weather.description, skipOffstage: false),
      findsNothing,
    );
    expect(find.textContaining('météo prévue'), findsOneWidget);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('météo prévue'), findsNothing);
  });

  testWidgets('retirer le logo rétablit l’écusson neutre', (tester) async {
    repository.club = Club(
      id: repository.club.id,
      name: repository.club.name,
      shortName: repository.club.shortName,
      inviteCode: repository.club.inviteCode,
      logoPath: 'club-logos/club-1/1.png',
    );
    await pumpPage(tester);

    await tester.ensureVisible(find.byKey(const Key('club-logo-remove')));
    await tester.tap(find.byKey(const Key('club-logo-remove')));
    await tester.pumpAndSettle();

    expect(repository.club.logoPath, isNull);
    expect(ClubIdentity.logoUrl, isNull);
    expect(find.byKey(const Key('club-logo-remove')), findsNothing);
  });

  testWidgets('choisir une couleur l’enregistre et habille l’application', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(AppTheme.primary, AppTheme.defaultPrimary);

    await tester.tap(find.byKey(const ValueKey('club-color-primary-#D62828')));
    await tester.pumpAndSettle();

    expect(repository.club.primaryColor, '#D62828');
    expect(AppTheme.primary, isNot(AppTheme.defaultPrimary));
    // La teinte choisie est conservée (rouge), la clarté est ajustée.
    final hue = HSLColor.fromColor(AppTheme.primary).hue;
    expect(hue < 20 || hue > 340, isTrue);
  });

  testWidgets('le bouton des badges reste visible quand le module est activé',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubModulesProvider.overrideWith(
            (ref) async => const ClubModules.allEnabled(),
          ),
          clubRepositoryProvider.overrideWithValue(repository),
          hasUnseenBadgeProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(home: Scaffold(body: BadgeTrophyButton())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(IconButton), findsOneWidget);
  });

  void addRule(
    String key,
    String label,
    String unit,
    int defaultValue,
    int min,
    int max,
  ) {
    repository.templates[key] = ClubRule(
      key: key,
      label: label,
      description: 'Description de $label.',
      unit: unit,
      group: 'Tests',
      defaultValue: defaultValue,
      min: min,
      max: max,
      value: defaultValue,
    );
    repository.ruleValues[key] = defaultValue;
  }

  testWidgets('une notification se coupe par un interrupteur, à sa place', (
    tester,
  ) async {
    addRule(
        'notify_live_goals', 'Notification : buts en direct', 'bool', 1, 0, 1);
    addRule('notify_admin_signups', 'Notification : nouvelle inscription',
        'bool', 1, 0, 1);
    await pumpPage(tester);
    await openSection(tester, 'live');

    final finder = find.byKey(const ValueKey('club-rule-notify_live_goals'));
    await tester.ensureVisible(finder);
    expect(tester.widget<SwitchListTile>(finder).value, isTrue);
    // Pas de compteur +/- pour un oui/non.
    expect(
      find.byKey(const ValueKey('club-rule-notify_live_goals-plus')),
      findsNothing,
    );
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(repository.ruleValues['notify_live_goals'], 0);
    expect(tester.widget<SwitchListTile>(finder).value, isFalse);

    // L'alerte d'inscription est rangée avec les membres.
    await openSection(tester, 'members');
    expect(
      find.byKey(const ValueKey('club-rule-notify_admin_signups')),
      findsOneWidget,
    );
  });

  testWidgets('le club peut jouer sans cotes', (tester) async {
    addRule('odds_mode', 'Cotes des pronostics', 'mode', 0, 0, 1);
    await pumpPage(tester);
    await openSection(tester, 'predictions');

    expect(find.text('Calculées automatiquement'), findsOneWidget);
    final select = find.byKey(const ValueKey('club-rule-odds_mode-select'));
    await tester.ensureVisible(select);
    await tester.tap(select);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sans cotes (barème seul)').last);
    await tester.pumpAndSettle();

    expect(repository.ruleValues['odds_mode'], 1);
    expect(ClubRules.oddsDisabled, isTrue);
  });

  testWidgets('les longues durées avancent par grands pas', (tester) async {
    addRule('odds_h2h_memory_days', 'Cotes : mémoire des confrontations',
        'jours', 900, 90, 3600);
    await pumpPage(tester);
    await openSection(tester, 'predictions');

    final plus =
        find.byKey(const ValueKey('club-rule-odds_h2h_memory_days-plus'));
    await tester.ensureVisible(plus);
    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(repository.ruleValues['odds_h2h_memory_days'], 990);
    expect(find.text('990 jours'), findsOneWidget);
  });

  testWidgets('un réglage est grisé quand sa fonctionnalité est désactivée', (
    tester,
  ) async {
    addRule('live_pilot_mode', 'Direct : qui le pilote', 'mode', 0, 0, 1);
    repository.modules['live_mode'] = false;
    await pumpPage(tester);
    await openSection(tester, 'matches');

    await openSection(tester, 'live');
    final select =
        find.byKey(const ValueKey('club-rule-live_pilot_mode-select'));
    await tester.ensureVisible(select);
    expect(tester.widget<DropdownButton<int>>(select).onChanged, isNull);

    // Réactiver le mode live rend le réglage modifiable.
    await tester
        .ensureVisible(find.byKey(const ValueKey('club-module-live_mode')));
    await tester.tap(find.byKey(const ValueKey('club-module-live_mode')));
    await tester.pumpAndSettle();
    expect(tester.widget<DropdownButton<int>>(select).onChanged, isNotNull);
  });
  testWidgets('32 options visibles, persistées, avec dépendances',
      (tester) async {
    for (final feature in ClubFeature.values) {
      addRule(feature.key, feature.key, 'bool', feature.defaultEnabled ? 1 : 0,
          0, 1);
    }
    await pumpPage(tester);
    for (final section in [
      'squad',
      'composition',
      'live',
      'matches',
      'rewards'
    ]) {
      await openSection(tester, section);
    }
    for (final feature in ClubFeature.values) {
      expect(find.byKey(ValueKey('club-rule-${feature.key}')), findsOneWidget);
    }
    final scorer = find.byKey(const ValueKey('club-rule-live_scorers'));
    final assist = find.byKey(const ValueKey('club-rule-live_assists'));
    await tester.ensureVisible(scorer);
    await tester.tap(scorer);
    await tester.pumpAndSettle();
    expect(repository.ruleValues['live_scorers'], 0);
    expect(tester.widget<SwitchListTile>(assist).onChanged, isNull);
    expect(repository.ruleValues['live_assists'], 1); // conservé, pas effacé
    await tester.ensureVisible(scorer);
    await tester.tap(scorer);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(assist).onChanged, isNotNull);
    expect(ClubRules.enabled(ClubFeature.liveAssists), isTrue);
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
  String? homeAddress;
  int usualSquadSize = 14;
  final Map<String, int> ruleValues = {'prediction_close_minutes': 15};

  /// Règles décrites comme le serveur les renvoie (libellé, unité, bornes).
  final Map<String, ClubRule> templates = {};

  List<ClubRule> _rules() => [
        for (final entry in ruleValues.entries)
          if (templates[entry.key] case final template?)
            ClubRule(
              key: template.key,
              label: template.label,
              description: template.description,
              unit: template.unit,
              group: template.group,
              defaultValue: template.defaultValue,
              min: template.min,
              max: template.max,
              value: entry.value,
            )
          else if (entry.key == 'waitlist_mode')
            ClubRule(
              key: entry.key,
              label: 'Liste d’attente : qui passe en premier',
              description: 'Quand il y a trop de disponibles.',
              unit: 'mode',
              group: 'Liste d’attente',
              defaultValue: 0,
              min: 0,
              max: 2,
              value: entry.value,
            )
          else
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
    ruleValues[key] = value ??
        templates[key]?.defaultValue ??
        (key == 'waitlist_mode' ? 0 : 15);
    return _rules();
  }

  @override
  Future<Club> fetchMyClub() async => club;

  @override
  Future<String?> fetchHomeAddress() async => homeAddress;

  @override
  Future<String?> updateHomeAddress(String? address) async {
    homeAddress = address;
    return address;
  }

  @override
  Future<int> fetchUsualSquadSize() async => usualSquadSize;

  @override
  Future<int> updateUsualSquadSize(int value) async {
    usualSquadSize = value;
    return value;
  }

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
  Future<Club> updateColors({
    required String primary,
    required String secondary,
  }) async {
    club = Club(
      id: club.id,
      name: club.name,
      shortName: club.shortName,
      inviteCode: club.inviteCode,
      primaryColor: primary,
      secondaryColor: secondary,
    );
    return club;
  }

  @override
  String? logoUrl(Club club) =>
      club.logoPath == null ? null : 'https://exemple.test/${club.logoPath}';

  @override
  Future<Club> removeLogo() async {
    club = Club(
      id: club.id,
      name: club.name,
      shortName: club.shortName,
      inviteCode: club.inviteCode,
      primaryColor: club.primaryColor,
      secondaryColor: club.secondaryColor,
    );
    return club;
  }

  @override
  Future<String> regenerateInviteCode() async => 'NEWCODE2';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
