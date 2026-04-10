import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../../routes/app_routes.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../../widgets/register/country_dropdown.dart';
import '../../../../widgets/register/register_badges.dart';
import '../../../../widgets/register/step_input.dart';
import 'register_controller.dart';

class RegisterScreen extends GetView<RegisterController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => controller.onBack(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              GestureDetector(
                onTap: controller.onBack,
                child: Obx(
                  () => Row(
                    children: [
                      const Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: AppColors.bodyColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        controller.backLabel,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.bodyColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Etape ${controller.currentStep.value} sur 3',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.bodyColor,
                        letterSpacing: 0.4,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${controller.progressPercent}%',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.bodyColor,
                        letterSpacing: 0.2,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: controller.progressValue,
                    backgroundColor: AppColors.surfaceHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => Text(
                  controller.stepTitle,
                  style: AppTextStyles.displayMd.copyWith(
                    fontSize: 40,
                    height: 1.02,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Obx(
                () => Text(
                  controller.stepSubtitle,
                  style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.bodyColor,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.26),
                    ),
                  ),
                  child: Text(
                    'Profil: ${controller.registrationProfileLabel}',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.bodyColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Obx(
                () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _StepForm(
                    key: ValueKey<int>(controller.currentStep.value),
                    step: controller.currentStep.value,
                    controller: controller,
                  ),
                ),
              ),
              Obx(() {
                if (controller.errorMsg.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Text(
                      controller.errorMsg.value,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Obx(
                () => GradientButton(
                  label: controller.actionLabel,
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.onContinue,
                  isLoading: controller.isLoading.value,
                  textColor: AppColors.onPrimary,
                  gradient: AppColors.primaryGradient,
                  height: 54,
                  borderRadius: 14,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      'Vous avez deja un compte ? ',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.bodyColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.offNamed(AppRoutes.candidateLogin),
                      child: Text(
                        'Se connecter',
                        style: AppTextStyles.titleMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                height: 1,
                color: AppColors.outlineVariant.withValues(alpha: 0.24),
              ),
              const SizedBox(height: 14),
                const RegisterBadges(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepForm extends StatelessWidget {
  const _StepForm({
    super.key,
    required this.step,
    required this.controller,
  });

  final int step;
  final RegisterController controller;

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case 1:
        return Form(
          key: controller.stepOneFormKey,
          child: Column(
            children: [
              RegisterStepInput(
                label: 'Prenom',
                hint: 'Daniel',
                icon: Icons.person_outline_rounded,
                controller: controller.firstNameCtrl,
                validator: controller.validateFirstName,
              ),
              const SizedBox(height: 14),
              RegisterStepInput(
                label: 'Nom de famille',
                hint: 'Nanga',
                icon: Icons.person_outline_rounded,
                controller: controller.lastNameCtrl,
                validator: controller.validateLastName,
              ),
            ],
          ),
        );
      case 2:
        return Form(
          key: controller.stepTwoFormKey,
          child: Column(
            children: [
              RegisterStepInput(
                label: 'Adresse email',
                hint: 'daniel@exemple.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                controller: controller.emailCtrl,
                validator: controller.validateEmail,
              ),
              const SizedBox(height: 14),
              RegisterCountryDropdown(controller: controller),
              const SizedBox(height: 14),
              RegisterStepInput(
                label: 'Numero de telephone',
                hint: '+226 XX XX XX XX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                controller: controller.phoneCtrl,
                validator: controller.validatePhone,
              ),
            ],
          ),
        );
      case 3:
      default:
        return Form(
          key: controller.stepThreeFormKey,
          child: Column(
            children: [
              Obx(
                () => RegisterStepInput(
                  label: 'Mot de passe',
                  hint: '********',
                  icon: Icons.lock_outline_rounded,
                  controller: controller.passwordCtrl,
                  validator: controller.validatePassword,
                  obscureText: controller.obscurePassword.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscurePassword.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.hintColor,
                      size: 20,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                  helper:
                      'Minimum 8 caracteres avec lettres et chiffres.',
                ),
              ),
              const SizedBox(height: 14),
              Obx(
                () => RegisterStepInput(
                  label: 'Confirmer le mot de passe',
                  hint: '********',
                  icon: Icons.lock_outline_rounded,
                  controller: controller.confirmPasswordCtrl,
                  validator: controller.validatePasswordConfirmation,
                  obscureText: controller.obscureConfirmPassword.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscureConfirmPassword.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.hintColor,
                      size: 20,
                    ),
                    onPressed: controller.toggleConfirmPasswordVisibility,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => GestureDetector(
                  onTap: controller.toggleTerms,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: controller.acceptedTerms.value
                          ? AppColors.surfaceSelected
                          : AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.acceptedTerms.value
                            ? AppColors.primary
                            : AppColors.outlineVariant.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: controller.acceptedTerms.value
                                ? AppColors.primary
                                : AppColors.surfaceCard,
                            border: Border.all(
                              color: controller.acceptedTerms.value
                                  ? AppColors.primary
                                  : AppColors.outlineVariant,
                            ),
                          ),
                          child: controller.acceptedTerms.value
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: AppColors.onPrimary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.bodyColor,
                              ),
                              children: [
                                const TextSpan(text: 'J\'accepte les '),
                                TextSpan(
                                  text: 'conditions generales d\'utilisation',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const TextSpan(text: ' et la '),
                                TextSpan(
                                  text: 'politique de confidentialite',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
