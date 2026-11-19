import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/feature_flags/presentation/feature_flags_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un réglage non chargé n'est pas présenté comme une fonction activée.
class ClubConfigurationStatusBanner extends ConsumerWidget {
  const ClubConfigurationStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(clubSessionIdentityProvider) == null) {
      return const SizedBox.shrink();
    }
    final club = ref.watch(myClubProvider);
    final modules = ref.watch(clubModulesProvider);
    final rules = ref.watch(clubRulesProvider);
    // Pendant le chargement, rien n'est affiché : un bandeau qui apparaît
    // puis disparaît fait sauter tout l'écran à l'ouverture. Les fonctions
    // du club restent masquées tant que leurs réglages ne sont pas connus.
    final failed = club.hasError || modules.hasError || rules.hasError;
    if (!failed) return const SizedBox.shrink();
    return Material(
      color: AppTheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: const Text('Les réglages du club sont indisponibles.'),
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
