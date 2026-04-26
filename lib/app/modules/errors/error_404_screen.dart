import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../../routes/app_routes.dart';

class Error404Screen extends StatelessWidget {
  const Error404Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -300,
            right: -300,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'JobAway',
                        style: AppTextStyles.displayMd.copyWith(
                          fontSize: 24,
                          color: AppColors.primary,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SERVER ACTIF',
                            style: AppTextStyles.labelSm.copyWith(
                              fontWeight: FontWeight.w600,
                              color:
                                  AppColors.primaryLight.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ERROR CODE',
                            style: AppTextStyles.labelLg.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3,
                              color:
                                  AppColors.primaryLight.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '404',
                            style: AppTextStyles.displayXl.copyWith(
                              fontSize: 120,
                              fontWeight: FontWeight.w900,
                              color:
                                  AppColors.titleColor.withValues(alpha: 0.1),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Oups ! Cette page semble être partie en vacances.',
                            style: AppTextStyles.headlineLg.copyWith(
                              fontSize: 24,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Le poste que vous recherchez a peut-être été pourvu, ou l'URL s'est perdue dans la forêt numérique. Ne vous inquiétez pas, votre carrière n'est qu'à un clic.",
                            style: AppTextStyles.bodyLg.copyWith(
                              color: AppColors.bodyColor.withValues(alpha: 0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () => Get.offAllNamed(AppRoutes.landing),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.home_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Retour à l\'accueil',
                                      style: AppTextStyles.buttonMd,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton(
                                onPressed: () => Get.offAllNamed(AppRoutes.landing),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.titleColor,
                                  side: BorderSide(
                                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.search_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Rechercher un job',
                                      style: AppTextStyles.titleMd,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'JobAway',
                        style: AppTextStyles.headlineMd.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFooterLink('Confidentialité'),
                          _buildDivider(),
                          _buildFooterLink('Conditions'),
                          _buildDivider(),
                          _buildFooterLink('Aide'),
                          _buildDivider(),
                          _buildFooterLink('Contact'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '© 2024 JobAway. Tous droits réservés.',
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                          color: AppColors.bodyColor.withValues(alpha: 0.5),
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
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: AppColors.bodyColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.outlineVariant.withValues(alpha: 0.3),
      ),
    );
  }
}