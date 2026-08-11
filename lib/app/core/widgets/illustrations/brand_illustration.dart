import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';

/// Langage commun des illustrations de marque Baara (2026).
///
/// Toutes les scènes partagent :
/// - un **blob** de fond doux dérivé du mesh de marque,
/// - des formes géométriques aux coins arrondis cohérents,
/// - des traits (`stroke`) d'épaisseur homogène,
/// - 100 % de couleurs dérivées d'[AppColors] (dark-aware, zéro couleur en dur),
/// - une animation d'entrée subtile (fade + scale spring) optionnelle.
///
/// Chaque illustration concrète fournit un [CustomPainter] via [createPainter]
/// et hérite ainsi du conteneur, du blob de fond et de l'animation.
abstract class BrandIllustration extends StatefulWidget {
  const BrandIllustration({
    super.key,
    this.size = 140,
    this.animate = true,
  });

  /// Côté (carré) de l'illustration en logical pixels.
  final double size;

  /// Active l'anim d'entrée (fade + scale). Désactivable pour les listes denses.
  final bool animate;

  /// Construit le peintre de la scène. La palette est résolue au build (donc
  /// dark-aware) et passée au peintre.
  CustomPainter createPainter(IllustrationPalette palette);

  @override
  State<BrandIllustration> createState() => _BrandIllustrationState();
}

class _BrandIllustrationState extends State<BrandIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: AppMotion.long,
      vsync: this,
    );
    if (widget.animate) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Palette résolue au build → suit le thème (clair/sombre) via AppColors.
    final palette = IllustrationPalette.resolve();
    final painter = widget.createPainter(palette);

    final canvas = SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(painter: painter),
    );

    if (!widget.animate) return canvas;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final fade = Curves.easeOut.transform(_ctrl.value);
        final scale = 0.92 + 0.08 * AppMotion.spring.transform(_ctrl.value);
        return Opacity(
          opacity: fade.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: canvas,
    );
  }
}

/// Palette dérivée d'[AppColors] partagée par toutes les illustrations.
///
/// Centralise les couleurs/épaisseurs pour garantir un style 100 % cohérent et
/// dark-aware. Aucune couleur en dur : tout vient des getters [AppColors].
@immutable
class IllustrationPalette {
  const IllustrationPalette({
    required this.blobTop,
    required this.blobBottom,
    required this.surface,
    required this.surfaceAlt,
    required this.line,
    required this.brand,
    required this.brandSoft,
    required this.accentBlue,
    required this.accentOrange,
    required this.accentPink,
    required this.accentPurple,
    required this.success,
    required this.error,
    required this.faint,
  });

  /// Halo / blob de fond (dégradé doux de marque).
  final Color blobTop;
  final Color blobBottom;

  /// Surfaces des "objets" dessinés (cartes, boîtes, bulles).
  final Color surface;
  final Color surfaceAlt;

  /// Trait des contours.
  final Color line;

  /// Vert de marque en premier plan + variante douce.
  final Color brand;
  final Color brandSoft;

  /// Accents catégoriels (confettis, détails) — dérivés des tokens category*.
  final Color accentBlue;
  final Color accentOrange;
  final Color accentPink;
  final Color accentPurple;

  final Color success;
  final Color error;

  /// Très léger (lignes de texte fantôme, ombrages internes).
  final Color faint;

  /// Épaisseur de trait commune (échelle 1 = pour une illustration de 140 px).
  static const double strokeBase = 2.4;

  /// Résout la palette depuis [AppColors] (donc dark-aware au moment du build).
  factory IllustrationPalette.resolve() {
    return IllustrationPalette(
      blobTop: AppColors.primaryMedium.withValues(alpha: 0.16),
      blobBottom: AppColors.primary.withValues(alpha: 0.06),
      surface: AppColors.surfaceCard,
      surfaceAlt: AppColors.surfaceHigh,
      line: AppColors.outlineVariant,
      brand: AppColors.primaryAccent,
      brandSoft: AppColors.surfaceIconSoft,
      accentBlue: AppColors.categoryBlue,
      accentOrange: AppColors.categoryOrange,
      accentPink: AppColors.categoryPink,
      accentPurple: AppColors.categoryPurple,
      success: AppColors.successAccent,
      error: AppColors.errorAccent,
      faint: AppColors.hintColor.withValues(alpha: 0.30),
    );
  }

  // Égalité basée sur les couleurs theme-dépendantes : suffit à détecter un
  // changement de thème (clair/sombre) pour piloter shouldRepaint sans
  // repeindre inutilement.
  @override
  bool operator ==(Object other) =>
      other is IllustrationPalette &&
      other.surface == surface &&
      other.brand == brand &&
      other.line == line &&
      other.success == success &&
      other.error == error;

  @override
  int get hashCode => Object.hash(surface, brand, line, success, error);
}

