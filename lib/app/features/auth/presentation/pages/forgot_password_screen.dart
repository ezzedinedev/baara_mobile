import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
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
              foregroundIcon: AppIcons.unlock,
              onLeadingTap: () => Get.back(),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Obx(() {
                final step = controller.step.value;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: step == 1
                      ? _RequestStep(key: const ValueKey('request'), controller: controller)
                      : _ResetStep(key: const ValueKey('reset'), controller: controller),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestStep extends StatelessWidget {
  const _RequestStep({super.key, required this.controller});
  final ForgotPasswordController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
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
            'Entrez votre email ou numéro de téléphone pour recevoir un code de réinitialisation.',
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.bodyColor, height: 1.45),
          ),
        ),
        const SizedBox(height: 20),
        Obx(() => _ModeToggle(
              mode: controller.mode.value,
              onChanged: controller.setMode,
            )),
        const SizedBox(height: 16),
        Obx(
          () => controller.mode.value == 'phone'
              ? AuthPhoneField(
                  key: const ValueKey('forgot-phone'),
                  controller: controller.phoneCtrl,
                  country: controller.selectedCountry,
                  onCountryChanged: (c) => controller.selectCountry(c.isoCode),
                  validator: controller.validatePhone,
                )
              : AuthTextField(
                  key: const ValueKey('forgot-email'),
                  label: 'Email',
                  hint: 'nom@exemple.com',
                  controller: controller.emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: controller.validateEmail,
                  icon: AppIcons.message,
                ),
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
}

class _ResetStep extends StatefulWidget {
  const _ResetStep({super.key, required this.controller});
  final ForgotPasswordController controller;

  @override
  State<_ResetStep> createState() => _ResetStepState();
}

class _ResetStepState extends State<_ResetStep> {
  String _password = '';

  @override
  void initState() {
    super.initState();
    widget.controller.passwordCtrl.addListener(_onPasswordChanged);
    _password = widget.controller.passwordCtrl.text;
  }

  void _onPasswordChanged() {
    final next = widget.controller.passwordCtrl.text;
    if (next != _password) setState(() => _password = next);
  }

  @override
  void dispose() {
    widget.controller.passwordCtrl.removeListener(_onPasswordChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final destination = c.mode.value == 'email'
        ? c.emailCtrl.text.trim()
        : c.fullPhone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nouveau mot de passe',
          style: AppTextStyles.displayHero.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 8),
        Text(
          'Saisissez le code reçu puis choisissez un mot de passe sécurisé.',
          style: AppTextStyles.bodyMd
              .copyWith(color: AppColors.bodyColor, height: 1.45),
        ),
        const SizedBox(height: 20),
        Obx(() => AuthDeliveryStatus(
              phase: c.deliveryPhase.value,
              destination: destination,
              errorMessage: c.sendError.value,
            )),
        AuthOtpField(
          controller: c.otpCtrl,
          length: 6,
          autofocus: false,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Nouveau mot de passe',
          hint: 'Au moins 8 caractères',
          controller: c.passwordCtrl,
          obscureText: true,
          icon: AppIcons.lock,
        ),
        AuthPasswordStrength(password: _password),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Confirmer le mot de passe',
          hint: 'Retapez le mot de passe',
          controller: c.confirmCtrl,
          obscureText: true,
          icon: AppIcons.password,
        ),
        Obx(() => AuthErrorBanner(message: c.errorMsg.value)),
        const SizedBox(height: 28),
        Obx(() => AuthCtaButton(
              label: 'Réinitialiser',
              isLoading: c.isLoading.value,
              onPressed: () => c.confirmReset(),
            )),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () {
              AppHaptics.tap();
              c.requestReset();
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

/// Bascule segmentée Email / Téléphone.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final String mode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isPhone = mode == 'phone';
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppShapes.pill,
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final segWidth = (c.maxWidth - 8) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: AppMotion.base,
                curve: AppMotion.standard,
                alignment:
                    isPhone ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: segWidth,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: AppShapes.pill,
                    boxShadow: AppColors.lightShadow,
                  ),
                ),
              ),
              Row(
                children: [
                  _seg('Email', AppIcons.message, !isPhone,
                      () => onChanged('email')),
                  _seg('Téléphone', AppIcons.phone, isPhone,
                      () => onChanged('phone')),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _seg(String label, IconData icon, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16,
                  color:
                      active ? AppColors.primaryAccent : AppColors.hintColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelLg.copyWith(
                  color: active ? AppColors.titleColor : AppColors.hintColor,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
