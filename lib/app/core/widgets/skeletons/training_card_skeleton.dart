import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
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
      // Skeleton compact qui tient dans la hauteur fixe du container
      // parent (314px sur petits ecrans Tecno) — la version precedente
      // faisait 414px et debordait de 96px sur un phone <380px de large.
      child: const SkeletonCluster(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover hero reduit — 124 pour tenir dans la hauteur du carrousel
            // (≈298px) sans overflow de quelques px.
            SkeletonBox(height: 124, width: double.infinity, radius: 0),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Provider row.
                  Row(
                    children: [
                      SkeletonBox(
                        height: 28,
                        width: 28,
                        shape: BoxShape.circle,
                      ),
                      SizedBox(width: 8),
                      SkeletonBox(height: 11, width: 110),
                      Spacer(),
                      SkeletonBox(height: 10, width: 50),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Titre 1 ligne (au lieu de 2).
                  SkeletonBox(height: 16, width: double.infinity),
                  SizedBox(height: 8),
                  // Description preview 1 ligne.
                  SkeletonBox(height: 10, width: double.infinity),
                  SizedBox(height: 12),
                  // Stats compactes.
                  Row(
                    children: [
                      SkeletonBox(height: 20, width: 20, radius: 6),
                      SizedBox(width: 6),
                      SkeletonBox(height: 11, width: 44),
                      SizedBox(width: 12),
                      SkeletonBox(height: 20, width: 20, radius: 6),
                      SizedBox(width: 6),
                      SkeletonBox(height: 11, width: 44),
                      SizedBox(width: 12),
                      SkeletonBox(height: 20, width: 20, radius: 6),
                      SizedBox(width: 6),
                      SkeletonBox(height: 11, width: 44),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Bandeau prix reduit.
                  SkeletonBox(height: 32, width: double.infinity, radius: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
