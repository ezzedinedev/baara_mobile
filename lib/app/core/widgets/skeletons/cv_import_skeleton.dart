import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_text_styles.dart';
import 'skeleton_box.dart';

/// Skeleton de traitement CV (analyse / amélioration / application).
class CvImportProcessingSkeleton extends StatelessWidget {
  const CvImportProcessingSkeleton({
    super.key,
    required this.label,
    required this.activeStep,
  });

  final String label;
  /// 0 = analyse, 1 = amélioration, 2 = application.
  final int activeStep;

  static const _steps = ['Analyse', 'Amélioration', 'Application'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceSelected,
              borderRadius: AppShapes.squircleRadius(AppRadius.sm),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: SkeletonCluster(
                child: Row(
                  children: [
                    SkeletonBox(height: 20, width: 20, radius: 6),
                    SizedBox(width: 10),
                    Expanded(child: SkeletonBox(height: 12, width: 160)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _StepIndicator(activeStep: activeStep),
          const SizedBox(height: AppSpacing.xl),
          DecoratedBox(
            decoration: ShapeDecoration(
              color: AppColors.surfaceCard,
              shape: AppShapes.cardBordered(AppColors.outlineVariant),
              shadows: AppColors.ambientShadow,
            ),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: SkeletonCluster(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 76, width: 76, shape: BoxShape.circle),
                    SizedBox(height: AppSpacing.lg),
                    SkeletonBox(height: 14, width: 180),
                    SizedBox(height: 10),
                    SkeletonBox(height: 10, width: double.infinity),
                    SizedBox(height: 8),
                    SkeletonBox(height: 10, width: double.infinity),
                    SizedBox(height: 8),
                    SkeletonBox(height: 10, width: 220),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.bodyColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.activeStep});

  final int activeStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < CvImportProcessingSkeleton._steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: AnimatedContainer(
                duration: AppMotion.short,
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: i <= activeStep
                      ? AppColors.primaryAccent
                      : AppColors.outlineVariant.withValues(alpha: 0.45),
                  borderRadius: AppShapes.pill,
                ),
              ),
            ),
          Column(
            children: [
              AnimatedContainer(
                duration: AppMotion.short,
                width: i == activeStep ? 12 : 10,
                height: i == activeStep ? 12 : 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= activeStep
                      ? AppColors.primaryAccent
                      : Colors.transparent,
                  border: Border.all(
                    color: i <= activeStep
                        ? AppColors.primaryAccent
                        : AppColors.outlineVariant,
                    width: i == activeStep ? 2 : 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 72,
                child: Text(
                  CvImportProcessingSkeleton._steps[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 9,
                    color: i == activeStep
                        ? AppColors.titleColor
                        : AppColors.hintColor,
                    fontWeight:
                        i == activeStep ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
