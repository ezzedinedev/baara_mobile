import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../controllers/recruiter_login_controller.dart';

class RecruiterLoginScreen extends GetView<RecruiterLoginController> {
  const RecruiterLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                  children: [
                    WavyAuthHeader(
                      height: 200,
                      showLeading: true,
                      onLeadingTap: () => Get.back(),
                      foregroundIcon: IconlyLight.work,
                      title: 'Recruteur',
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RevealOnMount(
                            child: Text(
                              'Connexion',
                              style: AppTextStyles.displayHero
                                  .copyWith(fontSize: 30),
                            ),
                          ),
                          const SizedBox(height: 6),
                          RevealOnMount(
                            delay: const Duration(milliseconds: 60),
                            child: Text(
                              'Accédez à votre espace recrutement.',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.bodyColor,
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Form(
                            key: controller.formKey,
                            child: Column(
                              children: [
                                AuthTextField(
                                  label: 'Email',
                                  hint: 'nom@entreprise.com',
                                  controller: controller.emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: controller.validateEmail,
                                  icon: IconlyLight.message,
                                ),
                                const SizedBox(height: 16),
                                AuthTextField(
                                  label: 'Mot de passe',
                                  hint: 'Votre mot de passe',
                                  controller: controller.passwordCtrl,
                                  obscureText: true,
                                  validator: controller.validatePassword,
                                  icon: IconlyLight.lock,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                AppHaptics.tap();
                                Get.toNamed(AppRoutes.forgotPassword);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                          Obx(() => AuthErrorBanner(
                              message: controller.errorMsg.value)),
                          const SizedBox(height: 24),
                          const AuthOrDivider(),
                          const SizedBox(height: 16),
                          AuthSocialButton(
                            icon: const GoogleLogoAsset(size: 20),
                            label: 'Continuer avec Google',
                            onTap: controller.loginWithGoogle,
                          ),
                          const SizedBox(height: 24),
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
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 8, 24, 24 + (bottomInset > 0 ? 4 : 0)),
              child: Obx(() => AuthCtaButton(
                    label: 'Se connecter',
                    isLoading: controller.isLoading.value,
                    onPressed: controller.loginWithEmail,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
