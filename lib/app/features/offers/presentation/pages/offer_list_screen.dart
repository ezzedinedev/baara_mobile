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
          if (controller.filteredOffers.isEmpty && !controller.isLoading.value) {
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
                  controller: TextEditingController(),
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
              controller: TextEditingController(),
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
        childAspectRatio: isTablet ? 1.4 : 2.5,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const OfferCardSkeleton(),
    );
  }

  Widget _buildEmptyState() {
    final filtered = controller.hasActiveFilter ||
        controller.searchQuery.value.trim().isNotEmpty;
    return RefreshIndicator(
      onRefresh: () => controller.loadOffers(refresh: true),
      color: AppColors.primary,
      child: ListView(
        children: [
          SizedBox(
            height: 400,
            child: EmptyState(
              icon: IconlyLight.work,
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
          itemCount: items.length + (controller.hasNextPage.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == items.length) {
              controller.loadOffers();
              return const Center(child: CircularProgressIndicator());
            }

            final offer = items[index];
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
      FilterGroup(key: 'contract', label: 'Type de contrat', options: contracts),
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
    
    return AppCard(
      onTap: onTap,
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
                Hero(
                  tag: 'offer-logo-${offer.id}',
                  child: BrandAvatar(
                    seed: offer.company,
                    label: offer.company,
                    imageUrl: offer.companyLogo,
                    size: 48,
                  ),
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
