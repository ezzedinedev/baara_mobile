import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'skeleton_box.dart';



class OfferCardSkeleton extends StatelessWidget {
  const OfferCardSkeleton({super.key, this.height = 280});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: const SkeletonCluster(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top : avatar + entreprise/posted + bookmark.
            Row(
              children: [
                SkeletonBox(height: 46, width: 46, shape: BoxShape.circle),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 12, width: 140),
                      SizedBox(height: 6),
                      SkeletonBox(height: 9, width: 80),
                    ],
                  ),
                ),
                SkeletonBox(height: 22, width: 22, shape: BoxShape.circle),
              ],
            ),
            SizedBox(height: 16),
            // Titre poste.
            SkeletonBox(height: 18, width: double.infinity),
            SizedBox(height: 6),
            SkeletonBox(height: 18, width: 220),
            SizedBox(height: 6),
            SkeletonBox(height: 11, width: 80),
            SizedBox(height: 14),
            // Bandeau salaire.
            SkeletonBox(
              height: 38,
              width: double.infinity,
              radius: 14,
            ),
            SizedBox(height: 12),
            // Meta chips.
            Row(
              children: [
                SkeletonBox(height: 26, width: 90, radius: 999),
                SizedBox(width: 8),
                SkeletonBox(height: 26, width: 70, radius: 999),
                SizedBox(width: 8),
                SkeletonBox(height: 26, width: 80, radius: 999),
              ],
            ),
            SizedBox(height: 10),
            // Skills row.
            Row(
              children: [
                SkeletonBox(height: 22, width: 60, radius: 999),
                SizedBox(width: 6),
                SkeletonBox(height: 22, width: 50, radius: 999),
                SizedBox(width: 6),
                SkeletonBox(height: 22, width: 70, radius: 999),
              ],
            ),
            Spacer(),
            // Footer : deadline + CTA postuler.
            Row(
              children: [
                SkeletonBox(height: 11, width: 130),
                Spacer(),
                SkeletonBox(height: 32, width: 90, radius: 999),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
