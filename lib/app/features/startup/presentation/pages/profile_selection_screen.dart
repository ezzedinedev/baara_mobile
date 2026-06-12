import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../controllers/profile_selection_controller.dart';

class ProfileSelectionScreen extends GetView<ProfileSelectionController> {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyAuthHeader(
              height: 150,
              showLeading: true,
              onLeadingTap: () => Get.back(),
              foregroundIcon: IconlyLight.profile),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RevealOnMount(
                    child: Text('Choisissez votre profil',
                        style:
                            AppTextStyles.displayHero.copyWith(fontSize: 28)),
                  ),
                  const SizedBox(height: 7),
                  Container(
                      width: 46,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.primaryAccent,
                          borderRadius: AppShapes.pill)),
                  const SizedBox(height: 8),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 60),
                    child: Text(
                        "Sélectionnez le profil qui correspond à votre situation.",
                        style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.bodyColor,
                            height: 1.35,
                            fontSize: 13)),
                  ),
                  const SizedBox(height: 20),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 120),
                    child: _ProfileCard(
                        type: ProfileType.jobseeker,
                        icon: IconlyLight.search,
                        title: 'Je cherche un emploi',
                        subtitle: "Trouvez un emploi et soyez recruté.",
                        controller: controller),
                  ),
                  const SizedBox(height: 10),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 170),
                    child: _ProfileCard(
                        type: ProfileType.student,
                        icon: IconlyLight.bookmark,
                        title: 'Je suis étudiant',
                        subtitle: 'Cherchez un emploi ou un stage.',
                        controller: controller),
                  ),
                  const SizedBox(height: 10),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 220),
                    child: _ProfileCard(
                        type: ProfileType.recruiter,
                        icon: IconlyLight.work,
                        title: 'Je recrute',
                        subtitle: 'Accédez à la plateforme web de recrutement.',
                        controller: controller,
                        showWebBadge: true),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 6, 26, 22),
              child: Obx(() => AuthCtaButton(
                  label: 'Continuer',
                  onPressed:
                      controller.canContinue ? controller.onContinue : null)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ProfileType type;
  final IconData icon;
  final String title;
  final String subtitle;
  final ProfileSelectionController controller;
  final bool showWebBadge;
  const _ProfileCard(
      {required this.type,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.controller,
      this.showWebBadge = false});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = controller.selected.value == type;
      return PressScale(
        haptic: false,
        curve: AppMotion.springEmphasized,
        onTap: () {
          AppHaptics.tap();
          controller.select(type);
        },
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.emphasizedDecelerate,
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.surfaceSelected
                  : AppColors.surfaceCard,
              borderRadius: AppShapes.squircleRadius(AppRadius.lg),
              border: Border.all(
                  color: isSelected
                      ? AppColors.primaryAccent
                      : AppColors.outlineVariant.withValues(alpha: 0.25),
                  width: isSelected ? 1.5 : 0.8),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryAccent.withValues(alpha: 0.16),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : AppColors.lightShadow),
          child: Row(
            children: [
              AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.emphasizedDecelerate,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryLight.withValues(alpha: 0.18)
                          : AppColors.surfaceIconSoft,
                      borderRadius: AppShapes.squircleRadius(AppRadius.sm)),
                  child: Icon(icon,
                      color: isSelected
                          ? AppColors.primaryAccent
                          : AppColors.primaryDark,
                      size: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Flexible(
                          child: Text(title,
                              style: AppTextStyles.titleLg.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: isSelected
                                      ? AppColors.primaryAccent
                                      : AppColors.titleColor))),
                      if (showWebBadge) ...[
                        const SizedBox(width: 6),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                                color: AppColors.surfaceHighest,
                                borderRadius: AppShapes.pill),
                            child: Text('WEB',
                                style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.bodyColor,
                                    fontSize: 8.5,
                                    letterSpacing: 1.0)))
                      ]
                    ]),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.bodyColor,
                            height: 1.3,
                            fontSize: 11.5)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Indicateur de sélection : pastille qui se REMPLIT en vert avec
              // une coche qui « pop » en spring (plus vivant qu'un radio).
              AnimatedContainer(
                duration: AppMotion.medium,
                curve: AppMotion.springEmphasized,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primaryAccent
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryAccent
                        : AppColors.outlineVariant,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                AppColors.primaryAccent.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: AppMotion.medium,
                  curve: AppMotion.springEmphasized,
                  child: const Icon(Icons.check_rounded,
                      size: 16, color: AppColors.onPrimary),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
