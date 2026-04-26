import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../../routes/app_routes.dart';
import '../../../../widgets/widgets.dart';
import 'register_controller.dart';

/// Inscription — wizard 3 étapes : (1) prénom/nom, (2) email/pays/téléphone,
/// (3) mot de passe + CGU. Logique préservée via [RegisterController].
/// Visuel : hero wavy + formulaire épuré (AuthTextField underline) + CTA pill.
class RegisterScreen extends GetView<RegisterController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => controller.onBack(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WavyAuthHeader(
                height: 220,
                showLeading: true,
                onLeadingTap: controller.onBack,
                foregroundIcon: Icons.person_add_alt_1_rounded,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 10, 26, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "S'inscrire",
                      style: AppTextStyles.displayMd.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 48,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ProgressHeader(controller: controller),
                    const SizedBox(height: 18),
                    Obx(
                      () => Text(
                        controller.stepTitle,
                        style: AppTextStyles.headlineLg.copyWith(fontSize: 22),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(
                      () => Text(
                        controller.stepSubtitle,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.bodyColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => _ProfilePill(
                        label: controller.registrationProfileLabel,
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
                        return const SizedBox(height: 20);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 6),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  controller.errorMsg.value,
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    Obx(
                      () => AuthCtaButton(
                        label: controller.actionLabel,
                        isLoading: controller.isLoading.value,
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.onContinue,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          AppHaptics.tap();
                          Get.offNamed(AppRoutes.candidateLogin);
                        },
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.bodyColor,
                            ),
                            children: [
                              const TextSpan(text: 'Vous avez déjà un compte ? '),
                              TextSpan(
                                text: 'Se connecter',
                                style: AppTextStyles.titleMd.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.controller});
  final RegisterController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Étape ${controller.currentStep.value} sur 3',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.bodyColor,
                  letterSpacing: 0.4,
                  fontSize: 11,
                ),
              ),
              Text(
                '${controller.progressPercent}%',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 0.2,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: controller.progressValue,
              backgroundColor: AppColors.surfaceHighest,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceIconSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: AppColors.primary,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            'Profil : $label',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
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
              AuthTextField(
                label: 'Prénom',
                hint: 'Daniel',
                icon: Icons.person_outline_rounded,
                controller: controller.firstNameCtrl,
                validator: controller.validateFirstName,
              ),
              const SizedBox(height: 18),
              AuthTextField(
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
              AuthTextField(
                label: 'Adresse email',
                hint: 'daniel@exemple.com',
                icon: Icons.mail_outline_rounded,
                controller: controller.emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: controller.validateEmail,
              ),
              const SizedBox(height: 18),
              RegisterCountryDropdown(controller: controller),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'Numéro de téléphone',
                hint: '+226 XX XX XX XX',
                icon: Icons.phone_outlined,
                controller: controller.phoneCtrl,
                keyboardType: TextInputType.phone,
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
                () => AuthTextField(
                  label: 'Mot de passe',
                  hint: '********',
                  icon: Icons.lock_outline_rounded,
                  controller: controller.passwordCtrl,
                  obscureText: controller.obscurePassword.value,
                  validator: controller.validatePassword,
                  helper:
                      'Minimum 8 caractères avec lettres et chiffres.',
                  suffix: IconButton(
                    tooltip: controller.obscurePassword.value ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                    icon: Icon(
                      controller.obscurePassword.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.hintColor,
                      size: 20,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Obx(
                () => AuthTextField(
                  label: 'Confirmer le mot de passe',
                  hint: '********',
                  icon: Icons.lock_outline_rounded,
                  controller: controller.confirmPasswordCtrl,
                  obscureText: controller.obscureConfirmPassword.value,
                  validator: controller.validatePasswordConfirmation,
                  suffix: IconButton(
                    tooltip: controller.obscureConfirmPassword.value ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
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
              const SizedBox(height: 16),
              Obx(
                () => GestureDetector(
                  onTap: () {
                    AppHaptics.tap();
                    controller.toggleTerms();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: controller.acceptedTerms.value
                          ? AppColors.surfaceSelected
                          : AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(14),
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
                          width: 22,
                          height: 22,
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.bodyColor,
                                height: 1.35,
                              ),
                              children: [
                                const TextSpan(text: "J'accepte les "),
                                TextSpan(
                                  text: "conditions générales d'utilisation",
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const TextSpan(text: ' et la '),
                                TextSpan(
                                  text: 'politique de confidentialité',
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
