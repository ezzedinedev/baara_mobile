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
import 'package:opportune_bf/routes/app_routes.dart';
import '../controllers/offer_controller.dart';
import '../widgets/offer_boost_badge.dart';
import '../../domain/entities/offer.dart';

class OfferListScreen extends GetView<OfferController> {
  const OfferListScreen({super.key, this.embedded = false});

  /// Quand `true`, rend seulement le corps (sans en-tête SankTabShell) pour
  /// être hébergé dans le hub Opportunités.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        final body = Obx(() {
          if (controller.isLoading.value && controller.offers.isEmpty) {
            return _buildSkeletons(isTablet);
          }
          if (controller.filteredOffers.isEmpty &&
              !controller.isLoading.value) {
            return _buildEmptyState();
          }
          return _buildList(isTablet);
        });

        if (embedded) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: AppSearchBar(
                  controller: controller.searchCtrl,
                  hint: 'Métier, entreprise, ville...',
                  onChanged: (v) => controller.searchQuery.value = v,
                ),
              ),
              Expanded(child: body),
            ],
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SankTabShell(
            title: 'Offres',
            subtitle: 'Opportunités sélectionnées pour votre profil.',
            headerActions: [
              AppIconButton(
                icon: IconlyLight.filter,
                onTap: () {
                  AppHaptics.tap();
                  openOffersFilter(context, controller);
                },
              ),
            ],
            headerChild: AppSearchBar(
              controller: controller.searchCtrl,
              hint: 'Métier, entreprise, ville...',
              onChanged: (v) => controller.searchQuery.value = v,
            ),
            body: body,
          ),
        );
      },
    );
  }

  Widget _buildSkeletons(bool isTablet) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 2 : 1,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isTablet ? 1.25 : 2.05,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const OfferCardSkeleton(),
    );
  }

  Widget _buildEmptyState() {
    final filtered = controller.hasActiveFilter ||
        controller.searchQuery.value.trim().isNotEmpty;
    return AppRefreshIndicator(
      onRefresh: () => controller.loadOffers(refresh: true),
      color: AppColors.primaryAccent,
      child: ListView(
        children: [
          SizedBox(
            height: 400,
            child: EmptyState(
              illustration: filtered
                  ? const NoResultsIllustration()
                  : const EmptyOffersIllustration(),
              title: filtered ? 'Aucun résultat' : 'Aucune offre',
              subtitle: filtered
                  ? 'Aucune offre ne correspond à ta recherche.'
                  : 'Reviens plus tard pour de nouvelles opportunités.',
              actionLabel: filtered ? 'Réinitialiser' : 'Actualiser',
              onAction: filtered
                  ? () {
                      AppHaptics.tap();
                      controller.clearFilters();
                      controller.searchQuery.value = '';
                    }
                  : () => controller.loadOffers(refresh: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(bool isTablet) {
    final items = controller.filteredOffers;
    return AppRefreshIndicator(
      onRefresh: () => controller.loadOffers(refresh: true),
      color: AppColors.primaryAccent,
      child: AnimationLimiter(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 2 : 1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isTablet ? 1.2 : 2.05,
          ),
          itemCount: items.length + (controller.hasNextPage.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == items.length) {
              controller.loadOffers();
              return Center(
                child: const AppLoader(),
              );
            }

            final offer = items[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: AppMotion.medium,
              columnCount: isTablet ? 2 : 1,
              child: SlideAnimation(
                verticalOffset: AppMotion.listSlideOffset,
                curve: AppMotion.emphasizedDecelerate,
                child: ScaleAnimation(
                  scale: 0.96,
                  curve: AppMotion.emphasizedDecelerate,
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
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Ouvre le sheet de filtres des offres (type de contrat + télétravail),
/// construit à partir des contrats réellement présents, et applique les choix
/// au controller. Partagé par l'écran Offres et le hub Opportunités.
Future<void> openOffersFilter(
    BuildContext context, OfferController controller) async {
  final contracts = controller.offers
      .map((o) => o.contractType)
      .where((c) => c.trim().isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  final groups = <FilterGroup>[
    if (contracts.isNotEmpty)
      FilterGroup(
          key: 'contract', label: 'Type de contrat', options: contracts),
    const FilterGroup(key: 'remote', label: 'Lieu', options: ['Télétravail']),
  ];
  final result = await showFilterSheet(
    context: context,
    groups: groups,
    selected: {
      'contract': controller.activeContract.value,
      'remote': controller.remoteOnly.value ? 'Télétravail' : null,
    },
  );
  if (result != null) {
    controller.activeContract.value = result['contract'];
    controller.remoteOnly.value = result['remote'] == 'Télétravail';
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: ShapeDecoration(
          color: AppColors.surfaceCard,
          shape: AppShapes.cardBordered(AppColors.outlineVariant),
          // Ombres en couches : portée courte + ambiante large (profondeur 2026).
          shadows: [...AppColors.lightShadow, ...AppColors.ambientShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (offer.isBoosted && offer.boostTier > 0) ...[
              OfferBoostBadge(
                tier: offer.boostTier,
                label: offer.boostLabel ?? 'À la une',
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'offer-logo-${offer.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: AppShapes.squircleRadius(AppRadius.sm),
                      boxShadow: AppColors.lightShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: AppShapes.squircleRadius(AppRadius.sm),
                      child: BrandAvatar(
                        seed: offer.company,
                        label: offer.company,
                        imageUrl: offer.companyLogo,
                        size: 52,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title,
                        style: AppTextStyles.headlineMd.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(IconlyLight.work,
                              size: 13, color: AppColors.primaryAccent),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              offer.company,
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Obx(() {
                  final saved = controller.isOfferSaved(offer.id);
                  return Semantics(
                    label:
                        saved ? 'Retirer des favoris' : 'Ajouter aux favoris',
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        AppHaptics.tap();
                        controller.toggleSaveOffer(offer);
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: saved
                              ? AppColors.warningAccent.withValues(alpha: 0.12)
                              : AppColors.surfaceLow,
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedSwitcher(
                          duration: AppMotion.fast,
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            saved ? IconlyBold.bookmark : IconlyLight.bookmark,
                            key: ValueKey(saved),
                            size: 19,
                            color: saved
                                ? AppColors.warningAccent
                                : AppColors.hintColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const Spacer(),
            Divider(
              height: AppSpacing.lg,
              thickness: 1,
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
            Row(
              children: [
                if (offer.contractType.isNotEmpty) ...[
                  _OfferBadge(
                    icon: IconlyLight.work,
                    label: offer.contractType,
                    accent: true,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: _OfferBadge(
                    icon: IconlyLight.location,
                    label: offer.isRemote ? 'Télétravail' : offer.location,
                  ),
                ),
                if (offer.salary.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: _OfferBadge(
                      icon: IconlyLight.wallet,
                      label: offer.salary,
                    ),
                  ),
                ],
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
  final bool accent;
  const _OfferBadge({
    required this.icon,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = accent ? AppColors.primaryAccent : AppColors.bodyColor;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.primaryAccent.withValues(alpha: 0.10)
            : AppColors.surfaceLow,
        borderRadius: AppShapes.squircleRadius(AppRadius.xs),
        border: accent
            ? Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.18))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
