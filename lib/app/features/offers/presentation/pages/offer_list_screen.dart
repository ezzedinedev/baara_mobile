import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../controllers/offer_controller.dart';
import '../widgets/offer_boost_badge.dart';
import '../../domain/entities/offer.dart';

class OfferListScreen extends GetView<OfferController> {
  const OfferListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          
          return SankTabShell(
            title: 'Offres',
            subtitle: 'Opportunités sélectionnées pour votre profil.',
            headerActions: [
              AppIconButton(
                icon: IconlyLight.filter,
                onTap: () => AppHaptics.tap(),
              ),
            ],
            headerChild: AppSearchBar(
              controller: TextEditingController(),
              hint: 'Métier, entreprise, ville...',
            ),
            body: Obx(() {
                  if (controller.isLoading.value && controller.offers.isEmpty) {
                    return _buildSkeletons(isTablet);
                  }

                  if (controller.offers.isEmpty && !controller.isLoading.value) {
                    return _buildEmptyState();
                  }

                  return _buildList(isTablet);
                }),
          );
        },
      ),
    );
  }

  Widget _buildSkeletons(bool isTablet) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 2 : 1,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isTablet ? 1.4 : 2.5,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const OfferCardSkeleton(),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () => controller.loadOffers(refresh: true),
      color: AppColors.primary,
      child: ListView(
        children: [
          SizedBox(
            height: 400,
            child: EmptyState(
              icon: IconlyLight.work,
              title: 'Aucune offre',
              subtitle: 'Ajustez vos filtres ou revenez plus tard',
              actionLabel: 'Actualiser',
              onAction: () => controller.loadOffers(refresh: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(bool isTablet) {
    return RefreshIndicator(
      onRefresh: () => controller.loadOffers(refresh: true),
      color: AppColors.primary,
      child: AnimationLimiter(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 2 : 1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isTablet ? 1.3 : 2.3,
          ),
          itemCount: controller.offers.length + (controller.hasNextPage.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.offers.length) {
              controller.loadOffers();
              return const Center(child: CircularProgressIndicator());
            }

            final offer = controller.offers[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 260),
              columnCount: isTablet ? 2 : 1,
              child: ScaleAnimation(
                scale: 0.96,
                child: FadeInAnimation(
                  child: _OfferCard(
                    offer: offer,
                    onTap: () {
                      AppHaptics.tap();
                      Get.toNamed(
                        AppRoutes.offerDetail.replaceFirst(':id', offer.id),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback onTap;

  const _OfferCard({required this.offer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OfferController>();
    
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
          boxShadow: AppColors.lightShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (offer.isBoosted && offer.boostTier > 0) ...[
              OfferBoostBadge(
                tier: offer.boostTier,
                label: offer.boostLabel ?? 'À la une',
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                BrandAvatar(
                  seed: offer.company,
                  label: offer.company,
                  imageUrl: offer.companyLogo,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.company,
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        offer.title,
                        style: AppTextStyles.headlineMd.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Obx(() => Semantics(
                  label: controller.isOfferSaved(offer.id) ? 'Retirer des favoris' : 'Ajouter aux favoris',
                  child: IconButton(
                    icon: Icon(
                      controller.isOfferSaved(offer.id) 
                          ? IconlyBold.bookmark 
                          : IconlyLight.bookmark,
                      color: controller.isOfferSaved(offer.id) 
                          ? AppColors.warning 
                          : AppColors.hintColor,
                    ),
                    onPressed: () {
                      AppHaptics.tap();
                      controller.toggleSaveOffer(offer);
                    },
                  ),
                )),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Flexible(
                  child: _OfferBadge(
                    icon: IconlyLight.location,
                    label: offer.location,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _OfferBadge(
                    icon: IconlyLight.wallet,
                    label: offer.salary,
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

class _OfferBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _OfferBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.bodyColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodySm.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
