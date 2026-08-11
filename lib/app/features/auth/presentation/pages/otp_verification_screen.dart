import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';
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
              foregroundIcon: AppIcons.message,
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
                    child: Column(
                      children: [
                        Text(
                          controller.deliveryExplanation,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.bodyColor,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (controller.phoneSecurityNote != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            controller.phoneSecurityNote!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.hintColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(() => AuthDeliveryStatus(
                        phase: controller.deliveryPhase.value,
                        destination: controller.codeDestination,
                        errorMessage: controller.sendError.value,
                      )),
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
