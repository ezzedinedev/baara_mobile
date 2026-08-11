import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';

/// Accès rapides en BENTO : raccourcis vers les actions profondes (gain de
/// taps), tuiles de tailles variées (squircle, profondeur douce, icônes
/// colorées, press spring). Ne duplique pas la bottom nav.
class HomeQuickAccessRow extends StatelessWidget {
  const HomeQuickAccessRow({super.key});

  @override
  Widget build(BuildContext context) {
    // Tuile vedette (large, à gauche) + 3 tuiles compactes empilées à droite.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 1,
            child: HomeBentoTile(
              icon: AppIcons.workFilled,
              color: AppColors.categoryBlue,
              label: 'home.quick_applications'.tr,
              caption: 'home.quick_applications_caption'.tr,
              route: AppRoutes.myApplications,
              feature: true,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                HomeBentoTile(
                  icon: AppIcons.document,
                  color: AppColors.categoryPurple,
                  label: 'home.quick_cv'.tr,
                  route: AppRoutes.profileCv,
                ),
                const SizedBox(height: AppSpacing.sm),
                HomeBentoTile(
                  icon: AppIcons.folder,
                  color: AppColors.categoryCyan,
                  label: 'home.quick_documents'.tr,
                  route: AppRoutes.profileDocuments,
                ),
                const SizedBox(height: AppSpacing.sm),
                HomeBentoTile(
                  icon: AppIcons.bookmarkFilled,
                  color: AppColors.categoryOrange,
                  label: 'home.quick_portfolio'.tr,
                  route: AppRoutes.profilePortfolio,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tuile bento squircle. [feature] = grand format (icône XL + caption),
/// sinon format compact (icône + label sur une ligne).
class HomeBentoTile extends StatelessWidget {
  const HomeBentoTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.route,
    this.caption,
    this.feature = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String route;
  final String? caption;
  final bool feature;

  @override
  Widget build(BuildContext context) {
    final iconBadge = Container(
      width: feature ? 52 : 40,
      height: feature ? 52 : 40,
      decoration: ShapeDecoration(
        color: color,
        shape: AppShapes.squircle(feature ? AppRadius.md : AppRadius.sm),
        shadows: [
          BoxShadow(
            color: color.withValues(alpha: 0.32),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, size: feature ? 25 : 20, color: AppColors.onPrimary),
    );

    final content = feature
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconBadge,
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          )
        : Row(
            children: [
              iconBadge,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          );

    return PressScale(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(route);
      },
      child: Container(
        padding: EdgeInsets.all(feature ? AppSpacing.lg : AppSpacing.md),
        constraints: BoxConstraints(minHeight: feature ? 132 : 0),
        decoration: ShapeDecoration(
          color: AppColors.surfaceCard,
          shape: AppShapes.cardBordered(AppColors.outlineVariant),
          shadows: AppColors.lightShadow,
        ),
        child: content,
      ),
    );
  }
}
