import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/app/shell/app_shell.dart';

void main() {
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
}
