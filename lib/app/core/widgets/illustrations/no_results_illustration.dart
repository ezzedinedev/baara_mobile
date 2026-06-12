import 'package:flutter/material.dart';

import 'brand_illustration.dart';

/// Aucun résultat de recherche : loupe de marque sur cartes fantômes.
class NoResultsIllustration extends BrandIllustration {
  const NoResultsIllustration({super.key, super.size, super.animate});

  @override
  CustomPainter createPainter(IllustrationPalette palette) =>
      _NoResultsPainter(palette);
}

class _NoResultsPainter extends IllustrationPainter {
  const _NoResultsPainter(super.palette);

  @override
  void paintScene(IllustrationCanvas c) {
    // Carte de résultat fantôme derrière la loupe.
    final cardRect = c.card(26, 40, 64, 44, radius: 12);
    c.canvas.drawRRect(cardRect, c.fill(palette.surface));
    c.canvas.drawRRect(cardRect, c.stroke(palette.line));
    c.ghostLines(36, 52, [40, 28, 18], thickness: 5, gap: 9);

    // Loupe (cercle + manche) en premier plan, accent marque.
    final center = c.p(92, 84);
    final radius = c.s(20);
    c.canvas.drawCircle(center, radius, c.fill(palette.brandSoft));
    c.canvas
        .drawCircle(center, radius, c.stroke(palette.brand, widthFactor: 1.2));
    // Manche.
    final handle = Path()
      ..moveTo(center.dx + radius * 0.72, center.dy + radius * 0.72)
      ..lineTo(center.dx + radius * 1.5, center.dy + radius * 1.5);
    c.canvas.drawPath(
      handle,
      c.stroke(palette.brand, widthFactor: 1.6),
    );
  }
}
