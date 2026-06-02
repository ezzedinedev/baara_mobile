import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// Icône dans un cercle pastel — pattern listes Paramètres / Sank Money.
class SoftCircleIcon extends StatelessWidget {
  const SoftCircleIcon({
    super.key,
    required this.icon,
    this.color,
    this.size = 48,
    this.iconSize = 22,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceIconSoft,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: resolved, size: iconSize),
    );
  }
}

/// @deprecated Préférer [ActionTile] sur l'accueil.
class GradientCircleIcon extends StatelessWidget {
  const GradientCircleIcon({
    super.key,
    required this.icon,
    this.size = 52,
    this.iconSize = 24,
    this.gradient,
    this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final LinearGradient? gradient;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Icon(
        icon,
        color: AppColors.primary,
        size: iconSize,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
