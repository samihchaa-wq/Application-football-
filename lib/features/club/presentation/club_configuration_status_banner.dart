import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:as_grinta/features/feature_flags/presentation/feature_flags_controller.dart';
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
    final failed = club.hasError || modules.hasError || rules.hasError;
    final loading = club.isLoading || modules.isLoading || rules.isLoading;
    if (!failed && !loading) return const SizedBox.shrink();
    return Material(
      color: AppTheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  failed
                      ? 'Les réglages du club sont indisponibles.'
                      : 'Chargement des réglages du club…',
                ),
              ),
              if (failed)
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
