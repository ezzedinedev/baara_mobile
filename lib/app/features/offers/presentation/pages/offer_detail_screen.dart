import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
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
            onRetry: () async => controller.onInit(),
          );
        }

        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildSliverAppBar(offer),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMainInfo(offer),
                        const SizedBox(height: 32),
                        _buildSectionTitle('À propos de l\'offre'),
                        const SizedBox(height: 12),
                        Text(
                          offer.description,
                          style: AppTextStyles.bodyMd.copyWith(height: 1.7, color: AppColors.bodyColor),
                        ),
                        const SizedBox(height: 32),
                        if (offer.requiredSkills.isNotEmpty) ...[
                          _buildSectionTitle('Compétences requises'),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: offer.requiredSkills.map((s) => _SkillChip(label: s)).toList(),
                          ),
                        ],
                        const SizedBox(height: 120), // Bottom padding for button
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
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppBackButton(onDark: true, onTap: () => Get.back<void>()),
      ),
      leadingWidth: 60,
      actions: [
        IconButton(
          icon: const Icon(IconlyLight.bookmark, color: Colors.white),
          onPressed: () {
            AppHaptics.tap();
            controller.toggleSave();
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: AppColors.heroOffersGradient,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(child: CustomPaint(painter: TopoPainter())),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Hero(
                    tag: 'offer-logo-${offer.id}',
                    child: BrandAvatar(
                      seed: offer.company,
                      label: offer.company,
                      size: 80,
                      imageUrl: offer.companyLogo,
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

  Widget _buildMainInfo(Offer offer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (offer.isBoosted && offer.boostTier > 0) ...[
          OfferBoostBadge(
            tier: offer.boostTier,
            label: offer.boostLabel ?? 'À la une',
          ),
          const SizedBox(height: 10),
        ],
        Text(
          offer.title,
          style: AppTextStyles.displayMd.copyWith(fontSize: 24, height: 1.2),
        ),
        const SizedBox(height: 8),
        Text(
          offer.company,
          style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoPill(icon: IconlyLight.location, label: offer.location),
            if (offer.contractType.isNotEmpty)
              _InfoPill(icon: IconlyLight.work, label: offer.contractType),
            if (offer.salary.isNotEmpty)
              _InfoPill(icon: IconlyLight.wallet, label: offer.salary),
            if (offer.isRemote)
              _InfoPill(icon: IconlyLight.location, label: 'Télétravail'),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleLg.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildBottomAction() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            PressScale(
              onTap: () {
                AppHaptics.tap();
                // Chat logic
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(IconlyLight.chat, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() {
                final applied = controller.hasApplied.value;
                return AuthCtaButton(
                  label:
                      applied ? 'CANDIDATURE ENVOYÉE' : 'POSTULER MAINTENANT',
                  isLoading: controller.isApplying.value,
                  trailing:
                      applied ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  onPressed: applied ? null : () => controller.apply(),
                );
              }),
            ),
          ],
        ),
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
          Icon(icon, size: 14, color: AppColors.primary),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(
          color: AppColors.titleColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
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
