import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import 'press_scale.dart';

/// Si [onTap] est fourni, la carte réagit au tap avec un effet [PressScale].
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppRadius.md,
    this.bordered = true,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  /// Couleur de bordure personnalisée (ex: surlignage non-lu d'une notif).
  final Color? borderColor;
  final double radius;
  final bool bordered;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(radius),
        border: bordered
            ? Border.all(color: borderColor ?? AppColors.outlineVariant)
            : null,
        boxShadow: elevated ? AppColors.lightShadow : null,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return PressScale(onTap: onTap, child: card);
  }
}
