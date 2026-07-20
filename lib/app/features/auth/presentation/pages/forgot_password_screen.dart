import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_motion.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';
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
                  icon: IconlyLight.message,
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
          'Saisissez le code reçu par email puis votre nouveau mot de passe.',
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

/// Bascule segmentée Email / Téléphone pour choisir l'identifiant de
/// réinitialisation (pilule glissante), alignée sur l'écran de connexion.
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
                  _seg('Email', IconlyLight.message, !isPhone,
                      () => onChanged('email')),
                  _seg('Téléphone', IconlyLight.call, isPhone,
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
