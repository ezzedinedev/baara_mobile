import 'package:flutter/material.dart';

import 'brand_illustration.dart';

/// Erreur réseau : nuage déconnecté + éclair. Accent [error] dark-aware.
class ErrorIllustration extends BrandIllustration {
  const ErrorIllustration({super.key, super.size, super.animate});

  @override
  CustomPainter createPainter(IllustrationPalette palette) =>
      _ErrorPainter(palette);
}

class _ErrorPainter extends IllustrationPainter {
  const _ErrorPainter(super.palette);

  @override
  void paintScene(IllustrationCanvas c) {
    // Nuage (3 lobes + base).
    final cloud = Path();
    cloud.addOval(Rect.fromCircle(center: c.p(54, 62), radius: c.s(16)));
    cloud.addOval(Rect.fromCircle(center: c.p(82, 58), radius: c.s(20)));
    cloud.addOval(Rect.fromCircle(center: c.p(98, 70), radius: c.s(14)));
    cloud.addRRect(c.card(40, 66, 64, 22, radius: 11));
    c.canvas.drawPath(cloud, c.fill(palette.surface));

    // Contour adouci du nuage (silhouette).
    c.canvas.drawRRect(
      c.card(40, 66, 64, 22, radius: 11),
      c.stroke(palette.line),
    );

    // Éclair / signal coupé (accent erreur).
    final bolt = Path()
      ..moveTo(c.s(74), c.s(70))
      ..lineTo(c.s(64), c.s(96))
      ..lineTo(c.s(72), c.s(96))
      ..lineTo(c.s(66), c.s(114))
      ..lineTo(c.s(84), c.s(88))
      ..lineTo(c.s(75), c.s(88))
      ..close();
    c.canvas.drawPath(bolt, c.fill(palette.error));
  }
}
