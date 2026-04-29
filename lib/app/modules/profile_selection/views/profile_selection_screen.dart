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
          // Header reduit (220 → 150) pour que le contenu tienne sans
          // scroll sur les petits ecrans (Tecno KG5j ~720dp visible).
          WavyAuthHeader(
            height: 150,
            showLeading: true,
            onLeadingTap: () => Get.back<void>(),
            foregroundIcon: Icons.account_circle_outlined,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choisissez votre profil',
                    style: AppTextStyles.displayMd.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 42,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sélectionnez le profil qui correspond à votre situation.',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.bodyColor,
                      height: 1.35,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ProfileCard(
                    type: ProfileType.jobseeker,
                    icon: Icons.manage_search_rounded,
                    title: 'Je cherche un emploi',
                    subtitle:
                        "Trouvez un emploi et soyez recruté.",
                    controller: controller,
                  ),
                  const SizedBox(height: 10),
                  _ProfileCard(
                    type: ProfileType.student,
                    icon: Icons.school_rounded,
                    title: 'Je suis étudiant',
                    subtitle:
                        'Cherchez un emploi ou un stage.',
                    controller: controller,
                  ),
                  const SizedBox(height: 10),
                  _ProfileCard(
                    type: ProfileType.recruiter,
                    icon: Icons.domain_rounded,
                    title: 'Je recrute',
                    subtitle:
                        'Accédez à la plateforme web de recrutement.',
                    controller: controller,
                    showWebBadge: true,
                  ),
                  const SizedBox(height: 14),
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
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.surfaceSelected
                : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.outlineVariant.withValues(alpha: 0.25),
              width: isSelected ? 1.5 : 0.8,
            ),
            boxShadow: AppColors.lightShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryLight.withValues(alpha: 0.18)
                      : AppColors.surfaceIconSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppTextStyles.titleLg.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.titleColor,
                            ),
                          ),
                        ),
                        if (showWebBadge) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHighest,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'WEB',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.bodyColor,
                                fontSize: 8.5,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.bodyColor,
                        height: 1.3,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                    width: isSelected ? 6.0 : 1.5,
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
