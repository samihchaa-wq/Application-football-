import 'dart:async';

import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/feature_flags/presentation/feature_flags_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Délai avant d'annoncer une panne des réglages du club.
///
/// Au retour au premier plan, un iPhone relit les réglages avant d'avoir
/// retrouvé le réseau : le premier essai échoue, le suivant réussit une
/// seconde plus tard. Sans ce délai, le bandeau clignote pour rien.
const clubConfigurationBannerDelay = Duration(seconds: 3);

/// Vrai seulement quand un réglage est en échec et qu'aucune nouvelle
/// lecture n'est en cours. Pendant une relecture, Riverpod garde l'erreur
/// précédente : on ne la montre pas tant que la réponse n'est pas connue.
final _clubConfigurationFailedProvider = Provider.autoDispose<bool>((ref) {
  if (ref.watch(clubSessionIdentityProvider) == null) return false;
  bool failed(AsyncValue<Object?> value) => value.hasError && !value.isLoading;
  return failed(ref.watch(myClubProvider)) ||
      failed(ref.watch(clubModulesProvider)) ||
      failed(ref.watch(clubRulesProvider));
});

/// Un réglage non chargé n'est pas présenté comme une fonction activée.
///
/// Les fonctions du club restent masquées dès le premier échec ; seul
/// l'affichage du bandeau attend que la panne dure.
class ClubConfigurationStatusBanner extends ConsumerStatefulWidget {
  const ClubConfigurationStatusBanner({super.key});

  @override
  ConsumerState<ClubConfigurationStatusBanner> createState() =>
      _ClubConfigurationStatusBannerState();
}

class _ClubConfigurationStatusBannerState
    extends ConsumerState<ClubConfigurationStatusBanner> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<bool>(
      _clubConfigurationFailedProvider,
      (_, failed) => _onFailedChanged(failed),
      fireImmediately: true,
    );
  }

  void _onFailedChanged(bool failed) {
    _timer?.cancel();
    _timer = null;
    if (!failed) {
      if (_visible && mounted) setState(() => _visible = false);
      return;
    }
    if (_visible) return;
    _timer = Timer(clubConfigurationBannerDelay, () {
      _timer = null;
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Material(
      color: AppTheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Expanded(
                child: Text('Les réglages du club sont indisponibles.'),
              ),
              TextButton(
                onPressed: () {
                  refreshClubConfiguration(ref.invalidate);
                  ref.invalidate(featureFlagsControllerProvider);
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
