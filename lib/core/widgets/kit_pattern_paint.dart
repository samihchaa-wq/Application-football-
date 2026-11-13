import 'package:as_grinta/core/club/club_kits.dart';
import 'package:flutter/painting.dart';

/// Même motif sur la fiche Infos, le portrait, le patron et la vidéo.
void paintKitPattern(Canvas canvas, Rect area, KitPattern pattern, Color trim) {
  final paint = Paint()..color = trim;
  switch (pattern) {
    case KitPattern.plain:
      break;
    case KitPattern.stripes:
      for (var i = 1; i < 6; i += 2) {
        canvas.drawRect(
          Rect.fromLTWH(
            area.left + area.width * i / 6,
            area.top,
            area.width / 6,
            area.height,
          ),
          paint,
        );
      }
    case KitPattern.hoops:
      for (var i = 1; i < 6; i += 2) {
        canvas.drawRect(
          Rect.fromLTWH(
            area.left,
            area.top + area.height * i / 6,
            area.width,
            area.height / 6,
          ),
          paint,
        );
      }
    case KitPattern.sash:
      canvas.drawPath(
        Path()
          ..moveTo(area.left, area.top)
          ..lineTo(area.left + area.width * .24, area.top)
          ..lineTo(area.right, area.bottom - area.height * .24)
          ..lineTo(area.right, area.bottom)
          ..lineTo(area.right - area.width * .24, area.bottom)
          ..lineTo(area.left, area.top + area.height * .24)
          ..close(),
        paint,
      );
  }
}
