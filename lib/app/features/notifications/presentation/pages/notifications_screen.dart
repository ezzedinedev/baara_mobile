import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../controllers/notifications_controller.dart';

class NotificationsScreen extends GetView<NotificationsController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SankSheetScaffold(
        title: 'Notifications',
        titleIcon: IconlyLight.notification,
        showBack: Navigator.of(context).canPop(),
        actions: [
          AppIconButton(
            onBrandHeader: true,
            icon: IconlyLight.tick_square,
            tooltip: 'Tout marquer comme lu',
            onTap: () {
              AppHaptics.tap();
              controller.markAllRead();
            },
          ),
        ],
        body: Obx(() {
          if (controller.isLoading.value) {
            return const PageSkeleton();
          }

          if (controller.notifications.isEmpty) {
            return const EmptyState(
              icon: IconlyLight.notification,
              title: 'Aucune notification',
              subtitle: 'Les nouvelles alertes apparaitront ici.',
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => controller.fetchNotifications(),
            child: AnimationLimiter(
              child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: controller.notifications.length +
                  (controller.hasMore.value ? 1 : 0),
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                // Sentinelle de fin de liste : déclenche le chargement de la
                // page suivante et affiche un indicateur.
                if (index >= controller.notifications.length) {
                  controller.loadMore();
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }
                final notification = controller.notifications[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 260),
                  child: SlideAnimation(
                    verticalOffset: 18,
                    child: FadeInAnimation(
                child: AppCard(
                  onTap: () {
                    AppHaptics.tap();
                    controller.markAsRead(notification.id);
                  },
                  borderColor: notification.isRead
                      ? null
                      : AppColors.primary.withValues(alpha: 0.40),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SoftCircleIcon(
                          icon: IconlyLight.notification,
                          color: notification.isRead
                              ? AppColors.bodyColor
                              : AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: AppTextStyles.titleLg.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w700
                                      : FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                notification.body,
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.bodyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                    ),
                  ),
                );
              },
              ),
            ),
          );
        }),
      ),
    );
  }
}

