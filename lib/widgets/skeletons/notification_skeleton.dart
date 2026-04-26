import 'package:flutter/material.dart';

import '../../app/core/theme/app_colors.dart';
import 'skeleton_box.dart';

/// Skeleton imitant une notification (icône + titre + body + badge catégorie).
class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: SkeletonCluster(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 13, width: 170),
                  SizedBox(height: 6),
                  SkeletonBox(height: 11, width: double.infinity),
                  SizedBox(height: 5),
                  SkeletonBox(height: 11, width: 220),
                  SizedBox(height: 9),
                  SkeletonBox(height: 9, width: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
