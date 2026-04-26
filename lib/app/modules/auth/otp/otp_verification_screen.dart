import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../../widgets/widgets.dart';
import 'otp_verification_controller.dart';

/// Écran de vérification OTP — 6 chiffres envoyés par email/SMS.
///
/// Arguments via `Get.toNamed(..., arguments: {'phone': ..., 'email': ...})`
/// — au moins l'un des deux doit être fourni. Le controller gère l'appel
/// backend (`/api/v1/auth/otp/verify`) et la résolution du flux.
class OtpVerificationScreen extends GetView<OtpVerificationController> {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          WavyAuthHeader(
            height: 260,
            showLeading: true,
            onLeadingTap: () => Get.back<void>(),
            foregroundIcon: Icons.verified_user_outlined,
            title: 'Vérification',
            subtitle:
                'Entrez le code à 6 chiffres envoyé pour confirmer votre compte.',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: 0,
                left: 24,
                right: 24,
                bottom: 28 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  // TextField invisible qui capture la saisie clavier native.
                  // Permet aussi l'autofill iOS depuis les SMS et la lecture OTP.
                  SizedBox(
                    height: 0,
                    child: TextField(
                      controller: controller.hiddenTextCtrl,
                      focusNode: controller.hiddenFocus,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: controller.onCodeChanged,
                      showCursor: false,
                      style: const TextStyle(height: 0, fontSize: 0),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: _OtpBoxes(controller: controller),
                  ),
                  const SizedBox(height: 18),
                  Obx(() {
                    if (!controller.showSuccess.value) {
                      return const SizedBox.shrink();
                    }
                    return const _SuccessPulse();
                  }),
                  const SizedBox(height: 18),
                  Obx(() {
                    final code = controller.currentCode;
                    if (code.length < 6 || controller.showSuccess.value) {
                      return const SizedBox.shrink();
                    }
                    return AuthCtaButton(
                      label: 'Vérifier',
                      isLoading: controller.isVerifying.value,
                      onPressed: controller.verify,
                    );
                  }),
                  Obx(() {
                    if (controller.errorMsg.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
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
                  const SizedBox(height: 18),
                  _ResendLink(controller: controller),
                  const SizedBox(height: 22),
                  _SecurityBadge(),
                  const SizedBox(height: 18),
                  _FooterLinks(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({required this.controller});
  final OtpVerificationController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) {
          return _OtpDigit(
            index: index,
            controller: controller,
          );
        }),
      ),
    );
  }
}

class _OtpDigit extends StatelessWidget {
  const _OtpDigit({required this.index, required this.controller});
  final int index;
  final OtpVerificationController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isActive = controller.focusIndex.value == index;
      final hasValue = index < controller.currentCode.length;
      final isSuccess = controller.showSuccess.value;

      final borderColor = isSuccess
          ? AppColors.successDark
          : hasValue
              ? AppColors.primary
              : isActive
                  ? AppColors.primary
                  : AppColors.outlineVariant.withValues(alpha: 0.4);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 50,
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.surfaceIconSoft
              : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isActive ? 2 : 1.2),
        ),
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            controller.requestFocusAt(index);
          },
          child: Text(
            hasValue ? controller.currentCode[index] : '',
            style: AppTextStyles.displayMd.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.titleColor,
            ),
          ),
        ),
      );
    });
  }
}

class _SuccessPulse extends StatefulWidget {
  const _SuccessPulse();

  @override
  State<_SuccessPulse> createState() => _SuccessPulseState();
}

class _SuccessPulseState extends State<_SuccessPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
      ),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.successDark,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.successDark.withValues(alpha: 0.32),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppColors.onPrimary,
          size: 34,
        ),
      ),
    );
  }
}

class _ResendLink extends StatelessWidget {
  const _ResendLink({required this.controller});
  final OtpVerificationController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final secondsLeft = controller.resendSecondsLeft.value;
      final canResend = secondsLeft <= 0;

      return GestureDetector(
        onTap: canResend
            ? () {
                AppHaptics.tap();
                controller.resend();
              }
            : null,
        child: Text(
          canResend
              ? 'Renvoyer le code'
              : 'Renvoyer dans ${secondsLeft}s',
          style: AppTextStyles.titleMd.copyWith(
            color:
                canResend ? AppColors.primary : AppColors.hintColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    });
  }
}

class _SecurityBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_user_rounded,
          color: AppColors.successDark,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          'Chiffrement sécurisé 256 bits',
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.bodyColor,
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _FooterLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _FooterLink(
          icon: Icons.headset_mic_outlined,
          label: 'Support',
          onTap: () {},
        ),
        _FooterLink(
          icon: Icons.privacy_tip_outlined,
          label: 'Confidentialité',
          onTap: () {},
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.bodyColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.bodyColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
