import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../../widgets/widgets.dart';
import 'register_profile_controller.dart';

/// Étape 2 : choix du type de candidat (étudiant / professionnel / entreprise).
/// Logique préservée via [RegisterProfileController].
class RegisterProfileScreen extends GetView<RegisterProfileController> {
  const RegisterProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyAuthHeader(
            height: 220,
            showLeading: true,
            onLeadingTap: controller.goBack,
            foregroundIcon: Icons.person_add_alt_1_rounded,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 6, 26, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quel type de compte ?',
                    style: AppTextStyles.displayMd.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Choisissez votre profil avant de continuer l'inscription.",
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.bodyColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Obx(
                    () => _ProfileCard(
                      icon: Icons.school_rounded,
                      title: 'Je suis étudiant',
                      subtitle:
                          "Je cherche un stage, une alternance ou un emploi.",
                      selected: controller.selected.value ==
                          RegisterProfileType.student,
                      onTap: () {
                        AppHaptics.tap();
                        controller.select(RegisterProfileType.student);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => _ProfileCard(
                      icon: Icons.work_outline_rounded,
                      title: 'Je suis professionnel',
                      subtitle:
                          'Je veux évoluer ou trouver de nouvelles opportunités.',
                      selected: controller.selected.value ==
                          RegisterProfileType.professional,
                      onTap: () {
                        AppHaptics.tap();
                        controller.select(RegisterProfileType.professional);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => _ProfileCard(
                      icon: Icons.domain_rounded,
                      title: 'Je représente une entreprise',
                      subtitle:
                          "Ce profil complète l'inscription sur le formulaire web.",
                      selected: controller.selected.value ==
                          RegisterProfileType.company,
                      showWebBadge: true,
                      onTap: () {
                        AppHaptics.tap();
                        controller.select(RegisterProfileType.company);
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceIconSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            AppColors.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Le profil Entreprise ouvre votre inscription sur la plateforme web.",
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.titleColor,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 6, 26, 22),
              child: Obx(
                () => AuthCtaButton(
                  label: controller.actionLabel,
                  isLoading: controller.isOpeningWeb.value,
                  onPressed:
                      controller.canContinue ? controller.onContinue : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.showWebBadge = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool showWebBadge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceSelected : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.26),
            width: selected ? 1.5 : 0.9,
          ),
          boxShadow: AppColors.lightShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryLight.withValues(alpha: 0.18)
                    : AppColors.surfaceIconSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                icon,
                size: 24,
                color: selected ? AppColors.primary : AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.titleLg.copyWith(
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppColors.primary
                                : AppColors.titleColor,
                          ),
                        ),
                      ),
                      if (showWebBadge)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'WEB',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.bodyColor,
                              fontSize: 9,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.bodyColor,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      selected ? AppColors.primary : AppColors.outlineVariant,
                  width: selected ? 6.5 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
