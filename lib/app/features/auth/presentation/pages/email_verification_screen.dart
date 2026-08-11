import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';

import '../controllers/email_verification_controller.dart';

/// Saisie du code reçu par email pour vérifier l'adresse de l'utilisateur.
class EmailVerificationScreen extends GetView<EmailVerificationController> {
  const EmailVerificationScreen({super.key});

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
              title: 'Vérifier l\'email',
              onLeadingTap: () => Get.back<void>(),
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
                      controller.email.isNotEmpty
                          ? 'Code à 6 chiffres envoyé à ${controller.email}.'
                          : 'Code à 6 chiffres envoyé à votre adresse email.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.bodyColor,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(() => AuthDeliveryStatus(
                        phase: controller.deliveryPhase.value,
                        destination: controller.email,
                        errorMessage: controller.sendError.value,
                      )),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 120),
                    child: AuthOtpField(
                      controller: controller.codeCtrl,
                      length: 6,
                      onCompleted: (_) => controller.verify(),
                    ),
                  ),
                  Obx(() => AuthErrorBanner(message: controller.errorMsg.value)),
                  const SizedBox(height: 28),
                  Obx(() => AuthCtaButton(
                        label: 'Vérifier',
                        isLoading: controller.isLoading.value,
                        onPressed: () => controller.verify(),
                      )),
                  const SizedBox(height: 14),
                  Obx(() {
                    final secs = controller.resendCountdown.value;
                    final busy = controller.isResending.value;
                    final disabled = busy || secs > 0;
                    return Center(
                      child: TextButton(
                        onPressed: disabled
                            ? null
                            : () {
                                AppHaptics.tap();
                                controller.resend();
                              },
                        child: Text(
                          busy
                              ? 'Envoi en cours…'
                              : secs > 0
                                  ? 'Renvoyer le code ($secs s)'
                                  : 'Renvoyer le code',
                          style: AppTextStyles.titleMd.copyWith(
                            color: disabled
                                ? AppColors.hintColor
                                : AppColors.primaryAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
}
