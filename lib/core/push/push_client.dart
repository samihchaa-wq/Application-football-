// Abonnement aux notifications push Web (no-op hors navigateur).
export 'push_client_stub.dart'
    if (dart.library.js_interop) 'push_client_web.dart';

/// Clé publique VAPID du serveur d'envoi (la clé privée reste dans
/// Supabase Vault, lue uniquement par l'Edge Function send-push).
///
/// Elle doit être la moitié publique de la paire `push_vapid_public` /
/// `push_vapid_private` du coffre de la base commerciale, créée le
/// 12/11/2026 par tool/commercial_supabase_setup.py. Jusqu'au 20/11/2026,
/// l'appli gardait la clé de l'application d'origine : les téléphones
/// s'abonnaient avec une clé que le serveur ne détenait pas, et Apple
/// refusait chaque envoi (code 400).
const String pushVapidPublicKey =
    'BIe-vdCcku4JJ6S1EKNF7aKwgqvv0naUAqZr-2IKguzKoSNuyxEXdkwvZXUP3vD38XYQ2P_16CR9vkQB-OWG1Yw';
