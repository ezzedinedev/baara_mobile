import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/app/features/streak/presentation/controllers/streak_controller.dart';
import 'package:baara/routes/app_routes.dart';

/// Carte d'accès à la série quotidienne (gamification de rétention).
class ProfileStreakCard extends StatelessWidget {
  const ProfileStreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<StreakController>()) return const SizedBox.shrink();
    final streak = Get.find<StreakController>();
    return PressScale(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(AppRoutes.streak);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: ShapeDecoration(
          color: AppColors.surfaceCard,
          shape: AppShapes.cardBordered(AppColors.outlineVariant),
          shadows: AppColors.lightShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: AppShapes.squircleRadius(AppRadius.sm),
              ),
              child: Text('🔥', style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    final n = streak.currentStreak.value;
                    return Text(
                      n <= 0
                          ? 'Démarrez votre série'
                          : '$n jour${n > 1 ? "s" : ""} de suite',
                      style: AppTextStyles.titleMd
                          .copyWith(fontWeight: FontWeight.w800),
                    );
                  }),
                  const SizedBox(height: 2),
                  Text(
                    'Votre série de connexions quotidiennes',
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.hintColor),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.arrowRight, color: AppColors.outlineVariant),
          ],
        ),
      ),
    );
  }
}
