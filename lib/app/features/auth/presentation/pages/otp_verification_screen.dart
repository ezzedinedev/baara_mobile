import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../controllers/otp_verification_controller.dart';

class OtpVerificationScreen extends GetView<OtpVerificationController> {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WavyAuthHeader(
            height: 180,
            showLeading: true,
            onLeadingTap: () => Get.offAllNamed(AppRoutes.candidateLogin),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Vérification OTP', style: AppTextStyles.displayMd),
                const SizedBox(height: 8),
                Text(
                  controller.phone.isNotEmpty
                      ? 'Saisissez le code à 6 chiffres envoyé au ${controller.phone}.'
                      : 'Saisissez le code à 6 chiffres reçu par SMS.',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.hintColor),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  label: 'Code reçu',
                  controller: controller.otpCtrl,
                  keyboardType: TextInputType.number,
                  icon: Icons.lock_clock_outlined,
                ),
                Obx(() => controller.errorMsg.value.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          controller.errorMsg.value,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.error),
                        ),
                      )),
                const SizedBox(height: 24),
                Obx(() => AuthCtaButton(
                      label: 'Vérifier',
                      isLoading: controller.isLoading.value,
                      onPressed: () => controller.verifyOtp(),
                    )),
                const SizedBox(height: 12),
                Obx(() => TextButton(
                      onPressed: controller.isResending.value
                          ? null
                          : () => controller.resend(),
                      child: Text(
                        controller.isResending.value
                            ? 'Envoi en cours…'
                            : 'Renvoyer le code',
                        style: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.primary),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
