import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/core/club/club_identity.dart';

/// Taille du texte forcée pour tout un passage de tests (contrôle manuel, pas
/// utilisé par la CI) :
///
///     flutter test --dart-define=PF_TEXT_SCALE=2
///
/// Les écrans doivent rester utilisables avec le texte agrandi du téléphone ;
/// un test qui échoue dans ce mode signale en général un débordement.
const _textScale = double.fromEnvironment('PF_TEXT_SCALE', defaultValue: 1);

/// Réglage commun à tous les tests.
///
/// Les tests d'écran ont été écrits avec un club d'exemple nommé
/// « AS Grinta » (nom court « ASG »). L'application n'écrit plus ce nom en
/// dur : il vient du club du compte connecté. Les tests fixent donc ici le
/// club d'exemple qu'ils attendent.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  ClubIdentity.set(name: 'AS Grinta', shortName: 'ASG');
  if (_textScale != 1) {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    setUp(
        () => binding.platformDispatcher.textScaleFactorTestValue = _textScale);
  }
  await testMain();
}
