import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/app/features/offers/domain/entities/matched_offer.dart';
import 'package:opportune_bf/app/features/offers/presentation/controllers/offer_controller.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../controllers/home_controller.dart';

/// Section « Pour toi » : offres recommandées par l'IA (match feed). Se charge
/// une fois au montage ; masquée si l'utilisateur n'a pas de CV ou aucun match.
class HomeMatchSection extends StatefulWidget {
  const HomeMatchSection({super.key});

  @override
  State<HomeMatchSection> createState() => _HomeMatchSectionState();
}

class _HomeMatchSectionState extends State<HomeMatchSection> {
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
      final error = controller.matchesError.value;

      // Échec de chargement : on garde la section visible avec un retry, plutôt
      // que de la faire disparaître en silence.
      if (matches.isEmpty && !loading && error != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
              child: Text(
                'home.for_you'.tr,
                style:
                    AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
              child: AppCard(
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 20, color: AppColors.hintColor),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'home.suggestions_unavailable'.tr,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.bodyColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        AppHaptics.tap();
                        controller.loadMatchedOffers();
                      },
                      child: Text(
                        'common.retry'.tr,
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }

      // Vide (succès sans match, ex. pas de CV) : section masquée, l'accueil
      // reste épuré.
      if (matches.isEmpty && !loading) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            child: SectionHeader(
              title: 'home.for_you'.tr,
              actionLabel: 'common.see_all'.tr,
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
                : AnimationLimiter(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageH),
                      itemCount: matches.length > 8 ? 8 : matches.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (_, i) =>
                          AnimationConfiguration.staggeredList(
                        position: i,
                        duration: AppMotion.medium,
                        child: SlideAnimation(
                          horizontalOffset: 32,
                          curve: AppMotion.emphasizedDecelerate,
                          child: FadeInAnimation(
                            child: HomeMatchCard(offer: matches[i]),
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

class HomeMatchCard extends StatelessWidget {
  const HomeMatchCard({super.key, required this.offer});
  final MatchedOffer offer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
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
            // Ombres en couches : ambiante large + portée courte (profondeur).
            shadows: [...AppColors.lightShadow, ...AppColors.ambientShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MatchScorePill(score: offer.score),
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
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.primaryAccent),
                ),
              ],
              const Spacer(),
              // Le « pourquoi » du match (explication IA) — l'intérêt de la
              // suggestion. À défaut, on retombe sur la localisation.
              if (offer.explanation.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 14, color: AppColors.primaryAccent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        offer.explanation,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.bodyColor,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                )
              else if (offer.location.isNotEmpty)
                Row(
                  children: [
                    Icon(IconlyLight.location,
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
      ),
    );
  }
}
