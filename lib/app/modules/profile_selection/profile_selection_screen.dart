import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/opportune_logo.dart';
import 'profile_selection_controller.dart';

class ProfileSelectionScreen extends GetView<ProfileSelectionController> {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Column(
                  children: [
                    const OpportuneLogo(
                      iconSize: 18,
                      fontSize: 20,
                      centerAlign: true,
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Choisissez votre profil',
                      style: AppTextStyles.displayMd.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Selectionnez le profil qui correspond\nle mieux a votre situation actuelle.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.bodyColor,
                        height: 1.55,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _ProfileCard(
                      type: ProfileType.jobseeker,
                      icon: Icons.manage_search_rounded,
                      title: 'Je cherche un emploi',
                      subtitle:
                          'Je suis a la recherche d\'un emploi\net je veux etre recrute',
                      controller: controller,
                    ),
                    const SizedBox(height: 12),
                    _ProfileCard(
                      type: ProfileType.student,
                      icon: Icons.school_rounded,
                      title: 'Je suis etudiant',
                      subtitle:
                          'Je suis etudiant et je cherche\nun emploi ou un stage',
                      controller: controller,
                    ),
                    const SizedBox(height: 12),
                    _ProfileCard(
                      type: ProfileType.recruiter,
                      icon: Icons.domain_rounded,
                      title: 'Je recrute',
                      subtitle:
                          'Accedez a notre plateforme web pour\ndes outils de recrutement avances',
                      controller: controller,
                      showWebBadge: true,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              child: Obx(
                () => GradientButton(
                  label: 'CONTINUER',
                  onPressed: controller.canContinue ? controller.onContinue : null,
                  height: 56,
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
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.controller,
    this.showWebBadge = false,
  });

  final ProfileType type;
  final IconData icon;
  final String title;
  final String subtitle;
  final ProfileSelectionController controller;
  final bool showWebBadge;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final isSelected = controller.selected.value == type;
        return GestureDetector(
          onTap: () => controller.select(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceSelected : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.outlineVariant.withValues(alpha: 0.25),
                width: isSelected ? 1.5 : 0.8,
              ),
              boxShadow: AppColors.lightShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight.withValues(alpha: 0.18)
                        : AppColors.surfaceIconSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppColors.primary : AppColors.primaryDark,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: AppTextStyles.titleLg.copyWith(
                                fontWeight: FontWeight.w700,
                                color:
                                    isSelected ? AppColors.primary : AppColors.titleColor,
                              ),
                            ),
                          ),
                          if (showWebBadge) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
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
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.bodyColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                        width: isSelected ? 6.5 : 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
