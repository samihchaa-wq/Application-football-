import 'dart:async';

import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:as_grinta/features/club/presentation/club_configuration_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const club =
      Club(id: 'a', name: 'Club A', shortName: 'A', inviteCode: 'ABCDEFGH');

  testWidgets('chargement visible puis erreur et nouvelle tentative réussie',
      (tester) async {
    final pending = Completer<ClubModules>();
    var calls = 0;
    final container = ProviderContainer(overrides: [
      clubSessionIdentityProvider.overrideWithValue('account-a'),
      myClubProvider.overrideWith((ref) async => club),
      clubRulesProvider.overrideWith((ref) async => const []),
      clubModulesProvider.overrideWith((ref) {
        calls += 1;
        return calls == 1 ? pending.future : const ClubModules.allEnabled();
      }),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
            home: Scaffold(body: ClubConfigurationStatusBanner()))));
    await tester.pump();
    expect(find.text('Chargement des réglages du club…'), findsOneWidget);
    expect(container.read(clubModuleEnabledProvider(ClubModule.predictions)),
        isFalse);

    pending.completeError(StateError('réseau indisponible'));
    await tester.pumpAndSettle();
    expect(
        find.text('Les réglages du club sont indisponibles.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(container.read(clubModuleEnabledProvider(ClubModule.predictions)),
        isFalse);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Les réglages du club sont indisponibles.'), findsNothing);
    expect(calls, 2);
    expect(container.read(clubModuleEnabledProvider(ClubModule.predictions)),
        isTrue);
  });

  testWidgets('hors connexion aucun chargement de club n’est lancé',
      (tester) async {
    var calls = 0;
    final container = ProviderContainer(overrides: [
      clubSessionIdentityProvider.overrideWithValue(null),
      myClubProvider.overrideWith((ref) async {
        calls += 1;
        return club;
      }),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
            home: Scaffold(body: ClubConfigurationStatusBanner()))));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Chargement des réglages du club…'), findsNothing);
  });
}
