import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../controllers/community_controller.dart';
import '../widgets/post_card.dart';
import '../widgets/comment_sheet.dart';
import '../widgets/report_sheet.dart';
import 'compose_post_screen.dart';

class CommunityFeedScreen extends GetView<CommunityController> {
  const CommunityFeedScreen({super.key});

  static const _filters = <String, String?>{
    'Tout': null,
    'Offres': 'emploi',
    'Formations': 'formation',
    'Articles': 'article',
    'Événements': 'evenement',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openComposer,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit, color: AppColors.onPrimary),
        label: Text('Publier', style: AppTextStyles.buttonMd.copyWith(color: AppColors.onPrimary)),
      ),
      body: SankTabShell(
        title: 'Réseau',
        subtitle: 'Le fil de la communauté OpporTune.',
        headerActions: [
          AppIconButton(
            icon: Icons.search_rounded,
            onTap: () {
              AppHaptics.tap();
              Get.toNamed(AppRoutes.communitySearch);
            },
          ),
          const SizedBox(width: 8),
          AppIconButton(
            icon: Icons.group_add_outlined,
            onTap: () {
              AppHaptics.tap();
              Get.toNamed(AppRoutes.communityConnections);
            },
          ),
        ],
        body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.posts.isEmpty) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, 90),
                  itemCount: 4,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, __) => const PostSkeleton(),
                );
              }
              if (controller.errorMessage.value != null && controller.posts.isEmpty) {
                return ErrorStateView(
                  message: controller.errorMessage.value ??
                      'Une erreur est survenue.',
                  onRetry: () => controller.loadFeed(),
                );
              }
              if (controller.posts.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.refreshFeed,
                  color: AppColors.primary,
                  child: ListView(
                    children: [
                      const SizedBox(height: 80),
                      EmptyState(
                        icon: Icons.forum_outlined,
                        title: 'Le fil est vide',
                        subtitle:
                            'Soyez le premier à publier dans la communauté.',
                        actionLabel: 'Publier',
                        onAction: _openComposer,
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.refreshFeed,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                      controller.loadMore();
                    }
                    return false;
                  },
                  child: AnimationLimiter(
                    child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.md, AppSpacing.md, 90),
                    itemCount: controller.posts.length + (controller.isLoadingMore.value ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) {
                      if (i >= controller.posts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final post = controller.posts[i];
                      return AnimationConfiguration.staggeredList(
                        position: i,
                        duration: AppMotion.base,
                        child: SlideAnimation(
                          verticalOffset: AppMotion.listSlideOffset,
                          child: FadeInAnimation(
                            child: PostCard(
                        post: post,
                        onLike: () => controller.toggleReaction(post.id, 'like'),
                        onComment: () => showCommentSheet(context, controller, post),
                        onRepost: () => controller.repost(post.id),
                        onFollow: post.author == null
                            ? null
                            : () => controller.toggleFollow(post.author!),
                        onTapAuthor: post.author == null
                            ? null
                            : () => Get.toNamed(AppRoutes.communityProfile
                                .replaceFirst(':id', post.author!.id)),
                        onReport: post.author?.isSelf == true
                            ? null
                            : () => showReportSheet(context, controller, post.id),
                        onDelete: post.author?.isSelf == true
                            ? () => _deletePost(context, post.id)
                            : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  ),
                ),
              );
            }),
          ),
        ],
        ),
      ),
    );
  }

  Widget _filterBar() {
    return SizedBox(
      height: 52,
      child: Obx(() => ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: _filters.entries.map((e) {
              final selected = controller.activeType.value == e.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e.key),
                  selected: selected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  onSelected: (_) => controller.loadFeed(type: e.value),
                ),
              );
            }).toList(),
          )),
    );
  }

  void _openComposer() {
    AppHaptics.tap();
    Get.to<void>(
      () => const ComposePostScreen(),
      fullscreenDialog: true,
      transition: Transition.downToUp,
    );
  }

  void _deletePost(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Supprimer cette publication\u00a0?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.deletePost(postId);
            },
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
