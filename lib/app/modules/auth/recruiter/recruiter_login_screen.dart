import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/app_colors.dart';
import '../../../../app/core/theme/app_text_styles.dart';
import '../../../../routes/app_routes.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../../widgets/google_logo_asset.dart';
import 'recruiter_login_controller.dart';

class RecruiterLoginScreen extends GetView<RecruiterLoginController> {
  const RecruiterLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: AppColors.titleColor,
            size: 22,
          ),
          onPressed: Get.back,
        ),
        title: Text(
          'OpporTune BF',
          style: AppTextStyles.headlineSm.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.ambientShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Connectez-vous à votre\ncompte OpporTune BF',
                        style: AppTextStyles.headlineLg.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'E-mail',
                      style: AppTextStyles.titleMd.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: controller.validateEmail,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.titleColor,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'm@exemple.com',
                        hintStyle: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.hintColor,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mot de passe',
                          style: AppTextStyles.titleMd.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Mot de passe oublié ?',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.bodyColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => TextFormField(
                        controller: controller.passwordCtrl,
                        obscureText: controller.obscurePass.value,
                        validator: controller.validatePassword,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.titleColor,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceLow,
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.obscurePass.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.hintColor,
                              size: 20,
                            ),
                            onPressed: controller.togglePassword,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Obx(
                      () {
                        if (controller.errorMsg.value.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            controller.errorMsg.value,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                    Obx(
                      () => GradientButton(
                        label: 'Se connecter',
                        onPressed: controller.login,
                        isLoading: controller.isLoading.value,
                        gradient: AppColors.recruiterGradient,
                        textColor: AppColors.onPrimary,
                        fontSize: 16,
                        height: 56,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color:
                                AppColors.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Ou continuer avec',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.hintColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color:
                                AppColors.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: controller.loginWithGoogle,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.outlineVariant
                                .withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const GoogleLogoAsset(size: 22),
                            const SizedBox(width: 14),
                            Text(
                              'Se connecter avec Google',
                              style: AppTextStyles.titleMd.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            'Vous n\'avez pas de compte ? ',
                            style: AppTextStyles.bodyMd,
                          ),
                          GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.registerProfile),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
