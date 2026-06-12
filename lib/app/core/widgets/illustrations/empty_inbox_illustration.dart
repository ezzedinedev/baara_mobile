import 'package:flutter/material.dart';

import 'brand_illustration.dart';

/// Messagerie vide (liste de conversations) : enveloppe stylisée + bulles.
class EmptyInboxIllustration extends BrandIllustration {
  const EmptyInboxIllustration({super.key, super.size, super.animate});

  @override
  CustomPainter createPainter(IllustrationPalette palette) =>
      _EmptyInboxPainter(palette);
}

class _EmptyInboxPainter extends IllustrationPainter {
  const _EmptyInboxPainter(super.palette);

  @override
  void paintScene(IllustrationCanvas c) {
    // Corps de l'enveloppe.
    final body = c.card(30, 52, 80, 56, radius: 12);
    c.canvas.drawRRect(body, c.fill(palette.surface));
    c.canvas.drawRRect(body, c.stroke(palette.line));

    // Rabat (V) de l'enveloppe.
    final flap = Path()
      ..moveTo(c.s(30), c.s(58))
      ..lineTo(c.s(70), c.s(86))
      ..lineTo(c.s(110), c.s(58));
    c.canvas.drawPath(flap, c.stroke(palette.brand, widthFactor: 1.1));

    // Petite pastille "marque" (notification) en haut à droite.
    c.canvas.drawCircle(c.p(108, 50), c.s(9), c.fill(palette.brand));
    c.canvas.drawCircle(
        c.p(108, 50), c.s(9), c.stroke(palette.surface, widthFactor: 1.2));
  }
}
