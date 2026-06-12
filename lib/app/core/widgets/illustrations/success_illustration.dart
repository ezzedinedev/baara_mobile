import 'package:flutter/material.dart';

import 'brand_illustration.dart';

/// Succès / candidature envoyée : coche dans un disque marque + confettis.
class SuccessIllustration extends BrandIllustration {
  const SuccessIllustration({super.key, super.size, super.animate});

  @override
  CustomPainter createPainter(IllustrationPalette palette) =>
      _SuccessPainter(palette);
}

class _SuccessPainter extends IllustrationPainter {
  const _SuccessPainter(super.palette);

  @override
  void paintScene(IllustrationCanvas c) {
    final center = c.p(70, 72);

    // Halo de succès.
    c.canvas.drawCircle(
        center, c.s(36), c.fill(palette.success.withValues(alpha: 0.14)));
    // Disque plein.
    c.canvas.drawCircle(center, c.s(26), c.fill(palette.success));

    // Coche.
    final check = Path()
      ..moveTo(c.s(58), c.s(72))
      ..lineTo(c.s(67), c.s(82))
      ..lineTo(c.s(84), c.s(60));
    c.canvas.drawPath(
      check,
      c.stroke(palette.surface, widthFactor: 1.8),
    );

    // Confettis de célébration.
    c.confetti();
  }
}
