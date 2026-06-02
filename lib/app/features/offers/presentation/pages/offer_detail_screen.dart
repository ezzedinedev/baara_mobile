import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../controllers/offer_detail_controller.dart';
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
                        _buildAiMatchBanner(),
                        const SizedBox(height: 24),
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      actions: [
        Obx(() => IconButton(
          icon: const Icon(
            IconlyLight.bookmark,
            color: Colors.white,
          ),
            onPressed: () {
              AppHaptics.tap();
              controller.toggleSave();
            },
        )),
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
                  BrandAvatar(
                    seed: offer.company,
                    label: offer.company,
                    size: 80,
                    imageUrl: offer.companyLogo,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiMatchBanner() {
    return Obx(() {
      if (controller.isAiLoading.value) {
        return const SkeletonBox(height: 60, radius: 16);
      }

      final score = controller.aiMatchScore.value;
      if (score == null) return const SizedBox.shrink();

      final percentage = (score.score * 100).toInt();
      final Color scoreColor = percentage > 70 ? AppColors.success : (percentage > 40 ? AppColors.warning : AppColors.error);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scoreColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scoreColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(IconlyBold.discovery, color: scoreColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Match IA : $percentage%',
                    style: AppTextStyles.titleMd.copyWith(color: scoreColor, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Basé sur votre profil et vos compétences.',
                    style: AppTextStyles.bodySm.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scoreColor),
          ],
        ),
      );
    });
  }

  Widget _buildMainInfo(Offer offer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Row(
          children: [
            _InfoTile(icon: IconlyLight.location, label: offer.location),
            const SizedBox(width: 16),
            const _InfoTile(icon: IconlyLight.calendar, label: 'Publié il y a 2j'),
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.hintColor),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600)),
      ],
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
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
