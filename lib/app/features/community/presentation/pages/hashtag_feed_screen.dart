import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/theme/app_motion.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';
import 'package:jobaway/routes/app_routes.dart';
import '../../domain/repositories/i_community_repository.dart';
import '../controllers/community_controller.dart';
import '../controllers/hashtag_feed_controller.dart';
import '../widgets/comment_sheet.dart';
import '../widgets/post_card.dart';
import '../widgets/report_sheet.dart';

/// Fil d'une étiquette `#tag` : mêmes cartes que le fil principal, pagination,
/// pull-to-refresh, états vide / erreur. Les réactions sont gérées localement
/// par [HashtagFeedController] ; le reste (commentaires, repost, signalement…)
/// réutilise le [CommunityController] global.
class HashtagFeedScreen extends StatefulWidget {
  const HashtagFeedScreen({super.key, required this.tag});

  final String tag;

  @override
  State<HashtagFeedScreen> createState() => _HashtagFeedScreenState();
}

class _HashtagFeedScreenState extends State<HashtagFeedScreen> {
  late final HashtagFeedController _controller;
  late final CommunityController _community;
  late final String _tagKey;

  @override
  void initState() {
    super.initState();
    _tagKey = 'hashtag_${widget.tag}';
    _community = Get.find<CommunityController>();
    _controller = Get.put(
      HashtagFeedController(Get.find<ICommunityRepository>(), widget.tag),
      tag: _tagKey,
    );
  }

  @override
  void dispose() {
    Get.delete<HashtagFeedController>(tag: _tagKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SankSheetScaffold(
      title: '#${widget.tag}',
      titleIcon: Icons.tag_rounded,
      body: Obx(() {
        if (_controller.isLoading.value && _controller.posts.isEmpty) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 24),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, __) => const PostSkeleton(),
          );
        }
        if (_controller.errorMessage.value != null &&
            _controller.posts.isEmpty) {
          return ErrorStateView(
            message:
                _controller.errorMessage.value ?? 'Une erreur est survenue.',
            illustration: const ErrorIllustration(),
            onRetry: _controller.load,
          );
        }
        if (_controller.posts.isEmpty) {
          return AppRefreshIndicator(
            onRefresh: _controller.reload,
            color: AppColors.primaryAccent,
            child: ListView(
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  illustration: EmptyFeedIllustration(),
                  title: 'Aucune publication',
                  subtitle: 'Aucune publication ne porte encore ce hashtag.',
                ),
              ],
            ),
          );
        }
        return AppRefreshIndicator(
          onRefresh: _controller.reload,
          color: AppColors.primaryAccent,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                _controller.loadMore();
              }
              return false;
            },
            child: AnimationLimiter(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 24),
                itemCount: _controller.posts.length +
                    (_controller.isLoadingMore.value ? 1 : 0),
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  if (i >= _controller.posts.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: const AppLoader(),
                      ),
                    );
                  }
                  final post = _controller.posts[i];
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
                              showCommentSheet(context, _community, post),
                          onRepost: () => _community.repost(post.id),
                          onTapAuthor: post.author == null
                              ? null
                              : () => Get.toNamed(
                                    AppRoutes.communityProfile
                                        .replaceFirst(':id', post.author!.id),
                                  ),
                          onReport: post.author?.isSelf == true
                              ? null
                              : () =>
                                  showReportSheet(context, _community, post.id),
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
