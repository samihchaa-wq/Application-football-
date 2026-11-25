import 'package:petit_filet/core/widgets/pf_error_retry.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:petit_filet/features/feature_flags/presentation/feature_flags_controller.dart';
import 'package:petit_filet/features/notifications/data/notification_inbox_repository.dart';
import 'package:petit_filet/features/sports_management/data/match_availability_board_repository.dart';
import 'package:petit_filet/features/sports_management/data/match_availability_repository.dart';
import 'package:petit_filet/features/sports_management/domain/match_availability.dart';
import 'package:petit_filet/features/sports_management/presentation/match_availability_provider.dart';
import 'package:petit_filet/features/unavailability/domain/player_unavailability.dart';
import 'package:petit_filet/features/sports_management/presentation/widgets/stadium_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petit_filet/core/widgets/pf_loader.dart';
import 'package:petit_filet/core/theme/pf_button_styles.dart';

class MatchAvailabilitySelector extends ConsumerStatefulWidget {
  const MatchAvailabilitySelector({
    super.key,
    required this.matchId,
    this.embeddedOnDark = false,
    this.topSpacing = 0,
    this.bottomSpacing = 0,
    this.showManageShortcut = false,
  });

  final String matchId;
  final bool embeddedOnDark;
  final double topSpacing;
  final double bottomSpacing;

  /// Affiche, sous les boutons de disponibilité, un raccourci « Effectif et
  /// composition » vers la gestion du match. Réservé à l'admin : c'est
  /// l'appelant (qui connaît le rôle) qui l'active.
  final bool showManageShortcut;

  @override
  ConsumerState<MatchAvailabilitySelector> createState() =>
      _MatchAvailabilitySelectorState();
}

class _MatchAvailabilitySelectorState
    extends ConsumerState<MatchAvailabilitySelector> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(sportsManagementEnabledProvider) ||
        _isPredictionRoute(context)) {
      return const SizedBox.shrink();
    }

    final availability = ref.watch(myMatchAvailabilityProvider(widget.matchId));
    return availability.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => Padding(
        padding: EdgeInsets.only(
          top: widget.topSpacing,
          bottom: widget.bottomSpacing,
        ),
        child: PfInlineErrorRetry(
          message: 'Ta disponibilité est momentanément indisponible.',
          onRetry: () =>
              ref.invalidate(myMatchAvailabilityProvider(widget.matchId)),
        ),
      ),
      data: (value) {
        // Une indisponibilité déclarée ferme la réponse : plutôt que de faire
        // disparaître le bloc sans rien dire, on rappelle au joueur ce qu'il a
        // lui-même saisi et où le modifier.
        if (value != null &&
            value.isUnavailablePeriod &&
            DateTime.now().isBefore(value.kickoffAt)) {
          return Padding(
            padding: EdgeInsets.only(
              top: widget.topSpacing,
              bottom: widget.bottomSpacing,
            ),
            child: _DeclaredUnavailabilityCard(availability: value),
          );
        }

        if (value == null || !value.canRespond) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.only(
            top: widget.topSpacing,
            bottom: widget.bottomSpacing,
          ),
          child: _AvailabilityPanel(
            availability: value,
            saving: _saving,
            embeddedOnDark: widget.embeddedOnDark,
            onAvailable: () =>
                _selectStatus(value, MatchAvailabilityStatus.available),
            onAbsent: () =>
                _selectStatus(value, MatchAvailabilityStatus.absent),
            showManageShortcut: widget.showManageShortcut,
            onOpenEffectif: () => context.push(
              '/matches/${widget.matchId}/lineup?section=effectif',
            ),
            onOpenComposition: () {
              // La vidéo de la compo peut se lancer à l'arrivée : l'appui la
              // débloque sur iPhone.
              primeStadiumVideo();
              context.push(
                '/matches/${widget.matchId}/lineup?section=composition',
              );
            },
          ),
        );
      },
    );
  }

  bool _isPredictionRoute(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.path.endsWith('/prediction');
    } catch (_) {
      return false;
    }
  }

  Future<void> _selectStatus(
    MatchAvailability availability,
    MatchAvailabilityStatus status,
  ) async {
    if (_saving || availability.status == status) return;

    final isFirstChoice =
        availability.status == MatchAvailabilityStatus.noResponse;
    if (!isFirstChoice) {
      final currentLabel = _statusLabel(availability.status);
      final targetLabel = _statusLabel(status);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            'Passer de « $currentLabel » à « $targetLabel »\u00A0?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('Passer à $targetLabel'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
    }

    await _save(availability, status);
  }

  Future<void> _save(
    MatchAvailability availability,
    MatchAvailabilityStatus status, {
    String? privateComment,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await ref.read(matchAvailabilityRepositoryProvider).setMyAvailability(
            matchId: availability.matchId,
            status: status,
            privateComment: privateComment,
          );
      ref
        ..invalidate(myMatchAvailabilityProvider(widget.matchId))
        ..invalidate(matchAvailabilityBoardProvider(widget.matchId))
        // Répondre marque comme lue la notification qui le demandait.
        ..invalidate(unreadNotificationCountProvider);
      await ref.read(myMatchAvailabilityProvider(widget.matchId).future);

      if (!mounted) return;
      final label = _statusLabel(status);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$label enregistré.')));
    } on MatchAvailabilityWriteConfirmedButRefreshFailed {
      ref
        ..invalidate(myMatchAvailabilityProvider(widget.matchId))
        ..invalidate(matchAvailabilityBoardProvider(widget.matchId))
        // Répondre marque comme lue la notification qui le demandait.
        ..invalidate(unreadNotificationCountProvider);
      if (!mounted) return;
      final label = _statusLabel(status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label enregistré, mais l’écran n’a pas pu être actualisé. '
            'Actualise la page avant toute nouvelle action.',
          ),
        ),
      );
    } on MatchAvailabilityWriteOutcomeUnknown {
      ref
        ..invalidate(myMatchAvailabilityProvider(widget.matchId))
        ..invalidate(matchAvailabilityBoardProvider(widget.matchId))
        // Répondre marque comme lue la notification qui le demandait.
        ..invalidate(unreadNotificationCountProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Connexion interrompue : ta disponibilité a peut-être été '
            'enregistrée. Actualise la page avant de réessayer.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(humanizeError(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _statusLabel(MatchAvailabilityStatus status) {
    return status == MatchAvailabilityStatus.available
        ? 'Présent'
        : status.label;
  }
}

