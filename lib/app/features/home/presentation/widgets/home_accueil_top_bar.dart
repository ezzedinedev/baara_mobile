import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/app/features/messaging/presentation/controllers/messages_controller.dart';
import 'package:baara/app/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:baara/app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:baara/routes/app_routes.dart';
import '../controllers/home_controller.dart';

/// Top bar plat (SafeArea) : avatar + salutation + vrai prénom, cloche à
/// droite. Tap avatar/greeting → onglet Profil ; tap cloche → notifications.
class HomeAccueilTopBar extends StatelessWidget {
  const HomeAccueilTopBar({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'home.greeting_morning'.tr;
    if (hour < 18) return 'home.greeting_afternoon'.tr;
    return 'home.greeting_evening'.tr;
  }

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();

    return Container(
      // Mesh de marque subtil sous la salutation (effet hero doux, dark-aware).
      decoration: BoxDecoration(gradient: AppColors.meshBrand),
      foregroundDecoration: BoxDecoration(gradient: AppColors.meshBrandGlow),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageH,
            AppSpacing.md,
            AppSpacing.pageH,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              Expanded(
                child: Obx(() {
                  final profile = profileController.profile.value;
                  final firstName = profile?.firstName.trim() ?? '';
                  final greetingName =
                      firstName.isEmpty ? 'home.welcome'.tr : firstName;
                  final initials = firstName.isEmpty ? 'OB' : firstName;

                  return InkWell(
                    onTap: () {
                      AppHaptics.tap();
                      Get.find<HomeController>().changeTab(4);
                    },
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          BrandAvatar(
                            seed: profile?.email ?? greetingName,
                            label: initials,
                            size: 48,
                            imageUrl: profile?.avatarUrl,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _greeting(),
                                  style: AppTextStyles.labelMd.copyWith(
                                    color: AppColors.bodyColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Prénom en typo expressive (lourde + serrée).
                                Text(
                                  greetingName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.displayHero
                                      .copyWith(fontSize: 24),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Accès rapide messagerie (déplacé de la bottom nav vers le haut).
              // Pastille = total des conversations non lues.
              Obx(() {
                final messages = Get.isRegistered<MessagesController>()
                    ? Get.find<MessagesController>()
                    : null;
                final unread = messages == null
                    ? 0
                    : messages.conversations
                        .fold<int>(0, (sum, c) => sum + c.unreadCount);
                final button = AppIconButton(
                  icon: AppIcons.chat,
                  tooltip: 'Messages',
                  onTap: () {
                    AppHaptics.tap();
                    Get.toNamed(AppRoutes.messages);
                  },
                );
                if (unread <= 0) return button;
                return Badge(
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  backgroundColor: AppColors.error,
                  child: button,
                );
              }),
              const SizedBox(width: AppSpacing.sm),
              Obx(() {
                final unread = Get.isRegistered<NotificationsController>()
                    ? Get.find<NotificationsController>().unreadCount.value
                    : 0;
                final bell = AppIconButton(
                  icon: AppIcons.bell,
                  onTap: () {
                    AppHaptics.tap();
                    Get.toNamed(AppRoutes.notifications);
                  },
                );
                if (unread <= 0) return bell;
                return Badge(
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  backgroundColor: AppColors.error,
                  child: bell,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
