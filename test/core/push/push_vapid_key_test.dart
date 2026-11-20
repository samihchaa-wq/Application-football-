import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/core/push/push_client.dart';

void main() {
  test('la clé d’envoi est une clé publique P-256 complète', () {
    final padded = pushVapidPublicKey.padRight(
        (pushVapidPublicKey.length + 3) ~/ 4 * 4, '=');
    final bytes = base64Url.decode(padded);
    expect(bytes.length, 65, reason: 'point non compressé de 65 octets');
    expect(bytes.first, 0x04);
  });

  test('ce n’est plus la clé de l’application d’origine', () {
    // Le serveur commercial n'a jamais eu la clé privée qui va avec : Apple
    // refusait chaque notification (code 400) tant que l'appli l'utilisait.
    expect(
      pushVapidPublicKey,
      isNot(startsWith('BDZa9YcR2dn5pzohdAgKuSxfM')),
    );
  });

  test('un abonnement créé avec une autre clé est retiré puis refait', () {
    final shell = File('web/app_shell.js').readAsStringSync();
    expect(shell, contains('keyDiffers: function (subscription, key)'));
    expect(shell, contains('subscription.options.applicationServerKey'));
    expect(
      shell,
      contains(
        'if (existing && window.asGrintaPush.keyDiffers(existing, key)) {',
      ),
    );
    expect(shell, contains('await existing.unsubscribe();'));
    expect(shell, contains('keyStatus: async function (vapidKey)'));
  });
}
