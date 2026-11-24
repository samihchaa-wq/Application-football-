import 'package:petit_filet/core/push/home_screen_install.dart';
import 'package:petit_filet/features/notifications/presentation/push_device_banner.dart';
import 'package:petit_filet/features/preferences/data/push_subscriptions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le navigateur ne sait pas s'abonner dans un test : la doublure tient
/// l'état de l'abonnement de cet appareil.
class _FakePushSubscriptions implements PushSubscriptionsRepository {
  _FakePushSubscriptions({this.subscribed = false, this.allow = true});

  bool subscribed;
  final bool allow;
  int enableCalls = 0;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<bool> isSubscribed() async => subscribed;

  @override
  Future<bool> resync() async => subscribed;

  @override
  Future<bool> enable() async {
    enableCalls += 1;
    if (!allow) return false;
    subscribed = true;
    await writePushOptOut(false);
    return true;
  }

  @override
  Future<void> disable() async => subscribed = false;
}

Future<void> _pump(
  WidgetTester tester,
  _FakePushSubscriptions repository, {
  PushDeviceAlert? forcedAlert,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pushSubscriptionsRepositoryProvider.overrideWithValue(repository),
        // Relit la doublure à chaque invalidation, comme la vraie cloche.
        pushStatusProvider.overrideWith(
          (ref) async => (supported: true, subscribed: repository.subscribed),
        ),
        if (forcedAlert != null)
          pushDeviceAlertProvider.overrideWith((ref) async => forcedAlert),
      ],
      child: const MaterialApp(
        home: Scaffold(body: Column(children: [PushDeviceBanner()])),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('bandeau absent du poste de contrôle, du bilan et de la connexion', () {
    expect(pushBannerAllowedOn('/control'), isFalse);
    expect(pushBannerAllowedOn('/wrapped'), isFalse);
    expect(pushBannerAllowedOn('/auth/accept-terms'), isFalse);
    expect(pushBannerAllowedOn('/matches'), isTrue);
    expect(pushBannerAllowedOn('/controle-technique'), isTrue);
  });


  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'un appareil désabonné sans l’avoir choisi est signalé, et réabonné en '
    'un geste',
    (tester) async {
      final repository = _FakePushSubscriptions();
      await _pump(tester, repository);

      expect(find.text('Notifications désactivées'), findsOneWidget);

      await tester.tap(find.text('Activer'));
      await tester.pumpAndSettle();

      expect(repository.enableCalls, 1);
      expect(find.text('Notifications désactivées'), findsNothing);
      expect(
        find.text('Notifications activées sur cet appareil.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('un appareil qui reçoit n’affiche rien', (tester) async {
    await _pump(tester, _FakePushSubscriptions(subscribed: true));

    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('« Non merci » est retenu sur cet appareil', (tester) async {
    final repository = _FakePushSubscriptions();
    await _pump(tester, repository);

    await tester.tap(find.text('Non merci'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications désactivées'), findsNothing);
    expect(await readPushOptOut(), isTrue);
    expect(repository.enableCalls, 0);

    // Réouverture de l'application : le choix tient toujours.
    await tester.pumpWidget(const SizedBox.shrink());
    await _pump(tester, repository);
    expect(find.text('Notifications désactivées'), findsNothing);
  });

  testWidgets(
    'un refus du téléphone est annoncé au lieu d’un faux succès',
    (tester) async {
      final repository = _FakePushSubscriptions(allow: false);
      await _pump(tester, repository);

      await tester.tap(find.text('Activer'));
      await tester.pumpAndSettle();

      expect(repository.subscribed, isFalse);
      expect(
        find.textContaining('Notifications bloquées sur ce téléphone'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'un téléphone qui bloque l’affichage le dit, et le redit tant qu’il '
    'bloque',
    (tester) async {
      await _pump(
        tester,
        _FakePushSubscriptions(),
        forcedAlert: PushDeviceAlert.blocked,
      );

      expect(find.text('Notifications bloquées'), findsOneWidget);
      expect(find.text('Activer'), findsNothing);

      await tester.tap(find.text('J’ai autorisé'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Toujours bloquées'), findsOneWidget);
    },
  );

  group('iPhone ouvert dans Safari', () {
    Future<void> pumpUnsupported(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pushSubscriptionsRepositoryProvider
                .overrideWithValue(_FakePushSubscriptions()),
            pushStatusProvider.overrideWith(
              (ref) async => (supported: false, subscribed: false),
            ),
            homeScreenInstallNeededProvider.overrideWithValue(true),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Column(children: [PushDeviceBanner()])),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('le joueur apprend qu’il doit installer l’appli, et comment',
        (tester) async {
      await pumpUnsupported(tester);

      expect(find.text('Installe l’appli pour être prévenu'), findsOneWidget);

      await tester.tap(find.byKey(const Key('install-guide-open')));
      await tester.pumpAndSettle();

      expect(find.text('Installer l’appli sur ton téléphone'), findsOneWidget);
      expect(find.textContaining('Sur l’écran d’accueil'), findsOneWidget);

      await tester.tap(find.text('J’ai compris'));
      await tester.pumpAndSettle();
      expect(find.text('Installer l’appli sur ton téléphone'), findsNothing);
    });

    testWidgets('« Plus tard » est retenu, sans couper les notifications',
        (tester) async {
      await pumpUnsupported(tester);

      await tester.tap(find.byKey(const Key('install-guide-later')));
      await tester.pumpAndSettle();

      expect(find.text('Installe l’appli pour être prévenu'), findsNothing);
      expect(await readInstallHintDismissed(), isTrue);
      expect(await readPushOptOut(), isFalse);
    });

    testWidgets('un ordinateur qui ne sait pas recevoir n’affiche rien',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pushSubscriptionsRepositoryProvider
                .overrideWithValue(_FakePushSubscriptions()),
            pushStatusProvider.overrideWith(
              (ref) async => (supported: false, subscribed: false),
            ),
            homeScreenInstallNeededProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Column(children: [PushDeviceBanner()])),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextButton), findsNothing);
    });
  });

  testWidgets(
    'au-dessus des écrans, comme dans l’appli, le guide s’ouvre quand même',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pushSubscriptionsRepositoryProvider
                .overrideWithValue(_FakePushSubscriptions()),
            pushStatusProvider.overrideWith(
              (ref) async => (supported: false, subscribed: false),
            ),
            homeScreenInstallNeededProvider.overrideWithValue(true),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            // Même place que dans lib/app/app.dart : hors du navigateur.
            builder: (context, child) => Column(
              children: [
                PushDeviceBanner(
                  navigatorContext: () => navigatorKey.currentContext,
                ),
                Expanded(child: child ?? const SizedBox.shrink()),
              ],
            ),
            home: const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('install-guide-open')));
      await tester.pumpAndSettle();

      expect(find.text('Installer l’appli sur ton téléphone'), findsOneWidget);
    },
  );

  testWidgets('le guide explique aussi l’installation sur Android',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showHomeScreenInstallGuide(
                context,
                platform: InstallPlatform.android,
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    // Téléphone Android reconnu : les gestes de Chrome d'abord.
    expect(find.textContaining('Dans Chrome, touche le menu'), findsOneWidget);
    expect(find.textContaining('Installer l’application'), findsOneWidget);

    // L'iPhone reste à un geste (pour aider un coéquipier).
    await tester.tap(find.text('iPhone'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dans Safari, touche le bouton Partager'),
        findsOneWidget);
    expect(find.textContaining('Dans Chrome'), findsNothing);
  });
}
