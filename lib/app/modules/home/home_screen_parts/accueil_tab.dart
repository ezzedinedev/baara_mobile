part of '../home_screen.dart';

class _AccueilTab extends StatelessWidget {
  const _AccueilTab({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.loadPublishedContent,
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AccueilTopBar(controller: controller),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: _AccueilHeroCard(controller: controller),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'home.section_offers'.tr,
                    actionLabel: 'home.section_offers_action'.tr,
                    onAction: () => controller.changeTab(2),
                  ),
                  const SizedBox(height: 14),
                  _OfferTinderDeck(
                    controller: controller,
                    height: 432,
                    showActions: true,
                    compact: false,
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'home.section_trainings'.tr,
                    actionLabel: 'home.section_trainings_action'.tr,
                    onAction: () => controller.changeTab(3),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            if (controller.isLoadingFormations.value &&
                controller.formations.isEmpty)
              SizedBox(
                height: 316,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, _) => SizedBox(
                    width: MediaQuery.sizeOf(context).width - 40,
                    child: const TrainingCardSkeleton(),
                  ),
                ),
              )
            else if (controller.formations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 220,
                  child: _ContentStatusCard(
                    message: controller.formationsLoadError.value.isNotEmpty
                        ? controller.formationsLoadError.value
                        : 'Aucune formation disponible pour le moment.',
                    onRetry: () => controller.reloadFormations(),
                  ),
                ),
              )
            else
              SizedBox(
                height: 316,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: controller.formations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final formation = controller.formations[index];
                    return SizedBox(
                      width: MediaQuery.sizeOf(context).width - 40,
                      child: _FormationDarkCard(
                        formation: formation,
                        compact: false,
                        onTap: () {
                          AppHaptics.tap();
                          _showFormationDetails(context, formation);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Top bar plat sur le fond de page : avatar + greeting + theme + bell.
/// Aucun gradient, aucune vague. Respecte le status bar via SafeArea.
class _AccueilTopBar extends StatelessWidget {
  const _AccueilTopBar({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 14, 4),
      child: Row(
        children: [
          _FlatAvatarButton(controller: controller),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              final firstName = controller
                  .profileManager.profile.value.firstName
                  .trim();
              final greetingName = firstName.isEmpty
                  ? 'home.greeting_fallback'.tr
                  : firstName;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'home.greeting'.tr,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.bodyColor,
                    ),
                  ),
                  Text(
                    greetingName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleLg.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.titleColor,
                      fontSize: 18,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(width: 6),
          const _FlatThemeButton(),
          const SizedBox(width: 8),
          _FlatNotificationBell(controller: controller),
        ],
      ),
    );
  }
}

/// Hero card : carte gradient violet/indigo (signature distincte du green
/// retire). Tagline + chip CTA + decor. Pas d'animation, juste du chic.
class _AccueilHeroCard extends StatelessWidget {
  const _AccueilHeroCard({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return RevealOnMount(
      duration: const Duration(milliseconds: 620),
      offsetY: 28,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        decoration: BoxDecoration(
          gradient: AppColors.heroAccueilGradient,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.34),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
        children: [
          // Decor : 2 cercles flous translucides.
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.onPrimary.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: 60,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.onPrimary.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Contenu.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppColors.onPrimary.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 12,
                      color: AppColors.categoryYellow,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'home.hero_badge'.tr,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onPrimary,
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'home.hero_title'.tr,
                style: AppTextStyles.headlineLg.copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  AppHaptics.tap();
                  controller.changeTab(2);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'home.hero_cta'.tr,
                        style: AppTextStyles.titleMd.copyWith(
                          color: AppColors.secondaryDeep,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const NudgeArrow(
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.secondaryDeep,
                        ),
                      ),
                    ],
                  ),
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

class _FlatAvatarButton extends StatelessWidget {
  const _FlatAvatarButton({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.profileManager.profile.value;
      return InkWell(
        onTap: () {
          AppHaptics.tap();
          controller.goToProfile();
        },
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.30),
              width: 1.5,
            ),
            boxShadow: AppColors.lightShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: profile.hasAvatar
              ? CachedNetworkImage(
                  imageUrl: profile.avatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(
                    IconlyBold.profile,
                    size: 22,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(
                  IconlyBold.profile,
                  size: 22,
                  color: AppColors.primary,
                ),
        ),
      );
    });
  }
}

class _FlatThemeButton extends StatelessWidget {
  const _FlatThemeButton();

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<AppThemeController>();
    return Obx(
      () => InkWell(
        onTap: () async {
          AppHaptics.tap();
          await themeController.toggle();
          if (Get.isRegistered<HomeController>()) {
            final manager = Get.find<HomeController>().profileManager;
            manager.preferences.value = manager.preferences.value.copyWith(
              theme: themeController.isDarkMode.value ? 'dark' : 'light',
            );
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.20),
            ),
            boxShadow: AppColors.lightShadow,
          ),
          child: Icon(
            themeController.isDarkMode.value
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            size: 20,
            color: AppColors.titleColor,
          ),
        ),
      ),
    );
  }
}

class _FlatNotificationBell extends StatelessWidget {
  const _FlatNotificationBell({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final unreadCount = controller.unreadNotificationsCount;
      return InkWell(
        onTap: () {
          AppHaptics.tap();
          Get.toNamed(AppRoutes.notifications);
        },
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.20),
                ),
                boxShadow: AppColors.lightShadow,
              ),
              child: Icon(
                IconlyLight.notification,
                size: 20,
                color: AppColors.titleColor,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -6,
                top: -7,
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Halo qui pulse autour du badge.
                      const PulsingDot(
                        color: AppColors.error,
                        size: 0,
                        haloSize: 26,
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.surfaceCard,
                            width: 1.5,
                          ),
                        ),
                        child: AnimatedCount(
                          value: unreadCount,
                          builder: (context, v) => Text(
                            v > 9 ? '9+' : '$v',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

