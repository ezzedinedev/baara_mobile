import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/asset_url.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/relative_time.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/offer_detail_controller.dart';
import '../controllers/offers_controller.dart';
import '../data/models/offer_model.dart';
import '../utils/apply_feedback.dart';

/// Detail d'une offre — hero (logo entreprise / gradient fallback) + back button,
/// metadonnees en cards, description, skills, deadline, et CTA Postuler en bottom.
/// Reagit au state du [OfferDetailController] (loading, error, ready).
class OfferDetailScreen extends GetView<OfferDetailController> {
  const OfferDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        final isLoading = controller.isLoading.value;
        final error = controller.errorMessage.value;
        final offer = controller.offer.value;

        if (isLoading && offer == null) {
          return const _OfferDetailSkeleton();
        }

        if (offer == null) {
          return SafeArea(
            child: Column(
              children: [
                const _MinimalBackBar(),
                Expanded(
                  child: ErrorStateView(
                    message: error.isEmpty ? 'Offre introuvable.' : error,
                    onRetry: controller.refreshOffer,
                  ),
                ),
              ],
            ),
          );
        }

        return _OfferDetailContent(offer: offer);
      }),
      bottomNavigationBar: Obx(() {
        final offer = controller.offer.value;
        if (offer == null) return const SizedBox.shrink();
        return _ApplyBottomBar(offer: offer);
      }),
    );
  }
}

class _OfferDetailContent extends StatelessWidget {
  const _OfferDetailContent({required this.offer});

  final OfferModel offer;

  @override
  Widget build(BuildContext context) {
    final accentEnd = AppColors.avatarGradientForSeed(offer.company).last;
    final logoUrl = (offer.companyLogo != null && offer.companyLogo!.trim().isNotEmpty)
        ? resolveAssetUrl(offer.companyLogo!)
        : '';
    final posted = relativeTimeFr(offer.createdAt);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => Get.find<OfferDetailController>().refreshOffer(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // ───────── HERO ─────────
          RevealOnMount(
            duration: const Duration(milliseconds: 540),
            offsetY: 18,
            child: _OfferHero(
              offer: offer,
              accentEnd: accentEnd,
              logoUrl: logoUrl,
              posted: posted,
            ),
          ),
          const SizedBox(height: 18),
          // ───────── Bandeau salaire ─────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _SalaryBanner(salary: offer.salary),
          ),
          const SizedBox(height: 14),
          // ───────── Metas (entreprise / location / contrat / etc) ─────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _MetaGrid(offer: offer),
          ),
          const SizedBox(height: 22),
          // ───────── Description ─────────
          if (offer.description.trim().isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _SectionTitle(
                icon: IconlyLight.document,
                title: 'Description du poste',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: AppRadius.lg,
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  offer.description,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.bodyColor,
                    height: 1.55,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
          // ───────── Skills ─────────
          if (offer.requiredSkills.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _SectionTitle(
                icon: IconlyLight.activity,
                title: 'Compétences requises',
                color: AppColors.categoryPurple,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: offer.requiredSkills
                    .map((skill) => _SkillChip(label: skill))
                    .toList(),
              ),
            ),
            const SizedBox(height: 22),
          ],
          // ───────── Deadline en pied ─────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: AppRadius.md,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    IconlyLight.calendar,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      offer.deadlineLabel,
                      style: AppTextStyles.titleMd.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Marge en bas pour ne pas etre cache par la bottom bar.
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _OfferHero extends StatelessWidget {
  const _OfferHero({
    required this.offer,
    required this.accentEnd,
    required this.logoUrl,
    required this.posted,
  });

  final OfferModel offer;
  final Color accentEnd;
  final String logoUrl;
  final String posted;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 16, 28),
      decoration: BoxDecoration(
        gradient: AppColors.heroOffersGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: AppRadius.xlRadius,
          bottomRight: AppRadius.xlRadius,
        ),
        boxShadow: AppColors.lightShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: CustomPaint(painter: TopoPainter())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  WavyHeaderLeadingButton(
                    onTap: () {
                      AppHaptics.tap();
                      Navigator.of(context).maybePop();
                    },
                  ),
                  const Spacer(),
                  if (offer.isRemote)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary.withValues(alpha: 0.20),
                        borderRadius: AppRadius.pill,
                        border: Border.all(
                          color: AppColors.onPrimary.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            IconlyLight.discovery,
                            size: 14,
                            color: AppColors.onPrimary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Remote',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              // Logo entreprise (avec fallback gradient via BrandAvatar).
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onDark.withValues(alpha: 0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: BrandAvatar(
                  seed: offer.company,
                  label: offer.company,
                  size: 76,
                  fontSize: 26,
                  imageUrl: logoUrl.isEmpty ? null : logoUrl,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                offer.title,
                style: AppTextStyles.displayMd.copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      offer.company.isEmpty ? '—' : offer.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMd.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (posted.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.onPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      posted,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
              if (offer.sector.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.18),
                    borderRadius: AppRadius.pill,
                    border: Border.all(
                      color: AppColors.onPrimary.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    offer.sector,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SalaryBanner extends StatelessWidget {
  const _SalaryBanner({required this.salary});
  final String salary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.successSoft,
            AppColors.successSoft.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: AppRadius.lg,
        border: Border.all(
          color: AppColors.successDark.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.successStrong.withValues(alpha: 0.12),
              borderRadius: AppRadius.md,
            ),
            child: const Icon(
              IconlyBold.wallet,
              color: AppColors.successStrong,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rémunération',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.successStrong,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  salary,
                  style: AppTextStyles.titleLg.copyWith(
                    color: AppColors.successStrong,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.offer});

  final OfferModel offer;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _MetaTile(
        icon: IconlyLight.location,
        label: 'Lieu',
        value: offer.location,
        color: AppColors.categoryBlue,
      ),
      _MetaTile(
        icon: IconlyLight.work,
        label: 'Type de contrat',
        value: offer.contractType.isEmpty ? 'Non précisé' : offer.contractType,
        color: AppColors.categoryPurple,
      ),
      _MetaTile(
        icon: IconlyLight.activity,
        label: 'Expérience',
        value: offer.experienceLabel,
        color: AppColors.categoryOrange,
      ),
      if (offer.sector.isNotEmpty)
        _MetaTile(
          icon: IconlyLight.category,
          label: 'Secteur',
          value: offer.sector,
          color: AppColors.categoryCyan,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles
              .map((t) => SizedBox(width: tileWidth, child: t))
              .toList(),
        );
      },
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.md,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.hintColor,
                    fontSize: 9,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.titleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });



  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: AppRadius.sm,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.headlineSm.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.titleColor,
          letterSpacing: 0.2,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MinimalBackBar extends StatelessWidget {
  const _MinimalBackBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              AppHaptics.tap();
              Navigator.of(context).maybePop();
            },
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.titleColor,
          ),
        ],
      ),
    );
  }
}

