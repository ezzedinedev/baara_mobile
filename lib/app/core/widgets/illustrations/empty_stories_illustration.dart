import 'package:flutter/material.dart';

import 'brand_illustration.dart';

/// Aucune story : anneau de story (cercle pointillé) avec +.
class EmptyStoriesIllustration extends BrandIllustration {
  const EmptyStoriesIllustration({super.key, super.size, super.animate});

  @override
  CustomPainter createPainter(IllustrationPalette palette) =>
      _EmptyStoriesPainter(palette);
}

class _EmptyStoriesPainter extends IllustrationPainter {
  const _EmptyStoriesPainter(super.palette);

  @override
  void paintScene(IllustrationCanvas c) {
    final center = c.p(70, 72);
    final radius = c.s(32);

    // Anneau segmenté (story ring) en arcs colorés de marque.
    final ringPaint = c.stroke(palette.brand, widthFactor: 1.6);
    const segments = 8;
    final colors = [
      palette.brand,
      palette.accentBlue,
      palette.brand,
      palette.accentOrange,
      palette.brand,
      palette.accentPink,
      palette.brand,
      palette.accentPurple,
    ];
    final sweep = (3.14159 * 2) / segments;
    for (var i = 0; i < segments; i++) {
      ringPaint.color = colors[i];
      c.canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep + 0.12,
        sweep - 0.24,
        false,
        ringPaint,
      );
    }

    // Disque central (avatar vide).
    c.canvas.drawCircle(center, radius - c.s(8), c.fill(palette.surface));
    c.canvas.drawCircle(center, radius - c.s(8), c.stroke(palette.line));

    // + de marque (ajouter une story).
    c.canvas.drawCircle(c.p(96, 96), c.s(10), c.fill(palette.brand));
    c.canvas.drawLine(
        c.p(96, 91), c.p(96, 101), c.stroke(palette.surface, widthFactor: 1.3));
    c.canvas.drawLine(
        c.p(91, 96), c.p(101, 96), c.stroke(palette.surface, widthFactor: 1.3));
  }
}
