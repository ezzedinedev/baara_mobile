import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Reflet spéculaire « verre / métal » : une bande de lumière diagonale balaie
/// périodiquement la surface (comme la lumière qui glisse sur du verre quand on
/// incline le téléphone). Effet 2026 « matériaux physiques », mais **léger** :
/// un seul [AnimatedBuilder] dans un [RepaintBoundary], clippé à la forme.
///
/// Respecte « réduire les animations » (rendu statique = simple [child]).
class SheenSweep extends StatefulWidget {
  const SheenSweep({
    super.key,
    required this.child,
    this.borderRadius,
    this.period = const Duration(milliseconds: 4200),
    this.pause = const Duration(milliseconds: 2600),
    this.intensity = 0.22,
    this.color,
    this.angle = 0.35,
  });

  /// Surface à faire « briller ».
  final Widget child;

  /// Forme du masque (doit matcher le child). Défaut : coins arrondis 0.
  final BorderRadiusGeometry? borderRadius;

  /// Durée d'un balayage de la bande lumineuse.
  final Duration period;

  /// Temps mort entre deux balayages (l'effet respire, pas de scintillement).
  final Duration pause;

  /// Opacité max du reflet (0–1). Subtil par défaut.
  final double intensity;

  /// Couleur du reflet (spéculaire = clair par physique). Défaut : on-color.
  final Color? color;

  /// Inclinaison de la bande en radians (léger biais diagonal).
  final double angle;

  @override
  State<SheenSweep> createState() => _SheenSweepState();
}

class _SheenSweepState extends State<SheenSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    // Un cycle = balayage + pause (la pause est rendue par une portion « hors
    // cadre » de la course, donc invisible).
    duration: widget.period + widget.pause,
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    final reduceMotion =
        mq?.disableAnimations == true || mq?.accessibleNavigation == true;
    if (reduceMotion) return widget.child;

    final radius = widget.borderRadius ?? BorderRadius.zero;
    final sheenColor = widget.color ?? AppColors.onPrimary;
    // Fraction de la course consacrée au balayage visible (le reste = pause).
    final sweepSpan = widget.period.inMilliseconds /
        (widget.period.inMilliseconds + widget.pause.inMilliseconds);

    return RepaintBoundary(
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: radius.resolve(Directionality.maybeOf(context)),
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    final v = _ctrl.value;
                    if (v > sweepSpan) return const SizedBox.shrink();
                    // Progression du balayage 0→1 sur la portion visible.
                    final t = v / sweepSpan;
                    return CustomPaint(
                      painter: _SheenPainter(
                        progress: t,
                        color: sheenColor,
                        intensity: widget.intensity,
                        angle: widget.angle,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheenPainter extends CustomPainter {
  _SheenPainter({
    required this.progress,
    required this.color,
    required this.intensity,
    required this.angle,
  });

  final double progress;
  final Color color;
  final double intensity;
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    // La bande traverse de gauche (hors cadre) à droite (hors cadre).
    final bandWidth = size.width * 0.45;
    final travel = size.width + bandWidth * 2;
    final cx = -bandWidth + travel * progress;

    // Atténue le reflet en début/fin de course (apparition/disparition douce).
    final edge = (progress < 0.15)
        ? progress / 0.15
        : (progress > 0.85 ? (1 - progress) / 0.15 : 1.0);
    final peak = intensity * edge.clamp(0.0, 1.0);

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: peak),
        color.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromLTWH(cx - bandWidth, -size.height, bandWidth * 2,
        size.height * 3); // haut/bas dépassent pour couvrir l'inclinaison
    canvas.save();
    canvas.translate(cx, size.height / 2);
    canvas.rotate(angle);
    canvas.translate(-cx, -size.height / 2);
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SheenPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.intensity != intensity;
}
