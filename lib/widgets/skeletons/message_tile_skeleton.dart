import 'package:flutter/material.dart';

import '../../app/core/theme/app_colors.dart';
import 'skeleton_box.dart';

/// Skeleton imitant un item de conversation (avatar + nom + preview + date).
class MessageTileSkeleton extends StatelessWidget {
  const MessageTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: const SkeletonCluster(
        child: Row(
          children: [
            SkeletonBox(height: 44, width: 44, shape: BoxShape.circle),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 13, width: 160),
                  SizedBox(height: 7),
                  SkeletonBox(height: 11, width: double.infinity),
                ],
              ),
            ),
            SizedBox(width: 10),
            SkeletonBox(height: 11, width: 32),
          ],
        ),
      ),
    );
  }
}
