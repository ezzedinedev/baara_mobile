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
              foregroundIcon: AppIcons.person,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    final step = controller.currentStep.value;
                    return _StepProgress(current: step, total: 3);
                  }),
                  const SizedBox(height: 20),
                  Text(
                    'Inscription',
                    style: AppTextStyles.displayHero.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 6),
                  Obx(() => Text(
                        _titles[controller.currentStep.value - 1],
                        style: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.bodyColor),
                      )),
                  const SizedBox(height: 24),
                  Obx(() {
                    final step = controller.currentStep.value;
                    return AnimatedSwitcher(
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
                    );
                  }),
                  Obx(() => AuthErrorBanner(
                        message: controller.errorMsg.value,
                      )),
                  const SizedBox(height: 28),
                  Obx(() {
                    final step = controller.currentStep.value;
                    return AuthCtaButton(
                      label: step == 3 ? 'Créer mon compte' : 'Continuer',
                      isLoading: controller.isLoading.value,
                      onPressed: () {
                        AppHaptics.tap();
                        controller.onContinue();
                      },
                    );
                  }),
                ],
              ),
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
        return _RegisterStepThree(controller: controller);
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
            validator: controller.validateRequired,
            icon: AppIcons.person,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'Nom',
            hint: 'Votre nom',
            controller: controller.lastNameCtrl,
            validator: controller.validateRequired,
            icon: AppIcons.person,
          ),
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
            validator: controller.validateEmail,
            icon: AppIcons.message,
          ),
          const SizedBox(height: 16),
          Obx(() => AuthPhoneField(
                controller: controller.phoneCtrl,
                country: controller.selectedCountry,
                onCountryChanged: (c) => controller.selectCountry(c.isoCode),
                validator: controller.validatePhone,
              )),
        ],
      ),
    );
  }
}

/// Étape 3 isolée : la force du mot de passe ne reconstruit que ce bloc.
class _RegisterStepThree extends StatefulWidget {
  const _RegisterStepThree({required this.controller});
  final RegisterController controller;

  @override
  State<_RegisterStepThree> createState() => _RegisterStepThreeState();
}

class _RegisterStepThreeState extends State<_RegisterStepThree> {
  String _password = '';

  @override
  void initState() {
    super.initState();
    widget.controller.passwordCtrl.addListener(_onPasswordChanged);
    _password = widget.controller.passwordCtrl.text;
  }

  void _onPasswordChanged() {
    final next = widget.controller.passwordCtrl.text;
    if (next != _password) setState(() => _password = next);
  }

  @override
  void dispose() {
    widget.controller.passwordCtrl.removeListener(_onPasswordChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Form(
      key: c.stepThreeFormKey,
      child: Column(
        children: [
          AuthTextField(
            label: 'Mot de passe',
            hint: 'Au moins 8 caractères',
            controller: c.passwordCtrl,
            obscureText: true,
            validator: c.validatePassword,
            icon: AppIcons.lock,
          ),
          AuthPasswordStrength(password: _password),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'Confirmation',
            hint: 'Retapez le mot de passe',
            controller: c.confirmPasswordCtrl,
            obscureText: true,
            validator: c.validateConfirmPassword,
            icon: AppIcons.password,
          ),
          const SizedBox(height: 16),
          Obx(() => _TermsTile(
                value: c.acceptedTerms.value,
                onChanged: (v) => c.acceptedTerms.value = v,
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

/// Case à cocher « conditions d'utilisation » sous forme de tuile carte.
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
                  ? const Icon(AppIcons.tickSquare,
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
