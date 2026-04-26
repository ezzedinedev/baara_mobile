import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../app/core/theme/app_colors.dart';

/// Couche decorative cinematique pour les heros wavy.
/// Empile : (1) bokeh d'orbes lumineuses qui derivent, (2) anneaux topo
/// concentriques en rotation lente, (3) poussiere d'etoiles scintillantes.
/// Tout pilote par un seul AnimationController (12s loop) pour rester sobre
/// en perfs. Le widget se positionne en `Positioned.fill` derriere le contenu.
class AnimatedHeroDecoration extends StatefulWidget {
  const AnimatedHeroDecoration({
    super.key,
    this.tintColor,
    this.intensity = 1.0,
  });

  /// Teinte des orbes / anneaux. Defaut : `onPrimary` (sur les heros sombres).
  final Color? tintColor;

  /// 0..1 : module l'opacite generale (utile sur fond clair).
  final double intensity;

  @override
  State<AnimatedHeroDecoration> createState() => _AnimatedHeroDecorationState();
}

class _AnimatedHeroDecorationState extends State<AnimatedHeroDecoration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = widget.tintColor ?? AppColors.onPrimary;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _HeroDecorationPainter(
              t: _ctrl.value,
              tint: tint,
              intensity: widget.intensity,
            ),
          );
        },
      ),
    );
  }
}

class _HeroDecorationPainter extends CustomPainter {
  _HeroDecorationPainter({
    required this.t,
    required this.tint,
    required this.intensity,
  });

  final double t; // 0..1, wraps
  final Color tint;
  final double intensity;

  // 4 orbes — trajectoires + tailles plus marquees pour un effet visible.
  static const _orbs = <_OrbConfig>[
    _OrbConfig(
      seedAngle: 0.0,
      orbitRadiusX: 0.22,
      orbitRadiusY: 0.14,
      centerX: 0.25,
      centerY: 0.32,
      radius: 130,
      speed: 1.0,
      pulseAmp: 0.10,
      baseAlpha: 0.36,
    ),
    _OrbConfig(
      seedAngle: math.pi * 0.6,
      orbitRadiusX: 0.18,
      orbitRadiusY: 0.10,
      centerX: 0.78,
      centerY: 0.58,
      radius: 110,
      speed: 0.7,
      pulseAmp: 0.12,
      baseAlpha: 0.30,
    ),
    _OrbConfig(
      seedAngle: math.pi * 1.3,
      orbitRadiusX: 0.24,
      orbitRadiusY: 0.10,
      centerX: 0.55,
      centerY: 0.18,
      radius: 80,
      speed: 1.4,
      pulseAmp: 0.14,
      baseAlpha: 0.26,
    ),
    _OrbConfig(
      seedAngle: math.pi * 0.3,
      orbitRadiusX: 0.16,
      orbitRadiusY: 0.12,
      centerX: 0.10,
      centerY: 0.78,
      radius: 95,
      speed: 0.9,
      pulseAmp: 0.10,
      baseAlpha: 0.28,
    ),
  ];

