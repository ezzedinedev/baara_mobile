import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../controllers/offer_detail_controller.dart';
import '../widgets/offer_boost_badge.dart';
import '../../domain/entities/offer.dart';

class OfferDetailScreen extends GetView<OfferDetailController> {
  const OfferDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const _OfferDetailSkeleton();
        }

        final offer = controller.offer.value;
        if (offer == null) {
          return ErrorStateView(
            message: controller.errorMessage.value ?? 'Erreur inconnue',
            illustration: const ErrorIllustration(),
            onRetry: () async => controller.onInit(),
          );
        }

        return Stack(
          children: [
            CustomScrollView(
              // Permet l'étirement du hero en overscroll (zoom élastique).
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildSliverAppBar(offer),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, 0),
                    // Chorégraphie : les sections montent en cascade
                    // (emphasizedDecelerate via RevealOnMount), une fois le hero
                    // posé. Délais échelonnés pour une entrée vivante mais calme.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RevealOnMount(
                          offsetY: 16,
                          child: _buildMainInfo(offer),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        RevealOnMount(
                          delay: AppMotion.stagger,
                          offsetY: 16,
                          child: _buildKeyInfoGrid(offer),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        RevealOnMount(
                          delay: AppMotion.stagger * 2,
                          offsetY: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                  'À propos de l\'offre', IconlyLight.document),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                offer.description,
                                style: AppTextStyles.bodyMd.copyWith(
                                    height: 1.7, color: AppColors.bodyColor),
                              ),
                            ],
                          ),
                        ),
                        if (offer.requiredSkills.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxl),
                          RevealOnMount(
                            delay: AppMotion.stagger * 3,
                            offsetY: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Compétences requises',
                                    IconlyLight.activity),
                                const SizedBox(height: AppSpacing.lg),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: offer.requiredSkills
                                      .map((s) => _SkillChip(label: s))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Espace pour dégager la CTA sticky.
                        const SizedBox(height: 130),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildBottomAction(),
          ],
        );
      }),
    );
  }

  Widget _buildSliverAppBar(Offer offer) {
    return SliverAppBar(
      expandedHeight: 224,
      pinned: true,
      // Étirement du hero au pull-down + zoom de l'arrière-plan (parallax 2026).
      stretch: true,
      stretchTriggerOffset: 120,
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: AppBackButton(onDark: true, onTap: () => Get.back<void>()),
      ),
      leadingWidth: 60,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: Obx(
            () => IconButton(
              icon: Icon(
                controller.isSaved.value
                    ? IconlyBold.bookmark
                    : IconlyLight.bookmark,
                color: AppColors.onPrimary,
              ),
              tooltip: controller.isSaved.value
                  ? 'Retirer des favoris'
                  : 'Enregistrer',
              onPressed: () {
                AppHaptics.tap();
                controller.toggleSave();
              },
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        // Parallax du hero au scroll + zoom de l'arrière-plan au pull-down.
        collapseMode: CollapseMode.parallax,
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: Container(
          decoration: BoxDecoration(gradient: AppColors.heroOffersGradient),
          // Halo mesh de marque par-dessus le dégradé (profondeur hero 2026).
          foregroundDecoration:
              BoxDecoration(gradient: AppColors.meshBrandGlow),
          child: Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: TopoPainter())),
              // Logo flou en filigrane (profondeur immersive) si dispo.
              if ((offer.companyLogo ?? '').isNotEmpty)
                Positioned(
                  right: -30,
                  top: -10,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Opacity(
                      opacity: 0.35,
                      child: BrandAvatar(
                        seed: offer.company,
                        label: offer.company,
                        size: 200,
                        imageUrl: offer.companyLogo,
                      ),
                    ),
                  ),
                ),
              // Voile pour la lisibilité.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.onDark.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.xxl,
                right: AppSpacing.xxl,
                bottom: AppSpacing.xl,
                // Bandeau d'infos entreprise en verre liquide (chrome hero).
                child: GlassSurface(
                  borderRadius: AppShapes.squircleRadius(AppRadius.md),
                  blurSigma: 14,
                  tintAlpha: 0.18,
                  color: AppColors.onDark,
                  borderColor: AppColors.onPrimary.withValues(alpha: 0.22),
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'offer-logo-${offer.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                AppShapes.squircleRadius(AppRadius.md),
                            border: Border.all(
                              color:
                                  AppColors.onPrimary.withValues(alpha: 0.30),
                              width: 2,
                            ),
                            boxShadow: AppColors.ambientShadow,
                          ),
                          child: ClipRRect(
                            borderRadius:
                                AppShapes.squircleRadius(AppRadius.md),
                            child: BrandAvatar(
                              seed: offer.company,
                              label: offer.company,
                              size: 64,
                              imageUrl: offer.companyLogo,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              offer.company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleLg.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (offer.sector.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                offer.sector.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.onPrimary
                                      .withValues(alpha: 0.85),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfo(Offer offer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (offer.isBoosted && offer.boostTier > 0) ...[
          OfferBoostBadge(
            tier: offer.boostTier,
            label: offer.boostLabel ?? 'À la une',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          offer.title,
          style: AppTextStyles.displayHero.copyWith(fontSize: 28),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _InfoPill(icon: IconlyLight.location, label: offer.location),
            if (offer.contractType.isNotEmpty)
              _InfoPill(icon: IconlyLight.work, label: offer.contractType),
            if (offer.isRemote)
              _InfoPill(icon: IconlyLight.location, label: 'Télétravail'),
          ],
        ),
      ],
    );
  }

  /// Grille d'infos clés (salaire / expérience / échéance) en cartes douces.
  Widget _buildKeyInfoGrid(Offer offer) {
    final tiles = <Widget>[
      if (offer.salary.isNotEmpty)
        _KeyInfoTile(
          icon: IconlyLight.wallet,
          label: 'Rémunération',
          value: offer.salary,
        ),
      if ((offer.experienceLabel ?? '').isNotEmpty)
        _KeyInfoTile(
          icon: IconlyLight.chart,
          label: 'Expérience',
          value: offer.experienceLabel!,
        ),
      if ((offer.deadlineLabel ?? '').isNotEmpty)
        _KeyInfoTile(
          icon: IconlyLight.calendar,
          label: 'Échéance',
          value: offer.deadlineLabel!,
        ),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.12),
            shape: AppShapes.squircle(AppRadius.xs),
          ),
          child: Icon(icon, size: 17, color: AppColors.primaryAccent),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          title,
          style: AppTextStyles.headlineSm.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, 0),
        decoration: BoxDecoration(
          // Fondu pour que le contenu disparaisse en douceur sous la CTA.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background.withValues(alpha: 0.0),
              AppColors.background,
              AppColors.background,
            ],
            stops: const [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            // CTA posée sur un panneau de verre liquide (chrome sticky 2026)
            // au lieu d'un simple fondu : profondeur + lisibilité au scroll.
            child: GlassSurface(
              borderRadius: AppShapes.squircleRadius(AppRadius.lg),
              blurSigma: 18,
              boxShadow: AppColors.ambientShadow,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Obx(() {
                final applied = controller.hasApplied.value;
                return AuthCtaButton(
                  label:
                      applied ? 'CANDIDATURE ENVOYÉE' : 'POSTULER MAINTENANT',
                  isLoading: controller.isApplying.value,
                  trailing: applied
                      ? IconlyBold.tick_square
                      : IconlyLight.arrow_right_2,
                  onPressed: applied ? null : () => controller.apply(),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte d'info clé compacte pour la grille de la fiche offre.
class _KeyInfoTile extends StatelessWidget {
  const _KeyInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(
          AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
        shadows: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryAccent),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.hintColor),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMd.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.bodyColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(IconlyLight.tick_square,
              size: 14, color: AppColors.primaryAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.primaryAccent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton de chargement de la fiche offre : hero + titre + chips + paragraphe.
class _OfferDetailSkeleton extends StatelessWidget {
  const _OfferDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: const [
        SkeletonBox(height: 240, radius: 0),
        Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 220, height: 26, radius: 8),
              SizedBox(height: 12),
              SkeletonBox(width: 150, height: 16, radius: 8),
              SizedBox(height: 24),
              Row(
                children: [
                  SkeletonBox(width: 90, height: 30, radius: 999),
                  SizedBox(width: 10),
                  SkeletonBox(width: 70, height: 30, radius: 999),
                  SizedBox(width: 10),
                  SkeletonBox(width: 80, height: 30, radius: 999),
                ],
              ),
              SizedBox(height: 28),
              SkeletonBox(height: 14, radius: 8),
              SizedBox(height: 10),
              SkeletonBox(height: 14, radius: 8),
              SizedBox(height: 10),
              SkeletonBox(width: 240, height: 14, radius: 8),
              SizedBox(height: 28),
              SkeletonBox(height: 54, radius: 16),
            ],
          ),
        ),
      ],
    );
  }
}
