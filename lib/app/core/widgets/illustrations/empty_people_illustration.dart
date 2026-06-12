import 'package:flutter/material.dart';

import 'brand_illustration.dart';

/// Aucun membre / connexion / vue : deux silhouettes abstraites + lien.
class EmptyPeopleIllustration extends BrandIllustration {
  const EmptyPeopleIllustration({super.key, super.size, super.animate});

  @override
  CustomPainter createPainter(IllustrationPalette palette) =>
      _EmptyPeoplePainter(palette);
}

class _EmptyPeoplePainter extends IllustrationPainter {
  const _EmptyPeoplePainter(super.palette);

  void _person(IllustrationCanvas c, Offset head, double r, Color color) {
    // Tête.
    c.canvas.drawCircle(head, r, c.fill(color));
    // Buste (demi-capsule).
    final bust = Path();
    final bw = r * 2.4;
    final top = head.dy + r + c.s(3);
    bust.moveTo(head.dx - bw / 2, top + bw * 0.7);
    bust.arcToPoint(
      Offset(head.dx + bw / 2, top + bw * 0.7),
      radius: Radius.circular(bw / 1.6),
      clockwise: true,
    );
    bust.close();
    c.canvas.drawPath(bust, c.fill(color));
  }

  @override
  void paintScene(IllustrationCanvas c) {
    // Personne arrière (douce).
    _person(c, c.p(94, 58), c.s(13), palette.surfaceAlt);
    // Personne avant (marque).
    _person(c, c.p(52, 62), c.s(15), palette.brand);

    // Lien / connexion (arc reliant les deux).
    c.canvas.drawArc(
      Rect.fromCircle(center: c.p(73, 50), radius: c.s(22)),
      0.5,
      2.1,
      false,
      c.stroke(palette.faint, widthFactor: 1.1),
    );

    // Pastille "+" de connexion.
    c.canvas.drawCircle(c.p(100, 96), c.s(10), c.fill(palette.brandSoft));
    c.canvas.drawLine(
        c.p(100, 91), c.p(100, 101), c.stroke(palette.brand, widthFactor: 1.3));
    c.canvas.drawLine(
        c.p(95, 96), c.p(105, 96), c.stroke(palette.brand, widthFactor: 1.3));
  }
}
