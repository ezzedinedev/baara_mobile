import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';

/// Hub du créateur de CV : trois méthodes (assistant IA, éditeur manuel,
/// import d'un CV existant) + accès à l'aperçu. Point d'entrée du flux CV.
class CvBuilderLandingScreen extends StatelessWidget {
  const CvBuilderLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header avec fond mesh subtil ──────────────────────────────────
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.meshBrand,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.meshBrandGlow,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 16, 16),
                  child: Row(
                    children: [
                      AppBackButton(onTap: () => Get.back<void>()),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Créer mon CV',
                              style: AppTextStyles.titleLg
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Choisissez la méthode qui vous convient',
                              style: AppTextStyles.bodySm
                                  .copyWith(color: AppColors.hintColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              children: [
                RevealOnMount(
                  delay: Duration.zero,
                  child: _MethodCard(
                    icon: AppIcons.chatFilled,
                    iconColor: AppColors.primaryAccent,
                    title: 'Assistant IA',
                    subtitle:
                        "Discutez avec l'IA, elle rédige et structure votre CV.",
                    badge: 'Recommandé',
                    onTap: () => Get.toNamed(AppRoutes.profileCvAssistant),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                RevealOnMount(
                  delay: const Duration(milliseconds: 80),
                  child: _MethodCard(
                    icon: AppIcons.edit,
                    iconColor: AppColors.secondary,
                    title: 'Éditeur manuel',
                    subtitle:
                        'Remplissez vous-même chaque section, à votre rythme.',
                    onTap: () => Get.toNamed(AppRoutes.profileCvManual),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                RevealOnMount(
                  delay: const Duration(milliseconds: 160),
                  child: _MethodCard(
                    icon: AppIcons.upload,
                    iconColor: AppColors.categoryPurple,
                    title: 'Importer un CV',
                    subtitle:
                        "Partez d'un PDF existant, l'IA le modernise pour vous.",
                    onTap: () => Get.toNamed(AppRoutes.profileCvImport),
                  ),
                ),
              ],
            ),
          ),
          CvStickyActionBar(
            primaryLabel: "Voir l'aperçu de mon CV",
            onPrimary: () => Get.toNamed(AppRoutes.profileCvPreview),
            secondaryLabel: 'Assistant IA',
            onSecondary: () => Get.toNamed(AppRoutes.profileCvAssistant),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      curve: AppMotion.spring,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: AppColors.surfaceCard,
          shape: AppShapes.cardBordered(AppColors.outlineVariant),
          shadows: [
            ...AppColors.lightShadow,
            ...AppColors.ambientShadow,
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AppShapes.squircleRadius(AppRadius.md),
                ),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppTextStyles.titleMd
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSelected,
                              borderRadius: AppShapes.pill,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              child: Text(
                                badge!,
                                style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.primaryAccent,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.bodyColor, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ListNavChevron(
                  color: AppColors.primaryAccent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
