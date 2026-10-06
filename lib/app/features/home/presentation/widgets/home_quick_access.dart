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

/// Accès rapides en bento : une tuile vedette (le suivi des candidatures,
/// l'action la plus fréquente) aux couleurs de la marque, et trois tuiles
/// calmes. Une seule couleur forte par bloc : la hiérarchie se lit d'un coup
/// d'œil. Ne duplique pas la barre de navigation.
class HomeQuickAccessRow extends StatelessWidget {
  const HomeQuickAccessRow({super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: HomeBentoTile(
              icon: AppIcons.workFilled,
              label: 'home.quick_applications'.tr,
              caption: 'home.quick_applications_caption'.tr,
              route: AppRoutes.myApplications,
              feature: true,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              children: [
                HomeBentoTile(
                  icon: AppIcons.document,
                  label: 'home.quick_cv'.tr,
                  route: AppRoutes.profileCv,
                ),
                const SizedBox(height: AppSpacing.sm),
                HomeBentoTile(
                  icon: AppIcons.folder,
                  label: 'home.quick_documents'.tr,
                  route: AppRoutes.profileDocuments,
                ),
                const SizedBox(height: AppSpacing.sm),
                HomeBentoTile(
                  icon: AppIcons.bookmarkFilled,
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

/// Tuile bento. [feature] = grand format vert forêt (icône sur pastille
/// citron, personnage Baara en filigrane, appel « Suivre ») ; sinon format
/// compact clair, icône monochrome de la marque.
class HomeBentoTile extends StatelessWidget {
  const HomeBentoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.route,
    this.caption,
    this.feature = false,
  });

  final IconData icon;
  final String label;
  final String route;
  final String? caption;
  final bool feature;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: caption == null ? label : '$label. $caption',
      excludeSemantics: true,
      child: PressScale(
        onTap: () {
          AppHaptics.tap();
          Get.toNamed(route);
        },
        child: feature ? _feature() : _compact(),
      ),
    );
  }

  Widget _feature() {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: BaaraMark.brandForest,
        shape: AppShapes.squircle(AppRadius.xl),
        shadows: AppColors.ambientShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            bottom: -30,
            child: BaaraMark(
              size: 120,
              color: Colors.white.withValues(alpha: 0.07),
              headColor: BaaraMark.brandLime.withValues(alpha: 0.14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: ShapeDecoration(
                    color: BaaraMark.brandLime,
                    shape: AppShapes.squircle(AppRadius.md),
                  ),
                  child: Icon(icon, size: 22, color: BaaraMark.brandForest),
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(
                      'Suivre',
                      style: AppTextStyles.labelMd.copyWith(
                        color: BaaraMark.brandLime,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      AppIcons.actionForward,
                      size: 15,
                      color: BaaraMark.brandLime,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compact() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: ShapeDecoration(
              color: AppColors.surfaceIconSoft,
              shape: AppShapes.squircle(AppRadius.sm),
            ),
            child: Icon(icon, size: 19, color: AppColors.primaryAccent),
          ),
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
          Icon(AppIcons.chevronRight, size: 16, color: AppColors.hintColor),
        ],
      ),
    );
  }
}
