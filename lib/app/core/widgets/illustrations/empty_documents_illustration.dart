import 'package:flutter/material.dart';

import 'brand_illustration.dart';

/// Aucun document : feuilles empilées avec coin replié (CV / diplômes).
class EmptyDocumentsIllustration extends BrandIllustration {
  const EmptyDocumentsIllustration({super.key, super.size, super.animate});

  @override
  CustomPainter createPainter(IllustrationPalette palette) =>
      _EmptyDocumentsPainter(palette);
}

class _EmptyDocumentsPainter extends IllustrationPainter {
  const _EmptyDocumentsPainter(super.palette);

  @override
  void paintScene(IllustrationCanvas c) {
    // Feuille arrière.
    c.canvas.drawRRect(
      c.card(48, 42, 50, 64, radius: 10),
      c.fill(palette.surfaceAlt),
    );

    // Feuille avant avec coin replié.
    const x = 36.0, y = 50.0, w = 54.0, h = 64.0, fold = 16.0;
    final page = Path()
      ..moveTo(c.s(x), c.s(y + 8))
      ..lineTo(c.s(x), c.s(y + h))
      ..lineTo(c.s(x + w), c.s(y + h))
      ..lineTo(c.s(x + w), c.s(y + fold))
      ..lineTo(c.s(x + w - fold), c.s(y))
      ..lineTo(c.s(x + 8), c.s(y))
      ..close();
    c.canvas.drawPath(page, c.fill(palette.surface));
    c.canvas.drawPath(page, c.stroke(palette.line));

    // Coin replié.
    final corner = Path()
      ..moveTo(c.s(x + w - fold), c.s(y))
      ..lineTo(c.s(x + w - fold), c.s(y + fold))
      ..lineTo(c.s(x + w), c.s(y + fold));
    c.canvas.drawPath(corner, c.stroke(palette.brand, widthFactor: 1.1));

    // Lignes de contenu.
    c.ghostLines(x + 8, y + 24, [34, 34, 24], thickness: 5, gap: 10);

    // Petit "+" de marque (ajouter un doc).
    c.canvas.drawCircle(c.p(96, 96), c.s(11), c.fill(palette.brand));
    c.canvas.drawLine(
        c.p(96, 91), c.p(96, 101), c.stroke(palette.surface, widthFactor: 1.3));
    c.canvas.drawLine(
        c.p(91, 96), c.p(101, 96), c.stroke(palette.surface, widthFactor: 1.3));
  }
}
