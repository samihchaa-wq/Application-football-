import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:petit_filet/features/admin/data/admin_repository.dart';
import 'package:petit_filet/features/players/data/roster_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petit_filet/core/theme/pf_button_styles.dart';

/// Créer ou finir la saison du club, dans les Réglages du club.
class ClubSeasonTile extends ConsumerWidget {
  const ClubSeasonTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(adminDashboardProvider);
    return dashboard.when(
      loading: () => const ListTile(
        leading: Icon(Icons.flag_outlined),
        title: Text('Saison'),
        subtitle: Text('Chargement…'),
      ),
      error: (_, __) => ListTile(
        leading: const Icon(Icons.refresh),
        title: const Text('Saison indisponible'),
        subtitle: const Text('Appuyer pour réessayer'),
        onTap: () => ref.invalidate(adminDashboardProvider),
      ),
      data: (data) {
        AdminSeasonItem? current;
        for (final season in data.seasons) {
          if (season.status == 'open') {
            current = season;
            break;
          }
        }
        final openSeason = current;
        if (openSeason == null) {
          return ListTile(
            leading: const Icon(Icons.add_circle_outlined),
            title: const Text('Créer une saison'),
            onTap: () => _createSeason(context, ref),
          );
        }
        return ListTile(
          leading: Icon(Icons.flag_outlined, color: AppTheme.error),
          title: Text(
            'Finir la saison',
            style: TextStyle(color: AppTheme.error),
          ),
          subtitle: Text('Saison ${openSeason.name}'),
          onTap: () => _finishSeason(context, ref, openSeason),
        );
      },
    );
  }

  Future<void> _finishSeason(
    BuildContext context,
    WidgetRef ref,
    AdminSeasonItem season,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Finir la saison\u00A0?'),
            content: Text(
              'La saison « ${season.name} » sera archivée immédiatement '
              'et le classement final figé. C’est définitif. '
              'Tu pourras ensuite créer une nouvelle saison.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler'),
              ),
              // Action définitive : bouton rouge, comme les autres
              // suppressions de l'appli.
              FilledButton(
                style: PfButtonStyles.danger,
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Finir la saison'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(adminRepositoryProvider).setSeasonStatus(
            season.id,
            'archived',
          );
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(openSeasonIdProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saison « ${season.name} » terminée.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanizeError(error))),
      );
    }
  }

  Future<void> _createSeason(BuildContext context, WidgetRef ref) async {
    final seasons =
        ref.read(adminDashboardProvider).valueOrNull?.seasons ?? const [];
    var enteredName = suggestedNewSeasonName(seasons, DateTime.now());
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouvelle saison'),
        content: TextFormField(
          initialValue: enteredName,
          onChanged: (value) => enteredName = value,
          decoration: const InputDecoration(labelText: 'Nom de la saison'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, enteredName),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (name == null || !context.mounted) return;
    if (name.trim().isEmpty) {
      // Avant, la fenêtre se fermait sans rien dire sur un nom vide.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indique un nom de saison.')),
      );
      return;
    }
    try {
      await ref.read(adminRepositoryProvider).createSeason(name);
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(openSeasonIdProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saison « ${name.trim()} » ouverte.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanizeError(error))),
      );
    }
  }
}
