import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';

/// Panneau « verre liquide » (Apple Liquid Glass + Material 3 tonal) :
/// flou d'arrière-plan + couche translucide tonale dark-aware, liseré
/// spéculaire en haut et bordure hairline. Coins squircle par défaut.
///
/// À RÉSERVER à la « chrome » : barre de nav, en-têtes, sheets, overlays hero.
/// NE PAS poser sur des listes longues ou des cellules scrollables (le
/// [BackdropFilter] est coûteux). Le blur est enveloppé dans un
/// [RepaintBoundary] et peut être désactivé via [enableBlur] (devices faibles)
/// pour retomber sur une surface translucide opaque.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.blurSigma = 20,
    this.enableBlur = true,
    this.tintAlpha,
    this.specular = true,
    this.borderColor,
    this.boxShadow,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Rayon des coins. Par défaut squircle de card. Passer
  /// [AppShapes.pill] pour une capsule (nav flottante).
  final BorderRadius? borderRadius;

  /// Intensité du flou (18-22 recommandé). Ignoré si [enableBlur] est false.
  final double blurSigma;

  /// Repli perf : si false, pas de [BackdropFilter] (surface translucide
  /// opaque à la place). À piloter selon les capacités du device.
  final bool enableBlur;

  /// Alpha de la couche tonale (surfaceCard). Défaut dark-aware (~0.6-0.7).
  final double? tintAlpha;

  /// Liseré spéculaire (gradient blanc faible → transparent) en haut.
  final bool specular;

  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  /// Teinte de base de la couche translucide (défaut [AppColors.surfaceCard]).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppShapes.cardRadius;
    final baseTint = color ?? AppColors.surfaceCard;
    // Sans blur on opacifie davantage pour garder la lisibilité.
    final alpha = tintAlpha ?? (enableBlur ? 0.66 : 0.94);

    final tonalLayer = DecoratedBox(
      decoration: BoxDecoration(
        color: baseTint.withValues(alpha: alpha),
        borderRadius: radius,
        border: Border.all(
          color:
              borderColor ?? AppColors.outlineVariant.withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Liseré spéculaire : reflet doux en haut du verre.
          if (specular)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(
                          alpha: AppColors.background.computeLuminance() < 0.2
                              ? 0.06
                              : 0.55,
                        ),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5],
                    ),
                  ),
                ),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    final shadowed = boxShadow == null
        ? tonalLayer
        : DecoratedBox(
            decoration:
                BoxDecoration(borderRadius: radius, boxShadow: boxShadow),
            child: tonalLayer,
          );

    if (!enableBlur) {
      return ClipRRect(borderRadius: radius, child: shadowed);
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: shadowed,
        ),
      ),
    );
  }
}
