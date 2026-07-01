import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../../../alerts/data/repositories/alerts_repository_impl.dart';
import '../controllers/offer_controller.dart';
import '../widgets/offer_boost_badge.dart';
import '../widgets/offer_logo_hero.dart';
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
              _CreateAlertBar(
                controller: controller,
                onCreate: () => _createAlert(context, controller),
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
                icon: IconlyLight.notification,
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(AppRoutes.alerts);
                },
              ),
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
            body: Column(
              children: [
                _CreateAlertBar(
                  controller: controller,
                  onCreate: () => _createAlert(context, controller),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Crée une alerte emploi à partir des filtres actifs (instantané via
  /// [OfferController.currentFilters]). Découplé du binding Alertes : instancie
  /// le repository à la volée (ApiProvider est permanent).
  Future<void> _createAlert(
      BuildContext context, OfferController controller) async {
    final label = await _promptAlertName(context, controller);
    final trimmed = label?.trim() ?? '';
    if (trimmed.isEmpty) return;
    final repo = AlertsRepositoryImpl(apiProvider: Get.find<ApiProvider>());
    try {
      final created = await repo.createSavedSearch(
        label: trimmed,
        filters: controller.currentFilters(),
      );
      if (created != null) {
        AppToast.success('Alerte créée',
            'Tu seras notifié des nouvelles offres correspondantes.');
      } else {
        AppToast.error('Alerte non créée', 'Réessaie dans un instant.');
      }
    } catch (e) {
      AppToast.error('Alerte non créée', userFacingError(e));
    }
  }

  String _suggestedLabel(OfferController c) {
    final s = c.searchQuery.value.trim();
    if (s.isNotEmpty) return s;
    if (c.activeContract.value != null) return c.activeContract.value!;
    if (c.remoteOnly.value) return 'Offres en télétravail';
    return 'Ma recherche';
  }

  /// Feuille de saisie du nom de l'alerte. Retourne le libellé, ou null si
  /// annulé.
  Future<String?> _promptAlertName(
      BuildContext context, OfferController controller) {
    final textCtrl = TextEditingController(text: _suggestedLabel(controller));
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: SheetHandle()),
                const SizedBox(height: 14),
                Text('Nouvelle alerte',
                    style: AppTextStyles.titleLg
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Donne un nom à cette recherche. Tu seras notifié dès qu\'une nouvelle offre y correspond.',
                  style:
                      AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 60,
                  decoration: InputDecoration(
                    hintText: 'Ex. Développeur à Ouaga',
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.surfaceLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (v) => Navigator.of(ctx).pop(v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(textCtrl.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('Créer l\'alerte', style: AppTextStyles.buttonMd),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(textCtrl.dispose);
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
                      embedded: embedded,
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

/// Ouvre le sheet de filtres des offres (contrat + télétravail + secteur + tri),
/// et applique les choix au controller. Les filtres secteur/contrat/tri sont
/// appliqués côté serveur (le controller recharge sur changement). Partagé par
/// l'écran Offres et le hub Opportunités.
Future<void> openOffersFilter(
    BuildContext context, OfferController controller) async {
  final contracts = controller.offers
      .map((o) => o.contractType)
      .where((c) => c.trim().isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  // Secteurs chargés depuis GET /offers/sectors/list.
  final sectorNames =
      controller.sectors.map((s) => s.name).where((n) => n.isNotEmpty).toList();
  // Libellé du secteur actuellement sélectionné (depuis son id).
  String? selectedSectorName;
  for (final s in controller.sectors) {
    if (s.id == controller.selectedSectorId.value) {
      selectedSectorName = s.name;
      break;
    }
  }
  const sortRecent = 'Plus récentes';
  const sortBoosted = 'À la une';

  final groups = <FilterGroup>[
    if (contracts.isNotEmpty)
      FilterGroup(
          key: 'contract', label: 'Type de contrat', options: contracts),
    if (sectorNames.isNotEmpty)
      FilterGroup(key: 'sector', label: 'Secteur', options: sectorNames),
    const FilterGroup(key: 'remote', label: 'Lieu', options: ['Télétravail']),
    const FilterGroup(
        key: 'sort', label: 'Trier par', options: [sortBoosted, sortRecent]),
  ];
  final result = await showFilterSheet(
    context: context,
    groups: groups,
    selected: {
      'contract': controller.activeContract.value,
      'sector': selectedSectorName,
      'remote': controller.remoteOnly.value ? 'Télétravail' : null,
      'sort': controller.sortMode.value == 'recent' ? sortRecent : sortBoosted,
    },
  );
  if (result != null) {
    controller.activeContract.value = result['contract'];
    controller.remoteOnly.value = result['remote'] == 'Télétravail';
    // Mappe le nom de secteur choisi vers son id (null = tous).
    String? sectorId;
    final chosenSector = result['sector'];
    if (chosenSector != null) {
      for (final s in controller.sectors) {
        if (s.name == chosenSector) {
          sectorId = s.id;
          break;
        }
      }
    }
    controller.selectedSectorId.value = sectorId;
    controller.sortMode.value =
        result['sort'] == sortRecent ? 'recent' : 'boosted';
  }
}

/// Barre d'appel à l'action « Créer une alerte », visible uniquement quand une
/// recherche/un filtre est actif (sinon rien à sauvegarder).
class _CreateAlertBar extends StatelessWidget {
  const _CreateAlertBar({required this.controller, required this.onCreate});
  final OfferController controller;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasActiveFilter) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Material(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: AppShapes.squircleRadius(AppRadius.md),
          child: InkWell(
            borderRadius: AppShapes.squircleRadius(AppRadius.md),
            onTap: () {
              AppHaptics.tap();
              onCreate();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 10),
              child: Row(
                children: [
                  Icon(IconlyBold.notification,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Créer une alerte pour cette recherche',
                      style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(Icons.add_circle_outline_rounded,
                      size: 18, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _OfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback onTap;
  final bool embedded;

  const _OfferCard({
    required this.offer,
    required this.onTap,
    this.embedded = false,
  });

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
                OfferLogoHero(
                  offerId: offer.id,
                  // Embarqué dans l'onglet Offre (index 1) → Hero actif seulement
                  // quand cet onglet est courant. En plein écran → toujours actif.
                  activeWhenTab: embedded ? 1 : null,
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
            const SizedBox(height: AppSpacing.md),
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
