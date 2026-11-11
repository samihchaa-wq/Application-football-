import 'dart:async';

import 'package:as_grinta/core/club/club_identity.dart';

/// Réglage commun à tous les tests.
///
/// Les tests d'écran ont été écrits avec un club d'exemple nommé
/// « AS Grinta » (nom court « ASG »). L'application n'écrit plus ce nom en
/// dur : il vient du club du compte connecté. Les tests fixent donc ici le
/// club d'exemple qu'ils attendent.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  ClubIdentity.set(name: 'AS Grinta', shortName: 'ASG');
  await testMain();
}
