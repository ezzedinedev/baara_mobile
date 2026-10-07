import 'package:flutter/material.dart';
import 'package:baara/app/core/widgets/baara_mark.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/common/app_loader.dart';
import 'package:baara/app/core/widgets/common/brand_avatar.dart';
import 'package:baara/app/core/widgets/common/press_scale.dart';
import 'package:baara/app/core/widgets/common/sheet_handle.dart';
import 'package:baara/app/core/widgets/skeletons/skeleton_box.dart';

import '../controllers/story_controller.dart';
import '../../domain/entities/story.dart';
import '../pages/story_composer_screen.dart';
import '../pages/story_text_composer_screen.dart';
import '../pages/story_viewer_screen.dart';

/// Barre horizontale de stories en tête du fil — tuile « Ma story » (création)
/// + bulles à anneau dégradé (non-vu) ou gris (tout vu).
class StoryBar extends StatelessWidget {
  const StoryBar({super.key});

  static const double _ring = 66;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<StoryController>();
    return Obx(() {
      final buckets = c.buckets;
      final isPublishing = c.isPublishing.value;
      // Skeleton tant que le 1er chargement n'a rien renvoyé → la barre
      // « vit » immédiatement au lieu d'afficher juste la tuile de création.
      final showSkeleton = c.isLoading.value && buckets.isEmpty;
      return SizedBox(
        height: 104,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageH, vertical: AppSpacing.sm),
          children: [
            _CreateTile(
              onTap: isPublishing ? () {} : () => _create(context, c),
              isPublishing: isPublishing,
            ),
            if (showSkeleton)
              for (var i = 0; i < 5; i++) ...[
                const SizedBox(width: AppSpacing.md),
                const _StorySkeletonTile(),
              ]
            else
              for (var i = 0; i < buckets.length; i++) ...[
                const SizedBox(width: AppSpacing.md),
                _StoryTile(
                  bucket: buckets[i],
                  onTap: () => _openViewer(context, c, i),
                ),
              ],
          ],
        ),
      );
    });
  }

  Future<void> _create(BuildContext context, StoryController c) async {
    AppHaptics.tap();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl * 1.7)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(AppIcons.image, color: AppColors.primaryAccent),
              title: Text('Photo', style: AppTextStyles.titleMd),
              onTap: () => Navigator.of(ctx).pop('photo'),
            ),
            ListTile(
              leading: Icon(AppIcons.video, color: AppColors.primaryAccent),
              title: Text('Vidéo', style: AppTextStyles.titleMd),
              onTap: () => Navigator.of(ctx).pop('video'),
            ),
            ListTile(
              leading: Icon(AppIcons.paper, color: AppColors.primaryAccent),
              title: Text('Texte', style: AppTextStyles.titleMd),
              onTap: () => Navigator.of(ctx).pop('text'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;

    if (choice == 'text') {
      await Get.to<void>(
        () => const StoryTextComposerScreen(),
        fullscreenDialog: true,
        transition: Transition.downToUp,
      );
      return;
    }

    final picked =
        choice == 'video' ? await c.pickStoryVideo() : await c.pickStoryImage();
    if (picked == null) return;

    await Get.to<void>(
      () => StoryComposerScreen(
        mediaPath: picked.path,
        isVideo: choice == 'video',
      ),
      fullscreenDialog: true,
      transition: Transition.downToUp,
    );
  }

  void _openViewer(BuildContext context, StoryController c, int index) {
    AppHaptics.tap();
    Get.to<void>(
      () =>
          StoryViewerScreen(buckets: c.buckets.toList(), initialBucket: index),
      fullscreenDialog: true,
      transition: Transition.fadeIn,
      opaque: true,
    );
  }
}

/// Tuile fantôme (shimmer) affichée pendant le 1er chargement des stories.
class _StorySkeletonTile extends StatelessWidget {
  const _StorySkeletonTile();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonBox(
            width: StoryBar._ring,
            height: StoryBar._ring,
            radius: StoryBar._ring,
            shape: BoxShape.circle),
        SizedBox(height: 8),
        SkeletonBox(width: 42, height: 8, radius: 4),
      ],
    );
  }
}

class _CreateTile extends StatelessWidget {
  const _CreateTile({required this.onTap, this.isPublishing = false});
  final VoidCallback onTap;
  final bool isPublishing;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      haptic: false,
      curve: AppMotion.spring,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            SizedBox(
              width: StoryBar._ring,
              height: StoryBar._ring,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: StoryBar._ring,
                    height: StoryBar._ring,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      // Squircle pour la tuile de création
                      borderRadius:
                          AppShapes.squircleRadius(StoryBar._ring / 2),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(AppIcons.profile,
                        size: 34, color: AppColors.hintColor),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.surfaceCard, width: 2),
                    ),
                    child: isPublishing
                        ? Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: AppLoader(
                              size: 12,
                              strokeWidth: 1.5,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Icon(AppIcons.add,
                            size: 16, color: AppColors.onPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPublishing ? 'Envoi...' : 'Ma story',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(
                // Posée sur le bandeau vert forêt de l'onglet Réseau.
                color: isPublishing
                    ? BaaraMark.brandLime
                    : Colors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({required this.bucket, required this.onTap});
  final StoryBucket bucket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unseen = bucket.hasUnseen;
    final label =
        bucket.isMine ? 'Ma story' : bucket.user.name.split(' ').first;

    // Rayon squircle pour l'anneau et l'avatar interne
    final ringRadius = AppShapes.squircleRadius(StoryBar._ring / 2);
    final innerRadius = AppShapes.squircleRadius((StoryBar._ring - 10) / 2);

    return PressScale(
      onTap: onTap,
      haptic: false,
      curve: AppMotion.spring,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: StoryBar._ring,
              height: StoryBar._ring,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                // Squircle via borderRadius au lieu de shape: BoxShape.circle
                borderRadius: ringRadius,
                gradient: unseen
                    ? const SweepGradient(
                        startAngle: 0,
                        endAngle: 6.283185,
                        colors: [
                          AppColors.secondaryMid,
                          AppColors.primary,
                          AppColors.primaryMedium,
                          AppColors.secondaryMid,
                        ],
                        stops: [0.0, 0.4, 0.75, 1.0],
                      )
                    : null,
                color: unseen
                    ? null
                    : AppColors.outlineVariant.withValues(alpha: 0.6),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: innerRadius,
                ),
                child: ClipRRect(
                  borderRadius: innerRadius,
                  // Hero lié vers l'en-tête du viewer plein écran. Tag unique par
                  // user : la story bar n'affiche qu'une tuile par utilisateur,
                  // donc aucune collision dans la barre.
                  child: Hero(
                    tag: 'story-avatar-${bucket.user.id}',
                    child: BrandAvatar(
                      seed: bucket.user.id,
                      label: bucket.user.name.isEmpty ? '?' : bucket.user.name,
                      imageUrl: bucket.user.avatarUrl,
                      size: StoryBar._ring - 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(
                color: unseen
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
                fontWeight: unseen ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
