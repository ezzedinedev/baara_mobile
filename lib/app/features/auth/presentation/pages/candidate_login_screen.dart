import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
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
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(bottom: bottomInset > 0 ? 12 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WavyAuthHeader(
                      height: 168,
                      showLeading: true,
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
                            Text(
                              'Connexion',
                              style: AppTextStyles.displayMd.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Accédez à vos offres, messages et candidatures.',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.bodyColor,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            AuthTextField(
                              label: 'Email',
                              hint: 'nom@exemple.com',
                              icon: Icons.mail_outline_rounded,
                              controller: controller.emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              validator: controller.validateEmail,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AuthTextField(
                              label: 'Mot de passe',
                              hint: 'Votre mot de passe',
                              icon: Icons.lock_outline_rounded,
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
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Mot de passe oublié ?',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.primary,
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
                            _OrDivider(),
                            const SizedBox(height: AppSpacing.lg),
                            _SocialButton(
                              icon: const GoogleLogoAsset(size: 20),
                              label: 'Continuer avec Google',
                              onTap: controller.loginWithGoogle,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  AppHaptics.tap();
                                  Get.offNamed(AppRoutes.registerProfile);
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.bodySm.copyWith(
                                      color: AppColors.bodyColor,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Pas encore de compte ? '),
                                      TextSpan(
                                        text: "S'inscrire",
                                        style: AppTextStyles.titleMd.copyWith(
                                          color: AppColors.primary,
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
                  onPressed: controller.loginWithEmail,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'ou',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTextStyles.titleMd.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
