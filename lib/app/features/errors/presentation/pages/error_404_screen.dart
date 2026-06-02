import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/routes/app_routes.dart';

class Error404Screen extends StatelessWidget {
  const Error404Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    size: 58,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Page introuvable',
                  style: AppTextStyles.displayMd,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "La page que vous cherchez n'existe pas ou a été déplacée.",
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.hintColor, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      AppHaptics.tap();
                      Get.offAllNamed(AppRoutes.home);
                    },
                    child: Text(
                      "Retour à l'accueil",
                      style: AppTextStyles.titleMd.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    AppHaptics.tap();
                    Get.back<void>();
                  },
                  child: Text(
                    'Revenir en arrière',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
