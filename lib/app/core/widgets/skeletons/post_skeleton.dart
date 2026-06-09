import 'package:flutter/material.dart';
import '../../theme/app_dimens.dart';
import '../common/app_card.dart';
import 'skeleton_box.dart';

/// Skeleton d'une carte de publication (fil Communauté) — même gabarit que
/// [PostCard] : en-tête avatar + nom/rôle, deux lignes de corps. Remplace le
/// spinner au chargement du fil et de l'aperçu réseau de l'accueil.
class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              SkeletonBox(width: 48, height: 48, radius: AppRadius.pill),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 12),
                    SizedBox(height: 6),
                    SkeletonBox(width: 90, height: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(width: double.infinity, height: 12),
          SizedBox(height: 8),
          SkeletonBox(width: 240, height: 12),
        ],
      ),
    );
  }
}
