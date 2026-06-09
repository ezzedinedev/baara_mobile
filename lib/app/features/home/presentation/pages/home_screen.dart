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
import 'package:opportune_bf/app/features/offers/presentation/controllers/offer_controller.dart';
import 'package:opportune_bf/app/features/offers/domain/entities/matched_offer.dart';
import 'package:opportune_bf/app/features/trainings/presentation/controllers/trainings_controller.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/profile_screen.dart';
import 'package:opportune_bf/app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:opportune_bf/app/features/messaging/presentation/pages/messages_screen.dart';
import 'package:opportune_bf/app/features/messaging/presentation/controllers/messages_controller.dart';
import 'package:opportune_bf/app/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:opportune_bf/app/features/community/presentation/pages/community_feed_screen.dart';
import 'package:opportune_bf/app/features/community/presentation/controllers/community_controller.dart';
import 'package:opportune_bf/app/features/community/presentation/widgets/post_card.dart';
import 'package:opportune_bf/app/features/community/presentation/widgets/comment_sheet.dart';
import 'package:opportune_bf/app/features/community/presentation/widgets/report_sheet.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import 'opportunites_screen.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(
        () => _LazyTabStack(
          index: controller.currentTabIndex.value,
          children: const [
            _DashboardTab(),
            OpportunitesScreen(),
            CommunityFeedScreen(),
            MessagesScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: const _HomeBottomNav(),
    );
  }
}

/// Accueil = **digest qui oriente**, pas un miroir des onglets. On ne ré-affiche
/// plus les listes complètes d'offres/formations (elles vivent dans le hub
/// Opportunités) : top bar + accès rapides vers les actions profondes + teaser
/// de l'activité réseau. Pull-to-refresh rafraîchit les données des onglets.
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final offerController = Get.find<OfferController>();
    final trainingsController = Get.find<TrainingsController>();
    final communityController = Get.find<CommunityController>();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.wait([
          offerController.loadOffers(refresh: true),
          offerController.loadMatchedOffers(),
          trainingsController.loadTrainings(refresh: true),
          communityController.refreshFeed(),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          const _AccueilTopBar(),
          const SizedBox(height: AppSpacing.lg),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            child: _QuickAccessRow(),
          ),
          const _MatchSection(),
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            child: SectionHeader(
              title: 'Ton réseau bouge',
              actionLabel: 'Tout voir',
              onAction: () {
                AppHaptics.tap();
                Get.find<HomeController>().changeTab(2);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _CommunityPreview(controller: communityController),
        ],
      ),
    );
  }
}

/// Accès rapides : raccourcis vers les actions profondes (gain de taps), sans
/// dupliquer ce que la bottom nav propose déjà.
class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow();

  @override
  Widget build(BuildContext context) {
    final items = <_QuickItem>[
      const _QuickItem(
        icon: IconlyLight.work,
        label: 'Candidatures',
        route: AppRoutes.myApplications,
      ),
      const _QuickItem(
        icon: IconlyLight.document,
        label: 'Mon CV',
        route: AppRoutes.profileCv,
      ),
      const _QuickItem(
        icon: IconlyLight.folder,
        label: 'Documents',
        route: AppRoutes.profileDocuments,
      ),
      const _QuickItem(
        icon: IconlyLight.bookmark,
        label: 'Portfolio',
        route: AppRoutes.profilePortfolio,
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: items[i]),
        ],
      ],
    );
  }
}

class _QuickItem extends StatelessWidget {
  const _QuickItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      elevated: false,
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(route);
      },
      child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceIconSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.bodyColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
    );
  }
}

/// Section « Pour toi » : offres recommandées par l'IA (match feed). Se charge
/// une fois au montage ; masquée si l'utilisateur n'a pas de CV ou aucun match.
class _MatchSection extends StatefulWidget {
  const _MatchSection();

  @override
  State<_MatchSection> createState() => _MatchSectionState();
}