class _ApplyBottomBar extends StatelessWidget {
  const _ApplyBottomBar({required this.offer});

  final OfferModel offer;

  @override
  Widget build(BuildContext context) {
    final offersController = Get.find<OffersController>();
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(
            top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          boxShadow: AppColors.lightShadow,
        ),
        child: Obx(() {
          final applied = offersController.hasAppliedToOffer(offer.id);
          final isApplying =
              offersController.isApplyingToOfferId.value == offer.id;

          if (applied) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: AppRadius.md,
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
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Candidature envoyée',
                    style: AppTextStyles.titleLg.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }

          return FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              minimumSize: const Size.fromHeight(52),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.md,
              ),
            ),
            onPressed: isApplying
                ? null
                : () async {
                    AppHaptics.tap();
                    final result =
                        await offersController.applyToOffer(offer.id);
                    if (!context.mounted) return;
                    await handleApplyResult(context, result);
                  },
            icon: isApplying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.onPrimary),
                    ),
                  )
                : const Icon(IconlyBold.send, size: 20),
            label: Text(
              isApplying ? 'Envoi…' : 'Postuler à cette offre',
              style: AppTextStyles.buttonLg.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Skeleton plein ecran pendant le chargement initial du detail.
/// Reprend la silhouette du hero + cards meta pour un effet "structure-preserving".
class _OfferDetailSkeleton extends StatelessWidget {
  const _OfferDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(20, topPadding + 12, 16, 28),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: const BorderRadius.only(
              bottomLeft: AppRadius.xlRadius,
              bottomRight: AppRadius.xlRadius,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 44),
              SkeletonBox(
                width: 76,
                height: 76,
                radius: 999,
                shape: BoxShape.circle,
              ),
              SizedBox(height: 14),
              SkeletonBox(width: 240, height: 22, radius: 6),
              SizedBox(height: 8),
              SkeletonBox(width: 160, height: 14, radius: 6),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: SkeletonBox(height: 64, radius: 18),
        ),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              Expanded(child: SkeletonBox(height: 60, radius: 14)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBox(height: 60, radius: 14)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: SkeletonBox(height: 140, radius: 18),
        ),
      ],
    );
  }
}
