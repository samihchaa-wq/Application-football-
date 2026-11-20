// Implémentation hors Web : les notifications push ne sont pas disponibles.
import 'package:petit_filet/core/push/home_screen_install.dart';

Future<bool> pushSupported() async => false;

Future<String> pushPermission() async => 'unsupported';

Future<String?> pushSubscribe(String vapidPublicKey) async => null;

Future<String?> pushCurrentSubscription() async => null;

Future<String?> pushUnsubscribe() async => null;

Future<String> pushDisplayReceipts() async => '[]';

Future<void> pushForgetDisplayReceipts(String sentJson) async {}

Future<void> pushSetAppBadge(int count) async {}

void pushListenReceived(void Function() callback) {}

/// Hors navigateur, aucune installation n'est à proposer.
bool pushNeedsHomeScreenInstall() => false;

Future<String> pushSubscriptionKeyStatus(String vapidPublicKey) async => 'none';

InstallPlatform pushInstallPlatform() => InstallPlatform.other;

/// Hors navigateur, l'application est déjà « installée ».
bool pushAppInstalled() => false;

bool pushCanPromptInstall() => false;

Future<String> pushPromptInstall() async => 'unavailable';
