import 'package:petit_filet/core/widgets/pf_status_banner.dart';
import 'package:petit_filet/features/preferences/data/push_subscriptions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bandeau du haut de l'application quand cet appareil ne recevra pas les
/// notifications du club sans que le joueur l'ait choisi.
///
/// Sans lui, rien ne prévenait le joueur : il fallait ouvrir l'écran des
/// notifications pour voir la cloche grise, et un téléphone qui bloquait
/// l'affichage dans ses réglages gardait même une cloche verte.
class PushDeviceBanner extends ConsumerStatefulWidget {
  const PushDeviceBanner({super.key});

  @override
  ConsumerState<PushDeviceBanner> createState() => _PushDeviceBannerState();
}

class _PushDeviceBannerState extends ConsumerState<PushDeviceBanner> {
  bool _busy = false;

  void _say(String message) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _enable() async {
    setState(() => _busy = true);
    var enabled = false;
    try {
      enabled = await ref.read(pushSubscriptionsRepositoryProvider).enable();
    } catch (_) {
      enabled = false;
    }
    ref.invalidate(pushStatusProvider);
    if (!mounted) return;
    setState(() => _busy = false);
    _say(
      enabled
          ? 'Notifications activées sur cet appareil.'
          : 'Notifications bloquées sur ce téléphone : autorise-les dans '
              'ses réglages, puis réessaie.',
    );
  }

  Future<void> _recheck() async {
    ref.invalidate(pushStatusProvider);
    final alert = await ref.read(pushDeviceAlertProvider.future);
    if (!mounted || alert != PushDeviceAlert.blocked) return;
    _say(
      'Toujours bloquées : ouvre les réglages du téléphone, rubrique '
      'Notifications, et autorise l’application.',
    );
  }

  Future<void> _decline() async {
    await writePushOptOut(true);
    ref.invalidate(pushStatusProvider);
  }

  Future<void> _laterInstall() async {
    await writeInstallHintDismissed(true);
    ref.invalidate(pushDeviceAlertProvider);
  }

  @override
  Widget build(BuildContext context) {
    final alert = ref.watch(pushDeviceAlertProvider).valueOrNull;
    if (alert == null || alert == PushDeviceAlert.none) {
      return const SizedBox.shrink();
    }
    if (alert == PushDeviceAlert.needsInstall) {
      return _InstallBanner(
        onHowTo: () => showHomeScreenInstallGuide(context),
        onLater: _laterInstall,
      );
    }

    final blocked = alert == PushDeviceAlert.blocked;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: PfStatusBanner(
            title: blocked
                ? 'Notifications bloquées'
                : 'Notifications désactivées',
            message: blocked
                ? 'Ton téléphone n’affiche pas les notifications du club. '
                    'Autorise-les dans ses réglages pour être prévenu des '
                    'disponibilités et des convocations.'
                : 'Tu ne reçois pas les notifications du club sur cet '
                    'appareil : ouverture des disponibilités, convocations.',
            tone: PfStatusTone.warning,
            compact: true,
            action: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy ? null : (blocked ? _recheck : _enable),
                  child: Text(blocked ? 'C’est fait' : 'Activer'),
                ),
                TextButton(
                  onPressed: _busy ? null : _decline,
                  child: const Text('Non merci'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Conseil affiché sur iPhone et iPad quand l'application est ouverte dans
/// Safari : sans ajout à l'écran d'accueil, aucune notification n'arrive.
class _InstallBanner extends StatelessWidget {
  const _InstallBanner({required this.onHowTo, required this.onLater});

  final VoidCallback onHowTo;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: PfStatusBanner(
            title: 'Installe l’appli pour être prévenu',
            message: 'Sur iPhone, les notifications du club n’arrivent que si '
                'l’appli est sur l’écran d’accueil.',
            tone: PfStatusTone.info,
            compact: true,
            action: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  key: const Key('install-guide-open'),
                  onPressed: onHowTo,
                  child: const Text('Comment faire'),
                ),
                TextButton(
                  key: const Key('install-guide-later'),
                  onPressed: onLater,
                  child: const Text('Plus tard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Les trois gestes pour ajouter l'application à l'écran d'accueil depuis
/// Safari, puis la rouvrir depuis son icône.
Future<void> showHomeScreenInstallGuide(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      Widget step(int number, IconData icon, String text) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  '$number',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
            ],
          ),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Installer l’appli sur ton iPhone',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Trente secondes, une seule fois.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              step(
                1,
                Icons.ios_share,
                'Dans Safari, touche le bouton Partager, en bas de l’écran.',
              ),
              step(
                2,
                Icons.add_box_outlined,
                'Fais défiler et choisis « Sur l’écran d’accueil », puis '
                '« Ajouter ».',
              ),
              step(
                3,
                Icons.touch_app_outlined,
                'Ouvre l’appli depuis sa nouvelle icône, puis accepte les '
                'notifications.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('J’ai compris'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
