import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';
import '../../../domain/entities/profile.dart';

class ProfileContactCard extends StatelessWidget {
  const ProfileContactCard({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    void edit() {
      AppHaptics.tap();
      Get.toNamed(AppRoutes.profileEdit);
    }

    final phone = profile.phone.trim();
    final email = profile.email.trim();
    final city = profile.city.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Coordonnées'),
        Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: ShapeDecoration(
              color: AppColors.surfaceCard,
              shape: AppShapes.cardBordered(AppColors.outlineVariant),
              shadows: [
                ...AppColors.lightShadow,
                ...AppColors.ambientShadow,
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ProfileContactRow(
                  icon: AppIcons.phone,
                  color: AppColors.categoryBlue,
                  value: phone.isEmpty ? 'Ajouter un numéro' : phone,
                  muted: phone.isEmpty,
                  onTap: edit,
                ),
                _rowDivider(),
                ProfileContactRow(
                  icon: AppIcons.message,
                  color: AppColors.categoryOrange,
                  value: email.isEmpty ? 'Ajouter un email' : email,
                  muted: email.isEmpty,
                  onTap: edit,
                ),
                _rowDivider(),
                ProfileContactRow(
                  icon: AppIcons.location,
                  color: AppColors.categoryCyan,
                  value: city.isEmpty ? 'Ajouter une ville' : city,
                  muted: city.isEmpty,
                  onTap: edit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _rowDivider() => Divider(
        height: 1,
        thickness: 1,
        indent: 60,
        color: AppColors.outlineVariant.withValues(alpha: 0.35),
      );
}

class ProfileContactRow extends StatelessWidget {
  const ProfileContactRow({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final Color color;
  final String value;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ProfileSquareTileIcon(icon: icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMd.copyWith(
                  color: muted ? AppColors.hintColor : AppColors.titleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(AppIcons.arrowRight, color: AppColors.outlineVariant),
          ],
        ),
      ),
    );
  }
}

class ProfileSquareTileIcon extends StatelessWidget {
  const ProfileSquareTileIcon({
    super.key,
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppShapes.squircleRadius(AppRadius.xs),
      ),
      child: Icon(icon, color: AppColors.onPrimary, size: 19),
    );
  }
}
