import 'package:petit_filet/app/shell/module_navigation.dart';
import 'package:petit_filet/core/club/club_identity.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/features/club/data/app_visit_logger.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/club/data/club_subscription.dart';
import 'package:petit_filet/features/club/presentation/club_suspended_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

@visibleForTesting
bool shouldRefocusMatchesAfterRouteReturn({
  required String? previousLocationPath,
  required String currentLocationPath,
}) {
  if (previousLocationPath == null ||
      previousLocationPath == '/matches' ||
      currentLocationPath != '/matches') {
    return false;
  }

  final segments = Uri.parse(previousLocationPath).pathSegments;
  final returnedFromModernPastMatch =
      segments.length == 2 && segments.first == 'matches';
  final returnedFromHistoricalMatch = segments.length == 3 &&
      segments[0] == 'matches' &&
      segments[1] == 'history';

  return !returnedFromModernPastMatch && !returnedFromHistoricalMatch;
}

/// Largeur maximale du contenu quand la barre latérale est affichée.
const double _maxContentWidth = 1080;

class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    required this.navigationShell,
    required this.location,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final String location;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  bool _matchFocusScheduled = false;
  bool _wasBackgrounded = false;
  // On mémorise nous-même l'index affiché à la frame précédente : le prop
  // `navigationShell` est le MÊME objet à chaque rebuild (StatefulShellRoute
  // ne le remplace pas), donc comparer `oldWidget.navigationShell.currentIndex`
  // à `widget.navigationShell.currentIndex` ne détecte jamais de transition —
  // les deux lisent l'état actuel du shell.
  int? _previousShellIndex;

  // Les écrans de la branche Calendrier partagent le même navigator. On garde
  // le chemin précédent pour distinguer une vraie arrivée sur `/matches` d'un
  // simple retour depuis une fiche de match consultée dans la chronologie.
  String? _previousLocationPath;

  Uri get _uri => Uri.parse(widget.location);
  int get _selectedIndex => widget.navigationShell.currentIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _logVisit());
  }

  // Compte la visite du jour pour le poste de contrôle de l'éditeur.
  void _logVisit() {
    if (!mounted) return;
    try {
      ref.read(appVisitLoggerProvider).log();
    } catch (_) {
      // Client indisponible (tests, démarrage incomplet) : rien à compter.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _wasBackgrounded = true;
      return;
    }
    if (state != AppLifecycleState.resumed || !_wasBackgrounded) return;
    _wasBackgrounded = false;
    _logVisit();
    if (_selectedIndex != 0 || _uri.path != '/matches') return;

    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || _selectedIndex != 0 || _uri.path != '/matches') return;
      _scheduleMatchFocus();
    });
  }

  void _scheduleMatchFocus() {
    if (_matchFocusScheduled) return;
    _matchFocusScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _matchFocusScheduled = false;
      if (!mounted) return;
      final notifier = ref.read(matchesFocusRequestProvider.notifier);
      notifier.state++;
    });
  }

  /// Bascule d'onglet sans empiler d'entrée d'historique.
  ///
  /// `goBranch` passe par `GoRouter.go()`, qui signale un `navigate` au moteur
  /// et crée donc une entrée à chaque aller-retour entre les onglets : après
  /// une session normale, l'historique atteignait le plafond de 50 entrées et
  /// le bouton Retour ne sortait plus jamais de l'application.
  /// `Router.neglect` conserve la mise à jour de l'URL mais la signale en
  /// remplacement de l'entrée courante.
  void _goBranchWithoutHistory(int index) {
    Router.neglect(
      context,
      () => widget.navigationShell.goBranch(index, initialLocation: true),
    );
  }

  void _openMatches() {
    if (widget.navigationShell.currentIndex != 0 || _uri.path != '/matches') {
      _goBranchWithoutHistory(0);
    }
    _scheduleMatchFocus();
  }

  void _openStats() {
    if (widget.navigationShell.currentIndex != 1 || _uri.path != '/stats') {
      _goBranchWithoutHistory(1);
    }
    ref.read(statsResetRequestProvider.notifier).state++;
  }

  void _selectDestination(int index) {
    if (index == 0) {
      _openMatches();
    } else {
      _openStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Club suspendu par l'éditeur : un écran d'explication remplace l'appli.
    if (ref.watch(myClubAccessProvider).valueOrNull == 'suspended') {
      return const ClubSuspendedPage();
    }

    // Une vraie arrivée sur Calendrier continue à recentrer sur l'élément
    // pertinent. Seul le simple pop d'une fiche de match issue du calendrier
    // conserve la position exacte afin de pouvoir parcourir plusieurs anciens
    // matchs à la suite.
    final currentShellIndex = widget.navigationShell.currentIndex;
    final currentLocationPath = _uri.path;
    final switchedToMatchesBranch = _previousShellIndex != null &&
        _previousShellIndex != 0 &&
        currentShellIndex == 0;
    final returnedToMatchesRoot = shouldRefocusMatchesAfterRouteReturn(
      previousLocationPath: _previousLocationPath,
      currentLocationPath: currentLocationPath,
    );

    if (switchedToMatchesBranch || returnedToMatchesRoot) {
      _scheduleMatchFocus();
    }
    _previousShellIndex = currentShellIndex;
    _previousLocationPath = currentLocationPath;

    final moduleTheme = Theme.of(context).copyWith(
      // Chaque route reste opaque afin que la page précédente ne traverse pas
      // le canvas pendant un geste Retour/Suivant du navigateur.
      scaffoldBackgroundColor: AppTheme.background,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Statistiques désactivées : il ne reste qu'un onglet, donc plus de
        // barre de navigation.
        final statsEnabled =
            ref.watch(clubModuleEnabledProvider(ClubModule.statistics));
        final useRail = constraints.maxWidth >= 840;
        final extendRail = constraints.maxWidth >= 1180;
        final content = Theme(data: moduleTheme, child: widget.navigationShell);
        // Sur grand écran, le contenu garde une largeur de lecture : des
        // cartes étirées sur 1 400 px sont pénibles à parcourir.
        final constrained = useRail
            ? Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: content,
                ),
              )
            : content;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            bottom: !useRail,
            child: Column(
              children: [
                Expanded(
                  child: useRail
                      ? Row(
                          children: [
                            if (statsEnabled) ...[
                              _DesktopNavigation(
                                selectedIndex: _selectedIndex,
                                extended: extendRail,
                                onSelected: _selectDestination,
                              ),
                              VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: AppTheme.outline.withValues(alpha: .28),
                              ),
                            ],
                            Expanded(child: constrained),
                          ],
                        )
                      : content,
                ),
              ],
            ),
          ),
          bottomNavigationBar: useRail || !statsEnabled
              ? null
              : Padding(
                  // Deux gros boutons avec texte, détachés des bords.
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: _NavButton(
                            label: 'Calendrier',
                            selected: _selectedIndex == 0,
                            onTap: () => _selectDestination(0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _NavButton(
                            label: 'Statistiques',
                            selected: _selectedIndex == 1,
                            onTap: () => _selectDestination(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({
    required this.selectedIndex,
    required this.extended,
    required this.onSelected,
  });

  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: extended ? 220 : 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 26),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/petit_filet_logo.webp',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                if (extended) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      ClubIdentity.appName,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _NavButton(
              label: 'Calendrier',
              selected: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _NavButton(
              label: 'Statistiques',
              selected: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton large de la barre du bas : texte seul, plein quand il est actif.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryBright, AppTheme.primary],
                  )
                : null,
            color: selected ? null : AppTheme.surfaceHigh,
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: .22)
                  : Colors.white.withValues(alpha: .10),
            ),
            boxShadow: AppTheme.cardShadows,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 17,
                    letterSpacing: .6,
                    color: selected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
