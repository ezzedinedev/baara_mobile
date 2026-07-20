import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/theme/app_motion.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';
import '../controllers/register_profile_controller.dart';

class RegisterProfileScreen extends GetView<RegisterProfileController> {
  const RegisterProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyAuthHeader(
            height: 180,
            showLeading: true,
            foregroundIcon: IconlyLight.category,
            onLeadingTap: () => Get.back(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RevealOnMount(
                    child: Text(
                      'Quel est votre profil ?',
                      style: AppTextStyles.displayHero.copyWith(fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 60),
                    child: Text(
                      'Cela nous aide à personnaliser les offres et formations qui vous correspondent.',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.bodyColor, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 28),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 120),
                    child: Obx(() => _ProfileOption(
                          icon: IconlyLight.bookmark,
                          title: 'Étudiant',
                          subtitle: 'Stages, premiers emplois et formations.',
                          isSelected:
                              controller.selectedProfile.value == 'student',
                          onTap: () => controller.selectProfile('student'),
                        )),
                  ),
                  const SizedBox(height: 14),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 180),
                    child: Obx(() => _ProfileOption(
                          icon: IconlyLight.work,
                          title: 'Professionnel',
                          subtitle:
                              'Emplois qualifiés et évolution de carrière.',
                          isSelected: controller.selectedProfile.value ==
                              'professional',
                          onTap: () => controller.selectProfile('professional'),
                        )),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              child: AuthCtaButton(
                label: 'Continuer',
                onPressed: controller.onContinue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      haptic: false,
      curve: AppMotion.springEmphasized,
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.emphasizedDecelerate,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceSelected : AppColors.surfaceCard,
          borderRadius: AppShapes.squircleRadius(AppRadius.lg),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryAccent
                : AppColors.outlineVariant.withValues(alpha: 0.35),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryAccent.withValues(alpha: 0.16),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : AppColors.lightShadow,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.emphasizedDecelerate,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryLight.withValues(alpha: 0.20)
                    : AppColors.surfaceIconSoft,
                borderRadius: AppShapes.squircleRadius(AppRadius.sm),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? AppColors.primaryAccent
                    : AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleLg.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primaryAccent
                          : AppColors.titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.bodyColor, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.springEmphasized,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryAccent
                      : AppColors.outlineVariant,
                  width: isSelected ? 6.5 : 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
