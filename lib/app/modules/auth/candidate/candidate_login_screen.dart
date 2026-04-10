import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/app_colors.dart';
import '../../../../app/core/theme/app_text_styles.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../../widgets/google_logo_asset.dart';
import '../../../../widgets/labeled_input.dart';
import '../../../../widgets/opportune_logo.dart';
import '../../../../routes/app_routes.dart';
import 'candidate_login_controller.dart';

class CandidateLoginScreen extends GetView<CandidateLoginController> {
  const CandidateLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -60,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(80),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -90,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(120),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Form(
                        key: controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 22),
                            const OpportuneLogo(iconSize: 18, fontSize: 20),
                            const SizedBox(height: 56),
                            Text(
                              'Connexion\nCandidat',
                              style: AppTextStyles.displayXl.copyWith(
                                fontSize: 46,
                                height: 1.04,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Connectez-vous pour explorer\nde nouvelles opportunites.',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.bodyColor,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 44),
                            LabeledInput(
                              label: 'e-mail',
                              placeholder: 'nom@exemple.com',
                              controller: controller.emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              validator: controller.validateEmail,
                            ),
                            const SizedBox(height: 20),
                            LabeledInput(
                              label: 'mot de passe',
                              placeholder: '********',
                              controller: controller.passwordCtrl,
                              isPassword: true,
                              validator: controller.validatePassword,
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Mot de passe oublie ?',
                                  style: AppTextStyles.titleMd.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Obx(() {
                              if (controller.errorMsg.value.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.error.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.error
                                          .withValues(alpha: 0.2),
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
                              () => GradientButton(
                                label: 'SE CONNECTER',
                                onPressed: controller.loginWithEmail,
                                isLoading: controller.isLoading.value,
                                height: 56,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: AppColors.outlineVariant
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  child: Text(
                                    'OU CONTINUER AVEC',
                                    style: AppTextStyles.labelMd.copyWith(
                                      fontSize: 10,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: AppColors.outlineVariant
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialButton(
                                    onTap: controller.loginWithGoogle,
                                    child: const GoogleLogoAsset(size: 24),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: _SocialButton(
                                    onTap: _noop,
                                    child: _LinkedInIcon(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: _SocialButton(
                                    onTap: _noop,
                                    child: _AppleIcon(),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 26, bottom: 28),
                              child: Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  children: [
                                    Text(
                                      'Pas encore de compte ? ',
                                      style: AppTextStyles.bodyMd,
                                    ),
                                    GestureDetector(
                                      onTap: () => Get.toNamed(
                                          AppRoutes.registerProfile),
                                      child: Text(
                                        'S\'inscrire',
                                        style: AppTextStyles.titleMd.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.lightShadow,
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _LinkedInIcon extends StatelessWidget {
  const _LinkedInIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.socialLinkedIn,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Text(
          'in',
          style: AppTextStyles.bodySm.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.onPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.apple_rounded,
      size: 26,
      color: AppColors.titleColor,
    );
  }
}

void _noop() {}
