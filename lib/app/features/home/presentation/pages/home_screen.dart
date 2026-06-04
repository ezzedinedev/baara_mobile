import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/app/features/offers/presentation/pages/offer_list_screen.dart';
import 'package:opportune_bf/app/features/offers/presentation/controllers/offer_controller.dart';
import 'package:opportune_bf/app/features/offers/presentation/widgets/offer_swipe_deck.dart';
import 'package:opportune_bf/app/features/trainings/presentation/pages/trainings_screen.dart';
import 'package:opportune_bf/app/features/trainings/presentation/controllers/trainings_controller.dart';
import 'package:opportune_bf/app/features/trainings/presentation/widgets/training_card.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/profile_screen.dart';
import 'package:opportune_bf/app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:opportune_bf/app/features/messaging/presentation/pages/messages_screen.dart';
import 'package:opportune_bf/routes/app_routes.dart';
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
            MessagesScreen(),
            OfferListScreen(),
            TrainingsScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: const _HomeBottomNav(),
    );
  }
}

/// Onglet Accueil restauré : top bar plat (avatar + greeting + cloche), un
/// deck d'offres swipe (réutilise [OfferSwipeDeck]) et un carrousel horizontal
/// de formations. Pull-to-refresh recharge offres + formations.
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final offerController = Get.find<OfferController>();
    final trainingsController = Get.find<TrainingsController>();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.wait([
          offerController.loadOffers(refresh: true),
          trainingsController.loadTrainings(refresh: true),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          const _AccueilTopBar(),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            child: SectionHeader(
              title: 'Offres',
              actionLabel: 'Tout voir',
              onAction: () => Get.find<HomeController>().changeTab(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            child: OfferSwipeDeck(
              controller: offerController,
              height: 432,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            child: SectionHeader(
              title: 'Formations',
              actionLabel: 'Tout voir',
              onAction: () => Get.find<HomeController>().changeTab(3),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TrainingsCarousel(controller: trainingsController),
        ],
      ),
    );
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
            AppIconButton(
              icon: IconlyLight.notification,
              onTap: () {
                AppHaptics.tap();
                Get.toNamed(AppRoutes.notifications);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Carrousel horizontal des formations. Gère loading (skeletons) et vide
/// (petit message). Chaque carte = [TrainingCard], largeur ~ (écran - 40).
class _TrainingsCarousel extends StatelessWidget {
  const _TrainingsCarousel({required this.controller});

  final TrainingsController controller;

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.sizeOf(context).width - 40;

    return Obx(() {
      final trainings = controller.trainings;
      final isLoading = controller.isLoading.value;

      if (isLoading && trainings.isEmpty) {
        return SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, __) => SizedBox(
              width: cardWidth,
              child: const TrainingCardSkeleton(),
            ),
          ),
        );
      }

      if (trainings.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
          child: Text(
            'Aucune formation disponible pour le moment.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyColor),
          ),
        );
      }

      return SizedBox(
        height: 300,
        child: AnimationLimiter(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            itemCount: trainings.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final t = trainings[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 320),
                child: SlideAnimation(
                  horizontalOffset: 40,
                  child: FadeInAnimation(
                    child: SizedBox(
                      width: cardWidth,
                      child: TrainingCard(
                        training: t,
                        onTap: () {
                          AppHaptics.tap();
                          Get.toNamed(
                            AppRoutes.trainingDetail.replaceFirst(':id', t.id),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
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
          destinations: const [
          NavigationDestination(
            icon: Icon(IconlyLight.home),
            selectedIcon: Icon(IconlyBold.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(IconlyLight.chat),
            selectedIcon: Icon(IconlyBold.chat),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(IconlyLight.work),
            selectedIcon: Icon(IconlyBold.work),
            label: 'Offres',
          ),
          NavigationDestination(
            icon: Icon(IconlyLight.video),
            selectedIcon: Icon(IconlyBold.video),
            label: 'Formations',
          ),
          NavigationDestination(
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
