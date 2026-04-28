import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../controllers/forgot_password_controller.dart';

/// Écran 1 du flow Mot de passe oublié : saisie du numéro de téléphone.
/// L'utilisateur entre son numéro, on POST /auth/forgot-password, en succès
/// on route vers l'écran 2 (saisie OTP + nouveau mot de passe).
class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Mot de passe oublié ?',
                      style: AppTextStyles.headlineLg.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entrez le numéro de téléphone associé à votre compte. '
                      'Nous vous enverrons un code à 6 chiffres pour réinitialiser '
                      'votre mot de passe.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.bodyColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _PhoneField(controller: controller),
                    const SizedBox(height: 12),
                    Obx(() {
                      final err = controller.requestError.value;
                      if (err.isEmpty) return const SizedBox.shrink();
                      return _ErrorBanner(message: err);
                    }),
                    const SizedBox(height: 24),
                    _SendButton(controller: controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour',
            icon: const Icon(IconlyLight.arrow_left_2),
            color: AppColors.titleColor,
            onPressed: () {
              AppHaptics.tap();
              Navigator.of(context).maybePop();
            },
          ),
        ],
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller});
  final ForgotPasswordController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: controller.phoneCtrl,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.send,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9 +]')),
        ],
        onChanged: (_) => controller.requestError.value = '',
        onSubmitted: (_) => controller.requestReset(),
        style: AppTextStyles.bodyLg.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.titleColor,
        ),
        decoration: InputDecoration(
          hintText: '+226 XX XX XX XX',
          hintStyle: AppTextStyles.bodyLg.copyWith(color: AppColors.hintColor),
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              IconlyLight.call,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.controller});
  final ForgotPasswordController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isRequesting.value;
      return FilledButton.icon(
        onPressed: loading ? null : controller.requestReset,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(AppColors.onPrimary),
                ),
              )
            : const Icon(IconlyBold.send, size: 20),
        label: Text(
          loading ? 'Envoi…' : 'Envoyer le code',
          style: AppTextStyles.buttonLg.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      );
    });
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.errorStrong,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
