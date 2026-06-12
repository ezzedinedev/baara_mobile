import 'package:flutter/material.dart';

import 'brand_illustration.dart';

/// Aucune notification : cloche stylisée, calme (pas de pastille rouge).
class EmptyNotificationsIllustration extends BrandIllustration {
  const EmptyNotificationsIllustration({super.key, super.size, super.animate});

  @override
  CustomPainter createPainter(IllustrationPalette palette) =>
      _EmptyNotificationsPainter(palette);
}

class _EmptyNotificationsPainter extends IllustrationPainter {
  const _EmptyNotificationsPainter(super.palette);

  @override
  void paintScene(IllustrationCanvas c) {
    // Corps de la cloche (dôme + base).
    final bell = Path();
    bell.moveTo(c.s(50), c.s(92));
    bell.cubicTo(c.s(48), c.s(70), c.s(50), c.s(52), c.s(70), c.s(48));
    bell.cubicTo(c.s(90), c.s(52), c.s(92), c.s(70), c.s(90), c.s(92));
    bell.close();
    c.canvas.drawPath(bell, c.fill(palette.surface));
    c.canvas.drawPath(bell, c.stroke(palette.line));

    // Anse haute.
    c.canvas.drawCircle(c.p(70, 44), c.s(5), c.fill(palette.brand));

    // Lèvre basse (barre).
    c.canvas.drawRRect(
      c.card(44, 90, 52, 8, radius: 4),
      c.fill(palette.brandSoft),
    );
    // Battant.
    c.canvas.drawCircle(c.p(70, 102), c.s(5), c.fill(palette.brand));

    // Petites "ondes" de silence latérales (légères).
    c.canvas.drawArc(
      Rect.fromCircle(center: c.p(70, 70), radius: c.s(46)),
      -2.6,
      0.5,
      false,
      c.stroke(palette.faint, widthFactor: 0.9),
    );
    c.canvas.drawArc(
      Rect.fromCircle(center: c.p(70, 70), radius: c.s(46)),
      0.2,
      0.5,
      false,
      c.stroke(palette.faint, widthFactor: 0.9),
    );
  }
}
