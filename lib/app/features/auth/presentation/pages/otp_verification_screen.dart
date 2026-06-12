import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../controllers/otp_verification_controller.dart';

class OtpVerificationScreen extends GetView<OtpVerificationController> {
  const OtpVerificationScreen({super.key});

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
              height: 200,
              showLeading: true,
              foregroundIcon: IconlyLight.message,
              title: 'Vérification',
              onLeadingTap: () => Get.offAllNamed(AppRoutes.candidateLogin),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RevealOnMount(
                    child: Text(
                      'Saisissez le code',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayHero.copyWith(fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 60),
                    child: Text(
                      controller.phone.isNotEmpty
                          ? 'Code à 6 chiffres envoyé au ${controller.phone}.'
                          : 'Code à 6 chiffres reçu par SMS.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.bodyColor,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 120),
                    child: AuthOtpField(
                      controller: controller.otpCtrl,
                      length: 6,
                      onCompleted: (_) => controller.verifyOtp(),
                    ),
                  ),
                  Obx(() => AuthErrorBanner(
                        message: controller.errorMsg.value,
                      )),
                  const SizedBox(height: 28),
                  Obx(() => AuthCtaButton(
                        label: 'Vérifier',
                        isLoading: controller.isLoading.value,
                        onPressed: () => controller.verifyOtp(),
                      )),
                  const SizedBox(height: 14),
                  Obx(() => Center(
                        child: TextButton(
                          onPressed: controller.isResending.value
                              ? null
                              : () {
                                  AppHaptics.tap();
                                  controller.resend();
                                },
                          child: Text(
                            controller.isResending.value
                                ? 'Envoi en cours…'
                                : 'Renvoyer le code',
                            style: AppTextStyles.titleMd.copyWith(
                              color: controller.isResending.value
                                  ? AppColors.hintColor
                                  : AppColors.primaryAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
