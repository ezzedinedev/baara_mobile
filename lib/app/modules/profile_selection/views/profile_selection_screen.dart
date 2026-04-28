import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/profile_selection_controller.dart';

/// Étape 1 : choix du type de profil (candidat / étudiant / recruteur).
/// Logique préservée via [ProfileSelectionController].
class ProfileSelectionScreen extends GetView<ProfileSelectionController> {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyAuthHeader(
            height: 220,
            showLeading: true,
            onLeadingTap: () => Get.back<void>(),
            foregroundIcon: Icons.account_circle_outlined,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 6, 26, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choisissez votre profil',
                    style: AppTextStyles.displayMd.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sélectionnez le profil qui correspond le mieux à votre situation actuelle.',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.bodyColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ProfileCard(
                    type: ProfileType.jobseeker,
                    icon: Icons.manage_search_rounded,
                    title: 'Je cherche un emploi',
                    subtitle:
                        "Je suis à la recherche d'un emploi et je veux être recruté.",
                    controller: controller,
                  ),
                  const SizedBox(height: 12),
                  _ProfileCard(
                    type: ProfileType.student,
                    icon: Icons.school_rounded,
                    title: 'Je suis étudiant',
                    subtitle:
                        'Je suis étudiant et je cherche un emploi ou un stage.',
                    controller: controller,
                  ),
                  const SizedBox(height: 12),
                  _ProfileCard(
                    type: ProfileType.recruiter,
                    icon: Icons.domain_rounded,
                    title: 'Je recrute',
                    subtitle:
                        'Accédez à notre plateforme web pour des outils de recrutement avancés.',
                    controller: controller,
                    showWebBadge: true,
                  ),
                  const SizedBox(height: 28),
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
                  label: 'Continuer',
                  onPressed: controller.canContinue ? controller.onContinue : null,
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
    return Obx(() {
      final isSelected = controller.selected.value == type;
      return GestureDetector(
        onTap: () {
          AppHaptics.tap();
          controller.select(type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.surfaceSelected
                : AppColors.surfaceCard,
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
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primaryDark,
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
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.titleColor,
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
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                      width: isSelected ? 6.5 : 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
