import 'package:flutter/material.dart';

import 'brand_illustration.dart';

/// Aucune offre : mallette professionnelle stylisée.
class EmptyOffersIllustration extends BrandIllustration {
  const EmptyOffersIllustration({super.key, super.size, super.animate});

  @override
  CustomPainter createPainter(IllustrationPalette palette) =>
      _EmptyOffersPainter(palette);
}

class _EmptyOffersPainter extends IllustrationPainter {
  const _EmptyOffersPainter(super.palette);

  @override
  void paintScene(IllustrationCanvas c) {
    // Anse de la mallette.
    final handle = c.card(56, 42, 28, 18, radius: 6);
    c.canvas.drawRRect(handle, c.stroke(palette.brand, widthFactor: 1.2));

    // Corps de la mallette.
    final body = c.card(30, 54, 80, 56, radius: 12);
    c.canvas.drawRRect(body, c.fill(palette.surface));
    c.canvas.drawRRect(body, c.stroke(palette.line));

    // Bande centrale (séparation marque) — insérée pour rester dans le corps.
    c.canvas.drawRRect(
        c.card(34, 74, 72, 12, radius: 0), c.fill(palette.brandSoft));

    // Fermoir.
    c.canvas.drawRRect(c.card(64, 76, 12, 8, radius: 3), c.fill(palette.brand));
  }
}
