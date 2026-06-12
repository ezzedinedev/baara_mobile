import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../controllers/community_controller.dart';
import '../widgets/comment_sheet.dart';
import '../widgets/post_card.dart';

/// Publications enregistrées (signet) de l'utilisateur courant.
/// Réutilise [PostCard] avec pagination, pull-to-refresh et états vide/erreur.
class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final _controller = Get.find<CommunityController>();

  @override
  void initState() {
    super.initState();
    _controller.loadSaved();
  }

  @override
  Widget build(BuildContext context) {
    return SankSheetScaffold(
      title: 'Enregistrés',
      body: Obx(() {
        if (_controller.savedLoading.value && _controller.savedPosts.isEmpty) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, __) => const PostSkeleton(),
          );
        }
        if (_controller.savedError.value != null &&
            _controller.savedPosts.isEmpty) {
          return ErrorStateView(
            message: _controller.savedError.value ?? 'Une erreur est survenue.',
            illustration: const ErrorIllustration(),
            onRetry: _controller.loadSaved,
          );
        }
        if (_controller.savedPosts.isEmpty) {
          return AppRefreshIndicator(
            color: AppColors.primaryAccent,
            onRefresh: _controller.loadSaved,
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: const EmptyState(
                    illustration: EmptyFeedIllustration(),
                    title: 'Aucune publication enregistrée',
                    subtitle: 'Touchez le signet sous une publication pour la '
                        'retrouver ici.',
                  ),
                ),
              ],
            ),
          );
        }

        return AppRefreshIndicator(
          color: AppColors.primaryAccent,
          onRefresh: _controller.loadSaved,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                _controller.loadMoreSaved();
              }
              return false;
            },
            child: AnimationLimiter(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md,
                    AppSpacing.md, AppSpacing.xxl),
                itemCount: _controller.savedPosts.length +
                    (_controller.savedLoadingMore.value ? 1 : 0),
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  if (i >= _controller.savedPosts.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: const AppLoader(),
                      ),
                    );
                  }
                  final post = _controller.savedPosts[i];
                  return AnimationConfiguration.staggeredList(
                    position: i,
                    duration: AppMotion.base,
                    child: SlideAnimation(
                      verticalOffset: AppMotion.listSlideOffset,
                      child: FadeInAnimation(
                        child: PostCard(
                          post: post,
                          onReact: (type) =>
                              _controller.toggleReaction(post.id, type),
                          onVote: (optionId) =>
                              _controller.votePoll(post.id, optionId),
                          onSave: () => _controller.toggleSave(post.id),
                          onComment: () =>
                              showCommentSheet(context, _controller, post),
                          onRepost: () => _controller.repost(post.id),
                          onTapAuthor: post.author == null
                              ? null
                              : () => Get.toNamed(AppRoutes.communityProfile
                                  .replaceFirst(':id', post.author!.id)),
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
    );
  }
}
