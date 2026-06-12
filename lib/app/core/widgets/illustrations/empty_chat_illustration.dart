import 'package:flutter/material.dart';

import 'brand_illustration.dart';

/// Conversation vide (thread) : deux bulles de discussion qui s'amorcent.
class EmptyChatIllustration extends BrandIllustration {
  const EmptyChatIllustration({super.key, super.size, super.animate});

  @override
  CustomPainter createPainter(IllustrationPalette palette) =>
      _EmptyChatPainter(palette);
}

class _EmptyChatPainter extends IllustrationPainter {
  const _EmptyChatPainter(super.palette);

  void _bubble(IllustrationCanvas c, RRect r, Color color, bool tailLeft) {
    c.canvas.drawRRect(r, c.fill(color));
    final tail = Path();
    if (tailLeft) {
      tail
        ..moveTo(r.left + c.s(6), r.bottom - c.s(2))
        ..lineTo(r.left - c.s(6), r.bottom + c.s(8))
        ..lineTo(r.left + c.s(18), r.bottom - c.s(2));
    } else {
      tail
        ..moveTo(r.right - c.s(6), r.bottom - c.s(2))
        ..lineTo(r.right + c.s(6), r.bottom + c.s(8))
        ..lineTo(r.right - c.s(18), r.bottom - c.s(2));
    }
    tail.close();
    c.canvas.drawPath(tail, c.fill(color));
  }

  @override
  void paintScene(IllustrationCanvas c) {
    // Bulle reçue (surface).
    final left = c.card(24, 44, 64, 32, radius: 12);
    _bubble(c, left, palette.surface, true);
    c.canvas.drawRRect(left, c.stroke(palette.line));
    c.ghostLines(34, 53, [40, 28], thickness: 4, gap: 9);

    // Bulle envoyée (marque douce).
    final right = c.card(56, 84, 60, 30, radius: 12);
    _bubble(c, right, palette.brandSoft, false);
    c.ghostLines(66, 92, [36, 22],
        thickness: 4, gap: 9, color: palette.brand.withValues(alpha: 0.55));
  }
}
