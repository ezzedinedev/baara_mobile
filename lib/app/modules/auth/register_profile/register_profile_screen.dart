import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../../widgets/opportune_logo.dart';
import 'register_profile_controller.dart';

class RegisterProfileScreen extends GetView<RegisterProfileController> {
  const RegisterProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: controller.goBack,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_back_rounded,
                            size: 18,
                            color: AppColors.bodyColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Retour',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.bodyColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const OpportuneLogo(
                      iconSize: 16,
                      fontSize: 18,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Quel type de compte voulez-vous creer ?',
                      style: AppTextStyles.displayMd.copyWith(
                        fontSize: 34,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choisissez votre profil avant de continuer l\'inscription.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.bodyColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Obx(
                      () => _ProfileCard(
                        icon: Icons.school_rounded,
                        title: 'Je suis etudiant',
                        subtitle:
                            'Je cherche un stage, une alternance ou un emploi.',
                        selected: controller.selected.value ==
                            RegisterProfileType.student,
                        onTap: () =>
                            controller.select(RegisterProfileType.student),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => _ProfileCard(
                        icon: Icons.work_outline_rounded,
                        title: 'Je suis professionnel',
                        subtitle:
                            'Je veux evoluer ou trouver de nouvelles opportunites.',
                        selected: controller.selected.value ==
                            RegisterProfileType.professional,
                        onTap: () =>
                            controller.select(RegisterProfileType.professional),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => _ProfileCard(
                        icon: Icons.domain_rounded,
                        title: 'Je represente une entreprise',
                        subtitle:
                            'Ce profil complete l\'inscription sur le formulaire web.',
                        selected: controller.selected.value ==
                            RegisterProfileType.company,
                        showWebBadge: true,
                        onTap: () =>
                            controller.select(RegisterProfileType.company),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.24),
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
                              'Le profil Entreprise ouvre votre inscription sur la plateforme web.',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.bodyColor,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              child: Obx(
                () => GradientButton(
                  label: controller.actionLabel,
                  onPressed:
                      controller.canContinue ? controller.onContinue : null,
                  isLoading: controller.isOpeningWeb.value,
                  textColor: AppColors.onPrimary,
                  height: 56,
                  borderRadius: 14,
                ),
              ),
            ),
          ],
        ),
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
          borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(12),
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
