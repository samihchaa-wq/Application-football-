import 'package:petit_filet/core/widgets/pf_menu_item_label.dart';
import 'package:petit_filet/app/shell/module_navigation.dart';
import 'package:petit_filet/core/utils/match_window.dart';
import 'package:petit_filet/features/matches/data/match_details_repository.dart';
import 'package:petit_filet/features/matches/domain/match_deletion_window.dart';
import 'package:petit_filet/features/matches/domain/match_model.dart';
import 'package:petit_filet/features/matches/presentation/match_form_page.dart';
import 'package:petit_filet/features/matches/presentation/matches_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petit_filet/core/theme/pf_button_styles.dart';

class AdminMatchOptionsButton extends ConsumerWidget {
  const AdminMatchOptionsButton({required this.match, super.key});

  final MatchModel match;

  /// Vrai s'il reste au moins une action possible sur ce match. Sinon le
  /// crayon n'est pas affiché : les cartes ne doivent alors pas lui réserver
  /// de place, sans quoi le score se décale vers la gauche.
  static bool hasOptions(MatchModel match, {DateTime? now}) =>
      _MatchAdminOptions.of(match, now ?? DateTime.now()).any;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => MatchFormPage(match: match)));
    if (!context.mounted) return;
    ref.invalidate(matchDetailsProvider(match.id));
    await ref.read(matchesControllerProvider.notifier).load(allSeasons: true);
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Annuler ce match\u00A0?'),
            content: const Text(
              'Le match sera marqué comme annulé. Il reste visible dans le '
              'calendrier pour informer les joueurs, mais ne sera plus '
              'ouvrable.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Retour'),
              ),
              FilledButton(
                style: PfButtonStyles.danger,
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Annuler le match'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final failure = await ref
        .read(matchesControllerProvider.notifier)
        .cancelMatch(match.id);
    ref.invalidate(matchDetailsProvider(match.id));
    messenger.showSnackBar(
      SnackBar(content: Text(failure ?? 'Match annulé.')),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Terminer ce match\u00A0?'),
            content: const Text(
              'Le match entre nous sera marqué comme terminé et sortira des '
              'matchs en cours. Cette action ne peut pas être annulée depuis '
              'l’application.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Retour'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Terminer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final failure = await ref
        .read(matchesControllerProvider.notifier)
        .finishInternalMatch(match.id);
    ref.invalidate(matchDetailsProvider(match.id));
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  /// Le contenu du message change selon l'état du match : pendant le Live et
  /// après la validation, la suppression emporte plus de choses qu'un simple
  /// match à venir.
  String _deleteWarning(DateTime now) {
    if (match.isFinished || match.isArchived) {
      return 'Le match, ses pronostics, ses buteurs et ses statistiques seront '
          'définitivement supprimés. Les classements seront recalculés.';
    }
    final phase = match.phase(now: now);
    if (phase == MatchDisplayPhase.live ||
        phase == MatchDisplayPhase.awaitingValidation) {
      return 'Ce match est en cours. Sa suppression efface aussi le Live '
          '(chronomètre, buts, remplacements), la composition et les '
          'pronostics. C’est définitif.';
    }
    return 'Le match, ses pronostics, ses buteurs et ses statistiques seront '
        'définitivement supprimés.';
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final warning = _deleteWarning(DateTime.now());
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Supprimer ce match\u00A0?'),
            content: Text(warning),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                style: PfButtonStyles.danger,
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final failure = await ref
        .read(matchesControllerProvider.notifier)
        .deleteMatch(match.id);
    ref.invalidate(matchDetailsProvider(match.id));
    if (failure == null) {
      // La suppression recharge brièvement la liste complète. Pendant ce
      // rafraîchissement le ScrollController peut être clampé à 0 ; on force
      // donc un nouvel ancrage sur le match pertinent une fois la liste prête.
      ref.read(matchesFocusRequestProvider.notifier).state++;
      messenger.showSnackBar(const SnackBar(content: Text('Match supprimé.')));
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(failure)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = _MatchAdminOptions.of(match, DateTime.now());

    // Match validé depuis plus de 24 h : plus rien à modifier, annuler ou
    // supprimer. Le crayon ouvrirait un menu vide, on ne l'affiche pas.
    if (!options.any) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: 'Options du match',
      icon: const Icon(Icons.edit_outlined),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            await _edit(context, ref);
            return;
          case 'stats':
            if (context.mounted) {
              context.push('/matches/${match.id}/finalize');
            }
            return;
          case 'finish':
            await _finish(context, ref);
            return;
          case 'cancel':
            await _cancel(context, ref);
            return;
          case 'delete':
            await _delete(context, ref);
            return;
        }
      },
      itemBuilder: (context) => [
        if (options.canEditIdentity)
          const PopupMenuItem(
            value: 'edit',
            child: PfMenuItemLabel(
                icon: Icons.settings_outlined, label: 'Modifier'),
          ),
        if (options.canEnterStats)
          const PopupMenuItem(
            value: 'stats',
            child: PfMenuItemLabel(
                icon: Icons.query_stats_outlined, label: 'Saisir les stats'),
          ),
        if (options.canFinishInternal)
          const PopupMenuItem(
            value: 'finish',
            child: PfMenuItemLabel(
                icon: Icons.check_circle_outlined, label: 'Terminer'),
          ),
        if (options.canCancel)
          const PopupMenuItem(
            value: 'cancel',
            child:
                PfMenuItemLabel(icon: Icons.block_outlined, label: 'Annuler'),
          ),
        if (options.canDelete)
          const PopupMenuItem(
            value: 'delete',
            child: PfMenuItemLabel(
                icon: Icons.delete_outlined, label: 'Supprimer'),
          ),
      ],
    );
  }
}

/// Les actions encore possibles sur un match, selon son état et l'heure.
class _MatchAdminOptions {
  const _MatchAdminOptions({
    required this.canEditIdentity,
    required this.canEnterStats,
    required this.canFinishInternal,
    required this.canCancel,
    required this.canDelete,
  });

  factory _MatchAdminOptions.of(MatchModel match, DateTime now) {
    final phase = match.phase(now: now);
    final editLocked =
        isMatchAdminEditLocked(match.kickoffAt) || match.isFinished;
    return _MatchAdminOptions(
      canEditIdentity: !editLocked && !match.isCancelled,
      canCancel: !editLocked && !match.isCancelled,
      canDelete: canDeleteMatch(match, now: now),
      canEnterStats: !match.isInternal &&
          !match.isArchived &&
          phase == MatchDisplayPhase.awaitingValidation,
      canFinishInternal: match.isInternal &&
          !match.isFinished &&
          !match.isCancelled &&
          !now.isBefore(match.kickoffAt) &&
          (phase == MatchDisplayPhase.live ||
              phase == MatchDisplayPhase.awaitingValidation),
    );
  }

  final bool canEditIdentity;
  final bool canEnterStats;
  final bool canFinishInternal;
  final bool canCancel;
  final bool canDelete;

  bool get any =>
      canEditIdentity ||
      canEnterStats ||
      canFinishInternal ||
      canCancel ||
      canDelete;
}
