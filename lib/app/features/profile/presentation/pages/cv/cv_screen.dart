import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';
import 'package:jobaway/routes/app_routes.dart';

import '../../controllers/my_cv_controller.dart';

/// « Mes CVs » : l'état réel du CV du candidat, chargé depuis l'API.
/// L'écran affichait auparavant un vide codé en dur — il annonçait « Aucun CV »
/// même à quelqu'un dont le CV était déjà complet sur la plateforme.
class CvScreen extends GetView<MyCvController> {
  const CvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyContentHeader(
            title: 'Mes CVs',
            subtitle: 'Créez et gérez vos CV professionnels',
            height: 200,
            gradient: AppColors.heroProfileGradient,
            onLeadingTap: () => Get.back<void>(),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const PageSkeleton(showHero: false);
              }
              if (controller.errorMessage.value != null) {
                return ErrorStateView(
                  message: controller.errorMessage.value!,
                  illustration: const ErrorIllustration(),
                  onRetry: controller.load,
                );
              }
              if (!controller.hasCv.value) {
                return EmptyState(
                  illustration: const EmptyDocumentsIllustration(),
                  title: 'Aucun CV pour le moment',
                  subtitle: 'Créez votre premier CV professionnel en quelques '
                      'minutes avec notre assistant.',
                  actionLabel: 'Créer mon CV',
                  onAction: () => Get.toNamed<void>(AppRoutes.profileCvBuilder),
                );
              }
              return AppRefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                  ),
                  children: const [
                    _CvCard(),
                    SizedBox(height: AppSpacing.lg),
                    _CvActions(),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CvCard extends StatelessWidget {
  const _CvCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MyCvController>();
    return Obx(() {
      final pct = controller.completionPct.value;
      final headline = controller.headline.value;
      return RevealOnMount(
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: AppColors.surfaceLow,
            shape: AppShapes.cardBordered(AppColors.outlineVariant),
            shadows: AppColors.ambientShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ScoreRing(
                      value: pct,
                      color: AppColors.primaryAccent,
                      size: 64,
                      strokeWidth: 6,
                      valueFontSize: 16,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mon CV',
                            style: AppTextStyles.titleMd.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.titleColor,
                            ),
                          ),
                          if (headline.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              headline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            'Complété à $pct %',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    _CvStat(
                      icon: IconlyLight.work,
                      value: controller.experienceCount.value,
                      label: 'Expériences',
                    ),
                    _CvStat(
                      icon: IconlyLight.document,
                      value: controller.educationCount.value,
                      label: 'Formations',
                    ),
                    _CvStat(
                      icon: IconlyLight.star,
                      value: controller.skillCount.value,
                      label: 'Compétences',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _CvStat extends StatelessWidget {
  const _CvStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryAccent),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: AppTextStyles.titleMd.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.titleColor,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.hintColor),
          ),
        ],
      ),
    );
  }
}

class _CvActions extends StatelessWidget {
  const _CvActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GradientButton(
          label: 'APERÇU & TÉLÉCHARGEMENT',
          textColor: AppColors.onPrimary,
          height: 52,
          borderRadius: 14,
          onPressed: () {
            AppHaptics.tap();
            Get.toNamed<void>(AppRoutes.profileCvPreview);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ActionTile(
              icon: IconlyLight.edit,
              label: 'Modifier',
              onTap: () {
                AppHaptics.tap();
                Get.toNamed<void>(AppRoutes.profileCvManual);
              },
            ),
            ActionTile(
              icon: IconlyLight.chat,
              label: 'Assistant',
              onTap: () {
                AppHaptics.tap();
                Get.toNamed<void>(AppRoutes.profileCvAssistant);
              },
            ),
            ActionTile(
              icon: IconlyLight.upload,
              label: 'Importer',
              onTap: () {
                AppHaptics.tap();
                Get.toNamed<void>(AppRoutes.profileCvImport);
              },
            ),
          ],
        ),
      ],
    );
  }
}
