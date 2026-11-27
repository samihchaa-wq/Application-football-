import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petit_filet/core/network/connectivity_service.dart';

/// Statistiques ouvertes sans réseau : la demande au serveur reste en
/// attente, et l'écran restait vide sans rien dire. Ces aides affichent
/// « Hors ligne » à la place, puis relancent la lecture au retour du réseau.
const statisticsOfflineTitle = 'Hors ligne';
const statisticsOfflineMessage =
    'Pas de connexion internet. Les statistiques s’afficheront dès le '
    'retour du réseau.';

/// Vrai seulement quand l'appareil se sait hors ligne (inconnu = en ligne).
bool watchStatisticsOffline(WidgetRef ref) =>
    ref.watch(onlineStatusProvider).valueOrNull == false;

/// Relit [provider] quand le réseau revient. À appeler dans `build`.
void refreshStatisticsWhenOnline(
    WidgetRef ref, ProviderBase<Object?> provider) {
  ref.listen<AsyncValue<bool>>(onlineStatusProvider, (previous, next) {
    if (previous?.valueOrNull == false && next.valueOrNull == true) {
      ref.invalidate(provider);
    }
  });
}
