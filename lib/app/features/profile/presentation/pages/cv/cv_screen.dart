import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';

class CvScreen extends StatelessWidget {
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
            onLeadingTap: () => Get.back(),
          ),
          Expanded(
            child: RevealOnMount(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.xl,
                      AppSpacing.xxl,
                      AppSpacing.xs,
                    ),
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: AppColors.surfaceLow,
                        shape: AppShapes.cardBordered(
                          AppColors.outlineVariant,
                        ),
                        shadows: [
                          ...AppColors.ambientShadow,
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              IconlyLight.info_circle,
                              size: 18,
                              color: AppColors.hintColor,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Vos CV enregistrés apparaîtront ici.',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.hintColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: EmptyState(
                      illustration: const EmptyDocumentsIllustration(),
                      title: 'Aucun CV pour le moment',
                      subtitle:
                          'Créez votre premier CV professionnel en quelques '
                          'minutes avec notre assistant.',
                      actionLabel: 'Créer mon CV',
                      onAction: () => Get.toNamed(AppRoutes.profileCvBuilder),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
