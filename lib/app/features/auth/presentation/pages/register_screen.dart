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
import '../controllers/register_controller.dart';

class RegisterScreen extends GetView<RegisterController> {
  const RegisterScreen({super.key});

  static const _titles = <String>[
    'Faisons connaissance',
    'Vos coordonnées',
    'Sécurisez votre compte',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            WavyAuthHeader(
              height: 180,
              showLeading: true,
              foregroundIcon: IconlyLight.profile,
              onLeadingTap: () {
                AppHaptics.tap();
                if (controller.currentStep.value > 1) {
                  controller.currentStep.value--;
                } else {
                  Get.back();
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Obx(() {
                final step = controller.currentStep.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepProgress(current: step, total: 3),
                    const SizedBox(height: 20),
                    Text(
                      'Inscription',
                      style: AppTextStyles.displayHero.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _titles[step - 1],
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.bodyColor),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.06, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey<int>(step),
                        child: _stepForm(step),
                      ),
                    ),
                    AuthErrorBanner(message: controller.errorMsg.value),
                    const SizedBox(height: 28),
                    AuthCtaButton(
                      label: step == 3 ? 'Créer mon compte' : 'Continuer',
                      isLoading: controller.isLoading.value,
                      onPressed: () {
                        AppHaptics.tap();
                        controller.onContinue();
                      },
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepForm(int step) {
    switch (step) {
      case 1:
        return _buildStepOne();
      case 2:
        return _buildStepTwo();
      default:
        return _buildStepThree();
    }
  }

  Widget _buildStepOne() {
    return Form(
      key: controller.stepOneFormKey,
      child: Column(
        children: [
          AuthTextField(
              label: 'Prénom',
              hint: 'Votre prénom',
              controller: controller.firstNameCtrl,
              icon: IconlyLight.profile),
          const SizedBox(height: 16),
          AuthTextField(
              label: 'Nom',
              hint: 'Votre nom',
              controller: controller.lastNameCtrl,
              icon: IconlyLight.profile),
        ],
      ),
    );
  }

  Widget _buildStepTwo() {
    return Form(
      key: controller.stepTwoFormKey,
      child: Column(
        children: [
          AuthTextField(
              label: 'Email',
              hint: 'nom@exemple.com',
              controller: controller.emailCtrl,
              keyboardType: TextInputType.emailAddress,
              icon: IconlyLight.message),
          const SizedBox(height: 16),
          AuthTextField(
              label: 'Téléphone',
              hint: '+226 ...',
              controller: controller.phoneCtrl,
              keyboardType: TextInputType.phone,
              icon: IconlyLight.call),
        ],
      ),
    );
  }

  Widget _buildStepThree() {
    return Form(
      key: controller.stepThreeFormKey,
      child: Column(
        children: [
          AuthTextField(
              label: 'Mot de passe',
              hint: 'Au moins 8 caractères',
              controller: controller.passwordCtrl,
              obscureText: true,
              icon: IconlyLight.lock),
          const SizedBox(height: 16),
          AuthTextField(
              label: 'Confirmation',
              hint: 'Retapez le mot de passe',
              controller: controller.confirmPasswordCtrl,
              obscureText: true,
              icon: IconlyLight.password),
          const SizedBox(height: 16),
          Obx(() => _TermsTile(
                value: controller.acceptedTerms.value,
                onChanged: (v) => controller.acceptedTerms.value = v,
              )),
        ],
      ),
    );
  }
}

/// Barre d'étapes (1/3 → 3/3) : segments remplis jusqu'à l'étape courante.
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 1; i <= total; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.emphasized,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= current
                        ? AppColors.primaryAccent
                        : AppColors.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: AppShapes.pill,
                  ),
                ),
              ),
              if (i != total) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Étape $current sur $total',
          style: AppTextStyles.labelSm.copyWith(color: AppColors.hintColor),
        ),
      ],
    );
  }
}

/// Case à cocher « conditions d'utilisation » sous forme de tuile carte :
/// surface douce, coche carrée verte animée, zone tap large (>=44).
class _TermsTile extends StatelessWidget {
  const _TermsTile({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppShapes.squircleRadius(AppRadius.lg),
      onTap: () {
        AppHaptics.tap();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: AppMotion.short,
        curve: AppMotion.emphasizedDecelerate,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: value ? AppColors.surfaceSelected : AppColors.surfaceCard,
          borderRadius: AppShapes.squircleRadius(AppRadius.lg),
          border: Border.all(
            color: value
                ? AppColors.primaryAccent.withValues(alpha: 0.55)
                : AppColors.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppMotion.short,
              curve: AppMotion.springEmphasized,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : Colors.transparent,
                borderRadius: AppShapes.squircleRadius(AppRadius.xs),
                border: Border.all(
                  color: value ? AppColors.primary : AppColors.outlineVariant,
                  width: 1.6,
                ),
              ),
              child: value
                  ? const Icon(IconlyLight.tick_square,
                      size: 16, color: AppColors.onPrimary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "J'accepte les conditions d'utilisation et la politique de confidentialité.",
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.bodyColor,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
