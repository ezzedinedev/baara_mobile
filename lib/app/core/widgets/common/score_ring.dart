import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';

/// Anneau de score animé et raffiné, partagé par les écrans CV / Audit / Score
/// de profil. Trace un arc à dégradé (terminaisons arrondies) sur une piste
/// tonale, anime la valeur de 0 → [value] et affiche le nombre au centre (avec
/// un suffixe optionnel type « / 100 »).
///
/// La [color] doit être une variante *Accent* (theme-aware) pour rester lisible
/// en dark. Le dégradé est dérivé de cette couleur (pleine → ~70 % alpha) pour
/// un rendu plus vivant qu'un trait plat, sans valeur en dur.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.value,
    required this.color,
    this.size = 168,
    this.strokeWidth = 12,
    this.suffix,
    this.label,
    this.valueFontSize,
    this.duration = AppMotion.slow,
  });

  /// Score 0–100.
  final int value;
  final Color color;
  final double size;
  final double strokeWidth;

  /// Suffixe sous la valeur (ex : « / 100 »). Masqué si nul.
  final String? suffix;

  /// Petit libellé sous le suffixe (ex : « ATS »). Masqué si nul.
  final String? label;
  final double? valueFontSize;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100);
    final fontSize = valueFontSize ?? size * 0.27;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: clamped / 100),
        duration: duration,
        curve: AppMotion.enter,
        builder: (context, t, _) {
          final shown = (t * clamped).round();
          return CustomPaint(
            painter: _RingPainter(
              progress: t,
              color: color,
              trackColor: AppColors.surfaceHigh,
              strokeWidth: strokeWidth,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$shown',
                    style: AppTextStyles.displayMd.copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1.0,
                    ),
                  ),
                  if (suffix != null)
                    Text(
                      suffix!,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor),
                    ),
                  if (label != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      label!,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.hintColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, math.pi * 2, false, track);

    if (progress <= 0) return;

    final sweep = math.pi * 2 * progress;
    final arc = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + math.pi * 2,
        colors: [
          color.withValues(alpha: 0.65),
          color,
        ],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
