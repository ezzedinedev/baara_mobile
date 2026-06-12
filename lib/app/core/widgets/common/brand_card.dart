import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

class BrandCard extends StatelessWidget {
  const BrandCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = AppRadius.lg,
    this.borderColor,
    this.shadow = BrandCardShadow.none,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final BrandCardShadow shadow;

  /// Override de la couleur de fond. `null` = `AppColors.surfaceCard`.
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedBorderColor =
        borderColor ?? AppColors.outlineVariant.withValues(alpha: 0.4);
    final boxShadow = switch (shadow) {
      BrandCardShadow.none => null,
      BrandCardShadow.light => AppColors.lightShadow,
      BrandCardShadow.ambient => AppColors.ambientShadow,
    };

    final decoration = BoxDecoration(
      color: color ?? AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: resolvedBorderColor),
      boxShadow: boxShadow,
    );

    if (onTap == null) {
      return Container(
        decoration: decoration,
        padding: padding,
        child: child,
      );
    }
    // Avec onTap : clip pour que le ripple respecte le radius.
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Niveau d'ombre porte par [BrandCard].
enum BrandCardShadow { none, light, ambient }
