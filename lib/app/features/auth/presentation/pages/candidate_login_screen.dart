import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';
import '../controllers/candidate_login_controller.dart';

class CandidateLoginScreen extends GetView<CandidateLoginController> {
  const CandidateLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(bottom: bottomInset > 0 ? 12 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WavyAuthHeader(
                      height: 170,
                      showLeading: true,
                      foregroundIcon: AppIcons.profile,
                      onLeadingTap: () => Get.back(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageH + 8,
                        AppSpacing.xl,
                        AppSpacing.pageH + 8,
                        AppSpacing.lg,
                      ),
                      child: Form(
                        key: controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RevealOnMount(
                              child: Semantics(
                                header: true,
                                child: Text(
                                  'Bon retour',
                                  style: AppTextStyles.displayHero.copyWith(
                                    fontSize: 30,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            RevealOnMount(
                              delay: const Duration(milliseconds: 60),
                              child: Text(
                                'Connectez-vous pour suivre vos offres, messages et candidatures.',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.bodyColor,
                                  height: 1.45,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            // Bascule Email / Téléphone (le recrutement, lui,
                            // reste sur le web).
                            Obx(
                              () => _LoginModeToggle(
                                mode: controller.loginMode.value,
                                onChanged: controller.setMode,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            // Champ d'identifiant selon le mode (un seul monté à
                            // la fois → seul son validateur s'exécute).
                            Obx(
                              () => controller.loginMode.value == 'phone'
                                  ? AuthPhoneField(
                                      key: const ValueKey('login-phone'),
                                      controller: controller.phoneCtrl,
                                      country: controller.selectedCountry,
                                      onCountryChanged: (c) =>
                                          controller.selectCountry(c.isoCode),
                                      validator: controller.validatePhone,
                                    )
                                  : AuthTextField(
                                      key: const ValueKey('login-email'),
                                      label: 'Email',
                                      hint: 'nom@exemple.com',
                                      icon: AppIcons.message,
                                      controller: controller.emailCtrl,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: controller.validateEmail,
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AuthTextField(
                              label: 'Mot de passe',
                              hint: 'Votre mot de passe',
                              icon: AppIcons.lock,
                              controller: controller.passwordCtrl,
                              obscureText: true,
                              validator: controller.validatePassword,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  AppHaptics.tap();
                                  Get.toNamed(AppRoutes.forgotPassword);
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Mot de passe oublié ?',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.primaryAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Obx(
                              () => AuthErrorBanner(
                                message: controller.errorMsg.value,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            const AuthOrDivider(),
                            const SizedBox(height: AppSpacing.lg),
                            AuthSocialButton(
                              icon: const GoogleLogoAsset(size: 20),
                              label: 'Continuer avec Google',
                              onTap: controller.loginWithGoogle,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  AppHaptics.tap();
                                  Get.toNamed(AppRoutes.profileSelection);
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.bodySm.copyWith(
                                      color: AppColors.bodyColor,
                                    ),
                                    children: [
                                      const TextSpan(
                                          text: 'Pas encore de compte ? '),
                                      TextSpan(
                                        text: "S'inscrire",
                                        style: AppTextStyles.titleMd.copyWith(
                                          color: AppColors.primaryAccent,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageH + 8,
                AppSpacing.sm,
                AppSpacing.pageH + 8,
                AppSpacing.lg + (bottomInset > 0 ? 4 : 0),
              ),
              child: Obx(
                () => AuthCtaButton(
                  label: 'Se connecter',
                  isLoading: controller.isLoading.value,
                  onPressed: controller.submit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bascule segmentée Email / Téléphone (pilule glissante en spring).
class _LoginModeToggle extends StatelessWidget {
  const _LoginModeToggle({required this.mode, required this.onChanged});

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
