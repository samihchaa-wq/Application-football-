import 'package:petit_filet/core/widgets/pf_accessibility_scope.dart';
import 'package:petit_filet/core/widgets/pf_labeled_button.dart';
import 'package:petit_filet/core/widgets/pf_status_banner.dart';
import 'package:petit_filet/core/widgets/pf_switch_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lecteur d'écran et clavier : ce que l'arbre d'accessibilité expose pour
/// les composants partagés corrigés à la suite de l'audit du 26/11/2026.
void main() {
  Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets(
      'interrupteur : nom et état annoncés, bouton d’information à part',
      (tester) async {
    final semantics = tester.ensureSemantics();
    var value = true;
    await tester.pumpWidget(app(StatefulBuilder(
      builder: (context, setState) => PfSwitchTile(
        label: 'Vidéo de la composition',
        value: value,
        onChanged: (next) => setState(() => value = next),
        trailingInfo: IconButton(
          tooltip: 'Informations',
          icon: const Icon(Icons.info_outlined),
          onPressed: () {},
        ),
      ),
    )));

    expect(
      tester.getSemantics(find.byType(Switch)),
      matchesSemantics(
        label: 'Vidéo de la composition',
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    // Le libellé visible n'est pas lu une deuxième fois.
    expect(find.bySemanticsLabel('Vidéo de la composition'), findsOneWidget);
    expect(find.byTooltip('Informations'), findsOneWidget);

    // Toucher la ligne bascule toujours l'interrupteur.
    await tester.tap(find.text('Vidéo de la composition'));
    await tester.pump();
    expect(
      tester.getSemantics(find.byType(Switch)),
      matchesSemantics(
        label: 'Vidéo de la composition',
        hasToggledState: true,
        isToggled: false,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('bandeau d’erreur : le message n’est lu qu’une fois',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app(const PfStatusBanner(
      title: 'Connexion impossible',
      message: 'Vérifie ton identifiant et ton mot de passe.',
      tone: PfStatusTone.error,
    )));

    expect(
      tester.getSemantics(find.byType(PfStatusBanner)),
      matchesSemantics(
        label: 'Connexion impossible. '
            'Vérifie ton identifiant et ton mot de passe.',
        isLiveRegion: true,
      ),
    );
    expect(find.bySemanticsLabel(RegExp('Vérifie')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('bouton d’en-tête nommé : atteignable au clavier',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app(PfLabeledButton(
      label: 'Notifications',
      semanticLabel: 'Notifications, 2 non lues',
      color: Colors.white,
      icon: const Icon(Icons.notifications_outlined),
      onTap: () {},
    )));

    expect(
      tester.getSemantics(find.byType(PfLabeledButton)),
      matchesSemantics(
        label: 'Notifications, 2 non lues',
        isButton: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets(
      'clavier : Tab passe par les boutons du haut avant la liste, '
      'et un contour bien visible suit le focus', (tester) async {
    final controller = ScrollController(initialScrollOffset: 600);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: PfAccessibilityScope(
        child: Scaffold(
          body: Column(
            children: [
              TextButton(onPressed: () {}, child: const Text('Cloche')),
              TextButton(
                onPressed: () {},
                child: const Text('Nouvel événement'),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  // Les cartes au-dessus de la vue restent construites.
                  cacheExtent: 2000,
                  children: [
                    for (var i = 0; i < 20; i++)
                      SizedBox(
                        height: 60,
                        child: TextButton(
                          onPressed: () {},
                          child: Text('Match $i'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    String? focusedText() {
      final focusContext = FocusManager.instance.primaryFocus?.context;
      if (focusContext == null) return null;
      final texts = find.descendant(
        of: find.byWidget(focusContext.widget),
        matching: find.byType(Text),
      );
      return texts.evaluate().isEmpty
          ? null
          : (texts.evaluate().first.widget as Text).data;
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focusedText(), 'Cloche');
    expect(find.byKey(const ValueKey('pf-focus-ring')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focusedText(), 'Nouvel événement');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focusedText(), startsWith('Match '));

    // Le contour entoure l'élément ciblé.
    final ring = tester.getRect(find.byKey(const ValueKey('pf-focus-ring')));
    final focused = FocusManager.instance.primaryFocus!.rect;
    expect(ring.contains(focused.center), isTrue);
  });

  testWidgets('au toucher, aucun contour de focus', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PfAccessibilityScope(
        child: Scaffold(
          body: TextButton(onPressed: () {}, child: const Text('Cloche')),
        ),
      ),
    ));
    await tester.tap(find.text('Cloche'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pf-focus-ring')), findsNothing);
  });
}
