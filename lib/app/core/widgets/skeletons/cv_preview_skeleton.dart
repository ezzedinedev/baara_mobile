import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_shapes.dart';
import 'skeleton_box.dart';

/// Skeleton de l'écran Aperçu CV : barre modèle + page A4 + CTA bas.
class CvPreviewSkeleton extends StatelessWidget {
  const CvPreviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: AppColors.surfaceLow,
              shape: AppShapes.cardBordered(AppColors.outlineVariant),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: SkeletonCluster(
                child: Row(
                  children: [
                    SkeletonBox(height: 18, width: 18, radius: 6),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(height: 13, width: 140),
                          SizedBox(height: 6),
                          SkeletonBox(height: 10, width: 90),
                        ],
                      ),
                    ),
                    SkeletonBox(height: 18, width: 18, radius: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Center(
              child: AspectRatio(
                aspectRatio: 210 / 297,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: AppColors.surfaceCard,
                    shape: AppShapes.squircle(AppRadius.md),
                    shadows: AppColors.ambientShadow,
                  ),
                  child: const SkeletonCluster(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(height: 14, width: 120),
                          SizedBox(height: AppSpacing.md),
                          SkeletonBox(height: 10, width: double.infinity),
                          SizedBox(height: 8),
                          SkeletonBox(height: 10, width: double.infinity),
                          SizedBox(height: 8),
                          SkeletonBox(height: 10, width: 200),
                          SizedBox(height: AppSpacing.lg),
                          SkeletonBox(height: 10, width: 80),
                          SizedBox(height: 8),
                          SkeletonBox(height: 10, width: double.infinity),
                          SizedBox(height: 8),
                          SkeletonBox(height: 10, width: double.infinity),
                          SizedBox(height: 8),
                          SkeletonBox(height: 10, width: 160),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: SkeletonBox(
              height: 52,
              width: double.infinity,
              radius: AppRadius.md,
            ),
          ),
        ),
      ],
    );
  }
}
