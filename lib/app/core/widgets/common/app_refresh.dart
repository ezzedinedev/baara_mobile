import 'dart:math' as math;

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';

/// Indicateur de pull-to-refresh « de marque » (premium), réutilisé partout via
/// ce widget commun. Sous le capot il s'appuie sur [CustomRefreshIndicator] pour
/// peindre un **anneau de marque** custom ([_BrandRingPainter]) : l'arc se
/// remplit proportionnellement au tirage (`controller.value` 0→1) puis tourne en
/// continu pendant `armed`/`loading`, en [AppColors.primaryAccent] sur une
/// pastille [AppColors.surfaceCard] (cercle, ombre douce). Le contenu se décale
/// vers le bas pendant le tirage (effet natif géré dans le builder).
///
/// L'API publique est **strictement identique** à la version précédente
/// (`onRefresh`, `child`, `color`, `backgroundColor`, `strokeWidth`,
/// `edgeOffset`, `displacement`) : les ~18 écrans appelants ne changent pas.
/// Certains overrides ([edgeOffset], `displacement`) ne pilotent plus la mise en
/// page native mais restent acceptés pour ne casser aucun appelant.
///
/// Reduce-motion : si `MediaQuery.disableAnimations` est actif, on n'anime pas la
/// rotation (anneau statique simple) — l'arc de tirage reste, sans tourner.
class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 2.6,
    this.edgeOffset = 0,
    this.displacement = 52,
  });

  final RefreshCallback onRefresh;
  final Widget child;

  /// Couleur de l'anneau. Par défaut [AppColors.primaryAccent] (dark-aware).
  final Color? color;

  /// Fond de la pastille. Par défaut [AppColors.surfaceCard] (dark-aware).
  final Color? backgroundColor;

  final double strokeWidth;

  /// Conservé pour compat API (anciennement passé à `RefreshIndicator`).
  final double edgeOffset;

  /// Distance d'apparition de l'anneau depuis le bord (déplacement max).
  final double displacement;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final ringColor = color ?? AppColors.primaryAccent;
    final pastilleColor = backgroundColor ?? AppColors.surfaceCard;

    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      // Apparition décélérée premium + repli rapide (tokens AppMotion).
      durations: const RefreshIndicatorDurations(
        completeDuration: AppMotion.medium,
        finalizeDuration: AppMotion.short,
      ),
      builder: (context, child, controller) {
        return Stack(
          children: [
            // Le contenu se décale vers le bas pendant le tirage (effet natif).
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final offset =
                    controller.value.clamp(0.0, 1.5) * displacement * 0.6;
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: child,
                );
              },
              child: child,
            ),
            _BrandRefreshOverlay(
              controller: controller,
              ringColor: ringColor,
              pastilleColor: pastilleColor,
              strokeWidth: strokeWidth,
              displacement: displacement,
              edgeOffset: edgeOffset,
              reduceMotion: reduceMotion,
            ),
          ],
        );
      },
      child: child,
    );
  }
}

/// Calque qui positionne et anime la pastille de marque au-dessus du contenu.
class _BrandRefreshOverlay extends StatelessWidget {
  const _BrandRefreshOverlay({
    required this.controller,
    required this.ringColor,
    required this.pastilleColor,
    required this.strokeWidth,
    required this.displacement,
    required this.edgeOffset,
    required this.reduceMotion,
  });

  final IndicatorController controller;
  final Color ringColor;
  final Color pastilleColor;
  final double strokeWidth;
  final double displacement;
  final double edgeOffset;
  final bool reduceMotion;

  static const double _pastilleSize = 40;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: edgeOffset,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final progress = controller.value.clamp(0.0, 1.0);
            // L'anneau descend avec le tirage jusqu'à `displacement`.
            final slide = Curves.easeOut.transform(progress) * displacement;
            // Apparition (fade + scale) sur la première moitié du tirage.
            final appear =
                Curves.easeOut.transform((progress * 1.6).clamp(0.0, 1.0));

