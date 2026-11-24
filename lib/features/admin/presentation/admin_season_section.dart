part of 'admin_page.dart';

class _SeasonCard extends ConsumerWidget {
  const _SeasonCard({
    required this.dashboard,
    required this.onSeasonCreated,
  });

  final AdminDashboardData dashboard;
  final VoidCallback onSeasonCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openSeasons = dashboard.seasons.where(
      (item) => item.status == 'open',
    );
    final openSeason = openSeasons.isEmpty ? null : openSeasons.first;

    // La saison en cours d'abord ; l'action définitive ensuite, expliquée et
    // en taille normale. Avant, « Finir la saison » était le plus gros
    // élément de la page, au-dessus même du nom de la saison.
    if (openSeason == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saison', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _createSeason(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Créer une saison'),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Saison ${openSeason.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'En cours',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.success,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'En fin de saison, l’archiver fige le classement final. Tu '
              'pourras ensuite en créer une nouvelle.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _changeStatus(
                  context,
                  ref,
                  openSeason,
                  'archived',
                  title: 'Finir la saison ?',
                  message: 'La saison « ${openSeason.name} » sera archivée '
                      'immédiatement et le classement final figé. '
                      'C’est définitif. Tu pourras ensuite créer une '
                      'nouvelle saison.',
                ),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Finir la saison'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    AdminSeasonItem season,
    String status, {
    required String title,
    required String message,
  }) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler'),
              ),
              // Action définitive : bouton rouge, comme les autres
              // suppressions de l'appli.
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .setSeasonStatus(season.id, status);
      ref.invalidate(adminDashboardProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(humanizeError(error))));
      }
    }
  }

  Future<void> _createSeason(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: suggestedNewSeasonName(dashboard.seasons, DateTime.now()),
    );
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouvelle saison'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nom de la saison'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref.read(adminRepositoryProvider).createSeason(name);
      ref.invalidate(adminDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saison « ${name.trim()} » ouverte. Ajoute maintenant ton '
              'effectif.',
            ),
          ),
        );
        onSeasonCreated();
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(humanizeError(error))));
      }
    }
  }
}
