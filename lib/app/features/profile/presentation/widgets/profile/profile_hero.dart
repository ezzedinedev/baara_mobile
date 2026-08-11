import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/constants/api_constants.dart';
import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/theme/app_theme_controller.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';
import '../../../domain/entities/profile.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/settings_controller.dart';

class ProfileHero extends StatelessWidget {
  const ProfileHero({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: AppColors.meshBrand),
      foregroundDecoration: BoxDecoration(gradient: AppColors.meshBrandGlow),
      child: Column(
        children: [
          SizedBox(height: topPadding + 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      label: 'Titre: Profil de ${profile.fullName}',
                      child: Text(
                        'Profil',
                        style: AppTextStyles.displayHero.copyWith(
                          color: AppColors.titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.55),
                        borderRadius: AppShapes.pill,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() {
                      final theme = Get.find<AppThemeController>();
                      final isDark = theme.isDarkMode.value;
                      return AppIconButton(
                        icon: isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        tooltip: isDark ? 'Mode clair' : 'Mode sombre',
                        onTap: () {
                          AppHaptics.tap();
                          if (Get.isRegistered<SettingsController>()) {
                            Get.find<SettingsController>().setDarkMode(!isDark);
                          } else {
                            theme.setDarkMode(!isDark);
                          }
                        },
                      );
                    }),
                    const SizedBox(width: 10),
                    AppIconButton(
                      icon: AppIcons.edit,
                      onTap: () => Get.toNamed(AppRoutes.profileEdit),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              children: [
                Transform.translate(
                  offset: const Offset(0, -50),
                  child: Column(
                    children: [
                      ProfileFloatingAvatar(profile: profile),
                      const SizedBox(height: 16),
                      Text(
                        profile.fullName,
                        style: AppTextStyles.headlineMd.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          color: AppColors.titleColor,
                        ),
                      ),
                      if (profile.headline != null &&
                          profile.headline!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          profile.headline!,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 12),
                      ProfileMemberBadge(
                          isComplete: profile.isProfileComplete),
                    ],
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

class ProfileFloatingAvatar extends StatelessWidget {
  const ProfileFloatingAvatar({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    final pct = profile.completionPercent();
    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: CircularProgressIndicator(
              value: pct / 100,
              strokeWidth: 4,
              backgroundColor: AppColors.outlineVariant.withValues(alpha: 0.45),
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
            ),
          ),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceLow,
                  border: Border.all(color: AppColors.surfaceCard, width: 4),
                  boxShadow: [
                    ...AppColors.lightShadow,
                    ...AppColors.ambientShadow,
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      (profile.avatarUrl ?? '').isEmpty
                          ? Icon(
                              AppIcons.profile,
                              size: 60,
                              color: AppColors.primaryAccent,
                            )
                          : CachedNetworkImage(
                              imageUrl: ApiConstants.resolveMediaUrl(
                                      profile.avatarUrl) ??
                                  '',
                              fit: BoxFit.cover,
                              placeholder: (_, __) => ColoredBox(
                                color: AppColors.surfaceLow,
                                child: Icon(AppIcons.profile,
                                    size: 60, color: AppColors.primaryAccent),
                              ),
                              errorWidget: (_, __, ___) => ColoredBox(
                                color: AppColors.surfaceLow,
                                child: Icon(AppIcons.profile,
                                    size: 60, color: AppColors.primaryAccent),
                              ),
                            ),
                      Obx(() => controller.isUploadingAvatar.value
                          ? ColoredBox(
                              color: AppColors.onDark.withValues(alpha: 0.45),
                              child: Center(
                                child: AppLoader(
                                  size: 24,
                                  strokeWidth: 2.5,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            )
                          : const SizedBox.shrink()),
                    ],
                  ),
                ),
              ),
              PressScale(
                onTap: () {
                  AppHaptics.tap();
                  controller.pickAndUploadAvatar();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      ...AppColors.lightShadow,
                      ...AppColors.ambientShadow,
                    ],
                  ),
                  child: const Icon(
                    AppIcons.camera,
                    size: 18,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedCount(
              value: pct,
              builder: (ctx, v) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppShapes.pill,
                  border: Border.all(color: AppColors.surfaceCard, width: 2),
                ),
                child: Text(
                  '$v%',
                  style: AppTextStyles.heroNumber.copyWith(
                    color: AppColors.onPrimary,
                    fontSize: 10,
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

class ProfileMemberBadge extends StatelessWidget {
  const ProfileMemberBadge({super.key, required this.isComplete});

  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final color =
        isComplete ? AppColors.successAccent : AppColors.warningAccent;
    final bg = isComplete ? AppColors.successSoft : AppColors.warningSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppShapes.pill,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete
                ? AppIcons.shieldDone
                : Icons.workspace_premium_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            isComplete ? 'Profil complet' : 'Membre standard',
            style: AppTextStyles.labelSm.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
