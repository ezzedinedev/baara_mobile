import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';
import 'package:jobaway/app/features/trainings/presentation/controllers/trainings_controller.dart';
import 'package:jobaway/app/features/trainings/presentation/widgets/training_card.dart';
import 'package:jobaway/routes/app_routes.dart';
import '../controllers/home_controller.dart';

/// Section « Formations pour toi » : aperçu vertical (jusqu'à 2 cartes) avec la
/// nouvelle carte formation. « Tout voir » bascule sur l'onglet Opportunités,
/// segment Formations présélectionné.
class HomeFormationsSection extends StatelessWidget {
  const HomeFormationsSection({super.key});

  static const _maxPreview = 2;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TrainingsController>();
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final items = controller.trainings;

      if (isLoading && items.isEmpty) {
        return const Column(
          children: [
            SizedBox(height: AppSpacing.xxl),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
              child: TrainingCardSkeleton(),
            ),
          ],
        );
      }
      if (items.isEmpty) return const SizedBox.shrink();

      final preview = items.take(_maxPreview).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            child: SectionHeader(
              title: 'home.section_trainings'.tr,
              actionLabel: 'common.see_all'.tr,
              onAction: () {
                AppHaptics.tap();
                Get.find<HomeController>().openOpportunites(segment: 1);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < preview.length; i++)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageH,
                0,
                AppSpacing.pageH,
                i == preview.length - 1 ? 0 : AppSpacing.md,
              ),
              child: TrainingCard(
                training: preview[i],
                // Tag Hero unique : évite un doublon avec l'onglet Formations
                // (mêmes cartes montées en même temps).
                heroTag: 'home-formation-${preview[i].id}',
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(
                    AppRoutes.trainingDetail.replaceFirst(':id', preview[i].id),
                  );
                },
              ),
            ),
        ],
      );
    });
  }
}
