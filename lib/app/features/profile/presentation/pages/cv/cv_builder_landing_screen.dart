import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';

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
          WavyContentHeader(
            title: 'Créer mon CV',
            subtitle: 'Choisissez la méthode qui vous convient',
            height: 200,
            gradient: AppColors.heroProfileGradient,
            onLeadingTap: () => Get.back(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              children: [
                _MethodCard(
                  icon: IconlyBold.chat,
                  iconColor: AppColors.primary,
                  title: 'Assistant IA',
                  subtitle:
                      'Discutez avec l\'IA, elle rédige et structure votre CV.',
                  badge: 'Recommandé',
                  onTap: () => Get.toNamed(AppRoutes.profileCvAssistant),
                ),
                const SizedBox(height: 14),
                _MethodCard(
                  icon: IconlyBold.edit,
                  iconColor: AppColors.secondary,
                  title: 'Éditeur manuel',
                  subtitle: 'Remplissez vous-même chaque section, à votre rythme.',
                  onTap: () => Get.toNamed(AppRoutes.profileCvManual),
                ),
                const SizedBox(height: 14),
                _MethodCard(
                  icon: IconlyBold.upload,
                  iconColor: AppColors.categoryPurple,
                  title: 'Importer un CV',
                  subtitle:
                      'Partez d\'un PDF existant, l\'IA le modernise pour vous.',
                  onTap: () => Get.toNamed(AppRoutes.profileCvImport),
                ),
                const SizedBox(height: 24),
                _SecondaryAction(
                  icon: IconlyLight.show,
                  label: 'Voir l\'aperçu de mon CV',
                  onTap: () => Get.toNamed(AppRoutes.profileCvPreview),
                ),
              ],
            ),
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
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.lightShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(title,
                            style: AppTextStyles.titleMd
                                .copyWith(fontWeight: FontWeight.w800)),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSelected,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(badge!,
                              style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.bodyColor, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(label,
                style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