  // Anneaux topo : 4 spots, chacun avec rotation lente.
  static const _ringSpots = <_RingSpotConfig>[
    _RingSpotConfig(
      cx: 0.25,
      cy: 0.40,
      baseR: 95,
      ringCount: 5,
      ringGap: 12,
      rotateSpeed: 1.0,
    ),
    _RingSpotConfig(
      cx: 0.75,
      cy: 0.62,
      baseR: 75,
      ringCount: 5,
      ringGap: 11,
      rotateSpeed: -0.8,
    ),
    _RingSpotConfig(
      cx: 0.55,
      cy: 0.18,
      baseR: 55,
      ringCount: 4,
      ringGap: 10,
      rotateSpeed: 1.4,
    ),
    _RingSpotConfig(
      cx: 0.15,
      cy: 0.78,
      baseR: 65,
      ringCount: 4,
      ringGap: 11,
      rotateSpeed: -1.2,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _drawOrbs(canvas, size);
    _drawSweepBeam(canvas, size);
    _drawTopoRings(canvas, size);
    _drawSparkles(canvas, size);
  }

  /// Rayon de lumière diagonal qui traverse le hero — l'effet "premium"
  /// qu'on voit sur les heros Apple/Stripe. Position et opacité animées.
  void _drawSweepBeam(Canvas canvas, Size size) {
    // 2 balayages decalles dans le temps.
    for (int i = 0; i < 2; i++) {
      final phase = (t + i * 0.5) % 1.0;
      // L'opacite croit puis decroit (cloche) sur le passage.
      final fade = math.pow(math.sin(phase * math.pi), 2).toDouble();
      if (fade < 0.05) continue;

      // Position du centre du beam : de -0.2 a 1.2 sur l'axe X.
      final progress = phase * 1.4 - 0.2;
      final centerX = size.width * progress;
      final beamWidth = size.width * 0.32;

      // Gradient lineaire diagonal applique dans un rect oblique.
      final beamRect = Rect.fromCenter(
        center: Offset(centerX, size.height * 0.5),
        width: beamWidth,
        height: size.height * 1.6,
      );
      final shader = LinearGradient(
        begin: const Alignment(-1, -0.8),
        end: const Alignment(1, 0.8),
        colors: [
          tint.withValues(alpha: 0.0),
          tint.withValues(alpha: 0.18 * fade * intensity),
          tint.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(beamRect);

      final paint = Paint()..shader = shader;
      canvas.save();
      // Inclinaison du beam (~ -22deg).
      canvas.translate(centerX, size.height * 0.5);
      canvas.rotate(-0.38);
      canvas.translate(-centerX, -size.height * 0.5);
      canvas.drawRect(beamRect, paint);
      canvas.restore();
    }
  }

  void _drawOrbs(Canvas canvas, Size size) {
    const twoPi = math.pi * 2;
    for (final orb in _orbs) {
      final phase = (t * orb.speed * twoPi) + orb.seedAngle;
      final dx =
          size.width * (orb.centerX + orb.orbitRadiusX * math.cos(phase));
      final dy =
          size.height * (orb.centerY + orb.orbitRadiusY * math.sin(phase));
      final pulse = 1.0 + orb.pulseAmp * math.sin(phase * 2);
      final alpha = (orb.baseAlpha * intensity).clamp(0.0, 1.0);

      // Glow exterieur (large, tres translucide).
      final outer = Paint()
        ..color = tint.withValues(alpha: alpha * 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
      canvas.drawCircle(Offset(dx, dy), orb.radius * pulse, outer);

      // Coeur (plus net).
      final inner = Paint()
        ..color = tint.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawCircle(Offset(dx, dy), orb.radius * 0.55 * pulse, inner);
    }
  }

  void _drawTopoRings(Canvas canvas, Size size) {
    const twoPi = math.pi * 2;
    for (final spot in _ringSpots) {
      final cx = size.width * spot.cx;
      final cy = size.height * spot.cy;
      // La rotation s'exprime via un decalage des arcs et un pulse de rayon.
      final phase = t * spot.rotateSpeed * twoPi;
      final breathing = 1.0 + 0.05 * math.sin(phase);

      for (int i = 0; i < spot.ringCount; i++) {
        final r = (spot.baseR - i * spot.ringGap) * breathing;
        if (r <= 0) break;
        final ringAlpha = (0.20 + 0.04 * i) * intensity;
        final paint = Paint()
          ..color = tint.withValues(alpha: ringAlpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        // Cercles partiels qui tournent — donne une impression de mouvement.
        final arcStart = phase + i * 0.6;
        const arcSweep = math.pi * 1.6; // 288deg, le reste fade
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r),
          arcStart,
          arcSweep,
          false,
          paint,
        );
      }
    }
  }

  void _drawSparkles(Canvas canvas, Size size) {
    const twoPi = math.pi * 2;
    final paintBase = Paint()..style = PaintingStyle.fill;
    // 12 sparkles deterministes — chaque dot a sa propre phase.
    for (int i = 0; i < _sparkleSeeds.length; i++) {
      final s = _sparkleSeeds[i];
      // Twinkle : sin^2 → 0..1 lisse.
      final twinkle = math.pow(math.sin(t * twoPi * s.speed + s.phase), 2)
          .toDouble();
      final alpha = (s.maxAlpha * twinkle * intensity).clamp(0.0, 1.0);
      if (alpha < 0.02) continue;
      final dx = size.width * s.x;
      final dy = size.height * s.y;
      paintBase.color = tint.withValues(alpha: alpha);
      // Petite croix scintillante (4 traits) plutot qu'un cercle.
      final r = s.size * (0.6 + 0.4 * twinkle);
      canvas.drawCircle(Offset(dx, dy), r, paintBase);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroDecorationPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.tint != tint ||
        oldDelegate.intensity != intensity;
  }
}

class _OrbConfig {
  const _OrbConfig({
    required this.seedAngle,
    required this.orbitRadiusX,
    required this.orbitRadiusY,
    required this.centerX,
    required this.centerY,
    required this.radius,
    required this.speed,
    required this.pulseAmp,
    required this.baseAlpha,
  });

  final double seedAngle;
  final double orbitRadiusX;
  final double orbitRadiusY;
  final double centerX;
  final double centerY;
  final double radius;
  final double speed;
  final double pulseAmp;
  final double baseAlpha;
}

class _RingSpotConfig {
  const _RingSpotConfig({
    required this.cx,
    required this.cy,
    required this.baseR,
    required this.ringCount,
    required this.ringGap,
    required this.rotateSpeed,
  });

  final double cx;
  final double cy;
  final double baseR;
  final int ringCount;
  final double ringGap;
  final double rotateSpeed;
}

class _SparkleSeed {
  const _SparkleSeed({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.maxAlpha,
  });
  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;
  final double maxAlpha;
}

const _sparkleSeeds = <_SparkleSeed>[
  _SparkleSeed(x: 0.10, y: 0.18, size: 1.6, speed: 1.4, phase: 0.0, maxAlpha: 0.65),
  _SparkleSeed(x: 0.30, y: 0.62, size: 1.2, speed: 1.0, phase: 0.7, maxAlpha: 0.50),
  _SparkleSeed(x: 0.45, y: 0.40, size: 1.8, speed: 1.6, phase: 1.4, maxAlpha: 0.75),
  _SparkleSeed(x: 0.60, y: 0.78, size: 1.4, speed: 0.9, phase: 2.2, maxAlpha: 0.55),
  _SparkleSeed(x: 0.72, y: 0.20, size: 1.6, speed: 1.2, phase: 0.4, maxAlpha: 0.60),
  _SparkleSeed(x: 0.85, y: 0.45, size: 1.0, speed: 1.8, phase: 1.1, maxAlpha: 0.45),
  _SparkleSeed(x: 0.20, y: 0.85, size: 1.3, speed: 1.3, phase: 1.9, maxAlpha: 0.50),
  _SparkleSeed(x: 0.55, y: 0.10, size: 1.1, speed: 1.5, phase: 2.6, maxAlpha: 0.55),
  _SparkleSeed(x: 0.92, y: 0.72, size: 1.7, speed: 1.0, phase: 0.9, maxAlpha: 0.65),
  _SparkleSeed(x: 0.05, y: 0.50, size: 1.5, speed: 1.7, phase: 1.5, maxAlpha: 0.55),
  _SparkleSeed(x: 0.40, y: 0.92, size: 1.2, speed: 1.1, phase: 2.0, maxAlpha: 0.45),
  _SparkleSeed(x: 0.66, y: 0.55, size: 1.4, speed: 1.4, phase: 0.3, maxAlpha: 0.60),
];
