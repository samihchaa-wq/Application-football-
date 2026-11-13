import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/features/admin/presentation/club_kits_page.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:as_grinta/features/matches/domain/jersey_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeClubRepository repository;

  setUp(() => repository = _FakeClubRepository());
  tearDown(ClubKits.reset);

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clubRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ClubKitsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('l’administrateur renomme, recolore et retire un maillot',
      (tester) async {
    await pumpPage(tester);

    expect(find.text('Domicile'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('kit-label-france')),
      'Rouge et noir',
    );
    await tester.tap(find.byKey(const ValueKey('kit-body-france-#D62828')));
    await tester.tap(find.byKey(const ValueKey('kit-enabled-blue')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('club-kits-save')));
    await tester.pumpAndSettle();

    final saved = repository.saved!;
    expect(saved.first.label, 'Rouge et noir');
    expect(saved.first.toJson()['body'], '#D62828');
    expect(saved.last.enabled, isFalse);
    expect(JerseyOption.france.label, 'Rouge et noir');
    expect(ClubKits.enabled, hasLength(2));
    expect(find.text('Maillots enregistrés.'), findsOneWidget);
  });

  testWidgets('l’admin peut choisir et enregistrer la couleur du gardien',
      (tester) async {
    await pumpPage(tester);
    await tester.tap(
      find.byKey(const ValueKey('kit-goalkeeper-body-france-#000000')),
    );
    await tester.tap(
      find.byKey(const ValueKey('kit-goalkeeper-trim-france-#FBE80C')),
    );
    await tester.tap(find.byKey(const ValueKey('club-kits-save')));
    await tester.pumpAndSettle();

    final kit = repository.saved!.first;
    expect(kit.toJson()['goalkeeper_body'], '#000000');
    expect(kit.toJson()['goalkeeper_trim'], '#FBE80C');
    expect(kit.toJson()['body'], colorToHex(kit.body));
    expect(ClubKits.of(JerseyOption.france).goalkeeperBody, kit.goalkeeperBody);
  });

  testWidgets('au moins un maillot doit rester proposé', (tester) async {
    await pumpPage(tester);
    for (final slot in ['france', 'orange', 'blue']) {
      await tester.tap(find.byKey(ValueKey('kit-enabled-$slot')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('club-kits-save')));
    await tester.pumpAndSettle();

    expect(repository.saved, isNull);
    expect(find.text('Au moins un maillot doit être proposé.'), findsOneWidget);
  });
}

class _FakeClubRepository implements ClubRepository {
  List<ClubKit>? saved;

  @override
  Future<List<ClubKit>> updateKits(List<ClubKit> kits) async {
    saved = kits;
    return kits;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