/// Boîte à outils partagée par les peintres : helpers de dessin cohérents
/// (blob de fond, carte arrondie, trait de marque, confettis…).
///
/// Toutes les coordonnées sont normalisées sur une grille de 140×140 puis mises
/// à l'échelle selon la taille réelle, pour un rendu identique à toute taille.
class IllustrationCanvas {
  IllustrationCanvas(this.canvas, this.size, this.palette)
      : scale = size.width / _grid;

  static const double _grid = 140;

  final Canvas canvas;
  final Size size;
  final IllustrationPalette palette;
  final double scale;

  double get strokeWidth => IllustrationPalette.strokeBase * scale;

  /// Convertit un point de la grille 140×140 en point réel.
  Offset p(double x, double y) => Offset(x * scale, y * scale);

  double s(double v) => v * scale;

  /// Blob de fond doux centré (halo de marque commun à toutes les scènes).
  void paintBlob() {
    final rect = Rect.fromCenter(
      center: p(70, 72),
      width: s(132),
      height: s(120),
    );
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [palette.blobTop, palette.blobBottom],
      ).createShader(rect);
    final path = _blobPath(rect);
    canvas.drawPath(path, paint);
  }

  Path _blobPath(Rect r) {
    // Blob organique doux (4 lobes), stable et léger.
    final path = Path();
    final cx = r.center.dx;
    final cy = r.center.dy;
    final rx = r.width / 2;
    final ry = r.height / 2;
    path.moveTo(cx, cy - ry);
    path.cubicTo(
      cx + rx * 0.9, cy - ry * 0.9, //
      cx + rx, cy - ry * 0.1, //
      cx + rx * 0.82, cy + ry * 0.45,
    );
    path.cubicTo(
      cx + rx * 0.6, cy + ry, //
      cx - rx * 0.5, cy + ry * 1.02, //
      cx - rx * 0.85, cy + ry * 0.4,
    );
    path.cubicTo(
      cx - rx * 1.02, cy - ry * 0.1, //
      cx - rx * 0.85, cy - ry * 0.9, //
      cx, cy - ry,
    );
    path.close();
    return path;
  }

  Paint fill(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  Paint stroke(Color color, {double widthFactor = 1}) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth * widthFactor
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  /// Carte/rectangle arrondi (coins continus doux, langage squircle).
  RRect card(double x, double y, double w, double h, {double radius = 10}) {
    return RRect.fromRectAndRadius(
      Rect.fromLTWH(s(x), s(y), s(w), s(h)),
      Radius.circular(s(radius)),
    );
  }

  /// Lignes de texte "fantôme" (barres arrondies) dans une carte.
  void ghostLines(
    double x,
    double y,
    List<double> widths, {
    double gap = 9,
    double thickness = 5,
    Color? color,
  }) {
    final paint = fill(color ?? palette.faint);
    var dy = y;
    for (final w in widths) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s(x), s(dy), s(w), s(thickness)),
          Radius.circular(s(thickness / 2)),
        ),
        paint,
      );
      dy += gap;
    }
  }

  /// Petites particules de célébration (confettis) — accents catégoriels.
  void confetti() {
    final spots = <_Confetti>[
      _Confetti(p(28, 28), s(5), palette.accentBlue, true),
      _Confetti(p(112, 34), s(6), palette.accentOrange, false),
      _Confetti(p(118, 86), s(5), palette.accentPink, true),
      _Confetti(p(22, 92), s(6), palette.accentPurple, false),
      _Confetti(p(96, 20), s(4), palette.brand, false),
    ];
    for (final c in spots) {
      if (c.isCircle) {
        canvas.drawCircle(c.center, c.r, fill(c.color));
      } else {
        canvas.save();
        canvas.translate(c.center.dx, c.center.dy);
        canvas.rotate(0.6);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: c.r * 2, height: c.r * 2),
            Radius.circular(c.r * 0.5),
          ),
          fill(c.color),
        );
        canvas.restore();
      }
    }
  }
}

class _Confetti {
  const _Confetti(this.center, this.r, this.color, this.isCircle);
  final Offset center;
  final double r;
  final Color color;
  final bool isCircle;
}

/// Base de peintre : dessine le blob commun puis délègue la scène. Compare la
/// palette pour un [shouldRepaint] correct (repaint seulement au changement de
/// thème, jamais inutilement).
abstract class IllustrationPainter extends CustomPainter {
  const IllustrationPainter(this.palette);

  final IllustrationPalette palette;

  /// Dessine la scène spécifique (le blob de fond est déjà peint).
  void paintScene(IllustrationCanvas c);

  /// Surcharge si la scène ne veut pas le blob de fond commun.
  bool get withBlob => true;

  @override
  void paint(Canvas canvas, Size size) {
    final c = IllustrationCanvas(canvas, size, palette);
    if (withBlob) c.paintBlob();
    paintScene(c);
  }

  @override
  bool shouldRepaint(covariant IllustrationPainter old) =>
      old.palette != palette;
}
