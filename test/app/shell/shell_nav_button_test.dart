import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/app/shell/app_shell.dart';

void main() {
  // La vraie police des boutons (Oswald, étroite) : la police de test par
  // défaut dessine chaque lettre en carré et couperait n'importe quel mot.
  setUpAll(() async {
    final loader = FontLoader('Oswald')
      ..addFont(rootBundle.load('assets/fonts/Oswald-Regular.ttf'));
    await loader.load();
  });

  testWidgets(
      'les boutons du bas gardent leur hauteur dans la barre du bas, '
      'ils ne prennent pas tout l’écran', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: ShellNavButton(
                    label: 'Calendrier',
                    selected: true,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShellNavButton(
                    label: 'Statistiques',
                    selected: false,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(ShellNavButton).first).height,
      lessThan(80),
    );
  });

  testWidgets(
      'avec un texte agrandi à 160 %, « Statistiques » reste entier : '
      'l’icône s’efface et le bouton grandit', (tester) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          textScaler: TextScaler.linear(1.6),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: ShellNavButton(
                      icon: Icons.calendar_month_outlined,
                      label: 'Calendrier',
                      selected: true,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShellNavButton(
                      icon: Icons.bar_chart_outlined,
                      label: 'Statistiques',
                      selected: false,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.bar_chart_outlined), findsNothing);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('Statistiques'),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(
      tester.getSize(find.byType(ShellNavButton).last).height,
      greaterThanOrEqualTo(52),
    );
  });
}