class _MatchSectionState extends State<_MatchSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<OfferController>()) {
        Get.find<OfferController>().loadMatchedOffers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OfferController>();
    return Obx(() {
      final matches = controller.matchedOffers;
      final loading = controller.isLoadingMatches.value;
      if (matches.isEmpty && !loading) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            child: SectionHeader(
              title: 'Pour toi',
              actionLabel: 'Tout voir',
              onAction: () {
                AppHaptics.tap();
                Get.find<HomeController>().changeTab(1);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 168,
            child: (loading && matches.isEmpty)
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageH),
                    itemCount: 3,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (_, __) => const SizedBox(
                      width: 250,
                      child: SkeletonBox(
                          width: 250, height: 168, radius: AppRadius.md),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageH),
                    itemCount: matches.length > 8 ? 8 : matches.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (_, i) => _MatchCard(offer: matches[i]),
                  ),
          ),
        ],
      );
    });
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.offer});
  final MatchedOffer offer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: AppCard(
        onTap: () {
          AppHaptics.tap();
          Get.toNamed(AppRoutes.offerDetail.replaceFirst(':id', offer.id));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${offer.score}% match',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              offer.title.isEmpty ? 'Offre' : offer.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMd.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.titleColor,
                height: 1.2,
              ),
            ),
            if (offer.company.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                offer.company,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.primary),
              ),
            ],
            const Spacer(),
            if (offer.location.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.hintColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      offer.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Aperçu Communauté sur l'accueil : jusqu'à 3 publications récentes, mêmes
/// cartes [PostCard] que l'écran dédié et que le web. Like / commenter /
/// republier / suivre fonctionnent directement depuis l'accueil.
class _CommunityPreview extends StatelessWidget {
  const _CommunityPreview({required this.controller});

  final CommunityController controller;

  static const _maxPreview = 3;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final posts = controller.posts;

      if (isLoading && posts.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
          child: Column(
            children: [
              PostSkeleton(),
              SizedBox(height: AppSpacing.md),
              PostSkeleton(),
            ],
          ),
        );
      }

      if (posts.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.forum_outlined, color: AppColors.hintColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Le fil communauté est encore vide. Soyez le premier à publier.',
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.bodyColor),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final preview = posts.take(_maxPreview).toList();
      return AnimationLimiter(
        child: Column(
          children: [
            for (var i = 0; i < preview.length; i++)
              AnimationConfiguration.staggeredList(
                position: i,
                duration: AppMotion.base,
                child: SlideAnimation(
                  verticalOffset: AppMotion.listSlideOffset,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.pageH,
                        0,
                        AppSpacing.pageH,
                        i == preview.length - 1 ? 0 : AppSpacing.md,
                      ),
                      child: PostCard(
                        post: preview[i],
                        onLike: () =>
                            controller.toggleReaction(preview[i].id, 'like'),
                        onComment: () =>
                            showCommentSheet(context, controller, preview[i]),
                        onRepost: () => controller.repost(preview[i].id),
                        onFollow: preview[i].author == null
                            ? null
                            : () => controller.toggleFollow(preview[i].author!),
                        onTapAuthor: preview[i].author == null
                            ? null
                            : () => Get.toNamed(AppRoutes.communityProfile
                                .replaceFirst(':id', preview[i].author!.id)),
                        onReport: () =>
                            showReportSheet(context, controller, preview[i].id),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

/// Top bar plat (SafeArea) : avatar + "Bonjour" + vrai prénom, cloche à
/// droite. Tap avatar/greeting → onglet Profil ; tap cloche → notifications.
class _AccueilTopBar extends StatelessWidget {
  const _AccueilTopBar();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          AppSpacing.md,
          AppSpacing.pageH,
          0,
        ),
        child: Row(
          children: [
            Expanded(
              child: Obx(() {
                final profile = profileController.profile.value;
                final firstName = profile?.firstName.trim() ?? '';
                final greetingName =
                    firstName.isEmpty ? 'Bienvenue' : firstName;
                final initials =
                    firstName.isEmpty ? 'OB' : firstName;

                return InkWell(
                  onTap: () {
                    AppHaptics.tap();
                    Get.find<HomeController>().changeTab(4);
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        BrandAvatar(
                          seed: profile?.email ?? greetingName,
                          label: initials,
                          size: 48,
                          imageUrl: profile?.avatarUrl,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.bodyColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                greetingName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleLg.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(width: AppSpacing.sm),
            Obx(() {
              final unread = Get.isRegistered<NotificationsController>()
                  ? Get.find<NotificationsController>().unreadCount.value
                  : 0;
              final bell = AppIconButton(
                icon: IconlyLight.notification,
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(AppRoutes.notifications);
                },
              );
              if (unread <= 0) return bell;
              return Badge(
                label: Text(unread > 99 ? '99+' : '$unread'),
                backgroundColor: AppColors.error,
                child: bell,
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Ne monte un onglet qu'après la première visite — évite 5 écrans + APIs au boot.
class _LazyTabStack extends StatefulWidget {
  const _LazyTabStack({
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<_LazyTabStack> createState() => _LazyTabStackState();
}

class _LazyTabStackState extends State<_LazyTabStack> {
  final Set<int> _mountedTabs = {0};

  @override
  void didUpdateWidget(covariant _LazyTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _mountedTabs.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    _mountedTabs.add(widget.index);
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (i) {
        if (!_mountedTabs.contains(i)) {
          return const SizedBox.shrink();
        }
        final active = i == widget.index;
        return Offstage(
          offstage: !active,
          child: TickerMode(
            enabled: active,
            child: widget.children[i],
          ),
        );
      }),
    );
  }
}

/// Badge non-lus (Material 3) sur une icône d'onglet, alimenté par le total
/// des conversations non lues. Réactif via Obx ; transparent si zéro.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MessagesController>()) return child;
    final messages = Get.find<MessagesController>();
    return Obx(() {
      final unread =
          messages.conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
      if (unread <= 0) return child;
      return Badge(
        label: Text(unread > 99 ? '99+' : '$unread'),
        backgroundColor: AppColors.error,
        child: child,
      );
    });
  }
}

class _HomeBottomNav extends GetView<HomeController> {
  const _HomeBottomNav();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => NavigationBarTheme(
        data: NavigationBarThemeData(
          // État actif clairement visible : icône + label en vert marque.
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.hintColor,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => AppTextStyles.labelSm.copyWith(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.hintColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: controller.currentTabIndex.value,
          onDestinationSelected: (index) {
            AppHaptics.tap();
            controller.changeTab(index);
          },
          backgroundColor: AppColors.surfaceCard,
          // Pastille indicatrice teintée marque (au lieu d'un gris quasi invisible).
          indicatorColor: AppColors.primary.withValues(alpha: 0.16),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
          const NavigationDestination(
            icon: Icon(IconlyLight.home),
            selectedIcon: Icon(IconlyBold.home),
            label: 'Accueil',
          ),
          const NavigationDestination(
            icon: Icon(IconlyLight.work),
            selectedIcon: Icon(IconlyBold.work),
            label: 'Opportunités',
          ),
          const NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Réseau',
          ),
          NavigationDestination(
            icon: _UnreadBadge(child: Icon(IconlyLight.chat)),
            selectedIcon: _UnreadBadge(child: Icon(IconlyBold.chat)),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(IconlyLight.profile),
            selectedIcon: Icon(IconlyBold.profile),
            label: 'Profil',
          ),
        ],
        ),
      ),
    );
  }
}
