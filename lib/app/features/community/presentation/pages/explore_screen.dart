import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../controllers/community_controller.dart';
import '../widgets/comment_sheet.dart';
import '../widgets/post_card.dart';
import '../widgets/report_sheet.dart';
import 'hashtag_feed_screen.dart';

/// Découverte : hashtags tendance (chips) + posts publics les plus engageants.
/// Réutilise le [CommunityController] global (état `explore*` + `trendingHashtags`).
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _controller = Get.find<CommunityController>();

  @override
  void initState() {
    super.initState();
    _controller.loadExplore();
    _controller.loadTrendingHashtags();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _controller.loadExplore(),
      _controller.loadTrendingHashtags(),
    ]);
  }

  void _openHashtag(String tag) {
    AppHaptics.tap();
    Get.to<void>(() => HashtagFeedScreen(tag: tag));
  }

  @override
  Widget build(BuildContext context) {
    return SankSheetScaffold(
      title: 'Explorer',
      titleIcon: IconlyLight.discovery,
      body: Obx(() {
        final loading = _controller.exploreLoading.value &&
            _controller.explorePosts.isEmpty;
        if (loading) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 24),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, __) => const PostSkeleton(),
          );
        }
        if (_controller.errorMessage.value != null &&
            _controller.explorePosts.isEmpty) {
          return ErrorStateView(
            message:
                _controller.errorMessage.value ?? 'Une erreur est survenue.',
            illustration: const ErrorIllustration(),
            onRetry: _controller.loadExplore,
          );
        }
        return AppRefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primaryAccent,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                _controller.loadMoreExplore();
              }
              return false;
            },
            child: AnimationLimiter(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 24),
                children: [
                  _trendingSection(),
                  ..._postList(),
                  if (_controller.exploreLoadingMore.value)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: const AppLoader(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _trendingSection() {
    return Obx(() {
      final tags = _controller.trendingHashtags;
      if (tags.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: 18, color: AppColors.primaryAccent),
                const SizedBox(width: 6),
                Text('Tendances',
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in tags)
                PressScale(
                  onTap: () => _openHashtag(t.tag),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: AppColors.primaryAccent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      '#${t.tag}',
                      style: AppTextStyles.labelLg.copyWith(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('À découvrir',
              style:
                  AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
        ],
      );
    });
  }

  List<Widget> _postList() {
    final posts = _controller.explorePosts;
    if (posts.isEmpty) {
      return const [
        SizedBox(height: 40),
        EmptyState(
          illustration: EmptyFeedIllustration(),
          title: 'Rien à explorer pour l’instant',
          subtitle: 'Les publications populaires apparaîtront ici.',
        ),
      ];
    }
    return [
      for (var i = 0; i < posts.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AnimationConfiguration.staggeredList(
            position: i,
            duration: AppMotion.base,
            child: SlideAnimation(
              verticalOffset: AppMotion.listSlideOffset,
              child: FadeInAnimation(
                child: PostCard(
                  post: posts[i],
                  onReact: (type) =>
                      _controller.toggleExploreReaction(posts[i].id, type),
                  onVote: (optionId) =>
                      _controller.votePoll(posts[i].id, optionId),
                  onSave: () => _controller.toggleSave(posts[i].id),
                  onComment: () =>
                      showCommentSheet(context, _controller, posts[i]),
                  onRepost: () => _controller.repost(posts[i].id),
                  onTapAuthor: posts[i].author == null
                      ? null
                      : () => Get.toNamed(
                            AppRoutes.communityProfile
                                .replaceFirst(':id', posts[i].author!.id),
                          ),
                  onReport: posts[i].author?.isSelf == true
                      ? null
                      : () =>
                          showReportSheet(context, _controller, posts[i].id),
                ),
              ),
            ),
          ),
        ),
    ];
  }
}
