import 'package:flutter/material.dart';

import 'brand_illustration.dart';

/// Fil communautaire vide : carte de publication stylisée (avatar + lignes).
class EmptyFeedIllustration extends BrandIllustration {
  const EmptyFeedIllustration({super.key, super.size, super.animate});

  @override
  CustomPainter createPainter(IllustrationPalette palette) =>
      _EmptyFeedPainter(palette);
}

class _EmptyFeedPainter extends IllustrationPainter {
  const _EmptyFeedPainter(super.palette);

  @override
  void paintScene(IllustrationCanvas c) {
    // Carte arrière (décalée) pour suggérer une pile de posts.
    final back = c.card(40, 38, 70, 64, radius: 12);
    c.canvas.drawRRect(back, c.fill(palette.surfaceAlt));

    // Carte avant (post).
    final front = c.card(28, 50, 76, 64, radius: 12);
    c.canvas.drawRRect(front, c.fill(palette.surface));
    c.canvas.drawRRect(front, c.stroke(palette.line));

    // Avatar + nom.
    c.canvas.drawCircle(c.p(46, 68), c.s(8), c.fill(palette.brand));
    c.ghostLines(60, 62, [30, 18], thickness: 4, gap: 7);

    // Corps du post.
    c.ghostLines(40, 88, [56, 48, 32], thickness: 5, gap: 9);

    // Petit cœur de marque (like) en bas à droite.
    final hx = c.s(92);
    final hy = c.s(96);
    final r = c.s(4);
    final heart = Path()
      ..moveTo(hx, hy + r)
      ..cubicTo(hx - r * 2, hy - r, hx - r, hy - r * 2.2, hx, hy - r * 0.6)
      ..cubicTo(hx + r, hy - r * 2.2, hx + r * 2, hy - r, hx, hy + r)
      ..close();
    c.canvas.drawPath(heart, c.fill(palette.accentPink));
  }
}
