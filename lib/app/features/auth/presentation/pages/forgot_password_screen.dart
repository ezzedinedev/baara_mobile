import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WavyAuthHeader(
              height: 180,
              showLeading: true,
              foregroundIcon: IconlyLight.unlock,
              onLeadingTap: () => Get.back(),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Obx(
                () => controller.step.value == 1
                    ? _buildRequestStep()
                    : _buildResetStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestStep() {
    return Column(
      key: const ValueKey('forgot-request'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RevealOnMount(
          child: Text(
            'Mot de passe oublié',
            style: AppTextStyles.displayHero.copyWith(fontSize: 28),
          ),
        ),
        const SizedBox(height: 8),
        RevealOnMount(
          delay: const Duration(milliseconds: 60),
          child: Text(
            'Entrez votre numéro de téléphone pour recevoir un code de réinitialisation.',
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.bodyColor, height: 1.45),
          ),
        ),
        const SizedBox(height: 24),
        AuthTextField(
          label: 'Téléphone',
          hint: '+226 ...',
          controller: controller.phoneCtrl,
          keyboardType: TextInputType.phone,
          icon: IconlyLight.call,
        ),
        Obx(() => AuthErrorBanner(message: controller.errorMsg.value)),
        const SizedBox(height: 28),
        Obx(() => AuthCtaButton(
              label: 'Envoyer le code',
              isLoading: controller.isLoading.value,
              onPressed: () => controller.requestReset(),
            )),
      ],
    );
  }

  Widget _buildResetStep() {
    return Column(
      key: const ValueKey('forgot-reset'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nouveau mot de passe',
          style: AppTextStyles.displayHero.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 8),
        Text(
          'Saisissez le code reçu par SMS puis votre nouveau mot de passe.',
          style: AppTextStyles.bodyMd
              .copyWith(color: AppColors.bodyColor, height: 1.45),
        ),
        const SizedBox(height: 24),
        AuthTextField(
          label: 'Code reçu',
          hint: 'Code à 6 chiffres',
          controller: controller.otpCtrl,
          keyboardType: TextInputType.number,
          icon: IconlyLight.time_circle,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Nouveau mot de passe',
          hint: 'Au moins 8 caractères',
          controller: controller.passwordCtrl,
          obscureText: true,
          icon: IconlyLight.lock,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Confirmer le mot de passe',
          hint: 'Retapez le mot de passe',
          controller: controller.confirmCtrl,
          obscureText: true,
          icon: IconlyLight.password,
        ),
        Obx(() => AuthErrorBanner(message: controller.errorMsg.value)),
        const SizedBox(height: 28),
        Obx(() => AuthCtaButton(
              label: 'Réinitialiser',
              isLoading: controller.isLoading.value,
              onPressed: () => controller.confirmReset(),
            )),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () {
              AppHaptics.tap();
              controller.requestReset();
            },
            child: Text(
              'Renvoyer le code',
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
