import 'package:flutter/material.dart';

import 'brand_illustration.dart';

/// Aucune candidature : dossier de candidature avec coche d'envoi à venir.
class EmptyApplicationsIllustration extends BrandIllustration {
  const EmptyApplicationsIllustration({super.key, super.size, super.animate});

  @override
  CustomPainter createPainter(IllustrationPalette palette) =>
      _EmptyApplicationsPainter(palette);
}

class _EmptyApplicationsPainter extends IllustrationPainter {
  const _EmptyApplicationsPainter(super.palette);

  @override
  void paintScene(IllustrationCanvas c) {
    // Presse-papiers (dossier de candidature).
    final board = c.card(34, 44, 72, 70, radius: 12);
    c.canvas.drawRRect(board, c.fill(palette.surface));
    c.canvas.drawRRect(board, c.stroke(palette.line));

    // Pince haute.
    c.canvas
        .drawRRect(c.card(58, 38, 24, 12, radius: 4), c.fill(palette.brand));

    // Lignes (champs du dossier).
    c.ghostLines(46, 64, [48, 40], thickness: 5, gap: 11);

    // Case à cocher de marque (statut).
    final box = c.card(46, 88, 14, 14, radius: 4);
    c.canvas.drawRRect(box, c.fill(palette.brandSoft));
    c.canvas.drawRRect(box, c.stroke(palette.brand, widthFactor: 1));
    final check = Path()
      ..moveTo(c.s(49), c.s(95))
      ..lineTo(c.s(52), c.s(98))
      ..lineTo(c.s(57), c.s(91));
    c.canvas.drawPath(check, c.stroke(palette.brand, widthFactor: 1.3));
    c.ghostLines(66, 92, [30], thickness: 5);
  }
}
