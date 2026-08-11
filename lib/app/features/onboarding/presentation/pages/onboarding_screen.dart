import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  static const _steps = <({IconData icon, String title, String body, String cta})>[
    (
      icon: AppIcons.personFilled,
      title: 'Complétez votre profil',
      body:
          'Ajoutez votre photo, votre titre et vos compétences pour attirer les recruteurs.',
      cta: 'Voir mon profil',
    ),
    (
      icon: AppIcons.document,
      title: 'Créez ou importez votre CV',
      body:
          'Un CV à jour multiplie vos chances. Importez un PDF ou créez-le avec l\'assistant Baara.',
      cta: 'Mon CV',
    ),
    (
      icon: AppIcons.workFilled,
      title: 'Découvrez vos opportunités',
      body:
          'Swipez les offres qui vous correspondent, postulez en un geste et suivez vos candidatures.',
      cta: 'Explorer les offres',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: controller.skip,
                child: Text(
                  'Passer',
                  style: AppTextStyles.labelLg.copyWith(
                    color: AppColors.hintColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final step = controller.currentStep.value;
                final data = _steps[step];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      RevealOnMount(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: AppShapes.squircleRadius(AppRadius.xl),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryAccent
                                    .withValues(alpha: 0.28),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(data.icon,
                              size: 40, color: AppColors.onPrimary),
                        ),
                      ),
                      const SizedBox(height: 32),
                      RevealOnMount(
                        delay: const Duration(milliseconds: 80),
                        child: Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displayHero.copyWith(fontSize: 28),
                        ),
                      ),
                      const SizedBox(height: 14),
                      RevealOnMount(
                        delay: const Duration(milliseconds: 140),
                        child: Text(
                          data.body,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.bodyColor,
                            height: 1.5,
                          ),
                        ),
                      ),
                      Obx(() {
                        final hint = controller.stepHint.value;
                        if (hint == null || hint.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            hint,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        );
                      }),
                      const Spacer(flex: 3),
                      _StepDots(current: step, total: _steps.length),
                      const SizedBox(height: 28),
                    ],
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Obx(() {
                final step = controller.currentStep.value;
                final isLast = step >= _steps.length - 1;
                return AuthCtaButton(
                  label: isLast ? 'Commencer' : _steps[step].cta,
                  isLoading: controller.isBusy.value,
                  onPressed: controller.isBusy.value
                      ? null
                      : () {
                          AppHaptics.tap();
                          controller.next(isLast: isLast);
                        },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          AnimatedContainer(
            duration: AppMotion.short,
            width: i == current ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current
                  ? AppColors.primaryAccent
                  : AppColors.outlineVariant.withValues(alpha: 0.55),
              borderRadius: AppShapes.pill,
            ),
          ),
        ],
      ],
    );
  }
}
