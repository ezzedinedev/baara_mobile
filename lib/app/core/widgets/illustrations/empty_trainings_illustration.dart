import 'package:flutter/material.dart';

import 'brand_illustration.dart';

/// Aucune formation / leçon : chapeau de diplômé sur livret.
class EmptyTrainingsIllustration extends BrandIllustration {
  const EmptyTrainingsIllustration({super.key, super.size, super.animate});

  @override
  CustomPainter createPainter(IllustrationPalette palette) =>
      _EmptyTrainingsPainter(palette);
}

class _EmptyTrainingsPainter extends IllustrationPainter {
  const _EmptyTrainingsPainter(super.palette);

  @override
  void paintScene(IllustrationCanvas c) {
    // Livret / écran de cours.
    final book = c.card(32, 66, 76, 44, radius: 12);
    c.canvas.drawRRect(book, c.fill(palette.surface));
    c.canvas.drawRRect(book, c.stroke(palette.line));
    c.ghostLines(44, 80, [40, 30], thickness: 5, gap: 11);

    // Bouton lecture (play) marque.
    c.canvas.drawCircle(c.p(92, 88), c.s(9), c.fill(palette.brandSoft));
    final play = Path()
      ..moveTo(c.s(89), c.s(84))
      ..lineTo(c.s(96), c.s(88))
      ..lineTo(c.s(89), c.s(92))
      ..close();
    c.canvas.drawPath(play, c.fill(palette.brand));

    // Chapeau de diplômé (mortier).
    final cx = c.s(70);
    final cy = c.s(44);
    final hw = c.s(30);
    final cap = Path()
      ..moveTo(cx, cy - c.s(10))
      ..lineTo(cx + hw, cy)
      ..lineTo(cx, cy + c.s(10))
      ..lineTo(cx - hw, cy)
      ..close();
    c.canvas.drawPath(cap, c.fill(palette.brand));
    // Base du chapeau.
    c.canvas.drawRRect(
      c.card(58, 44, 24, 10, radius: 3),
      c.fill(palette.accentPurple),
    );
    // Pompon.
    c.canvas.drawLine(
        c.p(70, 44), c.p(94, 54), c.stroke(palette.brand, widthFactor: 1));
    c.canvas.drawCircle(c.p(94, 56), c.s(3), c.fill(palette.accentOrange));
  }
}
