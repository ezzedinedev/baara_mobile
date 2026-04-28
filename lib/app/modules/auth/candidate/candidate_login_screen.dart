import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/app_colors.dart';
import '../../../../app/core/theme/app_dimens.dart';
import '../../../../app/core/theme/app_text_styles.dart';
import '../../../../app/core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../../routes/app_routes.dart';
import 'candidate_login_controller.dart';

/// Connexion candidat — redesign inspiré du mockup Sign up : hero wavy en
/// haut, formulaire épuré sous la vague, CTA pill primaire.
class CandidateLoginScreen extends GetView<CandidateLoginController> {
  const CandidateLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WavyAuthHeader(
              height: 240,
              showLeading: true,
              onLeadingTap: () => Get.back<void>(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 10, 26, 28),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connexion',
                      style: AppTextStyles.displayMd.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 48,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    const SizedBox(height: 26),
                    AuthTextField(
                      label: 'Email',
                      hint: 'nom@exemple.com',
                      icon: Icons.mail_outline_rounded,
                      controller: controller.emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: controller.validateEmail,
                    ),
                    const SizedBox(height: 18),
                    AuthTextField(
                      label: 'Mot de passe',
                      hint: '********',
                      icon: Icons.lock_outline_rounded,
                      controller: controller.passwordCtrl,
                      obscureText: true,
                      validator: controller.validatePassword,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          AppHaptics.tap();
                          // TODO: route mot de passe oublié
                        },
                        child: Text(
                          'Mot de passe oublié ?',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Obx(() {
                      if (controller.errorMsg.value.isEmpty) {
                        return const SizedBox(height: 24);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 8),
                        child: Container(
                          width: double.infinity,
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
                    Obx(
                      () => AuthCtaButton(
                        label: 'Se connecter',
                        isLoading: controller.isLoading.value,
                        onPressed: controller.loginWithEmail,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppColors.outlineVariant
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OU',
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.hintColor,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppColors.outlineVariant
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SocialButton(
                      icon: const GoogleLogoAsset(size: 20),
                      label: 'Continuer avec Google',
                      onTap: controller.loginWithGoogle,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () {
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
                                  fontWeight: FontWeight.w800,
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
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTextStyles.titleMd.copyWith(
                  color: AppColors.titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
