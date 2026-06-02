import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WavyAuthHeader(
              height: 180,
              showLeading: true,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Mot de passe oublié', style: AppTextStyles.displayMd),
        const SizedBox(height: 8),
        Text(
          'Entrez votre numéro de téléphone pour recevoir un code de réinitialisation.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
        ),
        const SizedBox(height: 20),
        AuthTextField(
          label: 'Téléphone',
          controller: controller.phoneCtrl,
          keyboardType: TextInputType.phone,
          icon: Icons.phone_outlined,
        ),
        _buildError(),
        const SizedBox(height: 24),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Nouveau mot de passe', style: AppTextStyles.displayMd),
        const SizedBox(height: 8),
        Text(
          'Saisissez le code reçu par SMS puis votre nouveau mot de passe.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
        ),
        const SizedBox(height: 20),
        AuthTextField(
          label: 'Code reçu',
          controller: controller.otpCtrl,
          keyboardType: TextInputType.number,
          icon: Icons.lock_clock_outlined,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Nouveau mot de passe',
          controller: controller.passwordCtrl,
          obscureText: true,
          icon: Icons.lock_outline,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Confirmer le mot de passe',
          controller: controller.confirmCtrl,
          obscureText: true,
          icon: Icons.lock_outline,
        ),
        _buildError(),
        const SizedBox(height: 24),
        Obx(() => AuthCtaButton(
              label: 'Réinitialiser',
              isLoading: controller.isLoading.value,
              onPressed: () => controller.confirmReset(),
            )),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => controller.requestReset(),
          child: Text(
            'Renvoyer le code',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Obx(() => controller.errorMsg.value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              controller.errorMsg.value,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          ));
  }
}
