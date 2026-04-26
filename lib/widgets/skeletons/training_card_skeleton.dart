import 'package:flutter/material.dart';

import '../../app/core/theme/app_colors.dart';
import 'skeleton_box.dart';

/// Skeleton aligne sur le _TrainingCard v2 : cover 180px + provider mini-avatar
/// + titre + description preview + stats row + bandeau prix.
class TrainingCardSkeleton extends StatelessWidget {
  const TrainingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: const SkeletonCluster(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover hero 180.
            SkeletonBox(height: 180, width: double.infinity, radius: 0),
            Padding(
              padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Provider row.
                  Row(
                    children: [
                      SkeletonBox(
                        height: 30,
                        width: 30,
                        shape: BoxShape.circle,
                      ),
                      SizedBox(width: 8),
                      SkeletonBox(height: 11, width: 110),
                      Spacer(),
                      SkeletonBox(height: 10, width: 50),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Titre.
                  SkeletonBox(height: 16, width: double.infinity),
                  SizedBox(height: 6),
                  SkeletonBox(height: 16, width: 180),
                  SizedBox(height: 8),
                  // Description preview.
                  SkeletonBox(height: 10, width: double.infinity),
                  SizedBox(height: 4),
                  SkeletonBox(height: 10, width: 230),
                  SizedBox(height: 14),
                  // Stats.
                  Row(
                    children: [
                      SkeletonBox(height: 24, width: 24, radius: 7),
                      SizedBox(width: 6),
                      SkeletonBox(height: 12, width: 50),
                      SizedBox(width: 14),
                      SkeletonBox(height: 24, width: 24, radius: 7),
                      SizedBox(width: 6),
                      SkeletonBox(height: 12, width: 50),
                      SizedBox(width: 14),
                      SkeletonBox(height: 24, width: 24, radius: 7),
                      SizedBox(width: 6),
                      SkeletonBox(height: 12, width: 50),
                    ],
                  ),
                  SizedBox(height: 14),
                  // Bandeau prix.
                  SkeletonBox(height: 38, width: double.infinity, radius: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
