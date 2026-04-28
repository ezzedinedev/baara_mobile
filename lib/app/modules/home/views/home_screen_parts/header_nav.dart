part of '../home_screen.dart';

// ignore: unused_element
class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.profileManager.profile.value;
      final isSelected =
          controller.currentTabIndex.value == HomeController.profileTabIndex;

      return InkWell(
        onTap: () {
          AppHaptics.tap();
          controller.goToProfile();
        },
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            shape: BoxShape.circle,
            boxShadow: AppColors.lightShadow,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: profile.hasAvatar
              ? CachedNetworkImage(
                  imageUrl: profile.avatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.person_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
        ),
      );
    });
  }
}

// ignore: unused_element
class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton();

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<AppThemeController>();

    return Obx(
      () => InkWell(
        onTap: () async {
          AppHaptics.tap();
          await themeController.toggle();
          // Synchronise la préférence locale du profil pour que le picker
          // "Thème" en paramètres reflète immédiatement le choix.
          if (Get.isRegistered<HomeController>()) {
            final manager = Get.find<HomeController>().profileManager;
            manager.preferences.value = manager.preferences.value.copyWith(
              theme: themeController.isDarkMode.value ? 'dark' : 'light',
            );
          }
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: AppColors.lightShadow,
          ),
          child: Icon(
            themeController.isDarkMode.value
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            size: 20,
            color: AppColors.titleColor,
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final unreadCount = controller.unreadNotificationsCount;
      return InkWell(
        onTap: () {
          AppHaptics.tap();
          Get.toNamed(AppRoutes.notifications);
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: AppColors.lightShadow,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 20,
                color: AppColors.titleColor,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -4,
                top: -5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onPrimary,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

/// Bottom nav avec effet pill-expand : l'item actif gagne un fond `onPrimary`
/// avec son label visible, les autres ne montrent que l'icone et se compactent.
class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<HomeNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        // Le gradient mène avec primary (vert vibrant de la landing) puis
        // décline vers primaryMedium pour rester énergique. L'olive sombre
        // ne sert plus que pour l'ombre portée — accent et non dominante.
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.primary, AppColors.primaryMedium],
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryDeep.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.26),
        ),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = index == currentIndex;
          return Expanded(
            // L'item selectionne occupe 2x l'espace pour accueillir le label,
            // les autres restent compacts (icone seule centree).
            flex: selected ? 2 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: () => onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.onPrimary.withValues(alpha: 0.95)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[index].icon,
                          size: 22,
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.onPrimary,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: selected
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    items[index].label.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.titleMd.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
