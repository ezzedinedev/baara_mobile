import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'skeleton_box.dart';

/// Affiche : un hero card (primary gradient box) + [rowCount] cards avec
/// titre + 2 lignes de texte. Respecte le dark mode via AppColors.
class PageSkeleton extends StatelessWidget {
  const PageSkeleton({
    super.key,
    this.showHero = true,
    this.rowCount = 3,
    this.padding = const EdgeInsets.fromLTRB(18, 14, 18, 32),
  });

  final bool showHero;
  final int rowCount;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (showHero) ...[
          const SkeletonBox(height: 100, radius: 22),
          const SizedBox(height: 18),
        ],
        for (int i = 0; i < rowCount; i++) ...[
          _SkeletonCard(),
          if (i < rowCount - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: const SkeletonCluster(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 13, width: 140),
            SizedBox(height: 10),
            SkeletonBox(height: 10, width: double.infinity),
            SizedBox(height: 6),
            SkeletonBox(height: 10, width: 220),
          ],
        ),
      ),
    );
  }
}
