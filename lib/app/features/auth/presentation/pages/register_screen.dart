import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
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
                    const SizedBox(height: 18),
                    Text('Inscription', style: AppTextStyles.displayMd),
                    const SizedBox(height: 4),
                    Text(
                      _titles[step - 1],
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.hintColor),
                    ),
                    const SizedBox(height: 20),
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
                    if (controller.errorMsg.value.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        controller.errorMsg.value,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.error),
                      ),
                    ],
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
              controller: controller.firstNameCtrl,
              icon: Icons.person_outline),
          const SizedBox(height: 12),
          AuthTextField(
              label: 'Nom',
              controller: controller.lastNameCtrl,
              icon: Icons.person_outline),
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
              controller: controller.emailCtrl,
              icon: Icons.email_outlined),
          const SizedBox(height: 12),
          AuthTextField(
              label: 'Téléphone',
              controller: controller.phoneCtrl,
              icon: Icons.phone_outlined),
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
              controller: controller.passwordCtrl,
              obscureText: true,
              icon: Icons.lock_outline),
          const SizedBox(height: 12),
          AuthTextField(
              label: 'Confirmation',
              controller: controller.confirmPasswordCtrl,
              obscureText: true,
              icon: Icons.lock_outline),
          const SizedBox(height: 8),
          Obx(() => InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  AppHaptics.tap();
                  controller.acceptedTerms.value =
                      !controller.acceptedTerms.value;
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: controller.acceptedTerms.value,
                        activeColor: AppColors.primary,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onChanged: (v) {
                          AppHaptics.tap();
                          controller.acceptedTerms.value = v ?? false;
                        },
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 11),
                          child: Text(
                            "J'accepte les conditions d'utilisation et la politique de confidentialité.",
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.bodyColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  duration: const Duration(milliseconds: 260),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= current
                        ? AppColors.primary
                        : AppColors.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
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
