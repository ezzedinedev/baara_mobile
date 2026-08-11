import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_motion.dart';

/// Effet de **burst** de micro-particules pour les moments de délice (réaction,
/// like, ajout de favori). Léger, non bloquant, auto-nettoyé.
///
/// Posé via [Overlay] au point [globalPosition] (centre des particules). Les
/// particules jaillissent en arc puis retombent légèrement, avec un fade-out.
/// L'[AnimationController] et l'[OverlayEntry] sont disposés automatiquement à
/// la fin de l'animation (~600 ms).
///
/// Respecte reduce-motion : si `MediaQuery.disableAnimations` est actif, aucun
/// overlay n'est inséré (l'icône appelante garde son propre pop léger).
///
/// Usage :
/// ```dart
/// showBurst(context, anchorCenterGlobalOffset);
/// showBurst(context, offset, emoji: '❤️');
/// showBurst(context, offset, color: AppColors.primaryAccent);
/// ```
void showBurst(
  BuildContext context,
  Offset globalPosition, {
  String? emoji,
  Color? color,
  int particleCount = 10,
  double spread = 46,
}) {
  final media = MediaQuery.maybeOf(context);
  final reduceMotion =
      media?.disableAnimations == true || media?.accessibleNavigation == true;
  if (reduceMotion) return;

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _BurstOverlay(
      origin: globalPosition,
      emoji: emoji,
      color: color ?? AppColors.primaryAccent,
      particleCount: particleCount,
      spread: spread,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _BurstOverlay extends StatefulWidget {
  const _BurstOverlay({
    required this.origin,
    required this.color,
    required this.particleCount,
    required this.spread,
    required this.onDone,
    this.emoji,
  });

  final Offset origin;
  final String? emoji;
  final Color color;
  final int particleCount;
  final double spread;
  final VoidCallback onDone;

  @override
  State<_BurstOverlay> createState() => _BurstOverlayState();
}

class _BurstOverlayState extends State<_BurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    // Demi-cercle vers le haut (les particules jaillissent et retombent).
    _particles = List.generate(widget.particleCount, (i) {
      final base = -math.pi / 2; // vers le haut
      final angle = base +
          (i / widget.particleCount - 0.5) * math.pi * 0.9 +
          (rnd.nextDouble() - 0.5) * 0.4;
      final distance = widget.spread * (0.55 + rnd.nextDouble() * 0.65);
      final size = 4.0 + rnd.nextDouble() * 4.0;
      return _Particle(
        angle: angle,
        distance: distance,
        size: size,
        phase: rnd.nextDouble() * 0.18,
      );
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _BurstPainter(
              origin: widget.origin,
              particles: _particles,
              color: widget.color,
              emoji: widget.emoji,
              progress: _controller,
            ),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.phase,
  });

  final double angle;
  final double distance;
  final double size;
  final double phase; // léger décalage de départ [0..0.2]
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.origin,
    required this.particles,
    required this.color,
    required this.emoji,
    required this.progress,
  }) : super(repaint: progress);

  final Offset origin;
  final List<_Particle> particles;
  final Color color;
  final String? emoji;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Normalise la progression par particule (avec son léger retard).
      final local = ((t - p.phase) / (1 - p.phase)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      // Distance parcourue avec décélération (emphasized) + gravité douce.
      final eased = AppMotion.emphasizedDecelerate.transform(local);
      final travel = p.distance * eased;
      final gravity = p.distance * 0.35 * local * local; // retombée
      final dx = math.cos(p.angle) * travel;
      final dy = math.sin(p.angle) * travel + gravity;
      final pos = origin + Offset(dx, dy);

      final opacity = (1.0 - local).clamp(0.0, 1.0);
      final scale = (1.0 - local * 0.4).clamp(0.0, 1.0);

      if (emoji != null && emoji!.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: emoji,
            style: TextStyle(fontSize: 14 * scale),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        // Fondu de l'emoji (couleur intrinsèque) via un layer à alpha global.
        final rect = Rect.fromCenter(
          center: pos,
          width: tp.width + 4,
          height: tp.height + 4,
        );
        canvas.saveLayer(
          rect,
          Paint()..color = Colors.white.withValues(alpha: opacity),
        );
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
        canvas.restore();
      } else {
        paint.color = color.withValues(alpha: opacity);
        canvas.drawCircle(pos, p.size * scale, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.origin != origin ||
      oldDelegate.color != color ||
      oldDelegate.emoji != emoji ||
      oldDelegate.particles != particles;
}