class _AvailabilityPanel extends StatelessWidget {
  const _AvailabilityPanel({
    required this.availability,
    required this.saving,
    required this.embeddedOnDark,
    required this.onAvailable,
    required this.onAbsent,
    this.showManageShortcut = false,
    this.onOpenEffectif,
    this.onOpenComposition,
  });

  final MatchAvailability availability;
  final bool saving;
  final bool embeddedOnDark;
  final VoidCallback onAvailable;
  final VoidCallback onAbsent;
  final bool showManageShortcut;
  final VoidCallback? onOpenEffectif;
  final VoidCallback? onOpenComposition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedAvailable =
        availability.status == MatchAvailabilityStatus.available;
    final selectedAbsent =
        availability.status == MatchAvailabilityStatus.absent;
    const secondary = AppTheme.textSecondary;

    // Plus de cadre ni de fond teinté derrière Présent / Absent : les boutons
    // se posent directement sur la carte.
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _AvailabilityChoice(
                  label: 'Présent',
                  icon: Icons.check_circle_outlined,
                  color: AppTheme.success,
                  solid: AppTheme.availabilityInSolid,
                  selected: selectedAvailable,
                  onPressed: saving ? null : onAvailable,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AvailabilityChoice(
                  label: 'Absent',
                  icon: Icons.cancel_outlined,
                  color: AppTheme.error,
                  solid: AppTheme.availabilityOutSolid,
                  selected: selectedAbsent,
                  onPressed: saving ? null : onAbsent,
                ),
              ),
            ],
          ),
          if (saving) ...[
            const SizedBox(height: 8),
            const PfLinearProgressIndicator(minHeight: 2),
          ],
          if (showManageShortcut) ...[
            const SizedBox(height: 14),
            Divider(
              height: 1,
              thickness: 1,
              color: AppTheme.outline.withValues(alpha: .3),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Gestion du match',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: secondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onOpenEffectif,
                    child: const Text('Effectif'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onOpenComposition,
                    child: const Text('Compo'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Un des deux choix Présent / Absent, comme sur l'ancienne version de
/// l'appli : fond translucide + icône + texte blanc quand il n'est pas choisi
/// (le fond noir des boutons à contour jurait sur la carte colorée), aplat
/// vert ou rouge profond, texte blanc, quand il l'est.
///
/// Le thème peint un dégradé rouge sur tous les boutons pleins, qui écrasait
/// le vert de « Présent » : [PfButtonStyles.solid] le remplace par un aplat.
class _AvailabilityChoice extends StatelessWidget {
  const _AvailabilityChoice({
    required this.label,
    required this.icon,
    required this.color,
    required this.solid,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;

  /// Couleur de l'icône quand le bouton n'est pas choisi.
  final Color color;

  /// Aplat quand le bouton est choisi.
  final Color solid;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: PfButtonStyles.solid(solid, foreground: Colors.white),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: .08),
        foregroundColor: AppTheme.textPrimary,
        iconColor: color,
        side: BorderSide(color: Colors.white.withValues(alpha: .22)),
      ),
    );
  }
}

/// Rappel affiché à la place des boutons quand le match tombe dans une période
/// d'indisponibilité déclarée par le joueur.
class _DeclaredUnavailabilityCard extends StatelessWidget {
  const _DeclaredUnavailabilityCard({required this.availability});

  final MatchAvailability availability;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starts = availability.unavailabilityStartsOn;
    final ends = availability.unavailabilityEndsOn;
    final period = starts == null || ends == null
        ? null
        : formatUnavailabilityPeriod(starts, ends);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.event_busy_outlined, color: AppTheme.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period == null
                        ? 'Tu es déclaré indisponible'
                        : 'Tu es déclaré indisponible $period',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    availability.unavailabilityReason ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tu ne fais pas partie de l’effectif convocable pour ce '
                    'match. Modifie ou annule ta période dans Paramètres.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
