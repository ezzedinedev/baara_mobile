import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../controllers/register_profile_controller.dart';

class RegisterProfileScreen extends GetView<RegisterProfileController> {
  const RegisterProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyAuthHeader(height: 180, showLeading: true, onLeadingTap: () => Get.back()),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text('Quel est votre profil ?', style: AppTextStyles.displayMd),
                const SizedBox(height: 30),
                Obx(() => _ProfileOption(title: 'Étudiant', isSelected: controller.selectedProfile.value == 'student', onTap: () => controller.selectProfile('student'))),
                const SizedBox(height: 12),
                Obx(() => _ProfileOption(title: 'Professionnel', isSelected: controller.selectedProfile.value == 'professional', onTap: () => controller.selectProfile('professional'))),
                const Spacer(),
                AuthCtaButton(label: 'Continuer', onPressed: controller.onContinue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final String title; final bool isSelected; final VoidCallback onTap;
  const _ProfileOption({required this.title, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isSelected ? AppColors.surfaceSelected : AppColors.surfaceCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant)),
        child: Row(children: [Text(title, style: AppTextStyles.titleMd), const Spacer(), if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary)]),
      ),
    );
  }
}
