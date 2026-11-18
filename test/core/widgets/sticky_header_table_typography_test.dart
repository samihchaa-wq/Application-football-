import 'package:petit_filet/core/widgets/sticky_header_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'la largeur minimale reprend exactement la typographie héritée',
    (tester) async {
      double? pinnedWidth;
      double? exactRequiredWidth;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          home: Scaffold(
            body: DefaultTextStyle(
              // Reproduit le point qui diffère selon la typographie de la
              // plateforme : Text hérite notamment du letter-spacing et de la
              // famille de police, contrairement à un TextPainter isolé.
              style: const TextStyle(letterSpacing: 2.5),
              child: Builder(
                builder: (context) {
                  const name = 'Stéphane';
                  const badgeSize = 48.0;
                  const badgeGap = 3.0;
                  final inheritedStyle = DefaultTextStyle.of(context).style;
                  final cellStyle = pfTableCellTextStyle(
                    context,
                    fontWeight: FontWeight.w800,
                  );
                  final resolvedStyle = inheritedStyle.merge(cellStyle);
                  final painter = TextPainter(
                    text: TextSpan(text: name, style: resolvedStyle),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                    locale: Localizations.maybeLocaleOf(context),
                    maxLines: 1,
                  )..layout();

                  exactRequiredWidth = pfTablePinnedRowPadding.left +
                      pfTableRankWidth +
                      pfTableRankGap +
                      painter.width +
                      badgeGap +
                      badgeSize +
                      pfTablePinnedRowPadding.right;
                  pinnedWidth = pfTablePinnedWidthForNames(
                    context,
                    const [name],
                    trailingWidth: badgeSize,
                    trailingGap: badgeGap,
                  );

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(pinnedWidth, greaterThanOrEqualTo(exactRequiredWidth!));
      expect(pinnedWidth! - exactRequiredWidth!, lessThan(1));
    },
  );
}
