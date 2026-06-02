import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../controllers/recruiter_login_controller.dart';

class RecruiterLoginScreen extends GetView<RecruiterLoginController> {
  const RecruiterLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyAuthHeader(height: 180, showLeading: true, onLeadingTap: () => Get.back(), foregroundIcon: Icons.business),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text('Connexion Recruteur', style: AppTextStyles.displayMd),
                const SizedBox(height: 20),
                AuthTextField(
                  label: 'Email', 
                  controller: controller.emailCtrl, 
                  keyboardType: TextInputType.emailAddress, 
                  validator: controller.validateEmail,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  label: 'Mot de passe', 
                  controller: controller.passwordCtrl, 
                  obscureText: true,
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: 30),
                Obx(() => AuthCtaButton(
                  label: 'Se connecter', 
                  isLoading: controller.isLoading.value, 
                  onPressed: () => controller.login(),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
