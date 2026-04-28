import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/relative_time.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/offers_controller.dart';
import '../models/offer_model.dart';
import '../utils/apply_feedback.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final OffersController controller = Get.find<OffersController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final RxString _query = ''.obs;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(OfferModel offer) {
    final q = _query.value.trim().toLowerCase();
    if (q.isEmpty) return true;
    return offer.title.toLowerCase().contains(q) ||
        offer.company.toLowerCase().contains(q) ||
        offer.location.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: ScrollToTopFab(controller: _scrollController),
      body: Column(
        children: [
          RevealOnMount(
            duration: const Duration(milliseconds: 540),
            offsetY: 18,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                WavyContentHeader(
                  title: 'offers.title'.tr,
                  subtitle: 'offers.subtitle'.tr,
                  gradient: AppColors.heroOffersGradient,
                  actions: [
                    WavyHeaderActionButton(
                      icon: Icons.tune_rounded,
                      onTap: () {
                        AppHaptics.tap();
                      },
                    ),
                  ],
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: -28,
                  child: AppSearchBar(
                    controller: _searchController,
                    hint: 'Rechercher une offre, entreprise...',
                    onChanged: (v) => _query.value = v,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Expanded(
            child: Obx(() {
        final isLoading = controller.isLoading.value;
        _query.value;
        final offers =
            controller.offers.where(_matchesQuery).toList(growable: false);
        final errorMessage = controller.errorMessage.value;

        if (isLoading && offers.isEmpty) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => const OfferCardSkeleton(),
          );
        }

        if (offers.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => controller.loadOffers(refresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.7,
                  child: errorMessage.isNotEmpty
                      ? ErrorStateView(
                          message: errorMessage,
                          onRetry: () =>
                              controller.loadOffers(refresh: true),
                        )
                      : EmptyState(
                          icon: IconlyLight.work,
                          title: 'Aucune offre disponible',
                          subtitle:
                              'Repassez plus tard, de nouvelles opportunités sont publiées régulièrement.',
                          actionLabel: 'Actualiser',
                          onAction: () {
                            AppHaptics.tap();
                            controller.loadOffers(refresh: true);
                          },
                        ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => controller.loadOffers(refresh: true),
          child: AnimationLimiter(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notif) {
                if (notif.metrics.pixels >=
                        notif.metrics.maxScrollExtent * 0.8 &&
                    !controller.isLoadingMore.value &&
                    controller.hasNextPage.value) {
                  controller.loadMoreOffers();
                }
                return false;
              },
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: offers.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == offers.length) {
                    return Obx(
                      () => controller.isLoadingMore.value
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  }

                  final offer = offers[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 320),
                    child: SlideAnimation(
                      verticalOffset: 18,
                      child: FadeInAnimation(
                        child: _OfferCard(
                          offer: offer,
                          onTap: () {
                            AppHaptics.tap();
                            // TODO: naviguer vers le détail
                          },
                          onToggleSave: () async {
                            AppHaptics.success();
                            if (controller.isOfferSaved(offer.id)) {
                              await controller.unsaveOffer(offer.id);
                            } else {
                              await controller.saveOffer(offer.id);
                            }
                          },
                          onApply: () async {
                            AppHaptics.tap();
                            final result =
                                await controller.applyToOffer(offer.id);
                            if (!context.mounted) return;
                            await handleApplyResult(context, result);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
            }),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatefulWidget {
  const _OfferCard({
    required this.offer,
    required this.onTap,
    required this.onToggleSave,
    required this.onApply,
  });

  final OfferModel offer;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;
  final Future<void> Function() onApply;

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OffersController>();
    final offer = widget.offer;
    final accentEnd = AppColors.avatarGradientForSeed(offer.company).last;
    final hasLogo =
        offer.companyLogo != null && offer.companyLogo!.trim().isNotEmpty;
    final posted = relativeTimeFr(offer.createdAt);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: accentEnd.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Halo decoratif en haut a droite (couleur de marque entreprise).
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentEnd.withValues(alpha: 0.10),
                        accentEnd.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row : avatar + entreprise/posted + bookmark
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentEnd.withValues(alpha: 0.30),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: BrandAvatar(
                            seed: offer.company,
                            label: offer.company,
                            size: 46,
                            fontSize: 16,
                            imageUrl: hasLogo ? offer.companyLogo : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer.company.isEmpty ? '—' : offer.company,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              if (posted.isNotEmpty)
                                Text(
                                  posted,
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.hintColor,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Obx(() {
                          final saved = controller.isOfferSaved(offer.id);
                          return IconButton(
                            tooltip: saved
                                ? 'Retirer des favoris'
                                : 'Sauvegarder',
                            onPressed: widget.onToggleSave,
                            iconSize: 22,
                            visualDensity: VisualDensity.compact,
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: Icon(
                                saved
                                    ? IconlyBold.bookmark
                                    : IconlyLight.bookmark,
                                key: ValueKey(saved),
                                color: saved
                                    ? AppColors.primary
                                    : AppColors.bodyColor,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Titre du poste (gros, lourd).
                    Text(
                      offer.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineMd.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    if (offer.sector.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        offer.sector,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          color: accentEnd,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    // Bandeau salaire mis en valeur.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.successSoft,
                            AppColors.successSoft.withValues(alpha: 0.55),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              AppColors.successDark.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            IconlyLight.wallet,
                            color: AppColors.successStrong,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              offer.salary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleMd.copyWith(
                                color: AppColors.successStrong,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Meta-chips colorees.
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          icon: IconlyLight.location,
                          label: offer.location,
                          color: AppColors.categoryBlue,
                        ),
                        _MetaChip(
                          icon: IconlyLight.work,
                          label: offer.contractType.isEmpty
                              ? 'Contrat'
                              : offer.contractType,
                          color: AppColors.categoryPurple,
                        ),
                        if (offer.isRemote)
                          const _MetaChip(
                            icon: IconlyLight.discovery,
                            label: 'Remote',
                            color: AppColors.categoryCyan,
                          ),
                        _MetaChip(
                          icon: IconlyLight.activity,
                          label: offer.experienceLabel,
                          color: AppColors.categoryOrange,
                        ),
                      ],
                    ),
                    if (offer.requiredSkills.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: offer.requiredSkills
                            .take(4)
                            .map(
                              (skill) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLow,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColors.outlineVariant
                                        .withValues(alpha: 0.30),
                                  ),
                                ),
                                child: Text(
                                  skill,
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.titleColor,
                                    letterSpacing: 0.2,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    // Pied : deadline + CTA Postuler.
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                IconlyLight.calendar,
                                size: 14,
                                color: AppColors.hintColor,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  offer.deadlineLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.hintColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _ApplyButton(
                          offerId: offer.id,
                          onApply: widget.onApply,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.offerId, required this.onApply});

  final String offerId;
  final Future<void> Function() onApply;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OffersController>();
    return Obx(() {
      final applied = controller.hasAppliedToOffer(offerId);
      final isLoading = controller.isApplyingToOfferId.value == offerId;

      if (applied) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                IconlyBold.tick_square,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Candidature envoyée',
                style: AppTextStyles.titleMd.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }

      return FilledButton.icon(
        onPressed: isLoading ? null : onApply,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.onPrimary),
                ),
              )
            : const Icon(IconlyBold.send, size: 18),
        label: Text(
          isLoading ? 'Envoi…' : 'Postuler',
          style: AppTextStyles.buttonMd,
        ),
      );
    });
  }
}

