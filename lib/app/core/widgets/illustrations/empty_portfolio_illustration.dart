import 'package:flutter/material.dart';

import 'brand_illustration.dart';

/// Portfolio / réalisations vides : grille de tuiles créatives.
class EmptyPortfolioIllustration extends BrandIllustration {
  const EmptyPortfolioIllustration({super.key, super.size, super.animate});

  @override
  CustomPainter createPainter(IllustrationPalette palette) =>
      _EmptyPortfolioPainter(palette);
}

class _EmptyPortfolioPainter extends IllustrationPainter {
  const _EmptyPortfolioPainter(super.palette);

  @override
  void paintScene(IllustrationCanvas c) {
    // Cadre principal (galerie).
    final frame = c.card(30, 42, 80, 66, radius: 12);
    c.canvas.drawRRect(frame, c.fill(palette.surface));
    c.canvas.drawRRect(frame, c.stroke(palette.line));

    // Tuiles colorées (œuvres) — accents catégoriels.
    c.canvas
        .drawRRect(c.card(40, 52, 26, 22, radius: 6), c.fill(palette.brand));
    c.canvas.drawRRect(
        c.card(74, 52, 26, 22, radius: 6), c.fill(palette.accentBlue));
    c.canvas.drawRRect(
        c.card(40, 80, 26, 18, radius: 6), c.fill(palette.accentOrange));

    // Tuile vide (placeholder) avec +.
    final empty = c.card(74, 80, 26, 18, radius: 6);
    c.canvas.drawRRect(empty, c.fill(palette.brandSoft));
    c.canvas.drawLine(
        c.p(87, 84), c.p(87, 94), c.stroke(palette.brand, widthFactor: 1.2));
    c.canvas.drawLine(
        c.p(82, 89), c.p(92, 89), c.stroke(palette.brand, widthFactor: 1.2));
  }
}