            if (appear <= 0 && controller.isIdle) {
              return const SizedBox.shrink();
            }

            return Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: slide),
                child: Opacity(
                  opacity: appear,
                  child: Transform.scale(
                    scale: 0.7 + 0.3 * appear,
                    child: _BrandPastille(
                      controller: controller,
                      ringColor: ringColor,
                      pastilleColor: pastilleColor,
                      strokeWidth: strokeWidth,
                      reduceMotion: reduceMotion,
                      size: _pastilleSize,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Pastille circulaire (surfaceCard + ombre douce) contenant l'anneau peint.
class _BrandPastille extends StatefulWidget {
  const _BrandPastille({
    required this.controller,
    required this.ringColor,
    required this.pastilleColor,
    required this.strokeWidth,
    required this.reduceMotion,
    required this.size,
  });

  final IndicatorController controller;
  final Color ringColor;
  final Color pastilleColor;
  final double strokeWidth;
  final bool reduceMotion;
  final double size;

  @override
  State<_BrandPastille> createState() => _BrandPastilleState();
}

class _BrandPastilleState extends State<_BrandPastille>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    widget.controller.addListener(_syncSpin);
  }

  /// Tourne uniquement quand l'indicateur est armé/charge (et hors reduce-motion).
  void _syncSpin() {
    if (widget.reduceMotion) return;
    final shouldSpin = widget.controller.isArmed ||
        widget.controller.isLoading ||
        widget.controller.isFinalizing;
    if (shouldSpin && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!shouldSpin && _spin.isAnimating) {
      _spin.stop();
      _spin.value = 0;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncSpin);
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.pastilleColor,
          shape: BoxShape.circle,
          boxShadow: AppColors.lightShadow,
        ),
        child: Center(
          child: SizedBox(
            width: widget.size * 0.55,
            height: widget.size * 0.55,
            child: AnimatedBuilder(
              // Repeint au fil du tirage ET de la rotation.
              animation: Listenable.merge([widget.controller, _spin]),
              builder: (context, _) {
                final progress = widget.controller.value.clamp(0.0, 1.0);
                final spinning = _spin.isAnimating;
                return CustomPaint(
                  painter: _BrandRingPainter(
                    progress: progress,
                    rotation: spinning ? _spin.value * 2 * math.pi : 0,
                    spinning: spinning,
                    color: widget.ringColor,
                    trackColor: widget.ringColor.withValues(alpha: 0.16),
                    strokeWidth: widget.strokeWidth,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Peinture légère de l'anneau de marque : piste tenue + arc qui se remplit
/// avec le tirage, puis arc « comète » qui tourne pendant le rafraîchissement.
class _BrandRingPainter extends CustomPainter {
  _BrandRingPainter({
    required this.progress,
    required this.rotation,
    required this.spinning,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  /// 0→1 : remplissage de l'arc pendant le tirage.
  final double progress;

  /// Angle de rotation (radians) pendant `armed`/`loading`.
  final double rotation;

  /// True pendant la phase de rafraîchissement (arc « comète »).
  final bool spinning;

  final Color color;
  final Color trackColor;
  final double strokeWidth;

  static const double _startAngle = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    if (spinning) {
      // Arc « comète » de ~270° qui tourne en continu.
      const sweep = 3 * math.pi / 2;
      canvas.drawArc(rect, _startAngle + rotation, sweep, false, arc);
    } else {
      // Pendant le tirage : l'arc se remplit proportionnellement.
      final sweep = (2 * math.pi) * progress.clamp(0.0, 1.0);
      if (sweep > 0) {
        canvas.drawArc(rect, _startAngle, sweep, false, arc);
      }
    }
  }

  @override
  bool shouldRepaint(_BrandRingPainter old) {
    return old.progress != progress ||
        old.rotation != rotation ||
        old.spinning != spinning ||
        old.color != color ||
        old.trackColor != trackColor ||
        old.strokeWidth != strokeWidth;
  }
}
