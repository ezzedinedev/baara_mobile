import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../../routes/app_routes.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../controllers/cv_builder_controller.dart';

/// Écran d'accueil du CV Builder — choix du mode : assistant IA, éditeur
/// manuel, import. Affiche aussi la progression du CV actuel en tête.
class CvBuilderLandingScreen extends GetView<CvBuilderController> {
  const CvBuilderLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Créer mon CV', style: AppTextStyles.headlineSm),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            AppHaptics.tap();
            Navigator.of(context).maybePop();
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Mes CV importés',
            onPressed: () {
              AppHaptics.tap();
              Get.toNamed(AppRoutes.profileCv);
            },
            icon: const Icon(IconlyLight.document),
          ),
        ],
      ),
      body: Obx(() {
        final isLoading = controller.isLoading.value;
        final hasError = controller.errorMessage.value.isNotEmpty
            && controller.cv.value == null;

        if (isLoading && controller.cv.value == null) {
          return const PageSkeleton(rowCount: 4);
        }

        if (hasError) {
          return ErrorStateView(
            message: controller.errorMessage.value,
            onRetry: controller.load,
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.load,
          child: AnimationLimiter(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
              physics: const AlwaysScrollableScrollPhysics(),
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 320),
                childAnimationBuilder: (child) => SlideAnimation(
                  verticalOffset: 20,
                  child: FadeInAnimation(child: child),
                ),
                children: [
                  _ProgressHero(controller: controller),
                  const SizedBox(height: 24),
                  Text(
                    'Comment veux-tu construire ton CV ?',
                    style: AppTextStyles.headlineMd.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choisis la méthode qui te convient. Tu pourras alterner à tout moment.',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.bodyColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ModeCard(
                    icon: IconlyBold.star,
                    color: AppColors.categoryPurple,
                    title: 'Assistant IA',
                    subtitle:
                        'Laisse-toi guider par des questions simples. L\'IA remplit ton CV au fil de la conversation.',
                    badge: 'Recommandé',
                    onTap: () {
                      AppHaptics.tap();
                      Get.toNamed(AppRoutes.profileCvAssistant);
                    },
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    icon: IconlyLight.edit_square,
                    color: AppColors.categoryBlue,
                    title: 'Éditeur manuel',
                    subtitle:
                        'Remplis chaque section toi-même, à ton rythme. Utile si tu sais déjà ce que tu veux écrire.',
                    onTap: () {
                      AppHaptics.tap();
                      Get.toNamed(AppRoutes.profileCvManual);
                    },
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    icon: IconlyLight.paper_upload,
                    color: AppColors.categoryOrange,
                    title: 'Importer un CV existant',
                    subtitle:
                        'Envoie ton CV (PDF, DOCX) — l\'IA analyse, corrige et réécrit les sections pour toi.',
                    onTap: () {
                      AppHaptics.tap();
                      Get.toNamed(AppRoutes.profileCvImport);
                    },
                  ),
                  const SizedBox(height: 24),
                  _PreviewButton(controller: controller),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({required this.controller});
  final CvBuilderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pct = controller.completionPct.value;
      final level = controller.level.value;
      final nextLevel = controller.nextLevel.value;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.ambientShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    IconlyBold.document,
                    color: AppColors.onPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ton CV est rempli à $pct%',
                        style: AppTextStyles.titleLg.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                      if (level.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          nextLevel.isNotEmpty
                              ? 'Niveau $level · Prochain : $nextLevel'
                              : 'Niveau $level',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.onPrimary.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 8,
                backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.onPrimary),
              ),
            ),
            if (controller.badges.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: controller.badges
                    .take(4)
                    .map(
                      (b) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _badgeLabel(b),
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onPrimary,
                            fontSize: 10,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      );
    });
  }

  String _badgeLabel(String code) {
    return switch (code) {
      'premier_pas' => '🚀 Premier pas',
      'mi_chemin' => '🏃 Mi-chemin',
      'presque_la' => '🎯 Presque là',
      'maitre' => '🏆 Maître',
      'detaille' => '📝 Détaillé',
      'polyglotte' => '🌍 Polyglotte',
      'expert' => '⭐ Expert',
      'certifie' => '✅ Certifié',
      'en_serie' => '🔥 En série',
      'perso_pro' => '💼 Perso/Pro',
      _ => code,
    };
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // PressScale englobe le tap : scale-down 0.97 + haptic.
    return PressScale(
      onTap: onTap,
      child: BrandCard(
        padding: const EdgeInsets.all(16),
        radius: 18,
        borderColor: AppColors.outlineVariant.withValues(alpha: 0.2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: AppTextStyles.titleLg),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!.toUpperCase(),
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onPrimary,
                              fontSize: 9,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.bodyColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.hintColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({required this.controller});
  final CvBuilderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pct = controller.completionPct.value;
      return OutlinedButton.icon(
        onPressed: pct < 20
            ? null
            : () {
                AppHaptics.tap();
                Get.toNamed(AppRoutes.profileCvPreview);
              },
        icon: const Icon(IconlyLight.show),
        label: Text(
          pct < 20 ? 'Continuez à remplir pour prévisualiser' : 'Prévisualiser mon CV',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    });
  }
}
