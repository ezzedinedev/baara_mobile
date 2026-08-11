import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_text_styles.dart';
import '../../services/offline_apply_queue.dart';
import '../../utils/haptics.dart';

/// Bandeau discret quand des candidatures sont en attente d'envoi (hors-ligne).
class OfflineApplyBanner extends StatelessWidget {
  const OfflineApplyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<OfflineApplyQueue>()) return const SizedBox.shrink();

    final queue = Get.find<OfflineApplyQueue>();
    return Obx(() {
      final count = queue.pending.length;
      if (count <= 0) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          0,
          AppSpacing.pageH,
          AppSpacing.md,
        ),
        child: Material(
          color: AppColors.warningAccent.withValues(alpha: 0.12),
          borderRadius: AppShapes.squircleRadius(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.cloud_upload_outlined,
                    size: 20, color: AppColors.warningAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    count == 1
                        ? '1 candidature en attente — envoi dès le retour du réseau'
                        : '$count candidatures en attente — envoi dès le retour du réseau',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.titleColor,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: queue.isFlushing.value
                      ? null
                      : () {
                          AppHaptics.tap();
                          queue.flush();
                        },
                  child: Obx(
                    () => Text(
                      queue.isFlushing.value ? 'Envoi…' : 'Réessayer',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.warningAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
