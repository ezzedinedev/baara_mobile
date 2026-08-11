import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/routes/app_routes.dart';
import '../controllers/community_controller.dart';
import '../widgets/post_card.dart';
import '../widgets/comment_sheet.dart';
import '../widgets/report_sheet.dart';
import '../widgets/story_bar.dart';
import '../widgets/suggestions_carousel.dart';
import '../controllers/story_controller.dart';
import 'compose_post_screen.dart';
import 'explore_screen.dart';
import 'saved_posts_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  CommunityController get controller => Get.find<CommunityController>();

  final _scrollController = ScrollController();
  bool _fabVisible = true;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final isScrollingDown = offset > _lastOffset;
    _lastOffset = offset;
    final visible = !isScrollingDown || offset < 80;
    if (visible != _fabVisible) {
      setState(() => _fabVisible = visible);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  static const _filters = <({String label, String? type, IconData icon})>[
    (label: 'Tout', type: null, icon: Icons.auto_awesome_rounded),
    (label: 'Offres', type: 'emploi', icon: AppIcons.work),
    (label: 'Formations', type: 'formation', icon: Icons.school_outlined),
    (label: 'Articles', type: 'article', icon: AppIcons.paper),
    (label: 'Événements', type: 'evenement', icon: AppIcons.calendar),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        offset: _fabVisible ? Offset.zero : const Offset(0, 2.5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: _fabVisible ? 1.0 : 0.0,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: FloatingActionButton.extended(
              onPressed: _openComposer,
              backgroundColor: AppColors.primary,
              icon: const Icon(AppIcons.edit, color: AppColors.onPrimary),
              label: Text('Publier',
                  style: AppTextStyles.buttonMd
                      .copyWith(color: AppColors.onPrimary)),
            ),
          ),
        ),
      ),
      body: SankTabShell(
        title: 'Réseau',
        subtitle: 'Le fil de la communauté Baara.',
        headerVisible: _fabVisible,
        headerActions: [
          AppIconButton(
            icon: AppIcons.bookmark,
            tooltip: 'Publications enregistrées',
            onTap: () {
              AppHaptics.tap();
              Get.to<void>(() => const SavedPostsScreen());
            },
          ),
          const SizedBox(width: 8),
          AppIconButton(
            icon: AppIcons.discovery,
            tooltip: 'Explorer',
            onTap: () {
              AppHaptics.tap();
              Get.to<void>(() => const ExploreScreen());
            },
          ),
          const SizedBox(width: 8),
          AppIconButton(
            icon: AppIcons.search,
            tooltip: 'Rechercher des membres',
            onTap: () {
              AppHaptics.tap();
              Get.toNamed(AppRoutes.communitySearch);
            },
          ),
          const SizedBox(width: 8),
          AppIconButton(
            icon: AppIcons.addUser,
            tooltip: 'Demandes de connexion',
            onTap: () {
              AppHaptics.tap();
              Get.toNamed(AppRoutes.communityConnections);
            },
          ),
        ],
        headerChild: const Padding(
          padding: EdgeInsets.only(top: AppSpacing.md),
          child: StoryBar(),
        ),
        body: Column(
          children: [
            _feedTabs(),
            _filterBar(),
            Expanded(child: _FeedBody(scrollController: _scrollController)),
          ],
        ),
      ),
    );
  }

  static const _tabs = <({String key, String label})>[
    (key: 'foryou', label: 'Pour vous'),
    (key: 'recent', label: 'Récent'),
    (key: 'connections', label: 'Connexions'),
  ];

  Widget _feedTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH, AppSpacing.sm, AppSpacing.pageH, 0),
      child: Obx(() {
        final current = controller.feedTab.value;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            children: [
              for (final t in _tabs)
                Expanded(
                  child: _FeedTabPill(
                    label: t.label,
                    selected: current == t.key,
                    onTap: () {
                      AppHaptics.tap();
                      controller.changeTab(t.key);
                    },
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _filterBar() {
    return SizedBox(
      height: 56,
      child: Obx(() {
        final active = controller.activeType.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageH,
            vertical: AppSpacing.sm,
          ),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, i) {
            final f = _filters[i];
            return _CategoryChip(
              label: f.label,
              icon: f.icon,
              selected: active == f.type,
              onTap: () => controller.loadFeed(type: f.type),
            );
          },
        );
      }),
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
}

Future<void> _refreshFeedWithStories(CommunityController controller) async {
  await controller.refreshFeed();
  if (Get.isRegistered<StoryController>()) {
    await Get.find<StoryController>().loadStories();
  }
}

/// Corps du fil : états globaux séparés de la liste (perf scroll/pagination).
class _FeedBody extends StatelessWidget {
  const _FeedBody({required this.scrollController});

  final ScrollController scrollController;

  CommunityController get controller => Get.find<CommunityController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.posts.isEmpty) {
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 90),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, __) => const PostSkeleton(),
        );
      }
      if (controller.errorMessage.value != null &&
          controller.posts.isEmpty) {
        return ErrorStateView(
          message: controller.errorMessage.value ?? 'Une erreur est survenue.',
          illustration: const ErrorIllustration(),
          onRetry: () => controller.loadFeed(),
        );
      }
      if (controller.posts.isEmpty) {
        return AppRefreshIndicator(
          onRefresh: () => _refreshFeedWithStories(controller),
          color: AppColors.primaryAccent,
          child: ListView(
            children: [
              const SizedBox(height: 80),
              EmptyState(
                illustration: const EmptyFeedIllustration(),
                title: 'Le fil est vide',
                subtitle: 'Soyez le premier à publier dans la communauté.',
                actionLabel: 'Publier',
                onAction: () {
                  AppHaptics.tap();
                  Get.to<void>(
                    () => const ComposePostScreen(),
                    fullscreenDialog: true,
                    transition: Transition.downToUp,
                  );
                },
              ),
            ],
          ),
        );
      }
      return AppRefreshIndicator(
        onRefresh: () => _refreshFeedWithStories(controller),
        color: AppColors.primaryAccent,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
              controller.loadMore();
            }
            return false;
          },
          child: Obx(() {
            final posts = controller.posts;
            final suggIndex = posts.length >= 3 ? 3 : 0;
            return AnimationLimiter(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 90),
                itemCount: posts.length + 2,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  if (i == suggIndex) {
                    return Transform.translate(
                      offset: const Offset(-AppSpacing.md, 0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: const SuggestionsCarousel(),
                      ),
                    );
                  }
                  final postIndex = i > suggIndex ? i - 1 : i;
                  if (postIndex >= posts.length) {
                    return const _FeedLoadMoreFooter();
                  }
                  final post = posts[postIndex];
                  return AnimationConfiguration.staggeredList(
                    position: i,
                    duration: AppMotion.base,
                    child: SlideAnimation(
                      verticalOffset: AppMotion.listSlideOffset,
                      child: FadeInAnimation(
                        child: RepaintBoundary(
                          child: PostCard(
                            post: post,
                            onReact: (type) =>
                                controller.toggleReaction(post.id, type),
                            onVote: (optionId) =>
                                controller.votePoll(post.id, optionId),
                            onSave: () => controller.toggleSave(post.id),
                            onComment: () =>
                                showCommentSheet(context, controller, post),
                            onRepost: () => controller.repost(post.id),
                            onFollow: post.author == null
                                ? null
                                : () => controller.toggleFollow(post.author!),
                            onTapAuthor: post.author == null
                                ? null
                                : () => Get.toNamed(
                                      AppRoutes.communityProfile.replaceFirst(
                                          ':id', post.author!.id),
                                    ),
                            onReport: post.author?.isSelf == true
                                ? null
                                : () => showReportSheet(
                                    context, controller, post.id),
                            onEdit: post.author?.isSelf == true
                                ? () {
                                    AppHaptics.tap();
                                    Get.to<void>(
                                      () => ComposePostScreen(editing: post),
                                      fullscreenDialog: true,
                                      transition: Transition.downToUp,
                                    );
                                  }
                                : null,
                            onDelete: post.author?.isSelf == true
                                ? () => _deletePostFromFeed(context, post.id)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      );
    });
  }
}

Future<void> _deletePostFromFeed(BuildContext context, String postId) async {
  AppHaptics.tap();
  final ok = await showConfirmSheet(
    context: context,
    icon: AppIcons.delete,
    iconColor: AppColors.errorAccent,
    title: 'Supprimer la publication',
    message: 'Cette action est définitive. Continuer ?',
    confirmLabel: 'Supprimer',
    cancelLabel: 'Annuler',
    isDestructive: true,
  );
  if (ok == true) Get.find<CommunityController>().deletePost(postId);
}

class _FeedLoadMoreFooter extends StatelessWidget {
  const _FeedLoadMoreFooter();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CommunityController>();
    return Obx(() {
      if (!controller.isLoadingMore.value) return const SizedBox.shrink();
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: AppLoader()),
      );
    });
  }
}

/// Onglet segmenté du fil intelligent (Pour vous / Récent / Connexions).
/// Indicateur plein qui glisse via [AnimatedContainer], texte animé.
class _FeedTabPill extends StatelessWidget {
  const _FeedTabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      haptic: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceCard : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: selected ? AppColors.lightShadow : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 240),
          style: AppTextStyles.labelLg.copyWith(
            color: selected ? AppColors.primaryAccent : AppColors.hintColor,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// Pill de filtre catégorie — icône + label, remplissage vert plein animé à la
/// sélection. Remplace le `ChoiceChip` Material (checkmark/bordures par défaut)
/// pour un rendu net et aligné sur la charte.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? AppColors.primaryAccent
                : AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: selected ? AppColors.lightShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppColors.onPrimary : AppColors.bodyColor,
            ),
            const SizedBox(width: 7),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: AppTextStyles.labelLg.copyWith(
                color: selected ? AppColors.onPrimary : AppColors.bodyColor,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
