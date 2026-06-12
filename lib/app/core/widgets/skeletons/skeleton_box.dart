import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_colors.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainer,
      highlightColor: AppColors.surfaceHigh,
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          shape: shape,
          borderRadius:
              shape == BoxShape.circle ? null : BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Wrapper qui applique le shimmer à un arbre de widgets arbitraire (ex: la structure
/// réelle d'une card en grisé). À préférer si la structure du skeleton est composée.
class SkeletonCluster extends StatelessWidget {
  const SkeletonCluster({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainer,
      highlightColor: AppColors.surfaceHigh,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}
