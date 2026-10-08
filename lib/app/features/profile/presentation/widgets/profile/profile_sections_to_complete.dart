import 'dart:async';

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
import '../../controllers/profile_controller.dart';

typedef ProfileSection = ({
  String label,
  IconData icon,
  bool done,
  String route,
});

List<ProfileSection> profileSectionsFor(Profile p) => [
      (
        label: 'Titre',
        icon: AppIcons.network,
        done: (p.headline ?? '').trim().isNotEmpty,
        route: AppRoutes.profileEdit,
      ),
      (
        label: 'Bio',
        icon: AppIcons.document,
        done: (p.bio ?? '').trim().isNotEmpty,
        route: AppRoutes.profileEdit,
      ),
      (
        label: 'Compétences',
        icon: AppIcons.star,
        done: p.skills.isNotEmpty,
        route: AppRoutes.profileCvManual,
      ),
      (
        label: 'Expériences',
        icon: AppIcons.work,
        done: p.experiences.isNotEmpty,
        route: AppRoutes.profileParcours,
      ),
      (
        label: 'Education',
        icon: Icons.school_outlined,
        done: p.educations.isNotEmpty,
        route: AppRoutes.profileParcours,
      ),
      (
        label: 'Langues',
        icon: Icons.translate_rounded,
        done: p.languages.isNotEmpty,
        route: AppRoutes.profileCvManual,
      ),
    ];

class ProfileSectionsToComplete extends StatelessWidget {
  const ProfileSectionsToComplete({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final missing = profileSectionsFor(profile).where((s) => !s.done).toList();
    if (missing.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: ShapeDecoration(
          color: AppColors.surfaceIconSoft,
          shape: AppShapes.squircle(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 18, color: AppColors.primaryAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sections à compléter',
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Complétez votre profil pour augmenter vos chances auprès des recruteurs.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in missing)
                  PressScale(
                    onTap: () async {
                      AppHaptics.tap();
                      await Get.toNamed(s.route);
                      // Retour d'édition : la pastille doit disparaître si la
                      // section est maintenant remplie.
                      if (Get.isRegistered<ProfileController>()) {
                        unawaited(Get.find<ProfileController>().fetchProfile());
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: AppShapes.pill,
                        border: Border.all(
                            color: AppColors.primaryAccent
                                .withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(s.icon,
                              size: 14, color: AppColors.primaryAccent),
                          const SizedBox(width: 6),
                          Text(
                            s.label,
                            style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.titleColor,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          Icon(AppIcons.add,
                              size: 14, color: AppColors.primaryAccent),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
