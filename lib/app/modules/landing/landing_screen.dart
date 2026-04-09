import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/opportune_logo.dart';
import 'landing_controller.dart';

class LandingScreen extends GetView<LandingController> {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -70,
            right: -45,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            top: 90,
            right: 10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryMedium.withValues(alpha: 0.11),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const OpportuneLogo(iconSize: 18, fontSize: 20),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withValues(alpha: 0.22),
                              blurRadius: 34,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'PLATEFORME NATIONALE',
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.onPrimary,
                                  letterSpacing: 1.1,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Ton prochain\nemploi commence\nmaintenant.',
                              style: AppTextStyles.displayLg.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 40,
                                height: 1.03,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Postule vite, suis tes candidatures\net connecte-toi aux meilleurs recruteurs.',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onPrimary.withValues(alpha: 0.90),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Row(
                              children: const [
                                Expanded(child: _HeroStat(value: '+12K', label: 'Offres')),
                                SizedBox(width: 10),
                                Expanded(child: _HeroStat(value: '24h', label: 'Reponse')),
                                SizedBox(width: 10),
                                Expanded(child: _HeroStat(value: '100%', label: 'Burkina')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Pourquoi OpporTune BF ?',
                        style: AppTextStyles.headlineMd.copyWith(
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _FeatureTile(
                        icon: Icons.flash_on_rounded,
                        title: 'Candidature rapide',
                        subtitle:
                            'Un profil unique pour postuler en quelques secondes.',
                      ),
                      const SizedBox(height: 10),
                      const _FeatureTile(
                        icon: Icons.verified_user_rounded,
                        title: 'Offres verifiees',
                        subtitle: 'Des entreprises serieuses et des opportunites qualifiees.',
                      ),
                      const SizedBox(height: 10),
                      const _FeatureTile(
                        icon: Icons.insights_rounded,
                        title: 'Suivi intelligent',
                        subtitle: 'Visualise tes candidatures et avance sans perdre de temps.',
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.lightShadow,
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Pret a commencer ?',
                              style: AppTextStyles.titleLg.copyWith(
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Choisis ton profil et entre dans ton espace.',
                              style: AppTextStyles.bodySm,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            GradientButton(
                              label: 'COMMENCER',
                              onPressed: controller.goToProfileSelection,
                              height: 56,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.headlineMd.copyWith(
              color: AppColors.onPrimary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.85),
              letterSpacing: 0.8,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceIconSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySm.copyWith(
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
