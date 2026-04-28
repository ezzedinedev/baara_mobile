import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../controllers/forgot_password_controller.dart';

/// Écran 2 du flow Mot de passe oublié : saisie de l'OTP reçu par SMS +
/// nouveau mot de passe. POST /auth/reset-password.
class ForgotPasswordResetScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordResetScreen({super.key});

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
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Réinitialisation',
                        style: AppTextStyles.headlineLg.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => Text(
                          'Saisissez le code reçu par SMS au '
                          '${controller.phone.value} '
                          'puis choisissez un nouveau mot de passe.',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.bodyColor,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _OtpField(controller: controller),
                      const SizedBox(height: 16),
                      _PasswordField(
                        controller: controller,
                        isConfirm: false,
                      ),
                      const SizedBox(height: 12),
                      _PasswordField(
                        controller: controller,
                        isConfirm: true,
                      ),
                      const SizedBox(height: 14),
                      Obx(() {
                        final err = controller.resetError.value;
                        if (err.isEmpty) return const SizedBox.shrink();
                        return _ErrorBanner(message: err);
                      }),
                      const SizedBox(height: 20),
                      _ResetButton(controller: controller),
                      const SizedBox(height: 14),
                      _ResendRow(controller: controller),
                    ],
                  ),
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

class _OtpField extends StatelessWidget {
  const _OtpField({required this.controller});
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
      child: TextFormField(
        controller: controller.otpCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        textAlign: TextAlign.center,
        style: AppTextStyles.headlineMd.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 12,
          fontSize: 22,
          color: AppColors.titleColor,
        ),
        decoration: InputDecoration(
          hintText: '······',
          hintStyle: AppTextStyles.headlineMd.copyWith(
            color: AppColors.hintColor,
            letterSpacing: 12,
            fontSize: 22,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        validator: (v) {
          if (v == null || v.length != 6) return 'Code à 6 chiffres requis.';
          return null;
        },
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.isConfirm,
  });

  final ForgotPasswordController controller;
  final bool isConfirm;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final obscure = isConfirm
          ? controller.obscureConfirmPassword.value
          : controller.obscureNewPassword.value;
      final textCtrl =
          isConfirm ? controller.confirmPasswordCtrl : controller.newPasswordCtrl;
      final hint = isConfirm
          ? 'Confirmer le mot de passe'
          : 'Nouveau mot de passe';

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
        child: TextFormField(
          controller: textCtrl,
          obscureText: obscure,
          textInputAction:
              isConfirm ? TextInputAction.done : TextInputAction.next,
          style: AppTextStyles.bodyLg.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.titleColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppTextStyles.bodyLg.copyWith(color: AppColors.hintColor),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                IconlyLight.lock,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            suffixIcon: IconButton(
              tooltip: obscure
                  ? 'Afficher le mot de passe'
                  : 'Masquer le mot de passe',
              icon: Icon(
                obscure ? IconlyLight.show : IconlyLight.hide,
                color: AppColors.hintColor,
                size: 20,
              ),
              onPressed: isConfirm
                  ? controller.toggleConfirmPasswordVisibility
                  : controller.toggleNewPasswordVisibility,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return isConfirm
                  ? 'Confirmez votre mot de passe.'
                  : 'Saisissez un mot de passe.';
            }
            if (!isConfirm && v.length < 8) return 'Au moins 8 caractères.';
            if (isConfirm && v != controller.newPasswordCtrl.text) {
              return 'Les mots de passe ne correspondent pas.';
            }
            return null;
          },
        ),
      );
    });
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.controller});
  final ForgotPasswordController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isResetting.value;
      return FilledButton.icon(
        onPressed: loading ? null : controller.resetPassword,
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
            : const Icon(IconlyBold.shield_done, size: 20),
        label: Text(
          loading ? 'Mise à jour…' : 'Réinitialiser le mot de passe',
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

class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.controller});
  final ForgotPasswordController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cooldown = controller.cooldownSecondsLeft.value;
      final isWaiting = cooldown > 0;
      return Center(
        child: TextButton(
          onPressed: isWaiting ? null : controller.resendOtp,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.hintColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
              children: [
                const TextSpan(text: 'Pas reçu ? '),
                TextSpan(
                  text: isWaiting
                      ? 'Renvoyer dans $cooldown s'
                      : 'Renvoyer le code',
                  style: AppTextStyles.titleMd.copyWith(
                    color: isWaiting ? AppColors.hintColor : AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
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
