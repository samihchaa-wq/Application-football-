import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Garantit un ordre de focus prévisible et un défilement utilisable au clavier,
/// à la souris et au tactile sur toutes les plateformes.
///
/// La vue suit également le focus : sans cela, la navigation au clavier
/// démarrait sur les fiches de matchs terminés situées plus de 1 600 px
/// au-dessus de la fenêtre, et il fallait dix-sept tabulations devant un écran
/// figé avant qu'un élément visible ne réagisse (échec WCAG 2.4.7).
class PfAccessibilityScope extends StatefulWidget {
  const PfAccessibilityScope({required this.child, super.key});

  final Widget child;

  @override
  State<PfAccessibilityScope> createState() => _PfAccessibilityScopeState();
}

class _PfAccessibilityScopeState extends State<PfAccessibilityScope> {
  FocusNode? _lastFocused;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    final node = FocusManager.instance.primaryFocus;
    if (node == null || identical(node, _lastFocused)) return;
    _lastFocused = node;

    // Un focus pris au doigt est déjà à l'écran : seul le parcours au clavier
    // a besoin de ce rattrapage.
    if (FocusManager.instance.highlightMode != FocusHighlightMode.traditional) {
      return;
    }

    final focusContext = node.context;
    if (focusContext == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !focusContext.mounted) return;
      if (Scrollable.maybeOf(focusContext) == null) return;
      Scrollable.ensureVisible(
        focusContext,
        alignment: .5,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: ScrollConfiguration(
        behavior: const _PfScrollBehavior(),
        child: Semantics(
          container: true,
          explicitChildNodes: false,
          child: PfFocusRing(child: widget.child),
        ),
      ),
    );
  }
}

/// Contour bien visible autour de l'élément qui a le focus clavier.
///
/// Le reflet de focus de Material (un voile à 12 %) était presque invisible
/// sur le thème sombre. Le contour n'apparaît qu'au clavier (Tab), jamais
/// au toucher ni à la souris.
class PfFocusRing extends StatefulWidget {
  const PfFocusRing({required this.child, super.key});

  final Widget child;

  /// Couleur du contour : jaune clair, contraste élevé sur le fond sombre.
  static const Color color = Color(0xFFFFD54F);

  @override
  State<PfFocusRing> createState() => _PfFocusRingState();
}

class _PfFocusRingState extends State<PfFocusRing> {
  final GlobalKey _stackKey = GlobalKey();
  Rect? _rect;
  bool _tracking = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_update);
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_update);
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode _) => _update();

  Rect? _focusedRect() {
    if (FocusManager.instance.highlightMode != FocusHighlightMode.traditional) {
      return null;
    }
    final node = FocusManager.instance.primaryFocus;
    final focusContext = node?.context;
    if (node == null || focusContext == null || !focusContext.mounted) {
      return null;
    }
    // Les nœuds qui ne servent qu'à regrouper (route, page) n'ont pas de
    // contour : seul un élément qu'on peut actionner en reçoit un.
    if (!node.canRequestFocus || node.skipTraversal) return null;
    final box = focusContext.findRenderObject();
    final stack = _stackKey.currentContext?.findRenderObject();
    if (box is! RenderBox ||
        stack is! RenderBox ||
        !box.attached ||
        !box.hasSize ||
        !stack.attached) {
      return null;
    }
    final size = stack.size;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: stack);
    final rect = topLeft & box.size;
    // Élément couvrant tout l'écran (page entière) : pas de contour.
    if (rect.width >= size.width - 1 && rect.height >= size.height - 1) {
      return null;
    }
    return rect;
  }

  void _update() {
    if (!mounted) return;
    final next = _focusedRect();
    if (next != _rect) setState(() => _rect = next);
    // Tant qu'un focus clavier est affiché, on suit l'élément image après
    // image (défilement, animation) ; sinon on ne fait rien.
    if (next != null && !_tracking) {
      _tracking = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tracking = false;
        _update();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rect = _rect;
    return Stack(
      key: _stackKey,
      children: [
        widget.child,
        if (rect != null)
          Positioned.fromRect(
            rect: rect.inflate(3),
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: DecoratedBox(
                  key: const ValueKey('pf-focus-ring'),
                  decoration: BoxDecoration(
                    border: Border.all(color: PfFocusRing.color, width: 3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PfScrollBehavior extends MaterialScrollBehavior {
  const _PfScrollBehavior();

  /// Chaque zone qui défile forme un groupe pour la touche Tab : le parcours
  /// « dans l'ordre de lecture » trie sinon les éléments par position à
  /// l'écran, et les cartes déjà construites au-dessus de la vue (historique
  /// de 2015 sur le Calendrier) passaient avant le bandeau, la cloche et
  /// « Nouvel événement ». En groupe, la liste prend la place de sa fenêtre
  /// visible dans l'ordre de la page.
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return FocusTraversalGroup(
      child: super.buildOverscrollIndicator(context, child, details),
    );
  }

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
