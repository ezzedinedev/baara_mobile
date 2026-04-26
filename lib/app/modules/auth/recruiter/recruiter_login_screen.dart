import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/app_colors.dart';
import '../../../../app/core/theme/app_dimens.dart';
import '../../../../app/core/theme/app_text_styles.dart';
import '../../../../app/core/utils/haptics.dart';
import '../../../../widgets/widgets.dart';
import '../../../../routes/app_routes.dart';
import 'recruiter_login_controller.dart';

/// Connexion recruteur — même visuel que candidat, accent `recruiterGradient`.
class RecruiterLoginScreen extends GetView<RecruiterLoginController> {
  const RecruiterLoginScreen({super.key});

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
              gradient: AppColors.recruiterGradient,
              foregroundIcon: Icons.business_center_outlined,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 10, 26, 28),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Espace recruteur',
                      style: AppTextStyles.displayMd.copyWith(
                        fontSize: 30,
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
                    const SizedBox(height: 12),
                    Text(
                      'Gérez vos offres et trouvez les meilleurs talents.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.bodyColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 26),
                    AuthTextField(
                      label: 'Email professionnel',
                      hint: 'contact@entreprise.com',
                      icon: Icons.mail_outline_rounded,
                      controller: controller.emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: controller.validateEmail,
                    ),
                    const SizedBox(height: 18),
                    Obx(
                      () => AuthTextField(
                        label: 'Mot de passe',
                        hint: '********',
                        icon: Icons.lock_outline_rounded,
                        controller: controller.passwordCtrl,
                        obscureText: controller.obscurePass.value,
                        validator: controller.validatePassword,
                        suffix: IconButton(
                          tooltip: controller.obscurePass.value ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                          icon: Icon(
                            controller.obscurePass.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.hintColor,
                            size: 20,
                          ),
                          onPressed: controller.togglePassword,
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
                        onPressed: controller.login,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          AppHaptics.tap();
                          Get.offAllNamed(AppRoutes.landing);
                        },
                        child: Text(
                          'Vous êtes candidat ? Retour à l\'accueil',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
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
