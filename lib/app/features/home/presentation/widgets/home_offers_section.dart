import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/app/features/offers/domain/entities/offer.dart';
import 'package:baara/app/features/offers/presentation/controllers/offer_controller.dart';
import 'package:baara/app/features/offers/presentation/widgets/offer_logo_hero.dart';
import 'package:baara/routes/app_routes.dart';
import '../controllers/home_controller.dart';

/// Section « Offres d'emploi » : aperçu horizontal des dernières offres
/// publiées. « Tout voir » bascule sur l'onglet Opportunités (segment Offres).
class HomeOffersSection extends StatelessWidget {
  const HomeOffersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OfferController>();
    return Obx(() {
      final loading = controller.isLoading.value;
      final offers = controller.offers;

      if (loading && offers.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
              child: SectionHeader(
                title: 'offers.title'.tr,
                onAction: () {},
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 176,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
                itemCount: 3,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (_, __) => const HomeOfferRailSkeleton(),
              ),
            ),
          ],
        );
      }
      if (offers.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            child: SectionHeader(
              title: 'offers.title'.tr,
              actionLabel: 'common.see_all'.tr,
              onAction: () {
                AppHaptics.tap();
                Get.find<HomeController>().openOpportunites(segment: 0);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 176,
            child: AnimationLimiter(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
                itemCount: offers.length > 8 ? 8 : offers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (_, i) => AnimationConfiguration.staggeredList(
                  position: i,
                  duration: AppMotion.medium,
                  child: SlideAnimation(
                    horizontalOffset: 32,
                    curve: AppMotion.emphasizedDecelerate,
                    child: FadeInAnimation(
                      child: HomeOfferRailCard(offer: offers[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// Carte d'offre compacte (rail horizontal de l'accueil), largeur fixe.
class HomeOfferRailCard extends StatelessWidget {
  const HomeOfferRailCard({super.key, required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: 260,
        child: PressScale(
        onTap: () {
          AppHaptics.tap();
          Get.toNamed(AppRoutes.offerDetail.replaceFirst(':id', offer.id));
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: ShapeDecoration(
            color: AppColors.surfaceCard,
            shape: AppShapes.cardBordered(AppColors.outlineVariant),
            shadows: [...AppColors.lightShadow, ...AppColors.ambientShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Morphing logo offre → détail (actif uniquement sur l'Accueil).
                  OfferLogoHero(
                    offerId: offer.id,
                    activeWhenTab: 0,
                    child: BrandAvatar(
                      seed: offer.company.isEmpty ? offer.title : offer.company,
                      label:
                          offer.company.isEmpty ? offer.title : offer.company,
                      imageUrl: offer.companyLogo,
                      size: 38,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      offer.company.isEmpty ? 'Entreprise' : offer.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.primaryAccent),
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
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  if (offer.location.isNotEmpty) ...[
                    Icon(AppIcons.location,
                        size: 13, color: AppColors.hintColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        offer.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.hintColor),
                      ),
                    ),
                  ],
                ],
              ),
              if (offer.salary.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  offer.salary.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }
}

/// Squelette shimmer d'une carte d'offre du rail (mime la vraie structure).
class HomeOfferRailSkeleton extends StatelessWidget {
  const HomeOfferRailSkeleton({super.key});

  Widget _bar(double w, double h, [double r = 7]) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: ShapeDecoration(
          color: AppColors.surfaceCard,
          shape: AppShapes.cardBordered(AppColors.outlineVariant),
        ),
        child: SkeletonCluster(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _bar(110, 11),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _bar(double.infinity, 13),
              const SizedBox(height: 8),
              _bar(150, 13),
              const Spacer(),
              _bar(120, 11),
              const SizedBox(height: 8),
              _bar(80, 12),
            ],
          ),
        ),
      ),
    );
  }
}
